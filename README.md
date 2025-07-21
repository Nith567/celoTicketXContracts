# CeloTicketX


## Setup

1. Clone the repository:

```bash
git clone https://github.com/mento-protocol/hackathon-demo.git
cd hackathon-demo
```

2. Install dependencies:

```bash
forge install
```

3. Set up environment variables:

```bash
cp .env.example .env
```

4. Add your private key to the .env file:

```bash
# For Celo mainnet RPC URL
CELO_MAINNET_RPC_URL="https://forno.celo.org"



# Your private key
PRIVATE_KEY=

# Celoscan API Key for verifying contracts
CELOSCAN_API_KEY=
```

## Running Tests

The repository includes fork tests that interact with the actual Celo mainnet contracts.

1. Run all tests:

```bash
forge test
```

## Deploying the Contract

To deploy the BrokerDemo contract to Celo mainnet:

1. Set your private key in the .env file:
j
```bash
PRIVATE_KEY=your_private_key_here
```

2. Deploy the contract:

```bash
forge script deploy/DeployCeloTicketX.s.sol --rpc-url https://forno.celo.org --broadcast
```

3. Verify the contract:

```bash
forge verify-contract $CONTRACT_ADDRESS  --chain celo --rpc-url https://forno.celo.org
```

## Running the Demo Script

The repository includes a script that demonstrates the swap functionality by interacting with a deployed BrokerDemo contract.

1. Update the script with your deployed contract address:

   - Open `script/BrokerDemo.s.sol`
   - Replace `BROKER_DEMO` constant with your deployed contract address
  
2. Run the script:

```bash
forge script script/CeloTicketX.s.sol --rpc-url https://forno.celo.org --broadcast
```


