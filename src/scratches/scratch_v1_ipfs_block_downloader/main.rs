use anyhow::Result;
use structopt::StructOpt;
use std::path::PathBuf;
use solshitector::scratches::scratch_v1_ipfs_block_downloader::IpfsBlockDownloader;

#[derive(StructOpt)]
#[structopt(name = "ipfs_block_downloader", about = "Download Solana blocks from IPFS")]
struct Opt {
    /// Block number to download
    #[structopt(short, long)]
    block_number: u64,
    
    /// Output path for the downloaded block
    #[structopt(short, long, parse(from_os_str))]
    output: PathBuf,
}

#[tokio::main]
async fn main() -> Result<()> {
    let opt = Opt::from_args();
    let downloader = IpfsBlockDownloader::new();
    downloader.download_block(opt.block_number, opt.output).await?;
    Ok(())
} 