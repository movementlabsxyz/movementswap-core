#!/bin/sh

# deployer address
SwapDeployer="0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593"
ResourceAccountDeployer="0xe3af437c5d29fe7f2cbfa66ec4b24466c4706fb700ae829cc6b86e7e619c06bc"
# SwapDeployer is your account, you must have its private key
# ResourceAccountDeployer is derivatived by SwapDeployer, you can refer to swap::test_resource_account to get the exact address

PATH_TO_REPO="."

# publish modules
movement move publish --package-dir $PATH_TO_REPO/uq64x64/ --assume-yes --url "https://seed-node1.movementlabs.xyz/v1"
movement move publish --package-dir $PATH_TO_REPO/u256/ --assume-yes
movement move publish --package-dir $PATH_TO_REPO/TestCoin/ --assume-yes
movement move publish --package-dir $PATH_TO_REPO/Faucet/ --assume-yes
movement move publish --package-dir $PATH_TO_REPO/LPResourceAccount/ --assume-yes
# create resource account & publish LPCoin
# use this command to compile LPCoin
movement move compile --package-dir $PATH_TO_REPO/LPCoin/ --save-metadata
# get the first arg
hexdump -ve '1/1 "%02x"' $PATH_TO_REPO/LPCoin/build/LPCoin/package-metadata.bcs
# get the second arg
hexdump -ve '1/1 "%02x"' $PATH_TO_REPO/LPCoin/build/LPCoin/bytecode_modules/LPCoinV1.mv
# This command is to publish LPCoin contract, using ResourceAccountDeployer address. Note: replace two args with the above two hex
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::LPResourceAccount::initialize_lp_account \
--args hex:064c50436f696e010000000000000000403839433333334434424434463131383441453033374139433139363935343530393741314345343641313533394538364430304135443045303133373439413790021f8b08000000000002ff4590314fc3301085f7fc8a283324761cc731124305626240ac5507fb7c6ea3367664270184f8efd850c472ba77f7bdd3d3ed67056775c443e1d484e57d593dbf3cf8d155c586218edee511a9594daaa2d81b9cd1197430623c14bb79f1f12924df9b0fe7047e96c771c986d3b2ccf1ae69923cadba063f352ac3b717a5e3b5051fb04e407553c6559b3164e3ef6af21b36f6eff095ffd7c91170cbf8c0fa8e1a66c9c044df5a460521a427c85172ab35050deda02da9caaf945e191330c61cfd15a35f03e00ec0af6e79c4f9e23ff027027917b29784a046aaa8e29db512256b2d95c0bbc172a02a951e85619decf9c08582d60a4d0d55ba056dd3a7be0145d9d0655701000001084c50436f696e56316b1f8b08000000000002ff5dc8b10a80201080e1bda7b80768b15122881a1b22a23deca0403d516f10f1dd2bdafab7ff3374b0465830107b85bd52c4368ee83425f4524ef34097dd04e40a9e42f4ac227cdaba73b7910cbcb32687a2863f351de452951b1e36ff316700000000000300000000000000000000000000000000000000000000000000000000000000010e4170746f734672616d65776f726b00000000000000000000000000000000000000000000000000000000000000010b4170746f735374646c696200000000000000000000000000000000000000000000000000000000000000010a4d6f76655374646c696200 \
hex:a11ceb0b0500000005010002020208070a1c0826200a460500000001000200010001084c50436f696e5631064c50436f696e0b64756d6d795f6669656c64e3af437c5d29fe7f2cbfa66ec4b24466c4706fb700ae829cc6b86e7e619c06bc000201020100 --assume-yes
movement move publish --package-dir $PATH_TO_REPO/Swap/ --assume-yes

# admin steps
# TestCoinsV1
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::initialize --assume-yes

movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::mint_coin \
--args address:0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593 u64:20000000000000000 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::USDT --assume-yes

movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::mint_coin \
--args address:0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593 u64:2000000000000 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC --assume-yes

# FaucetV1
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::FaucetV1::create_faucet \
--args u64:10000000000000000 u64:1000000000 u64:3600 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::USDT --assume-yes

movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::FaucetV1::create_faucet \
--args u64:1000000000000 u64:10000000 u64:3600 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC --assume-yes

# AnimeSwapPool
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::add_liquidity_entry \
--args u64:10000000000 u64:100000000 u64:1 u64:1 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::USDT 0x1::aptos_coin::AptosCoin --assume-yes

movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::add_liquidity_entry \
--args u64:10000000 u64:100000000 u64:1 u64:1 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin --assume-yes

movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::add_liquidity_entry \
--args u64:100000000 u64:100000000000 u64:1 u64:1 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::USDT --assume-yes

echo "Finished Admin Functions"
exit
# user
# fund
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::FaucetV1::request \
--args address:0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::USDT
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::FaucetV1::request \
--args address:0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC
# swap (type args shows the swap direction, in this example, swap BTC to APT)
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::swap_exact_coins_for_coins_entry \
--args u64:100 u64:1 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin
# swap
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::swap_coins_for_exact_coins_entry \
--args u64:100 u64:1000000000 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin
# multiple pair swap (this example, swap 100 BTC->APT->USDT)
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::swap_exact_coins_for_coins_2_pair_entry \
--args u64:100 u64:1 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::USDT
# add lp (if pair not exist, will auto create lp first)
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::add_liquidity_entry \
--args u64:1000 u64:10000 u64:1 u64:1 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::remove_liquidity_entry \
--args u64:1000 u64:1 u64:1 \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin

# Admin cmd example
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::set_dao_fee_to \
--args address:0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::set_admin_address \
--args address:0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::set_dao_fee \
--args u64:5
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::set_swap_fee \
--args u64:30
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::withdraw_dao_fee \
--type-args 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::BTC 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::TestCoinsV1::USDT
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::pause
movement move run --function-id 0x6dc4a568ae04c627de026a740f12d6d2d7e329001e6c37eecb8afdc66ad4a593::AnimeSwapPoolV1::unpause