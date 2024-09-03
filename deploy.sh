# addprofile()

profile='-p development'
owner=0x05bcf773a0bb4e867826f47aabacb6c6371cfbb76cc29e82c33e91cc3b3e0b42
fee='--fee-token eth'

# For declaring the contract
sncast $profile declare --contract-name appchain $fee

classhash=0x791ef6274f2ff1a1a351e686dfdb1689592b3b32b32d3e36e31f3ccb41486c8
sncast $profile deploy -c $owner 1 1 1 --class-hash $classhash $fee
