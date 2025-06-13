#!/usr/bin/env python3
"""
Simple Monitoring Dashboard - Hackathon Version
Real-time arbitrage monitoring and statistics
"""

import asyncio
import json
import sqlite3
import time
from datetime import datetime, timedelta
from typing import Dict, List

from fastapi import FastAPI, WebSocket
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
import uvicorn

app = FastAPI(title="Arbitrage Bot Dashboard")

class ArbitrageDashboard:
    """Simplified dashboard for monitoring arbitrage activities"""
    
    def __init__(self):
        self.db_path = "arbitrage_data.db"
        self.active_connections = []
        
    async def get_dashboard_data(self) -> Dict:
        """Get all dashboard data"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get recent opportunities
            cursor.execute('''
                SELECT * FROM opportunities 
                ORDER BY created_at DESC 
                LIMIT 10
            ''')
            opportunities = cursor.fetchall()
            
            # Get active plans
            cursor.execute('''
                SELECT * FROM arbitrage_plans 
                WHERE status IN ('approved', 'executing')
                ORDER BY expected_profit DESC
                LIMIT 5
            ''')
            active_plans = cursor.fetchall()
            
            # Get recent executions
            cursor.execute('''
                SELECT * FROM executions 
                ORDER BY created_at DESC 
                LIMIT 10
            ''')
            executions = cursor.fetchall()
            
            # Get statistics
            cursor.execute('''
                SELECT 
                    COUNT(*) as total_opportunities,
                    AVG(spread_bps) as avg_spread,
                    MAX(spread_bps) as max_spread
                FROM opportunities 
                WHERE created_at > datetime('now', '-1 hour')
            ''')
            hourly_stats = cursor.fetchone()
            
            cursor.execute('''
                SELECT 
                    COUNT(*) as total_executions,
                    SUM(actual_profit) as total_profit,
                    AVG(actual_profit) as avg_profit,
                    SUM(gas_used) as total_gas
                FROM executions
                WHERE created_at > datetime('now', '-24 hours')
            ''')
            daily_stats = cursor.fetchone()
            
            conn.close()
            
            return {
                'timestamp': int(time.time()),
                'opportunities': self._format_opportunities(opportunities),
                'active_plans': self._format_plans(active_plans),
                'recent_executions': self._format_executions(executions),
                'stats': {
                    'hourly': {
                        'opportunities': hourly_stats[0] or 0,
                        'avg_spread': round(hourly_stats[1] or 0, 1),
                        'max_spread': hourly_stats[2] or 0
                    },
                    'daily': {
                        'executions': daily_stats[0] or 0,
                        'total_profit': round(daily_stats[1] or 0, 2),
                        'avg_profit': round(daily_stats[2] or 0, 2),
                        'total_gas': round(daily_stats[3] or 0, 2),
                        'net_profit': round((daily_stats[1] or 0) - (daily_stats[3] or 0), 2)
                    }
                }
            }
            
        except Exception as e:
            print(f"Error getting dashboard data: {e}")
            return self._get_empty_data()
    
    def _format_opportunities(self, opportunities: List) -> List[Dict]:
        """Format opportunities for dashboard"""
        formatted = []
        for opp in opportunities:
            formatted.append({
                'id': opp[0],
                'token': opp[1],
                'chain_a': opp[2],
                'chain_b': opp[3],
                'price_a': round(opp[4], 2),
                'price_b': round(opp[5], 2),
                'spread_bps': opp[6],
                'profit_estimate': round(opp[7], 2),
                'status': opp[8],
                'created_at': opp[9]
            })
        return formatted
    
    def _format_plans(self, plans: List) -> List[Dict]:
        """Format plans for dashboard"""
        formatted = []
        for plan in plans:
            formatted.append({
                'plan_id': plan[0],
                'token': plan[2],
                'direction': plan[3],
                'trade_size_usd': round(plan[4], 2),
                'expected_profit': round(plan[6], 2),
                'profit_bps': round(plan[7], 1),
                'status': plan[13],
                'deadline': plan[12]
            })
        return formatted
    
    def _format_executions(self, executions: List) -> List[Dict]:
        """Format executions for dashboard"""
        formatted = []
        for execution in executions:
            formatted.append({
                'id': execution[0],
                'plan_id': execution[1],
                'tx_hash': execution[2],
                'expected_profit': round(execution[4], 2),
                'actual_profit': round(execution[5], 2),
                'gas_used': round(execution[6], 2),
                'execution_time': round(execution[7], 1),
                'status': execution[8],
                'created_at': execution[9]
            })
        return formatted
    
    def _get_empty_data(self) -> Dict:
        """Return empty data structure"""
        return {
            'timestamp': int(time.time()),
            'opportunities': [],
            'active_plans': [],
            'recent_executions': [],
            'stats': {
                'hourly': {'opportunities': 0, 'avg_spread': 0, 'max_spread': 0},
                'daily': {'executions': 0, 'total_profit': 0, 'avg_profit': 0, 'total_gas': 0, 'net_profit': 0}
            }
        }
    
    async def broadcast_update(self, data: Dict):
        """Broadcast update to all connected clients"""
        if self.active_connections:
            message = json.dumps(data)
            for connection in self.active_connections:
                try:
                    await connection.send_text(message)
                except:
                    # Remove disconnected clients
                    self.active_connections.remove(connection)

# Global dashboard instance
dashboard = ArbitrageDashboard()

# API Routes
@app.get("/")
async def get_dashboard():
    """Serve the main dashboard HTML"""
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Arbitrage Bot Dashboard</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; background: #0f0f0f; color: #fff; }
            .header { text-align: center; border-bottom: 2px solid #333; padding-bottom: 20px; }
            .stats { display: flex; justify-content: space-around; margin: 20px 0; }
            .stat-card { background: #1a1a1a; padding: 20px; border-radius: 8px; text-align: center; border: 1px solid #333; }
            .opportunities, .plans, .executions { margin: 20px 0; }
            .section-title { color: #4CAF50; font-size: 1.5em; margin-bottom: 10px; }
            table { width: 100%; border-collapse: collapse; background: #1a1a1a; }
            th, td { padding: 10px; text-align: left; border-bottom: 1px solid #333; }
            th { background: #333; color: #4CAF50; }
            .profit-positive { color: #4CAF50; font-weight: bold; }
            .profit-negative { color: #f44336; font-weight: bold; }
            .status-approved { color: #4CAF50; }
            .status-executing { color: #FF9800; }
            .status-completed { color: #4CAF50; }
            .status-failed { color: #f44336; }
            .update-time { text-align: center; color: #666; font-size: 0.9em; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🚀 Cross-Chain Arbitrage Bot</h1>
            <p>Real-time monitoring dashboard</p>
        </div>
        
        <div class="stats" id="stats">
            <div class="stat-card">
                <h3>Opportunities (1h)</h3>
                <div id="hourly-opportunities">-</div>
                <small>Avg Spread: <span id="avg-spread">-</span> bps</small>
            </div>
            <div class="stat-card">
                <h3>Executions (24h)</h3>
                <div id="daily-executions">-</div>
                <small>Success Rate: <span id="success-rate">-</span>%</small>
            </div>
            <div class="stat-card">
                <h3>Total Profit (24h)</h3>
                <div id="total-profit" class="profit-positive">$-</div>
                <small>Gas Cost: $<span id="total-gas">-</span></small>
            </div>
            <div class="stat-card">
                <h3>Net Profit (24h)</h3>
                <div id="net-profit" class="profit-positive">$-</div>
                <small>Avg per trade: $<span id="avg-profit">-</span></small>
            </div>
        </div>
        
        <div class="opportunities">
            <h2 class="section-title">🎯 Recent Opportunities</h2>
            <table>
                <thead>
                    <tr>
                        <th>Token</th>
                        <th>Chains</th>
                        <th>Price A</th>
                        <th>Price B</th>
                        <th>Spread</th>
                        <th>Profit Est.</th>
                        <th>Status</th>
                        <th>Time</th>
                    </tr>
                </thead>
                <tbody id="opportunities-table">
                    <tr><td colspan="8">Loading...</td></tr>
                </tbody>
            </table>
        </div>
        
        <div class="plans">
            <h2 class="section-title">📋 Active Plans</h2>
            <table>
                <thead>
                    <tr>
                        <th>Plan ID</th>
                        <th>Token</th>
                        <th>Direction</th>
                        <th>Size (USD)</th>
                        <th>Expected Profit</th>
                        <th>Profit %</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody id="plans-table">
                    <tr><td colspan="7">Loading...</td></tr>
                </tbody>
            </table>
        </div>
        
        <div class="executions">
            <h2 class="section-title">⚡ Recent Executions</h2>
            <table>
                <thead>
                    <tr>
                        <th>Plan ID</th>
                        <th>TX Hash</th>
                        <th>Expected</th>
                        <th>Actual</th>
                        <th>Gas Used</th>
                        <th>Time (s)</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody id="executions-table">
                    <tr><td colspan="7">Loading...</td></tr>
                </tbody>
            </table>
        </div>
        
        <div class="update-time">
            Last updated: <span id="last-update">-</span>
        </div>
        
        <script>
            const ws = new WebSocket(`ws://localhost:8080/ws`);
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                updateDashboard(data);
            };
            
            function updateDashboard(data) {
                // Update stats
                document.getElementById('hourly-opportunities').textContent = data.stats.hourly.opportunities;
                document.getElementById('avg-spread').textContent = data.stats.hourly.avg_spread;
                document.getElementById('daily-executions').textContent = data.stats.daily.executions;
                document.getElementById('total-profit').textContent = '$' + data.stats.daily.total_profit;
                document.getElementById('total-gas').textContent = data.stats.daily.total_gas;
                document.getElementById('net-profit').textContent = '$' + data.stats.daily.net_profit;
                document.getElementById('avg-profit').textContent = data.stats.daily.avg_profit;
                
                // Update opportunities table
                updateOpportunitiesTable(data.opportunities);
                
                // Update plans table
                updatePlansTable(data.active_plans);
                
                // Update executions table
                updateExecutionsTable(data.recent_executions);
                
                // Update timestamp
                document.getElementById('last-update').textContent = new Date().toLocaleTimeString();
            }
            
            function updateOpportunitiesTable(opportunities) {
                const tbody = document.getElementById('opportunities-table');
                tbody.innerHTML = '';
                
                opportunities.forEach(opp => {
                    const row = tbody.insertRow();
                    row.innerHTML = `
                        <td>${opp.token}</td>
                        <td>${opp.chain_a} → ${opp.chain_b}</td>
                        <td>$${opp.price_a}</td>
                        <td>$${opp.price_b}</td>
                        <td>${opp.spread_bps} bps</td>
                        <td class="profit-positive">$${opp.profit_estimate}</td>
                        <td><span class="status-${opp.status}">${opp.status}</span></td>
                        <td>${new Date(opp.created_at).toLocaleTimeString()}</td>
                    `;
                });
            }
            
            function updatePlansTable(plans) {
                const tbody = document.getElementById('plans-table');
                tbody.innerHTML = '';
                
                plans.forEach(plan => {
                    const row = tbody.insertRow();
                    row.innerHTML = `
                        <td>${plan.plan_id.substring(0, 12)}...</td>
                        <td>${plan.token}</td>
                        <td>${plan.direction}</td>
                        <td>$${plan.trade_size_usd}</td>
                        <td class="profit-positive">$${plan.expected_profit}</td>
                        <td>${plan.profit_bps} bps</td>
                        <td><span class="status-${plan.status}">${plan.status}</span></td>
                    `;
                });
            }
            
            function updateExecutionsTable(executions) {
                const tbody = document.getElementById('executions-table');
                tbody.innerHTML = '';
                
                executions.forEach(exec => {
                    const row = tbody.insertRow();
                    const profitClass = exec.actual_profit > 0 ? 'profit-positive' : 'profit-negative';
                    row.innerHTML = `
                        <td>${exec.plan_id.substring(0, 12)}...</td>
                        <td>${exec.tx_hash.substring(0, 10)}...</td>
                        <td>$${exec.expected_profit}</td>
                        <td class="${profitClass}">$${exec.actual_profit}</td>
                        <td>$${exec.gas_used}</td>
                        <td>${exec.execution_time}s</td>
                        <td><span class="status-${exec.status}">${exec.status}</span></td>
                    `;
                });
            }
            
            // Initial load
            fetch('/api/data').then(r => r.json()).then(updateDashboard);
            
            // Auto refresh every 10 seconds
            setInterval(() => {
                fetch('/api/data').then(r => r.json()).then(updateDashboard);
            }, 10000);
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)

@app.get("/api/data")
async def get_dashboard_data():
    """Get current dashboard data"""
    return await dashboard.get_dashboard_data()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time updates"""
    await websocket.accept()
    dashboard.active_connections.append(websocket)
    
    try:
        while True:
            # Send initial data
            data = await dashboard.get_dashboard_data()
            await websocket.send_text(json.dumps(data))
            await asyncio.sleep(5)  # Update every 5 seconds
    except:
        dashboard.active_connections.remove(websocket)

@app.get("/api/approved-plans")
async def get_approved_plans():
    """API endpoint for Chainlink Functions to fetch approved plans"""
    try:
        conn = sqlite3.connect(dashboard.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT * FROM arbitrage_plans 
            WHERE status = 'approved' 
            AND deadline > ?
            ORDER BY expected_profit DESC
            LIMIT 5
        ''', (int(time.time()),))
        
        rows = cursor.fetchall()
        conn.close()
        
        plans = []
        for row in rows:
            plans.append({
                'plan_id': row[0],
                'timestamp': row[1],
                'token': row[2],
                'direction': row[3],
                'trade_size_usd': row[4],
                'trade_size_tokens': row[5],
                'expected_profit': row[6],
                'profit_bps': row[7],
                'buy_chain': row[8],
                'sell_chain': row[9],
                'buy_price': row[10],
                'sell_price': row[11],
                'deadline': row[12],
                'status': row[13]
            })
        
        return plans
        
    except Exception as e:
        print(f"Error getting approved plans: {e}")
        return []

def main():
    """Start the dashboard server"""
    print("🚀 Starting Arbitrage Dashboard...")
    print("📊 Dashboard: http://localhost:8080")
    
    uvicorn.run(app, host="0.0.0.0", port=8080)

if __name__ == "__main__":
    main() 