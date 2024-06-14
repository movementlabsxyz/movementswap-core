use anyhow::Result;
use aptos_sdk::coin_client::CoinClient;
use aptos_sdk::crypto::ed25519::Ed25519PrivateKey;
use aptos_sdk::crypto::ed25519::Ed25519PublicKey;
use aptos_sdk::crypto::ValidCryptoMaterialStringExt;
use aptos_sdk::move_types::identifier::Identifier;
use aptos_sdk::move_types::language_storage::StructTag;
use aptos_sdk::move_types::language_storage::TypeTag;
use aptos_sdk::rest_client::FaucetClient;
use aptos_sdk::types::move_utils::MemberId;
use aptos_sdk::types::transaction::authenticator::AuthenticationKey;
use aptos_sdk::types::transaction::EntryFunction;
use aptos_sdk::types::transaction::ExecutionStatus;
use aptos_sdk::types::transaction::TransactionInfo;
use aptos_sdk::types::transaction::TransactionInfoV0;
use aptos_sdk::{
    rest_client::Client,
    transaction_builder::TransactionFactory,
    types::{
        //        account_address::AccountAddress,
        chain_id::ChainId, //SignedTransaction, TransactionArgument
        LocalAccount,
    },
};

const PRIVATE_KEY: &str = "0xcb1fe7df72aff4a114d2bff60ecce2172f342b66cd5dafb2b8844b25e29b8d58";
//const PUBLIC_KEY: &str = "0xd82405d9faa256840ff6a8fe78d28d3f43581b1d34aa7f78476f4ce7e47a9e92";
const CHAIN_ID: u8 = 4;
//const RPC_URL: &str = "http://127.0.0.1:30731";
const RPC_URL: &str = "http://127.0.0.1:8080";
const FAUCET_URL: &str = "http://127.0.0.1:30732";

#[tokio::main]
async fn main() -> Result<()> {
    let private_key = Ed25519PrivateKey::from_encoded_string(PRIVATE_KEY)?;
    let public_key = Ed25519PublicKey::from(&private_key);
    let account_address = AuthenticationKey::ed25519(&public_key).account_address();
    let chain_id = ChainId::new(CHAIN_ID);

    // Build a local representation of an account.
    let account = LocalAccount::new(account_address, private_key, 0);

    let faucet_client = FaucetClient::new(FAUCET_URL.parse()?, RPC_URL.parse()?);
    faucet_client
        .fund(account_address, 100_000_000_000)
        .await
        .unwrap();

    // Build an API client.
    let client = Client::new(RPC_URL.parse()?);
    let coin_client = CoinClient::new(&client);

    let balance = coin_client
        .get_account_balance(&account_address)
        .await
        .unwrap();

    // let balance = client.get_account_balance(account_address).await;
    println!("balance:{balance:?}",);

    //get account sequence numner
    let account_rpc = client.get_account(account_address).await.unwrap();
    let mut sequence_number = account_rpc.inner().sequence_number;
    println!("sequence_number: {sequence_number:?}",);

    // # TestCoinsV1
    // echo "Mint BTC TestCoinsV1"

    // echo "Initialize TestCoinsV1"
    // aptos move run --function-id ${SwapDeployer}::TestCoinsV1::initialize --assume-yes
    let tx_result = run_function(
    	"0xd82405d9faa256840ff6a8fe78d28d3f43581b1d34aa7f78476f4ce7e47a9e92::TestCoinsV1::initialize",
    	&account, &client, sequence_number, chain_id, vec![], vec![]).await?;
    println!("RESULTTTTTTT Mint tx_receipt_data: {tx_result:?}",);
    sequence_number += 1;

    // echo "Mint USDT TestCoinsV1"
    // aptos move run --function-id ${SwapDeployer}::TestCoinsV1::mint_coin \
    // --args address:${SwapDeployer} u64:20000000000000000 \
    // --type-args ${SwapDeployer}::TestCoinsV1::USDT --assume-yes
    let tytag = TypeTag::Struct(Box::new(StructTag {
        address: account_address,
        module: Identifier::new("TestCoinsV1").unwrap(),
        name: Identifier::new("USDT").unwrap(),
        type_args: vec![],
    }));
    let tx_result = run_function("0xd82405d9faa256840ff6a8fe78d28d3f43581b1d34aa7f78476f4ce7e47a9e92::TestCoinsV1::mint_coin", 
    	&account, &client, sequence_number, chain_id
    	, vec![tytag], vec![bcs::to_bytes(&account_address).unwrap(), bcs::to_bytes(&(20000000000000000 as u64)).unwrap()]).await?;
    println!("RESULTTTTTTT Mint tx_receipt_data: {tx_result:?}",);
    sequence_number += 1;

    // aptos move run --function-id ${SwapDeployer}::TestCoinsV1::mint_coin \
    // --args address:${SwapDeployer} u64:2000000000000 \
    // --type-args ${SwapDeployer}::TestCoinsV1::BTC --assume-yes
    let tytag = TypeTag::Struct(Box::new(StructTag {
        address: account_address,
        module: Identifier::new("TestCoinsV1").unwrap(),
        name: Identifier::new("BTC").unwrap(),
        type_args: vec![],
    }));
    let tx_result = run_function("0xd82405d9faa256840ff6a8fe78d28d3f43581b1d34aa7f78476f4ce7e47a9e92::TestCoinsV1::mint_coin", 
    	&account, &client, sequence_number, chain_id
    	, vec![tytag], vec![bcs::to_bytes(&account_address).unwrap(), bcs::to_bytes(&(2000000000000 as u64)).unwrap()]).await?;
    println!("RESULTTTTTTT Mint tx_receipt_data: {tx_result:?}",);
    sequence_number += 1;

    Ok(())
}

async fn run_function(
    function_id: &str,
    account: &LocalAccount,
    client: &Client,
    sequence_number: u64,
    chainid: ChainId,
    ty_args: Vec<TypeTag>,
    args: Vec<Vec<u8>>,
) -> Result<TransactionInfoV0> {
    let MemberId {
        module_id,
        member_id,
    } = str::parse(function_id)?;

    let entry_function = EntryFunction::new(module_id, member_id, ty_args, args);
    let raw_tx = TransactionFactory::new(chainid)
        .entry_function(entry_function)
        .sender(account.address())
        .sequence_number(sequence_number)
        .build();
    println!("raw_tx:{raw_tx:?}",);

    let signed_transaction = account.sign_transaction(raw_tx);
    println!("signed_transaction:{signed_transaction:?}",);

    let tx_receipt_data = client.submit_and_wait_bcs(&signed_transaction).await?;
    println!("RESULTTTTTTT Mint tx_receipt_data: {tx_receipt_data:?}",);
    //TODO process result
    let TransactionInfo::V0(tx_info) = tx_receipt_data.into_inner().info;

    if let ExecutionStatus::Success = tx_info.status() {
        Ok(tx_info)
    } else {
        println!("Tx fail with result {tx_info:?}",);
        Err(anyhow::anyhow!(format!("Tx send fail:{tx_info:?}")).into())
    }
}
