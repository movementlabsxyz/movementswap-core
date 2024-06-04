import { Aptos, AptosConfig, Account, MoveModuleBytecode, AccountAddress, Ed25519PrivateKey, APTOS_COIN, HexInput } from "@aptos-labs/ts-sdk"
import dotenv from "dotenv"
// import 'mocha'
// import {expect} from "chai"

// Specify the path to the .env file in the parent directory
dotenv.config({ path: '../.env' });

const SwapDeployer = process.env.SWAP_DEPLOYER;
const ResourceAccount = process.env.RESOURCE_ACCOUNT_DEPLOYER;

const aptosConfig = new AptosConfig({ fullnode: process.env.FULLNODE || "https://aptos.devnet.m1.movementlabs.xyz" });
const aptos = new Aptos(aptosConfig);
console.log(process.env.PRIVATE_KEY)

const privateKey = new Ed25519PrivateKey(process.env.PRIVATE_KEY as string);
const deployer = Account.fromPrivateKey({ privateKey });

const alice = Account.generate();
const bob = Account.generate();

const amount = 100000000;

async function transact(signer: any, func: `${string}::${string}::${string}`, typeArgs: string[], args: any[]) {
    const transaction = await aptos.transaction.build.simple({
        sender: signer.accountAddress,
        data: {
            function: func,
            typeArguments: [...typeArgs],
            functionArguments: [...args],
        },
    });
    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: signer, transaction });
    return committedTransaction
}

async function main() {

    console.log(SwapDeployer)
    console.log(ResourceAccount)

    aptos.faucet.fundAccount({ accountAddress: alice.accountAddress, amount: amount })
    aptos.faucet.fundAccount({ accountAddress: bob.accountAddress, amount: amount })
    // describe("sdk", async () => {
    //     test("transaction reads", async () => {
    const fund = await aptos.getAccountInfo({ accountAddress: alice.accountAddress });
    const modules = await aptos.getAccountModules({ accountAddress: deployer.accountAddress });
    const tokens = await aptos.getAccountOwnedTokens({ accountAddress: deployer.accountAddress });

    const testCoinsV1 = await aptos.getAccountResource<typeof APTOS_COIN>({
        accountAddress: deployer.accountAddress,
        resourceType: `0x1::coin::CoinStore<${deployer.accountAddress}::TestCoinsV1::USDT>`,
    })

    // expect(fund).to.be(String(amount));
    // expect(modules[0].abi?.name).to.be(`uq64x64`)
    // expect(tokens[0].token_standard).to.be('AptosCoin')
    // })


    // test("transaction writes", async () => {
    const mint = await transact(deployer, `${SwapDeployer}::TestCoinV1::mint_coin`, [`${SwapDeployer}::TestCoinsV1::USDT`], [20000000000000000]);
    const usdt_request = await transact(alice, `${SwapDeployer}::FaucetV1::request`, [`${SwapDeployer}::TestCoinsV1::USDT`], [alice.accountAddress])
    const nice_request = await transact(bob, `${SwapDeployer}::FaucetV1::request`, [`${SwapDeployer}::TestCoinsV1::USDT`], [alice.accountAddress])

    const btc_request = await transact(alice, `${SwapDeployer}::FaucetV1::request`, [`${SwapDeployer}::TestCoinsV1::BTC`], [alice.accountAddress])
    // swap exact BTC
    const btc_swap = await transact(alice, `${SwapDeployer}::AnimeSwapPoolV1::swap_exact_coins_for_coins_entry`, [`${SwapDeployer}::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin`], ['u64:100 u64:1000000000'])
    // swap BTC for exact USDT
    const btc_swap_exact = await transact(alice, `${SwapDeployer}::AnimeSwapPoolV1::swap_exact_coins_for_coins_entry`, [`${SwapDeployer}::TestCoinsV1::BTC 0x1::aptos_coin::AptosCoin`, `0x1::aptos_coin::AptosCoin`, `${SwapDeployer}::TestCoinsV1::USDT`], ['u64:100 u64:1'])

    //         expect(mint.type).to.be(String(1))
    //         expect(usdt_request.type).to.be(String(1))
    //         expect(nice_request.type).to.be(String(1))
    //         expect(btc_request.type).to.be(String(1))
    //         expect(btc_swap.type).to.be(String(1))
    //         expect(btc_swap_exact.type).to.be(String(1))
    //     })
    // })

}
main().catch((err) => { console.log(err) })