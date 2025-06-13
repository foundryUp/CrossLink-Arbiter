#!/usr/bin/env python3
"""
Environment Setup Script for Cross-Domain Arbitrage Bot

This script sets up the development environment, installs dependencies,
and configures the system for first-time setup.
"""

import os
import sys
import subprocess
import json
import shutil
from pathlib import Path
from typing import Dict, List


def run_command(cmd: str, cwd: str = None) -> bool:
    """Run a shell command and return success status."""
    try:
        print(f"Running: {cmd}")
        result = subprocess.run(
            cmd, shell=True, cwd=cwd, check=True,
            capture_output=True, text=True
        )
        if result.stdout:
            print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {cmd}")
        print(f"Error: {e.stderr}")
        return False


def check_prerequisites() -> bool:
    """Check if all required tools are installed."""
    print("🔍 Checking prerequisites...")
    
    required_tools = {
        'node': 'Node.js 18+',
        'npm': 'npm package manager',
        'python3': 'Python 3.9+',
        'pip': 'Python package manager',
        'docker': 'Docker',
        'docker-compose': 'Docker Compose',
        'forge': 'Foundry (install from https://getfoundry.sh)'
    }
    
    missing_tools = []
    
    for tool, description in required_tools.items():
        if not shutil.which(tool):
            missing_tools.append(f"  - {tool}: {description}")
    
    if missing_tools:
        print("❌ Missing required tools:")
        for tool in missing_tools:
            print(tool)
        print("\nPlease install missing tools and run this script again.")
        return False
    
    print("✅ All prerequisites found!")
    return True


def setup_environment_file():
    """Create .env file from template if it doesn't exist."""
    print("📄 Setting up environment file...")
    
    env_file = Path('.env')
    env_example = Path('.env.example')
    
    if env_file.exists():
        print("✅ .env file already exists")
        return True
    
    if not env_example.exists():
        print("❌ .env.example not found")
        return False
    
    # Copy template
    shutil.copy(env_example, env_file)
    print("✅ Created .env from template")
    print("⚠️  Please edit .env file with your configuration before proceeding")
    return True


def setup_node_dependencies() -> bool:
    """Install Node.js dependencies."""
    print("📦 Installing Node.js dependencies...")
    
    if not run_command("npm install"):
        return False
    
    print("✅ Node.js dependencies installed")
    return True


def setup_python_dependencies() -> bool:
    """Install Python dependencies."""
    print("🐍 Setting up Python environment...")
    
    # Create virtual environment if it doesn't exist
    if not Path('venv').exists():
        if not run_command("python3 -m venv venv"):
            return False
        print("✅ Created Python virtual environment")
    
    # Activate venv and install dependencies
    if sys.platform.startswith('win'):
        activate_cmd = "venv\\Scripts\\activate"
    else:
        activate_cmd = "source venv/bin/activate"
    
    install_cmd = f"{activate_cmd} && pip install -r requirements.txt"
    
    if not run_command(install_cmd):
        return False
    
    print("✅ Python dependencies installed")
    return True


def setup_foundry() -> bool:
    """Setup Foundry environment for smart contracts."""
    print("⚒️  Setting up Foundry environment...")
    
    contracts_dir = Path('contracts')
    if not contracts_dir.exists():
        print("❌ contracts directory not found")
        return False
    
    # Install Foundry dependencies
    if not run_command("forge install", cwd=str(contracts_dir)):
        return False
    
    # Create remappings
    remappings = [
        "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/",
        "@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/",
        "solmate/=lib/solmate/src/"
    ]
    
    remappings_file = contracts_dir / "remappings.txt"
    with open(remappings_file, 'w') as f:
        f.write('\n'.join(remappings))
    
    print("✅ Foundry environment setup complete")
    return True


def setup_directories() -> bool:
    """Create necessary directories."""
    print("📁 Creating project directories...")
    
    directories = [
        'logs',
        'data',
        'backups',
        'temp',
        'keys' # For development keys only
    ]
    
    for directory in directories:
        Path(directory).mkdir(exist_ok=True)
    
    print("✅ Directories created")
    return True


def setup_git_hooks() -> bool:
    """Setup Git hooks for development."""
    print("🪝 Setting up Git hooks...")
    
    hooks_dir = Path('.git/hooks')
    if not hooks_dir.exists():
        print("❌ .git/hooks directory not found")
        return False
    
    # Pre-commit hook
    pre_commit_hook = hooks_dir / 'pre-commit'
    pre_commit_content = """#!/bin/sh
# Pre-commit hook for Cross-Domain Arbitrage Bot

echo "Running pre-commit checks..."

# Run linters
echo "Running ESLint..."
npm run lint
if [ $? -ne 0 ]; then
    echo "ESLint failed. Please fix errors before committing."
    exit 1
fi

echo "Running Python linters..."
python -m flake8 agents/
if [ $? -ne 0 ]; then
    echo "Python linting failed. Please fix errors before committing."
    exit 1
fi

echo "Running Foundry formatter check..."
cd contracts && forge fmt --check
if [ $? -ne 0 ]; then
    echo "Solidity formatting check failed. Run 'forge fmt' to fix."
    exit 1
fi

echo "Pre-commit checks passed!"
"""
    
    with open(pre_commit_hook, 'w') as f:
        f.write(pre_commit_content)
    
    # Make executable
    pre_commit_hook.chmod(0o755)
    
    print("✅ Git hooks setup complete")
    return True


def setup_docker_environment() -> bool:
    """Setup Docker development environment."""
    print("🐳 Setting up Docker environment...")
    
    # Check if Docker is running
    if not run_command("docker info > /dev/null 2>&1"):
        print("❌ Docker is not running. Please start Docker and try again.")
        return False
    
    # Pull required images
    images = [
        'postgres:15-alpine',
        'redis:7-alpine',
        'prom/prometheus:latest',
        'grafana/grafana:latest'
    ]
    
    for image in images:
        print(f"Pulling {image}...")
        if not run_command(f"docker pull {image}"):
            print(f"⚠️  Failed to pull {image}, continuing...")
    
    print("✅ Docker environment ready")
    return True


def create_development_config():
    """Create development configuration files."""
    print("⚙️  Creating development configuration...")
    
    # Development configuration
    dev_config = {
        "environment": "development",
        "debug": True,
        "log_level": "DEBUG",
        "database": {
            "host": "localhost",
            "port": 5432,
            "database": "arbitrage_bot",
            "username": "arbitrage_user",
            "password": "arbitrage_password"
        },
        "redis": {
            "host": "localhost",
            "port": 6379,
            "db": 0
        },
        "monitoring": {
            "prometheus_port": 9090,
            "grafana_port": 3000,
            "dashboard_port": 8080
        }
    }
    
    config_file = Path('config/development.json')
    with open(config_file, 'w') as f:
        json.dump(dev_config, f, indent=2)
    
    print("✅ Development configuration created")
    return True


def run_initial_tests() -> bool:
    """Run initial tests to verify setup."""
    print("🧪 Running initial tests...")
    
    # Test Node.js setup
    if not run_command("npm run lint"):
        print("⚠️  Node.js linting test failed")
    
    # Test Python setup
    if not run_command("python3 -c 'import agents.shared.models; print(\"Python imports working\")'"):
        print("⚠️  Python import test failed")
    
    # Test Foundry setup
    if not run_command("forge build", cwd="contracts"):
        print("⚠️  Foundry build test failed")
    
    print("✅ Initial tests completed")
    return True


def print_next_steps():
    """Print next steps for the user."""
    print("\n" + "="*60)
    print("🎉 SETUP COMPLETE!")
    print("="*60)
    print("\n📝 Next Steps:")
    print("1. Edit .env file with your configuration:")
    print("   - Add your private keys")
    print("   - Configure RPC URLs")
    print("   - Set up AWS credentials")
    print("   - Configure Chainlink subscriptions")
    print("\n2. Start the development environment:")
    print("   make docker-up")
    print("\n3. Deploy contracts to testnet:")
    print("   make deploy-testnet")
    print("\n4. Start the monitoring dashboard:")
    print("   make start-dashboard")
    print("\n5. Start the AI agents:")
    print("   make start-agents")
    print("\n📚 Documentation:")
    print("   - Architecture: docs/ARCHITECTURE.md")
    print("   - Implementation: docs/IMPLEMENTATION.md")
    print("   - Team Tasks: docs/TEAM_TASKS.md")
    print("\n🔧 Available Commands:")
    print("   make help  # Show all available commands")
    print("\n⚠️  Security Reminders:")
    print("   - Never commit real private keys")
    print("   - Use testnet for development")
    print("   - Test thoroughly before mainnet")
    print("\n🚀 Happy Building!")


def main():
    """Main setup function."""
    print("🚀 Cross-Domain Arbitrage Bot - Environment Setup")
    print("="*50)
    
    steps = [
        ("Check Prerequisites", check_prerequisites),
        ("Setup Environment File", setup_environment_file),
        ("Setup Directories", setup_directories),
        ("Install Node.js Dependencies", setup_node_dependencies),
        ("Install Python Dependencies", setup_python_dependencies),
        ("Setup Foundry", setup_foundry),
        ("Setup Git Hooks", setup_git_hooks),
        ("Setup Docker Environment", setup_docker_environment),
        ("Create Development Config", create_development_config),
        ("Run Initial Tests", run_initial_tests),
    ]
    
    failed_steps = []
    
    for step_name, step_func in steps:
        print(f"\n🔄 {step_name}...")
        try:
            if not step_func():
                failed_steps.append(step_name)
                print(f"❌ {step_name} failed")
            else:
                print(f"✅ {step_name} completed")
        except Exception as e:
            print(f"❌ {step_name} failed with error: {e}")
            failed_steps.append(step_name)
    
    if failed_steps:
        print(f"\n⚠️  Setup completed with {len(failed_steps)} issues:")
        for step in failed_steps:
            print(f"   - {step}")
        print("\nPlease review the errors above and fix them manually.")
    
    print_next_steps()
    
    return 0 if not failed_steps else 1


if __name__ == "__main__":
    sys.exit(main()) 