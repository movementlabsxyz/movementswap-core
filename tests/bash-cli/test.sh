#!/bin/sh

APTOS_URL="https://aptos.devnet.m1.movementlabs.xyz"
PATH_TO_REPO="."

initialize_output=$(echo -ne '\n' | aptos init --network custom --rest-url $APTOS_URL --faucet-url $APTOS_URL --assume-yes)

CONFIG_FILE=".aptos/config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Initialization failed. Config file not found."
  exit 1
fi

PrivateKey=$(grep 'private_key:' "$CONFIG_FILE" | awk -F': ' '{print $2}' | tr -d '"')

lookup_address_output=$(aptos account lookup-address)
echo "Lookup Address Output: $lookup_address_output"
SwapDeployer=0x$(echo "$lookup_address_output" | grep -o '"Result": "[0-9a-fA-F]\{64\}"' | sed 's/"Result": "\(.*\)"/\1/')
if [ -z "$SwapDeployer" ]; then
  echo "SwapDeployer extraction failed."
  exit 1
fi

test_resource_account_output=$(aptos move test --package-dir "$PATH_TO_REPO/Swap/" --filter test_resource_account --named-addresses SwapDeployer=default,uq64x64=default,u256=default,ResourceAccountDeployer=default)
echo "Test Resource Account Output: $test_resource_account_output"
ResourceAccountDeployer=$(echo "$test_resource_account_output" | grep -o '\[debug\] @[^\s]*' | sed 's/\[debug\] @\(.*\)/\1/')

echo "SwapDeployer: $SwapDeployer"
echo "ResourceAccountDeployer: $ResourceAccountDeployer"

add_or_update_env() {
    local key=$1
    local value=$2
    local file=".env"
    if grep -q "^$key=" "$file"; then
        # Update the existing key with the new value
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/^$key=.*/$key=$value/" "$file"
        else
            # Linux and other Unix-like systems
            sed -i "s/^$key=.*/$key=$value/" "$file"
        fi
    else
        # Add the key-value pair if it doesn't exist
        echo "$key=$value" >> "$file"
    fi
}

add_or_update_env "SWAP_DEPLOYER" $SwapDeployer
add_or_update_env "RESOURCE_ACCOUNT_DEPLOYER" $ResourceAccountDeployer
add_or_update_env "PRIVATE_KEY" $PrivateKey
add_or_update_env "FULLNODE" $APTOS_URL

# publish 
aptos move publish --package-dir $PATH_TO_REPO/uq64x64/ --assume-yes --named-addresses uq64x64=$SwapDeployer 
aptos move publish --package-dir $PATH_TO_REPO/u256/ --assume-yes --named-addresses u256=$SwapDeployer 
aptos move publish --package-dir $PATH_TO_REPO/TestCoin/ --assume-yes --named-addresses SwapDeployer=$SwapDeployer 
aptos move publish --package-dir $PATH_TO_REPO/Faucet/ --assume-yes --named-addresses SwapDeployer=$SwapDeployer
aptos move publish --package-dir $PATH_TO_REPO/LPResourceAccount/ --assume-yes --named-addresses SwapDeployer=$SwapDeployer
# create resource account & publish LPCoin
# use this command to compile LPCoin
aptos move compile --package-dir $PATH_TO_REPO/LPCoin/ --save-metadata
# get the first arg
arg1=$(hexdump -ve '1/1 "%02x"' $PATH_TO_REPO/LPCoin/build/LPCoin/package-metadata.bcs)
# get the second arg
arg2=$(hexdump -ev '1/1 "%02x"' $PATH_TO_REPO/LPCoin/build/LPCoin/bytecode_modules/LPCoinV1.mv)
# This command is to publish LPCoin contract, using ResourceAccountDeployer address. Note: replace two args with the above two hex
aptos move run --function-id ${SwapDeployer}::LPResourceAccount::initialize_lp_account \
--args hex:$arg1 hex:$arg2 --assume-yes
aptos move publish --package-dir $PATH_TO_REPO/Swap/ --assume-yes --named-addresses SwapDeployer=$SwapDeployer,ResourceAccountDeployer=$ResourceAccountDeployer

# admin steps
# TestCoinsV1
aptos move run --function-id ${SwapDeployer}::TestCoinsV1::initialize --assume-yes

aptos move run --function-id ${SwapDeployer}::TestCoinsV1::mint_coin \
--args address:${SwapDeployer} u64:20000000000000000 \
--type-args ${SwapDeployer}::TestCoinsV1::USDT --assume-yes

aptos move run --function-id ${SwapDeployer}::TestCoinsV1::mint_coin \
--args address:${SwapDeployer} u64:2000000000000 \
--type-args ${SwapDeployer}::TestCoinsV1::BTC --assume-yes

# FaucetV1
aptos move run --function-id ${SwapDeployer}::FaucetV1::create_faucet \
--args u64:10000000000000000 u64:1000000000 u64:3600 \
--type-args ${SwapDeployer}::TestCoinsV1::USDT --assume-yes

aptos move run --function-id ${SwapDeployer}::FaucetV1::create_faucet \
--args u64:1000000000000 u64:10000000 u64:3600 \
--type-args ${SwapDeployer}::TestCoinsV1::BTC --assume-yes

# AnimeSwapPool
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::add_liquidity_entry \
--args u64:10000000000 u64:100000000 u64:1 u64:1 \
--type-args ${SwapDeployer}::TestCoinsV1::USDT 0x1::aptos_coin::AptosCoin --assume-yes

aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::add_liquidity_entry \
--args u64:10000000 u64:100000000 u64:1 u64:1 \
--type-args ${SwapDeployer}::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin --assume-yes

aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::add_liquidity_entry \
--args u64:100000000 u64:100000000000 u64:1 u64:1 \
--type-args ${SwapDeployer}::TestCoinsV1::BTC ${SwapDeployer}::TestCoinsV1::USDT --assume-yes

echo "Finished Admin Functions"
exit
# user
# fund
aptos move run --function-id ${SwapDeployer}::FaucetV1::request \
--args address:${SwapDeployer} \
--type-args ${SwapDeployer}::TestCoinsV1::USDT
aptos move run --function-id ${SwapDeployer}::FaucetV1::request \
--args address:${SwapDeployer} \
--type-args ${SwapDeployer}::TestCoinsV1::BTC
# swap (type args shows the swap direction, in this example, swap BTC to APT)
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::swap_exact_coins_for_coins_entry \
--args u64:100 u64:1 \
--type-args ${SwapDeployer}::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin
# swap
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::swap_coins_for_exact_coins_entry \
--args u64:100 u64:1000000000 \
--type-args ${SwapDeployer}::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin
# multiple pair swap (this example, swap 100 BTC->APT->USDT)
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::swap_exact_coins_for_coins_2_pair_entry \
--args u64:100 u64:1 \
--type-args ${SwapDeployer}::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin ${SwapDeployer}::TestCoinsV1::USDT
# add lp (if pair not exist, will auto create lp first)
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::add_liquidity_entry \
--args u64:1000 u64:10000 u64:1 u64:1 \
--type-args ${SwapDeployer}::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::remove_liquidity_entry \
--args u64:1000 u64:1 u64:1 \
--type-args ${SwapDeployer}::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin

# Admin cmd example
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::set_dao_fee_to \
--args address:${SwapDeployer}
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::set_admin_address \
--args address:${SwapDeployer}
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::set_dao_fee \
--args u64:5
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::set_swap_fee \
--args u64:30
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::withdraw_dao_fee \
--type-args ${SwapDeployer}::TestCoinsV1::BTC ${SwapDeployer}::TestCoinsV1::USDT
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::pause
aptos move run --function-id ${SwapDeployer}::AnimeSwapPoolV1::unpause