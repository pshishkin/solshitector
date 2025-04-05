use anyhow::Result;
use ipfs_api::{IpfsClient, IpfsApi};
use std::path::PathBuf;
use std::fs::File;
use std::io::Write;
use futures::StreamExt;
use bytes::Bytes;

pub struct IpfsBlockDownloader {
    client: IpfsClient,
}

impl IpfsBlockDownloader {
    pub fn new() -> Self {
        Self {
            client: IpfsClient::default(),
        }
    }

    pub async fn download_block(&self, block_number: u64, output_path: PathBuf) -> Result<()> {
        println!("Downloading block {} to {:?}", block_number, output_path);
        
        // TODO: Replace with actual IPFS hash for the block
        // This is a placeholder - we need to find the correct IPFS hash for Solana block 2700000
        let ipfs_hash = "Qm..."; // We need to find the actual hash
        
        // Create the output directory if it doesn't exist
        if let Some(parent) = output_path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        
        // Create the output file
        let mut file = File::create(&output_path)?;
        
        // Get the block data from IPFS as a stream
        let mut stream = self.client.cat(&ipfs_hash);
        
        // Process the stream and write to file
        while let Some(chunk) = stream.next().await {
            let chunk = chunk?;
            file.write_all(&chunk)?;
        }
        
        println!("Successfully downloaded block {} to {:?}", block_number, output_path);
        Ok(())
    }
} 