// Chainlink Functions Source Code - Hackathon Version
// Fetches AI-generated arbitrage plans from Bedrock agents

const source = `
// SIMPLIFIED CHAINLINK FUNCTIONS FOR HACKATHON

// Main function to fetch and validate arbitrage plans
async function main() {
    console.log("🔗 Chainlink Functions: Fetching arbitrage plans...");
    
    try {
        // Step 1: Fetch approved plans from AI agents
        const plansResponse = await Functions.makeHttpRequest({
            url: "http://localhost:8080/api/approved-plans",
            method: "GET",
            headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer " + secrets.apiKey
            }
        });
        
        if (plansResponse.error) {
            throw new Error("Failed to fetch plans: " + plansResponse.error);
        }
        
        const plans = plansResponse.data;
        console.log("📋 Retrieved " + plans.length + " approved plans");
        
        if (plans.length === 0) {
            return Functions.encodeString("NO_PLANS");
        }
        
        // Step 2: Select best plan based on profit
        const bestPlan = plans.reduce((best, current) => {
            return current.expected_profit > best.expected_profit ? current : best;
        });
        
        console.log("💰 Best plan: " + bestPlan.plan_id + " with $" + bestPlan.expected_profit.toFixed(2) + " profit");
        
        // Step 3: Basic validation
        const validationResult = validatePlan(bestPlan);
        if (!validationResult.valid) {
            throw new Error("Plan validation failed: " + validationResult.reason);
        }
        
        // Step 4: Get current prices for validation
        const priceValidation = await validatePrices(bestPlan);
        if (!priceValidation.valid) {
            throw new Error("Price validation failed: " + priceValidation.reason);
        }
        
        // Step 5: Return encoded plan data
        const planData = {
            planId: bestPlan.plan_id,
            token: bestPlan.token,
            tradeSizeUsd: bestPlan.trade_size_usd,
            expectedProfit: bestPlan.expected_profit,
            buyChain: bestPlan.buy_chain,
            sellChain: bestPlan.sell_chain,
            deadline: bestPlan.deadline,
            timestamp: Math.floor(Date.now() / 1000)
        };
        
        console.log("✅ Plan validated and ready for execution");
        return Functions.encodeString(JSON.stringify(planData));
        
    } catch (error) {
        console.error("❌ Error in Chainlink Functions:", error.message);
        throw error;
    }
}

// Validate plan parameters
function validatePlan(plan) {
    // Check required fields
    if (!plan.plan_id || !plan.token || !plan.expected_profit) {
        return { valid: false, reason: "Missing required fields" };
    }
    
    // Check profit threshold (minimum 0.2% = 20 bps)
    if (plan.profit_bps < 20) {
        return { valid: false, reason: "Profit below minimum threshold" };
    }
    
    // Check trade size limits
    if (plan.trade_size_usd > 50000) {
        return { valid: false, reason: "Trade size too large" };
    }
    
    // Check deadline
    const now = Math.floor(Date.now() / 1000);
    if (plan.deadline <= now) {
        return { valid: false, reason: "Plan expired" };
    }
    
    return { valid: true };
}

// Validate current prices against plan prices
async function validatePrices(plan) {
    try {
        // SIMPLIFIED: In production would use actual price feeds
        // For hackathon, we'll do basic validation
        
        const priceResponse = await Functions.makeHttpRequest({
            url: "https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd",
            method: "GET"
        });
        
        if (priceResponse.error) {
            console.log("⚠️  Price API error, proceeding with plan prices");
            return { valid: true };
        }
        
        const currentPrice = priceResponse.data.ethereum.usd;
        const planPrice = (plan.buy_price + plan.sell_price) / 2;
        
        // Allow 5% price movement
        const priceDeviation = Math.abs(currentPrice - planPrice) / planPrice;
        if (priceDeviation > 0.05) {
            return { 
                valid: false, 
                reason: "Price moved too much: " + (priceDeviation * 100).toFixed(2) + "%" 
            };
        }
        
        return { valid: true };
        
    } catch (error) {
        console.log("⚠️  Price validation error, proceeding: " + error.message);
        return { valid: true };
    }
}

// Execute main function
return main();
`;

// Export the source code
module.exports = { source }; 