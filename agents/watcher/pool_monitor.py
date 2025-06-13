"""
Pool Monitor Agent - Watches DEX pools for arbitrage opportunities.

This agent continuously monitors liquidity pools on Arbitrum and Avalanche
to detect price discrepancies that could be profitable for arbitrage.
"""

import asyncio
import logging
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Dict, List, Optional, Set
import json

from web3 import Web3
from web3.contract import Contract
import redis
import structlog

from ..shared.models import (
    DEXPool, ArbitrageOpportunity, TokenInfo, DEXType, ChainType,
    MarketData, AgentConfig
)
from ..shared.utils import calculate_profit_bps
from ..config.chains_config import get_chain_config


logger = structlog.get_logger(__name__)


class PoolMonitor:
    """
    Monitors DEX pools for price discrepancies across chains.
    """
    
    def __init__(self, config: AgentConfig):
        self.config = config
        self.redis_client = redis.Redis.from_url(config.redis_url)
        self.opportunities: Set[str] = set()
        self.last_update: Dict[str, datetime] = {}
        
        # Web3 connections
        self.arbitrum_w3 = Web3(Web3.HTTPProvider(config.arbitrum_rpc))
        self.avalanche_w3 = Web3(Web3.HTTPProvider(config.avalanche_rpc))
        
        # Pool contracts cache
        self.pool_contracts: Dict[str, Contract] = {}
        self.token_contracts: Dict[str, Contract] = {}
        
        # Configuration
        self.chains_config = get_chain_config()
        self.monitored_pairs = self._load_monitored_pairs()
        
        logger.info("PoolMonitor initialized", pairs=len(self.monitored_pairs))
    
    async def start_monitoring(self):
        """Start the main monitoring loop."""
        logger.info("Starting pool monitoring")
        
        while True:
            try:
                await self._monitor_pools()
                await asyncio.sleep(self.config.update_interval_seconds)
                
            except Exception as e:
                logger.error("Error in monitoring loop", error=str(e))
                await asyncio.sleep(5)  # Short delay before retry
    
    async def _monitor_pools(self):
        """Monitor all configured pools for opportunities."""
        tasks = []
        
        for pair in self.monitored_pairs:
            task = asyncio.create_task(self._check_pair_opportunity(pair))
            tasks.append(task)
        
        # Execute all checks concurrently
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Process results
        opportunities_found = 0
        for i, result in enumerate(results):
            if isinstance(result, ArbitrageOpportunity):
                await self._handle_opportunity(result)
                opportunities_found += 1
            elif isinstance(result, Exception):
                logger.error("Pool check failed", pair=self.monitored_pairs[i], error=str(result))
        
        logger.debug("Pool monitoring cycle complete", opportunities=opportunities_found)
    
    async def _check_pair_opportunity(self, pair_config: Dict) -> Optional[ArbitrageOpportunity]:
        """Check a specific token pair for arbitrage opportunities."""
        try:
            # Get pool data from both chains
            arbitrum_pool = await self._get_pool_data(
                pair_config, ChainType.ARBITRUM
            )
            avalanche_pool = await self._get_pool_data(
                pair_config, ChainType.AVALANCHE
            )
            
            if not arbitrum_pool or not avalanche_pool:
                return None
            
            # Calculate price difference
            price_diff_bps = self._calculate_price_difference(
                arbitrum_pool, avalanche_pool
            )
            
            # Check if profitable opportunity exists
            if abs(price_diff_bps) >= self.config.min_profit_threshold_bps:
                return await self._create_opportunity(
                    arbitrum_pool, avalanche_pool, price_diff_bps
                )
            
            return None
            
        except Exception as e:
            logger.error("Failed to check pair", pair=pair_config, error=str(e))
            return None
    
    async def _get_pool_data(self, pair_config: Dict, chain: ChainType) -> Optional[DEXPool]:
        """Get current pool data for a specific chain."""
        try:
            w3 = self.arbitrum_w3 if chain == ChainType.ARBITRUM else self.avalanche_w3
            chain_config = self.chains_config[chain.value]
            
            # Get pool contract
            pool_address = pair_config[f"{chain.value}_pool"]
            pool_contract = await self._get_pool_contract(pool_address, chain)
            
            if not pool_contract:
                return None
            
            # Get reserves
            reserves = await self._get_pool_reserves(pool_contract, pair_config["dex"])
            
            if not reserves:
                return None
            
            # Create token info
            token_a = TokenInfo(
                symbol=pair_config["token_a"],
                address=pair_config[f"{chain.value}_token_a"],
                decimals=pair_config["decimals_a"],
                chain=chain
            )
            
            token_b = TokenInfo(
                symbol=pair_config["token_b"],
                address=pair_config[f"{chain.value}_token_b"],
                decimals=pair_config["decimals_b"],
                chain=chain
            )
            
            return DEXPool(
                dex=DEXType(pair_config["dex"]),
                chain=chain,
                token_a=token_a,
                token_b=token_b,
                reserve_a=Decimal(str(reserves[0])),
                reserve_b=Decimal(str(reserves[1])),
                pool_address=pool_address,
                fee_bps=pair_config["fee_bps"],
                last_updated=datetime.now()
            )
            
        except Exception as e:
            logger.error("Failed to get pool data", chain=chain.value, error=str(e))
            return None
    
    async def _get_pool_contract(self, pool_address: str, chain: ChainType) -> Optional[Contract]:
        """Get or create pool contract instance."""
        cache_key = f"{chain.value}:{pool_address}"
        
        if cache_key in self.pool_contracts:
            return self.pool_contracts[cache_key]
        
        try:
            w3 = self.arbitrum_w3 if chain == ChainType.ARBITRUM else self.avalanche_w3
            
            # Load appropriate ABI based on DEX type
            abi = self._get_pool_abi(chain)
            contract = w3.eth.contract(address=pool_address, abi=abi)
            
            self.pool_contracts[cache_key] = contract
            return contract
            
        except Exception as e:
            logger.error("Failed to create pool contract", address=pool_address, error=str(e))
            return None
    
    async def _get_pool_reserves(self, pool_contract: Contract, dex_type: str) -> Optional[tuple]:
        """Get reserves from pool contract."""
        try:
            if dex_type in ["sushiswap", "trader_joe", "pangolin"]:
                # Uniswap V2 style pools
                reserves = pool_contract.functions.getReserves().call()
                return (reserves[0], reserves[1])
            
            elif dex_type == "uniswap_v3":
                # Uniswap V3 pools - more complex calculation needed
                slot0 = pool_contract.functions.slot0().call()
                liquidity = pool_contract.functions.liquidity().call()
                # Simplified - real implementation would calculate reserves from sqrt price
                return (liquidity, liquidity)  # Placeholder
            
            else:
                logger.error("Unsupported DEX type", dex=dex_type)
                return None
                
        except Exception as e:
            logger.error("Failed to get reserves", error=str(e))
            return None
    
    def _calculate_price_difference(self, pool_a: DEXPool, pool_b: DEXPool) -> int:
        """Calculate price difference in basis points."""
        try:
            # Get prices (token A in terms of token B)
            price_a = pool_a.price_a_to_b
            price_b = pool_b.price_a_to_b
            
            if price_a == 0 or price_b == 0:
                return 0
            
            # Calculate percentage difference
            diff = abs(price_a - price_b) / min(price_a, price_b)
            return int(diff * 10000)  # Convert to basis points
            
        except Exception as e:
            logger.error("Failed to calculate price difference", error=str(e))
            return 0
    
    async def _create_opportunity(
        self,
        arbitrum_pool: DEXPool,
        avalanche_pool: DEXPool,
        price_diff_bps: int
    ) -> ArbitrageOpportunity:
        """Create an arbitrage opportunity object."""
        
        # Determine trade direction
        if arbitrum_pool.price_a_to_b < avalanche_pool.price_a_to_b:
            # Buy on Arbitrum, sell on Avalanche
            origin_pool = arbitrum_pool
            destination_pool = avalanche_pool
            token_in = arbitrum_pool.token_a
            token_out = arbitrum_pool.token_b
        else:
            # Buy on Avalanche, sell on Arbitrum
            origin_pool = avalanche_pool
            destination_pool = arbitrum_pool
            token_in = avalanche_pool.token_a
            token_out = avalanche_pool.token_b
        
        # Calculate optimal trade size
        amount_in = await self._calculate_optimal_size(origin_pool, destination_pool)
        
        # Estimate output and profit
        expected_amount_out = await self._estimate_output(
            origin_pool, destination_pool, amount_in
        )
        
        # Estimate gas costs
        gas_estimate = await self._estimate_gas_costs(origin_pool, destination_pool)
        
        # Calculate expected profit
        expected_profit = expected_amount_out - amount_in - Decimal(str(gas_estimate))
        profit_bps = calculate_profit_bps(amount_in, expected_amount_out, Decimal(str(gas_estimate)))
        
        # Calculate confidence score
        confidence_score = self._calculate_confidence(
            origin_pool, destination_pool, price_diff_bps
        )
        
        opportunity_id = f"{token_in.symbol}_{token_out.symbol}_{int(datetime.now().timestamp())}"
        
        return ArbitrageOpportunity(
            id=opportunity_id,
            origin_pool=origin_pool,
            destination_pool=destination_pool,
            token_in=token_in,
            token_out=token_out,
            amount_in=amount_in,
            expected_amount_out=expected_amount_out,
            expected_profit=expected_profit,
            profit_bps=profit_bps,
            gas_estimate=gas_estimate,
            confidence_score=confidence_score,
            detected_at=datetime.now()
        )
    
    async def _calculate_optimal_size(self, origin_pool: DEXPool, destination_pool: DEXPool) -> Decimal:
        """Calculate optimal trade size for maximum profit."""
        # Simplified calculation - real implementation would use more sophisticated math
        max_size = min(
            origin_pool.reserve_a * Decimal("0.1"),  # Max 10% of pool
            self.config.max_trade_size_usd
        )
        return max_size
    
    async def _estimate_output(
        self, 
        origin_pool: DEXPool, 
        destination_pool: DEXPool, 
        amount_in: Decimal
    ) -> Decimal:
        """Estimate output amount after both swaps."""
        # Simplified estimation - real implementation would simulate actual swaps
        first_output = amount_in * origin_pool.price_a_to_b
        final_output = first_output * destination_pool.price_b_to_a
        return final_output
    
    async def _estimate_gas_costs(self, origin_pool: DEXPool, destination_pool: DEXPool) -> int:
        """Estimate total gas costs for the arbitrage."""
        # Simplified estimation
        swap_gas = 150000  # Gas for DEX swap
        ccip_gas = 300000  # Gas for CCIP transfer
        remote_gas = 100000  # Gas for remote execution
        
        # Get current gas prices
        arbitrum_gas_price = await self._get_gas_price(ChainType.ARBITRUM)
        avalanche_gas_price = await self._get_gas_price(ChainType.AVALANCHE)
        
        total_gas_cost = (
            (swap_gas + ccip_gas) * arbitrum_gas_price +
            remote_gas * avalanche_gas_price
        )
        
        return int(total_gas_cost)
    
    async def _get_gas_price(self, chain: ChainType) -> int:
        """Get current gas price for a chain."""
        try:
            w3 = self.arbitrum_w3 if chain == ChainType.ARBITRUM else self.avalanche_w3
            return w3.eth.gas_price
        except:
            # Fallback gas prices
            return 1000000000 if chain == ChainType.ARBITRUM else 25000000000
    
    def _calculate_confidence(
        self, 
        origin_pool: DEXPool, 
        destination_pool: DEXPool, 
        price_diff_bps: int
    ) -> float:
        """Calculate confidence score for the opportunity."""
        # Factors affecting confidence:
        # 1. Price difference magnitude
        # 2. Pool liquidity
        # 3. Time since last update
        
        # Base confidence from price difference
        confidence = min(price_diff_bps / 1000.0, 1.0)  # Max at 10% diff
        
        # Adjust for liquidity
        min_liquidity = min(origin_pool.reserve_a, destination_pool.reserve_a)
        if min_liquidity < 1000:  # Low liquidity penalty
            confidence *= 0.5
        
        # Adjust for data freshness
        data_age = (datetime.now() - origin_pool.last_updated).total_seconds()
        if data_age > 60:  # Older than 1 minute
            confidence *= 0.8
        
        return max(0.0, min(1.0, confidence))
    
    async def _handle_opportunity(self, opportunity: ArbitrageOpportunity):
        """Handle a detected arbitrage opportunity."""
        # Avoid duplicate opportunities
        if opportunity.id in self.opportunities:
            return
        
        self.opportunities.add(opportunity.id)
        
        # Store in Redis for planner agent
        await self._store_opportunity(opportunity)
        
        # Log the opportunity
        logger.info(
            "Arbitrage opportunity detected",
            id=opportunity.id,
            profit_bps=opportunity.profit_bps,
            confidence=opportunity.confidence_score,
            origin=opportunity.origin_pool.chain.value,
            destination=opportunity.destination_pool.chain.value
        )
        
        # Cleanup old opportunities
        await self._cleanup_old_opportunities()
    
    async def _store_opportunity(self, opportunity: ArbitrageOpportunity):
        """Store opportunity in Redis for other agents."""
        try:
            key = f"opportunity:{opportunity.id}"
            value = opportunity.to_dict()
            
            # Store with expiration
            await self.redis_client.setex(
                key, 
                timedelta(minutes=5).total_seconds(),
                json.dumps(value)
            )
            
            # Add to opportunities list
            await self.redis_client.lpush("opportunities", opportunity.id)
            await self.redis_client.ltrim("opportunities", 0, 100)  # Keep last 100
            
        except Exception as e:
            logger.error("Failed to store opportunity", error=str(e))
    
    async def _cleanup_old_opportunities(self):
        """Remove old opportunities from tracking."""
        cutoff_time = datetime.now() - timedelta(minutes=10)
        
        # Remove from memory
        self.opportunities = {
            opp_id for opp_id in self.opportunities 
            if self._get_opportunity_time(opp_id) > cutoff_time
        }
    
    def _get_opportunity_time(self, opportunity_id: str) -> datetime:
        """Extract timestamp from opportunity ID."""
        try:
            timestamp = int(opportunity_id.split('_')[-1])
            return datetime.fromtimestamp(timestamp)
        except:
            return datetime.now()
    
    def _load_monitored_pairs(self) -> List[Dict]:
        """Load configuration for monitored trading pairs."""
        # This would load from configuration file
        # For now, return example configuration
        return [
            {
                "token_a": "WETH",
                "token_b": "USDC",
                "dex": "sushiswap",
                "fee_bps": 30,
                "decimals_a": 18,
                "decimals_b": 6,
                "arbitrum_pool": "0x905dfCD5649c72037CbC4b0b7F6Fc5B7f1ba46B9",
                "arbitrum_token_a": "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
                "arbitrum_token_b": "0xA0b86a33E6417c4d75A664794d4A4D32Bd7ed31F",
                "avalanche_pool": "0xfE15c2695F1F920da45C30AAE47d11dE51007AF9",
                "avalanche_token_a": "0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB",
                "avalanche_token_b": "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E"
            }
            # Add more pairs as needed
        ]
    
    def _get_pool_abi(self, chain: ChainType) -> List:
        """Get ABI for pool contracts."""
        # Simplified ABI for Uniswap V2 style pools
        return [
            {
                "constant": True,
                "inputs": [],
                "name": "getReserves",
                "outputs": [
                    {"name": "_reserve0", "type": "uint112"},
                    {"name": "_reserve1", "type": "uint112"},
                    {"name": "_blockTimestampLast", "type": "uint32"}
                ],
                "type": "function"
            }
        ]


# Entry point for the agent
if __name__ == "__main__":
    config = AgentConfig.from_env()
    monitor = PoolMonitor(config)
    
    asyncio.run(monitor.start_monitoring()) 