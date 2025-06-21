import express from 'express'
import fetch from 'node-fetch'

const app = express()
const PORT = process.env.PORT || 3000

// RPC & Groq configs from env
const ETHEREUM_RPC   = "https://eth-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl"
const ARBITRUM_RPC    = "https://arb-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl"
const GROQ_API_KEY    = "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"
const GROQ_API_URL    = 'https://api.groq.com/openai/v1/chat/completions'
const GET_RESERVES_ABI = '0x0902f1ac'

async function rpcCall(rpcUrl, to, data) {
  const res = await fetch(rpcUrl, {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
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

async function gasPrice(rpcUrl) {
  const res = await fetch(rpcUrl, {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
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

function decodeReserves(hex) {
  if (hex.startsWith('0x')) hex = hex.slice(2)
  return {
    r0: BigInt('0x'+hex.slice(0,64)),
    r1: BigInt('0x'+hex.slice(64,128))
  }
}

async function decideArbitrage(ethPair, arbPair) {
  // 1. fetch reserves
  const [eHex, aHex] = await Promise.all([
    rpcCall(ETHEREUM_RPC, ethPair, GET_RESERVES_ABI),
    rpcCall(ARBITRUM_RPC,  arbPair, GET_RESERVES_ABI)
  ])
  const {r0:e0,r1:e1} = decodeReserves(eHex)
  const {r0:a0,r1:a1} = decodeReserves(aHex)
  const pE = Number(e1)/Number(e0), pA = Number(a1)/Number(a0)
  const edge = pA>pE ? (pA-pE)*10000/pE : (pE-pA)*10000/pA
  if (!isFinite(edge)) throw new Error('Invalid reserves')

  // 2. fetch gas
  const [gE,gA] = await Promise.all([
    gasPrice(ETHEREUM_RPC),
    gasPrice(ARBITRUM_RPC)
  ])
  const ge = Number(gE)/1e9, ga = Number(gA)/1e9

  // 3. build prompt
  const prompt = `
You are an arbitrage analyzer.
ETH price: ${pE}
ARB price: ${pA}
Edge bps: ${edge}
ETH gas: ${ge} gwei
ARB gas: ${ga} gwei

Criteria: minEdgeBps=50, maxGasGwei=50

Respond with JSON:
{"execute":bool,"amount":"wei","minEdgeBps":50,"maxGasGwei":50}
`

  // 4. call Groq
  const llmRes = await fetch(GROQ_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${GROQ_API_KEY}`
    },
    body: JSON.stringify({
      model: 'llama-3.3-70b-versatile',
      messages: [
        { role: 'system', content: 'You are a helpful assistant.' },
        { role: 'user',   content: prompt }
      ]
    })
  })
  const llmJ = await llmRes.json()
  console.log('LLM response:', llmJ)
  const text = llmJ.choices?.[0]?.message?.content
  if (!text) throw new Error('No response from Groq')
  const m = text.match(/\{[\s\S]*\}/)
  if (!m) throw new Error('No JSON in LLM response')
  return JSON.parse(m[0])
}

app.get('/api/analyze', async (req, res) => {
  try {
    const { ethPair, arbPair } = req.query
    if (!ethPair || !arbPair) {
      return res.status(400).json({ error: 'Missing ethPair or arbPair' })
    }
    const decision = await decideArbitrage(ethPair, arbPair)
    res.json(decision)
  } catch (e) {
    res.status(500).json({ error: e.message })
  }
})

app.listen(PORT, () => {
  console.log(`API listening on http://localhost:${PORT}`)
})
