-include .env

.PHONY: all test clean

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std --no-commit && \
forge install openzeppelin/openzeppelin-contracts --no-commit && \
forge install chiru-labs/ERC721A --no-commit

# Update Dependencies
update :; forge update

build :; forge build

build-op :; forge build --via-ir --optimize

snapshot :; forge snapshot

slither :; slither ./src 

anvil :; anvil -m 'test test test test test test test test test test test junk'


# normal EVM gas test
gas-test :; forge test --match-test testMint10k --gas-report

# Polygon's zkEVM
gas-test-polygon-zkevm :; forge test --match-test testMint10kGasDeal --gas-report --fork-url https://zkevm-rpc.com

# zkSync Era
gas-test-zksync-era :; forge test --match-test testMint10kGasDeal --gas-report --fork-url https://mainnet.era.zksync.io