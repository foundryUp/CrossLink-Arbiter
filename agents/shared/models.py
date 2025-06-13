"""
Core data models for the Cross-Domain Arbitrage Bot AI agents.

This module defines the data structures used across all AI agents for
arbitrage detection, planning, and execution.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Any
from decimal import Decimal
from enum import Enum
from datetime import datetime
import json


class ChainType(Enum):
    """Supported blockchain networks."""
    ARBITRUM = "arbitrum"
    AVALANCHE = "avalanche"


class TokenType(Enum):
    """Supported token types."""
    WETH = "WETH"
    USDC = "USDC"
    USDT = "USDT"
    WAVAX = "WAVAX"


class DEXType(Enum):
    """Supported DEX protocols."""
    SUSHISWAP = "sushiswap"
    UNISWAP_V3 = "uniswap_v3"
    TRADER_JOE = "trader_joe"
    PANGOLIN = "pangolin"


class PlanStatus(Enum):
    """Arbitrage plan status."""
    PENDING = "pending"
    APPROVED = "approved"
    EXECUTING = "executing"
    COMPLETED = "completed"
    FAILED = "failed"
    EXPIRED = "expired"


@dataclass
class TokenInfo:
    """Token information."""
    symbol: str
    address: str
    decimals: int
    chain: ChainType
    
    def __str__(self) -> str:
        return f"{self.symbol} ({self.chain.value})"


@dataclass
class DEXPool:
    """DEX pool information."""
    dex: DEXType
    chain: ChainType
    token_a: TokenInfo
    token_b: TokenInfo
    reserve_a: Decimal
    reserve_b: Decimal
    pool_address: str
    fee_bps: int  # Fee in basis points
    last_updated: datetime
    
    @property
    def price_a_to_b(self) -> Decimal:
        """Price of token A in terms of token B."""
        if self.reserve_a == 0:
            return Decimal('0')
        return self.reserve_b / self.reserve_a
    
    @property
    def price_b_to_a(self) -> Decimal:
        """Price of token B in terms of token A."""
        if self.reserve_b == 0:
            return Decimal('0')
        return self.reserve_a / self.reserve_b


@dataclass
class ArbitrageOpportunity:
    """Detected arbitrage opportunity."""
    id: str
    origin_pool: DEXPool
    destination_pool: DEXPool
    token_in: TokenInfo
    token_out: TokenInfo
    amount_in: Decimal
    expected_amount_out: Decimal
    expected_profit: Decimal
    profit_bps: int
    gas_estimate: int
    confidence_score: float  # 0-1, higher is better
    detected_at: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            'id': self.id,
            'origin_chain': self.origin_pool.chain.value,
            'destination_chain': self.destination_pool.chain.value,
            'token_in': self.token_in.symbol,
            'token_out': self.token_out.symbol,
            'amount_in': str(self.amount_in),
            'expected_amount_out': str(self.expected_amount_out),
            'expected_profit': str(self.expected_profit),
            'profit_bps': self.profit_bps,
            'gas_estimate': self.gas_estimate,
            'confidence_score': self.confidence_score,
            'detected_at': self.detected_at.isoformat()
        }


@dataclass
class TradeRoute:
    """Trade route information."""
    origin_dex: DEXType
    destination_dex: DEXType
    origin_chain: ChainType
    destination_chain: ChainType
    token_path: List[TokenInfo]
    expected_output: Decimal
    gas_cost: Decimal
    fees: Decimal
    slippage_tolerance: Decimal
    
    def __str__(self) -> str:
        path = " -> ".join([token.symbol for token in self.token_path])
        return f"{self.origin_dex.value} -> {self.destination_dex.value}: {path}"


@dataclass
class RiskAssessment:
    """Risk assessment for an arbitrage opportunity."""  
    opportunity_id: str
    risk_score: float  # 0-1, higher is riskier
    gas_risk: float
    slippage_risk: float
    liquidity_risk: float
    bridge_risk: float
    time_risk: float
    max_trade_size: Decimal
    recommended_action: str
    risk_factors: List[str]
    assessed_at: datetime
    
    @property
    def is_safe(self) -> bool:
        """Check if opportunity is considered safe to execute."""
        return self.risk_score < 0.3  # 30% risk threshold


@dataclass
class ArbitragePlan:
    """Complete arbitrage execution plan."""
    id: str
    opportunity: ArbitrageOpportunity
    route: TradeRoute
    risk_assessment: RiskAssessment
    execution_params: Dict[str, Any]
    status: PlanStatus
    created_at: datetime
    updated_at: datetime
    signature: Optional[str] = None  # KMS signature
    execution_deadline: Optional[datetime] = None
    
    def to_json(self) -> str:
        """Convert to JSON for transmission."""
        data = {
            'id': self.id,
            'opportunity': self.opportunity.to_dict(),
            'route': {
                'origin_dex': self.route.origin_dex.value,
                'destination_dex': self.route.destination_dex.value,
                'origin_chain': self.route.origin_chain.value,
                'destination_chain': self.route.destination_chain.value,
                'token_path': [token.symbol for token in self.route.token_path],
                'expected_output': str(self.route.expected_output),
                'gas_cost': str(self.route.gas_cost),
                'fees': str(self.route.fees),
                'slippage_tolerance': str(self.route.slippage_tolerance)
            },
            'risk_assessment': {
                'risk_score': self.risk_assessment.risk_score,
                'gas_risk': self.risk_assessment.gas_risk,
                'slippage_risk': self.risk_assessment.slippage_risk,
                'liquidity_risk': self.risk_assessment.liquidity_risk,
                'bridge_risk': self.risk_assessment.bridge_risk,
                'time_risk': self.risk_assessment.time_risk,
                'max_trade_size': str(self.risk_assessment.max_trade_size),
                'recommended_action': self.risk_assessment.recommended_action,
                'risk_factors': self.risk_assessment.risk_factors
            },
            'execution_params': self.execution_params,
            'status': self.status.value,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
            'signature': self.signature,
            'execution_deadline': self.execution_deadline.isoformat() if self.execution_deadline else None
        }
        return json.dumps(data, indent=2)
    
    @classmethod
    def from_json(cls, json_str: str) -> 'ArbitragePlan':
        """Create from JSON string."""
        # Implementation would parse JSON and reconstruct object
        # This is a placeholder for the actual implementation
        pass


@dataclass
class MarketData:
    """Market data snapshot."""
    chain: ChainType
    token_prices: Dict[str, Decimal]  # token symbol -> price in USD
    gas_price: Decimal  # in gwei
    block_number: int
    timestamp: datetime
    
    def get_token_price(self, token: str) -> Optional[Decimal]:
        """Get price for a specific token."""
        return self.token_prices.get(token)


@dataclass
class ExecutionResult:
    """Result of an arbitrage execution."""
    plan_id: str
    success: bool
    tx_hash: Optional[str]
    profit_realized: Optional[Decimal]
    gas_used: Optional[int]
    execution_time: Optional[float]  # seconds
    error_message: Optional[str]
    executed_at: datetime
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            'plan_id': self.plan_id,
            'success': self.success,
            'tx_hash': self.tx_hash,
            'profit_realized': str(self.profit_realized) if self.profit_realized else None,
            'gas_used': self.gas_used,
            'execution_time': self.execution_time,
            'error_message': self.error_message,
            'executed_at': self.executed_at.isoformat()
        }


@dataclass
class AgentConfig:
    """Configuration for AI agents."""
    agent_name: str
    bedrock_model_id: str
    aws_region: str
    max_concurrent_operations: int
    update_interval_seconds: int
    risk_tolerance: float
    max_trade_size_usd: Decimal
    min_profit_threshold_bps: int
    
    @classmethod
    def from_env(cls) -> 'AgentConfig':
        """Load configuration from environment variables."""
        import os
        from decimal import Decimal
        
        return cls(
            agent_name=os.getenv('AGENT_NAME', 'arbitrage-bot'),
            bedrock_model_id=os.getenv('BEDROCK_MODEL_ID', 'anthropic.claude-3-haiku-20240307-v1:0'),
            aws_region=os.getenv('AWS_REGION', 'us-east-1'),
            max_concurrent_operations=int(os.getenv('MAX_CONCURRENT_OPERATIONS', '5')),
            update_interval_seconds=int(os.getenv('UPDATE_INTERVAL_SECONDS', '30')),
            risk_tolerance=float(os.getenv('RISK_TOLERANCE', '0.3')),
            max_trade_size_usd=Decimal(os.getenv('MAX_TRADE_SIZE_USD', '10000')),
            min_profit_threshold_bps=int(os.getenv('MIN_PROFIT_THRESHOLD_BPS', '50'))
        )


# Utility functions for data validation and conversion

def validate_arbitrage_plan(plan: ArbitragePlan) -> List[str]:
    """Validate an arbitrage plan and return list of errors."""
    errors = []
    
    if plan.opportunity.profit_bps < 10:
        errors.append("Profit margin too low (< 10 bps)")
    
    if plan.risk_assessment.risk_score > 0.5:
        errors.append("Risk score too high (> 50%)")
    
    if plan.opportunity.confidence_score < 0.7:
        errors.append("Confidence score too low (< 70%)")
    
    if plan.execution_deadline and plan.execution_deadline < datetime.now():
        errors.append("Execution deadline has passed")
    
    return errors


def calculate_profit_bps(amount_in: Decimal, amount_out: Decimal, gas_cost: Decimal) -> int:
    """Calculate profit in basis points."""
    if amount_in == 0:
        return 0
    
    net_profit = amount_out - amount_in - gas_cost
    profit_ratio = net_profit / amount_in
    return int(profit_ratio * 10000)  # Convert to basis points 