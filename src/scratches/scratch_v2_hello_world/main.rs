use anyhow::Result;
use dotenv::dotenv;
use reqwest::Client;
use serde_json::{json, Value};
use std::env;
use structopt::StructOpt;

#[derive(StructOpt)]
#[structopt(name = "solana_block_fetcher", about = "Fetch Solana block and parse tx hashes")]
struct Opt {
    /// Block number to fetch
    #[structopt(short, long)]
    block_number: u64,
}

#[tokio::main]
async fn main() -> Result<()> {
    // Load environment variables from .env file
    dotenv().ok();
    
    // Parse command line arguments
    let opt = Opt::from_args();
    let block_number = opt.block_number;
    
    // Get the node URL from environment variables
    let node_url = env::var("NODE_URL").expect("NODE_URL must be set in .env file");
    
    println!("Fetching block {} from {}", block_number, node_url);
    
    // Create HTTP client
    let client = Client::new();
    
    // Create JSON-RPC request payload
    let payload = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "getBlock",
        "params": [
            block_number,
            {
                "commitment": "confirmed",
                "encoding": "jsonParsed",
                "maxSupportedTransactionVersion": 0
            }
        ]
    });
    
    // Send request to Solana node
    let response = client.post(&node_url)
        .json(&payload)
        .send()
        .await?
        .json::<Value>()
        .await?;
    
    // Check if there's an error in the response
    if response["error"].is_object() {
        println!("Error: {}", response["error"]);
        return Ok(());
    }
    
    // Get the block data
    let block = &response["result"];
    
    // Extract and print transaction hashes
    if let Some(transactions) = block["transactions"].as_array() {
        println!("Found {} transactions in block {}", transactions.len(), block_number);
        println!("Transaction hashes:");
        
        for (i, tx) in transactions.iter().enumerate() {
            if let Some(tx_hash) = tx["transaction"]["signatures"][0].as_str() {
                println!("{}. {}", i + 1, tx_hash);
            }
        }
    } else {
        println!("No transactions found in block {}", block_number);
    }
    
    Ok(())
} 