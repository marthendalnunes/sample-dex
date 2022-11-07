import { ethers, run } from 'hardhat'
require('dotenv').config({ path: '.env' })
import { CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS } from '../constants'
const BLOCk_CONFIRMATIONS_WAIT = 4

async function main() {
  const cryptoDevTokenAddress = CRYPTO_DEV_TOKEN_CONTRACT_ADDRESS
  const exchangeContract = await ethers.getContractFactory('Exchange')
  const deployedExchangeContract = await exchangeContract.deploy(
    cryptoDevTokenAddress
  )
  await deployedExchangeContract.deployTransaction.wait(
    BLOCk_CONFIRMATIONS_WAIT
  )
  console.log('Exchange Contract Address:', deployedExchangeContract.address)

  await run(`verify:verify`, {
    address: deployedExchangeContract.address
  })
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
