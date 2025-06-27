export PRIVATE_KEY=0x9971812261ecfc8d83860eaceff14ab42748678da818e0ab8a586f6dde6adb2d
export ETHEREUM_SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl
export ARBITRUM_SEPOLIA_RPC_URL=https://arb-sepolia.g.alchemy.com/v2/xiJw6cj_7U8PXLSncrSON78PWDXP4Dkl

export BUNDLE_EXECUTOR=0xB20412c4403277A6dD64e0D0dCa19F81b5412cBA
export PLAN_STORE=0x1177D6F59e9877D6477743C6961988D86ee78174
export FUNCTIONS_CONSUMER=0x59c6AC86b75Caf8FC79782F79C85B8588211b6C2
export REMOTE_EXECUTOR=0x45ee7AA56775aB9385105393458FC4e56b4B578c



forge script script/DeployArbitrageFunctionsConsumer.s.sol --private-key $PRIVATE_KEY --rpc-url $ETHEREUM_SEPOLIA_RPC_URL --broadcast


cast send --private-key $PRIVATE_KEY $PLAN_STORE "setFunctionsConsumer(address)" $FUNCTIONS_CONSUMER  --rpc-url $ETHEREUM_SEPOLIA_RPC_URL

Update consumer in chainlink site

cast call $PLAN_STORE "functionsConsumer()" --rpc-url $ETHEREUM_SEPOLIA_RPC_URL


