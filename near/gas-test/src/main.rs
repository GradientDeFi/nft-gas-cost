// use near_units::{parse_gas, parse_near};
use serde_json::json;
// use workspaces::prelude::*;
// use workspaces::{network::Sandbox, Account, Contract, Worker};

const NFT_WASM_FILEPATH: &str = "../res/nep171.wasm"; // relative directory is gas-test/

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // initiate environemnt
    let worker = workspaces::sandbox().await?;

    // deploy contracts
    let nft_wasm = std::fs::read(NFT_WASM_FILEPATH)?;
    let nft_contract = worker.dev_deploy(&nft_wasm).await?;

    // create accounts
    let owner = worker.root_account().unwrap();
    // let alice = owner
    //     .create_subaccount("alice")
    //     .initial_balance(parse_near!("30 N"))
    //     .transact()
    //     .await?
    //     .into_result()?;

    // Initialize NFT contract
    
    let outcome = nft_contract
        .call("new_default_meta")
        .args_json(json!({
            "owner_id": nft_contract.id(), // owner.id()
        }))
        .transact()
        .await?;

    // println!("new_default_meta outcome: {:#?}", outcome);

    let deposit = 10000000000000000000000;
    let outcome = nft_contract
        .call("nft_mint")
        .args_json(json!({
            "token_id": "0",
            // "token_owner_id": nft_contract.id(),
            "receiver_id": owner.id(),
            "token_metadata": {
                "title": "Olympus Mons",
                "dscription": "Tallest mountain in charted solar system",
                "copies": 1,
            },
        }))
        .deposit(deposit)
        .transact()
        .await?;

    println!("nft_mint outcome: {:#?}", outcome);

    println!("------------------");
    println!(
        "Gas burnt: {}",
        comma_separate(outcome.total_gas_burnt) // outcome.outcome().gas_burnt
    );
    println!(
        "converted to NEAR: {}",
        // burnt gas to NEAR => gas * 10^(-15)
        // 1 TGas = 10^12 gas unit
        // 1 NEAR = 10^3 TGas (1 NEAR = 10^3 milliNEAR = 10^4 TGas)
        outcome.total_gas_burnt as f64 / 1_000_000_000_000_000.0
    );

    // let result: serde_json::Value = worker.view(nft_contract.id(), "nft_metadata").await?.json()?;
    // println!("--------------\n{}", result);
    // println!("Dev Account ID: {}", nft_contract.id());

    Ok(())
}

fn comma_separate(x: u64) -> String {
    x.to_string()
        .as_bytes()
        .rchunks(3)
        .rev()
        .map(std::str::from_utf8)
        .collect::<Result<Vec<&str>, _>>()
        .unwrap()
        .join(",")
}