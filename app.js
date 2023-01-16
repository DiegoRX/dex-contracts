const SUSHI_ABI = require('./build/contracts/SushiToken.json')
const { ethers } = require('ethers')
require("dotenv").config()

const ROUTER_ADDRESS = '0xE592427A0AEce92De3Edee1F18E0157C05861564'
const WETH_ADDRESS = '0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6'
const UNI_ADDRESS = '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984'
const MATIC_ADDRESS_MUMBAI = '0x0000000000000000000000000000000000001010'
const WMATIC_ADDRESS_MUMBAI = '0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889'
const USDC_ADDRESS_MUMBAI = '0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e'
const WALLET_ADDRESS = process.env.WALLET_ADDRESS
const WALLET_SECRET = process.env.WALLET_SECRET
const INFURA_TEST_URL = process.env.INFURA_TEST_URL
const SUSHI_ADDRESS = '0xCE0eA7b7bD93B54826009753A4EdeA20f5E5480a'

const provider = new ethers.providers.JsonRpcProvider(INFURA_TEST_URL)

const signer = new ethers.Wallet(WALLET_SECRET, provider)

const sushi = new ethers.Contract(
    SUSHI_ADDRESS,
    SUSHI_ABI.abi
)

const inputAmount = ethers.utils.parseEther('0.01')

async function main() {  
           const balanceOf = await sushi.functions.name()
            console.log(balanceOf)

}

main()