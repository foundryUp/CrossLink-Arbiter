import express from 'express'
import fetch from 'node-fetch'
import { Buffer } from 'buffer'
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime'

const app = express()
const PORT = process.env.PORT || 3000

// RPC & Bedrock configs
const ETHEREUM_RPC    = "https://eth-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl"
const ARBITRUM_RPC    = "https://arb-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl"
const GET_RESERVES_ABI = '0x0902f1ac'

// AWS Bedrock configuration - using Titan Text Express (cheapest and most available)
const AWS_REGION = process.env.AWS_REGION || 'us-east-1'
const BEDROCK_MODEL_ID = 'amazon.titan-text-express-v1' // Usually available by default

// Initialize Bedrock client
const bedrockClient = new BedrockRuntimeClient({ 
  region: AWS_REGION,
  // AWS credentials will be loaded from environment variables or AWS credentials file
})

// Simple JSON-RPC eth_call helper
async function rpcCall(rpcUrl, to, data) {
  const res = await fetch(rpcUrl, {
    method: 'POST',
    headers: { 'Content-Type':'application/json' },
    body: JSON.stringify({
      jsonrpc: '2.0',
      method: 'eth_call',
      params: [{ to, data }, 'latest'],
      id: 1
    })
  })
  const j = await res.json()
  if (j.error) throw new Error(j.error.message)
  return j.result
}

// Fetch current gas price
async function gasPrice(rpcUrl) {
  const res = await fetch(rpcUrl, {
    method: 'POST',
    headers: { 'Content-Type':'application/json' },
    body: JSON.stringify({
      jsonrpc: '2.0',
      method: 'eth_gasPrice',
      params: [],
      id: 1
    })
  })
  const j = await res.json()
  if (j.error) throw new Error(j.error.message)
  return BigInt(j.result)
}

// Decode Uniswap V2 reserves from the eth_call hex
function decodeReserves(hex) {
  if (hex.startsWith('0x')) hex = hex.slice(2)
  return {
    r0: BigInt('0x' + hex.slice(0, 64)),
    r1: BigInt('0x' + hex.slice(64, 128))
  }
}

// Fallback rule-based decision
function makeRuleBasedDecision(pE, pA, edge, ge, ga) {
  const minEdgeBps = 50
  const maxGasGwei = 50
  
  const shouldExecute = edge >= minEdgeBps && ge <= maxGasGwei && ga <= maxGasGwei
  const amount = shouldExecute ? "1000000000000000000" : "0" // 1 ETH in wei
  
  return {
    execute: shouldExecute,
    amount: amount,
    minEdgeBps: minEdgeBps,
    maxGasGwei: maxGasGwei
  }
}

// Core arbitrage decision logic
async function decideArbitrage(ethPair, arbPair) {
  // 1) fetch reserves in parallel
  const [eHex, aHex] = await Promise.all([
    rpcCall(ETHEREUM_RPC, ethPair, GET_RESERVES_ABI),
    rpcCall(ARBITRUM_RPC,  arbPair, GET_RESERVES_ABI)
  ])
  const { r0: e0, r1: e1 } = decodeReserves(eHex)
  const { r0: a0, r1: a1 } = decodeReserves(aHex)

  // compute price and edge bps
  const pE   = Number(e1) / Number(e0)
  const pA   = Number(a1) / Number(a0)
  const edge = pA > pE
    ? (pA - pE) * 10000 / pE
    : (pE - pA) * 10000 / pA

  if (!isFinite(edge)) throw new Error('Invalid reserves')

  // 2) fetch gas prices
  const [gE, gA] = await Promise.all([
    gasPrice(ETHEREUM_RPC),
    gasPrice(ARBITRUM_RPC)
  ])
  const ge = Number(gE) / 1e9
  const ga = Number(gA) / 1e9

  console.log(`Market Data: ETH price: ${pE}, ARB price: ${pA}, Edge: ${edge} bps, ETH gas: ${ge} gwei, ARB gas: ${ga} gwei`)

  try {
    // 3) Try Bedrock first
    const prompt = `Analyze this arbitrage opportunity:

ETH price: ${pE}
ARB price: ${pA}
Price difference: ${edge} basis points
ETH gas: ${ge} gwei
ARB gas: ${ga} gwei

Rules:
- Execute if edge >= 50 bps AND both gas prices <= 50 gwei
- Amount should be 1000000000000000000 wei (1 ETH) if executing, 0 if not

Respond with only JSON: {"execute": true/false, "amount": "wei_amount", "minEdgeBps": 50, "maxGasGwei": 50}`

    const payload = {
      inputText: prompt,
      textGenerationConfig: {
        maxTokenCount: 200,
        temperature: 0.1,
        topP: 0.9
      }
    }

    const command = new InvokeModelCommand({
      modelId: BEDROCK_MODEL_ID,
      contentType: "application/json",
      accept: "application/json",
      body: JSON.stringify(payload)
    })

    const response = await bedrockClient.send(command)
    const responseBody = JSON.parse(new TextDecoder().decode(response.body))
    
    console.log('Bedrock response:', responseBody)
    
    const text = responseBody.results?.[0]?.outputText
    if (!text) throw new Error('No response from Bedrock')

  // extract JSON substring
  const m = text.match(/\{[\s\S]*\}/)
    if (!m) throw new Error('No JSON in Bedrock response')
    
    const decision = JSON.parse(m[0])
    console.log('AI Decision:', decision)
    return decision

  } catch (error) {
    console.log('Bedrock failed, using rule-based decision:', error.message)
    // 4) Fallback to rule-based decision
    const decision = makeRuleBasedDecision(pE, pA, edge, ge, ga)
    console.log('Rule-based Decision:', decision)
    return decision
  }
}

app.get('/api/analyze', async (req, res) => {
  try {
    const { ethPair, arbPair } = req.query
    if (!ethPair || !arbPair) {
      return res.status(400).json({ error: 'Missing ethPair or arbPair' })
    }

    const decision = await decideArbitrage(ethPair, arbPair)

    // build a comma-separated CSV string of all four values
    const csv = `${decision.execute},${decision.amount},${decision.minEdgeBps},${decision.maxGasGwei}`

    // return full JSON including the new csv field
    res.json({ ...decision, csv })
  } catch (e) {
    console.error('Error:', e)
    res.status(500).json({ error: e.message })
  }
})

app.listen(PORT, () => {
  console.log(`API listening on http://localhost:${PORT}`)
  console.log(`Using AWS Bedrock model: ${BEDROCK_MODEL_ID}`)
  console.log(`AWS Region: ${AWS_REGION}`)
  console.log(`Fallback to rule-based logic if Bedrock fails`)
})
