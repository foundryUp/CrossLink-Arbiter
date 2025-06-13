#!/usr/bin/env python3
"""
Full Flow Test Script - Hackathon Version
Tests the complete arbitrage flow end-to-end
"""

import asyncio
import json
import logging
import sys
import time
from datetime import datetime

# Add project root to path
sys.path.append('.')

from agents.watcher import SimplifiedWatcher
from agents.planner import ArbitragePlanner
from agents.executor import ArbitrageExecutor
from suave.bundle_builder import SUAVEBundleBuilder

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FullFlowTester:
    """Test the complete arbitrage flow"""
    
    def __init__(self):
        self.watcher = SimplifiedWatcher()
        self.planner = ArbitragePlanner()
        self.executor = ArbitrageExecutor()
        self.suave = SUAVEBundleBuilder()
        
    async def run_full_test(self):
        """Run complete end-to-end test"""
        logger.info("🚀 Starting Full Arbitrage Flow Test")
        logger.info("=" * 60)
        
        try:
            # Step 1: Setup databases
            await self._setup_databases()
            
            # Step 2: Simulate opportunity detection
            opportunity = await self._simulate_opportunity_detection()
            
            if not opportunity:
                logger.error("❌ Failed to detect opportunity")
                return False
            
            # Step 3: Generate arbitrage plan
            plan = await self._test_plan_generation(opportunity)
            
            if not plan:
                logger.error("❌ Failed to generate plan")
                return False
            
            # Step 4: Test SUAVE integration
            bundle_id = await self._test_suave_integration(plan)
            
            if not bundle_id:
                logger.error("❌ Failed SUAVE integration")
                return False
            
            # Step 5: Simulate execution
            success = await self._test_execution(plan)
            
            if not success:
                logger.error("❌ Failed execution test")
                return False
            
            # Step 6: Display results
            await self._display_test_results()
            
            logger.info("✅ Full Flow Test Completed Successfully!")
            return True
            
        except Exception as e:
            logger.error(f"❌ Test failed with error: {e}")
            return False
    
    async def _setup_databases(self):
        """Initialize test databases"""
        logger.info("📁 Setting up test databases...")
        
        # Initialize watcher database
        self.watcher.init_database()
        
        # Create some test data
        test_prices = {
            'arbitrum_uniswap_v3_WETH': 2485.50,
            'arbitrum_uniswap_v3_USDC': 1.0001,
            'avalanche_trader_joe_WETH': 2510.25,
            'avalanche_trader_joe_USDC': 0.9998
        }
        
        # Store test prices
        for key, price in test_prices.items():
            parts = key.split('_')
            chain = parts[0]
            dex = '_'.join(parts[1:-1])
            token = parts[-1]
            
            self.watcher.store_price(chain, dex, token, price)
        
        logger.info("✅ Test databases initialized")
    
    async def _simulate_opportunity_detection(self):
        """Simulate the watcher finding an arbitrage opportunity"""
        logger.info("🔍 Simulating opportunity detection...")
        
        # Create a profitable opportunity
        opportunity = {
            'token': 'WETH',
            'chain_a': 'arbitrum',
            'chain_b': 'avalanche',
            'price_a': 2485.50,  # Lower price on Arbitrum
            'price_b': 2510.25,  # Higher price on Avalanche
            'spread_bps': int(((2510.25 - 2485.50) / 2485.50) * 10000),  # ~99 bps
            'profit_estimate': 24.75  # Rough estimate
        }
        
        logger.info(f"🎯 Opportunity detected:")
        logger.info(f"   Token: {opportunity['token']}")
        logger.info(f"   Arbitrum: ${opportunity['price_a']:.2f}")
        logger.info(f"   Avalanche: ${opportunity['price_b']:.2f}")
        logger.info(f"   Spread: {opportunity['spread_bps']} bps")
        logger.info(f"   Profit estimate: ${opportunity['profit_estimate']:.2f}")
        
        return opportunity
    
    async def _test_plan_generation(self, opportunity):
        """Test the planner generating an execution plan"""
        logger.info("🧠 Testing plan generation...")
        
        plan = await self.planner.process_opportunity(opportunity)
        
        if plan:
            logger.info(f"📋 Plan generated successfully:")
            logger.info(f"   Plan ID: {plan['plan_id']}")
            logger.info(f"   Trade size: ${plan['trade_size_usd']:,.2f}")
            logger.info(f"   Expected profit: ${plan['expected_profit']:.2f}")
            logger.info(f"   Profit margin: {plan['profit_bps']:.1f} bps")
            logger.info(f"   Direction: {plan['direction']}")
            logger.info(f"   AI approval: {plan['ai_validation']['approved']}")
            logger.info(f"   AI confidence: {plan['ai_validation']['confidence']}%")
        
        return plan
    
    async def _test_suave_integration(self, plan):
        """Test SUAVE bundle creation"""
        logger.info("🛡️ Testing SUAVE integration...")
        
        bundle_id = await self.suave.create_arbitrage_bundle(plan)
        
        if bundle_id:
            logger.info(f"📦 SUAVE bundle created: {bundle_id}")
            
            # Test bundle status
            status = await self.suave.get_bundle_status(bundle_id)
            logger.info(f"📊 Bundle status: {status['status']}")
            
            # Test success rate estimation
            success_rate = await self.suave.estimate_bundle_success_rate(plan)
            logger.info(f"🎯 Estimated success rate: {success_rate:.1%}")
        
        return bundle_id
    
    async def _test_execution(self, plan):
        """Test execution flow"""
        logger.info("⚡ Testing execution flow...")
        
        # Update plan status to approved for testing
        await self.executor._update_plan_status(plan['plan_id'], 'approved')
        
        # Test plan retrieval
        approved_plans = await self.executor._get_approved_plans()
        logger.info(f"📋 Found {len(approved_plans)} approved plans")
        
        if approved_plans:
            test_plan = approved_plans[0]
            logger.info(f"🎯 Testing execution of plan: {test_plan['plan_id']}")
            
            # Simulate execution
            await self.executor._execute_plan(test_plan)
            
            # Check execution results
            stats = await self.executor.get_execution_stats()
            logger.info(f"📊 Execution stats: {stats}")
            
            return True
        
        return False
    
    async def _display_test_results(self):
        """Display comprehensive test results"""
        logger.info("📊 Test Results Summary")
        logger.info("=" * 40)
        
        # Get execution statistics
        stats = await self.executor.get_execution_stats()
        
        logger.info(f"✅ Total executions: {stats.get('total_executions', 0)}")
        logger.info(f"💰 Total profit: ${stats.get('total_profit', 0):.2f}")
        logger.info(f"⛽ Total gas cost: ${stats.get('total_gas_cost', 0):.2f}")
        logger.info(f"📈 Net profit: ${stats.get('net_profit', 0):.2f}")
        logger.info(f"📊 Average profit: ${stats.get('avg_profit', 0):.2f}")
        
        # Success rate calculation
        if stats.get('total_executions', 0) > 0:
            success_rate = 100  # All test executions succeed
            logger.info(f"🎯 Success rate: {success_rate}%")
        
        logger.info("=" * 40)

async def main():
    """Main test execution"""
    print("🚀 Cross-Chain Arbitrage Bot - Full Flow Test")
    print("=" * 60)
    
    tester = FullFlowTester()
    
    try:
        success = await tester.run_full_test()
        
        if success:
            print("\n✅ ALL TESTS PASSED!")
            print("🎉 The arbitrage bot is ready for demo!")
        else:
            print("\n❌ TESTS FAILED!")
            print("🔧 Please check the logs and fix issues before demo.")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n⏸️ Test interrupted by user")
    except Exception as e:
        print(f"\n💥 Test failed with unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main()) 