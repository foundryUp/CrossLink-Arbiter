#!/usr/bin/env python3
"""
AI Planner Agent - Hackathon Version
Calculates optimal arbitrage routes using Amazon Bedrock
"""

import asyncio
import json
import logging
import sqlite3
import time
from datetime import datetime
from typing import Dict, List, Optional, Tuple

import boto3
from web3 import Web3

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ArbitragePlanner:
    """Simplified AI planner for calculating optimal arbitrage routes"""
    
    def __init__(self, config_path: str = "config/chains.json"):
        self.db_path = "arbitrage_data.db"
        self.bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
        
        # Simplified configuration
        self.config = {
            "min_profit_bps": 20,  # 0.2% minimum profit
            "max_trade_size_usd": 50000,  # $50k max trade size
            "max_slippage_bps": 300,  # 3% max slippage
            "bridge_fee_usd": 8,  # $8 CCIP bridge fee
        }
        
    async def process_opportunity(self, opportunity: Dict) -> Optional[Dict]:
        """Process detected opportunity and create execution plan"""
        try:
            # Calculate optimal trade size
            optimal_size = await self._calculate_optimal_size(opportunity)
            
            if not optimal_size:
                logger.warning(f"No profitable size found for {opportunity['token']}")
                return None
            
            # Generate execution plan
            plan = await self._generate_plan(opportunity, optimal_size)
            
            # Validate with AI
            validated_plan = await self._ai_validate_plan(plan)
            
            if validated_plan:
                await self._store_plan(validated_plan)
                logger.info(f"Plan created: {validated_plan['plan_id']} - "
                           f"${validated_plan['expected_profit']:.2f} profit")
                return validated_plan
            
            return None
            
        except Exception as e:
            logger.error(f"Error processing opportunity: {e}")
            return None
    
    async def _calculate_optimal_size(self, opportunity: Dict) -> Optional[Dict]:
        """Calculate optimal trade size considering slippage and fees"""
        try:
            token = opportunity['token']
            price_a = opportunity['price_a']
            price_b = opportunity['price_b']
            spread_bps = opportunity['spread_bps']
            
            # Simple size calculation (in production would be more sophisticated)
            base_price = min(price_a, price_b)
            
            # Calculate different trade sizes and their profitability
            sizes_usd = [1000, 5000, 10000, 25000, 50000]  # Test sizes
            best_size = None
            best_profit = 0
            
            for size_usd in sizes_usd:
                if size_usd > self.config["max_trade_size_usd"]:
                    continue
                    
                # Simplified slippage calculation
                # In reality would query DEX contracts
                slippage_bps = self._estimate_slippage(size_usd, token)
                
                # Calculate net profit
                gross_profit = size_usd * spread_bps / 10000
                slippage_cost = size_usd * slippage_bps / 10000
                bridge_cost = self.config["bridge_fee_usd"]
                gas_cost = self._estimate_gas_cost(size_usd)
                
                net_profit = gross_profit - slippage_cost - bridge_cost - gas_cost
                net_profit_bps = (net_profit / size_usd) * 10000
                
                if net_profit_bps > self.config["min_profit_bps"] and net_profit > best_profit:
                    best_profit = net_profit
                    best_size = {
                        "size_usd": size_usd,
                        "size_tokens": size_usd / base_price,
                        "expected_profit": net_profit,
                        "profit_bps": net_profit_bps,
                        "slippage_bps": slippage_bps
                    }
            
            return best_size
            
        except Exception as e:
            logger.error(f"Error calculating optimal size: {e}")
            return None
    
    def _estimate_slippage(self, size_usd: float, token: str) -> float:
        """Estimate slippage for given trade size (simplified)"""
        # Simplified slippage model
        # In production would query actual DEX pools
        base_slippage = {
            'WETH': 5,   # 0.05% base slippage
            'USDC': 2,   # 0.02% base slippage
            'USDT': 3,   # 0.03% base slippage
            'WBTC': 8    # 0.08% base slippage
        }
        
        base = base_slippage.get(token, 10)
        
        # Slippage increases with trade size
        size_multiplier = (size_usd / 10000) ** 0.5  # Square root scaling
        
        return base * size_multiplier
    
    def _estimate_gas_cost(self, size_usd: float) -> float:
        """Estimate total gas costs (simplified)"""
        # Simplified gas estimation
        # Arbitrum gas: ~$2-5
        # Avalanche gas: ~$1-3
        # CCIP: included in bridge fee
        
        base_gas = 8  # $8 base gas cost
        
        # Larger trades might need more gas
        if size_usd > 25000:
            base_gas += 5
        
        return base_gas
    
    async def _generate_plan(self, opportunity: Dict, size_info: Dict) -> Dict:
        """Generate detailed execution plan"""
        plan_id = f"ARB_{int(time.time())}_{opportunity['token']}"
        
        # Determine trade direction
        buy_chain = 'arbitrum' if opportunity['price_a'] < opportunity['price_b'] else 'avalanche'
        sell_chain = 'avalanche' if buy_chain == 'arbitrum' else 'arbitrum'
        
        plan = {
            "plan_id": plan_id,
            "timestamp": int(time.time()),
            "token": opportunity['token'],
            "direction": f"{buy_chain}_to_{sell_chain}",
            "trade_size_usd": size_info["size_usd"],
            "trade_size_tokens": size_info["size_tokens"],
            "expected_profit": size_info["expected_profit"],
            "profit_bps": size_info["profit_bps"],
            "buy_chain": buy_chain,
            "sell_chain": sell_chain,
            "buy_price": opportunity['price_a'] if buy_chain == 'arbitrum' else opportunity['price_b'],
            "sell_price": opportunity['price_b'] if buy_chain == 'arbitrum' else opportunity['price_a'],
            "deadline": int(time.time()) + 300,  # 5 minute deadline
            "status": "pending_validation"
        }
        
        return plan
    
    async def _ai_validate_plan(self, plan: Dict) -> Optional[Dict]:
        """Use Amazon Bedrock to validate the arbitrage plan"""
        try:
            prompt = f"""
            Analyze this arbitrage plan and determine if it should be executed:
            
            PLAN DETAILS:
            - Token: {plan['token']}
            - Trade Size: ${plan['trade_size_usd']:,.2f} ({plan['trade_size_tokens']:.4f} tokens)
            - Direction: {plan['direction']}
            - Buy Price: ${plan['buy_price']:.2f}
            - Sell Price: ${plan['sell_price']:.2f}
            - Expected Profit: ${plan['expected_profit']:.2f} ({plan['profit_bps']:.1f} bps)
            - Time Limit: {plan['deadline'] - plan['timestamp']} seconds
            
            VALIDATION CRITERIA:
            1. Is profit margin > 0.2% after all costs?
            2. Is trade size reasonable for market conditions?
            3. Is price spread realistic and sustainable?
            4. Are there any obvious risk factors?
            
            Respond with JSON only:
            {{
                "approved": true/false,
                "confidence": 0-100,
                "reason": "brief explanation",
                "suggested_adjustments": "any modifications recommended"
            }}
            """
            
            response = self.bedrock.invoke_model(
                modelId='anthropic.claude-3-sonnet-20240229-v1:0',
                body=json.dumps({
                    'anthropic_version': 'bedrock-2023-05-31',
                    'max_tokens': 400,
                    'messages': [{'role': 'user', 'content': prompt}]
                })
            )
            
            result = json.loads(response['body'].read())
            ai_decision = json.loads(result['content'][0]['text'])
            
            if ai_decision.get('approved', False) and ai_decision.get('confidence', 0) > 70:
                plan['ai_validation'] = ai_decision
                plan['status'] = 'approved'
                logger.info(f"AI approved plan {plan['plan_id']}: {ai_decision['reason']}")
                return plan
            else:
                logger.warning(f"AI rejected plan {plan['plan_id']}: {ai_decision.get('reason', 'Unknown')}")
                return None
                
        except Exception as e:
            logger.error(f"Error in AI validation: {e}")
            return None
    
    async def _store_plan(self, plan: Dict):
        """Store approved plan in database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS arbitrage_plans (
                    plan_id TEXT PRIMARY KEY,
                    timestamp INTEGER,
                    token TEXT,
                    direction TEXT,
                    trade_size_usd REAL,
                    trade_size_tokens REAL,
                    expected_profit REAL,
                    profit_bps REAL,
                    buy_chain TEXT,
                    sell_chain TEXT,
                    buy_price REAL,
                    sell_price REAL,
                    deadline INTEGER,
                    status TEXT,
                    ai_validation TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            cursor.execute('''
                INSERT INTO arbitrage_plans 
                (plan_id, timestamp, token, direction, trade_size_usd, trade_size_tokens,
                 expected_profit, profit_bps, buy_chain, sell_chain, buy_price, sell_price,
                 deadline, status, ai_validation)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                plan['plan_id'], plan['timestamp'], plan['token'], plan['direction'],
                plan['trade_size_usd'], plan['trade_size_tokens'], plan['expected_profit'],
                plan['profit_bps'], plan['buy_chain'], plan['sell_chain'],
                plan['buy_price'], plan['sell_price'], plan['deadline'], plan['status'],
                json.dumps(plan['ai_validation'])
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            logger.error(f"Error storing plan: {e}")

def main():
    """Main entry point for planner agent"""
    planner = ArbitragePlanner()
    
    # Example usage
    example_opportunity = {
        'token': 'WETH',
        'chain_a': 'arbitrum',
        'chain_b': 'avalanche',
        'price_a': 2485.0,
        'price_b': 2510.0,
        'spread_bps': 100,
        'profit_estimate': 25.0
    }
    
    try:
        plan = asyncio.run(planner.process_opportunity(example_opportunity))
        if plan:
            print(f"✅ Created plan: {plan['plan_id']}")
            print(f"💰 Expected profit: ${plan['expected_profit']:.2f}")
        else:
            print("❌ No profitable plan found")
    except KeyboardInterrupt:
        logger.info("Planner stopped by user")

if __name__ == "__main__":
    main() 