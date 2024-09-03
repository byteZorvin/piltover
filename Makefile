# Variables
PROFILE := -p development
OWNER := 0x05bcf773a0bb4e867826f47aabacb6c6371cfbb76cc29e82c33e91cc3b3e0b42
FEE := --fee-token eth
CLASSHASH := 0x791ef6274f2ff1a1a351e686dfdb1689592b3b32b32d3e36e31f3ccb41486c8

# Default target
all: declare deploy

# Declare the contract
declare:
	sncast $(PROFILE) declare --contract-name appchain $(FEE)

# Deploy the contract
deploy:
	sncast $(PROFILE) deploy -c $(OWNER) 1 1 1 --class-hash $(CLASSHASH) $(FEE)

# Add profile (placeholder for the original shell function)
addprofile:
	@echo "addprofile function placeholder"

# Clean target (optional)
clean:
	@echo "Cleaning up..."

.PHONY: all declare deploy addprofile clean
