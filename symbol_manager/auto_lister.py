import requests
import time
import os
import web3

from configs import ChainConfig, chain_configs
from local_config import PRIVATE_KEY


def on_new_symbols(config: ChainConfig, symbols):
    print(f"New symbols detected: {symbols}")

    # Create the contract instance
    contract_address = config.symmio_address
    contract = web3.eth.contract(
        address=contract_address, abi=config.limited_symbol_adder_abi
    )

    # Set up the account
    account = web3.eth.account.from_key(PRIVATE_KEY)

    # Call the `addSymbols` Function on the Contract
    nonce = web3.eth.get_transaction_count(account.address)
    gas_price = web3.eth.gas_price

    # Build the transaction
    tx = contract.functions.addSymbols(symbols).build_transaction(
        {
            "from": account.address,
            "nonce": nonce,
            "gas": 2000000,  # Adjust the gas limit as needed
            "gasPrice": gas_price,
        }
    )

    # Sign the transaction
    signed_tx = web3.eth.account.sign_transaction(tx, PRIVATE_KEY)

    # Send the transaction
    tx_hash = web3.eth.send_raw_transaction(signed_tx.rawTransaction)
    print(f"Transaction sent: {tx_hash.hex()}")

    # Wait for the transaction receipt (optional)
    receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    print(f"Transaction receipt: {receipt}")


def fetch_active_binance_symbols():
    url = "https://fapi.binance.com/fapi/v1/exchangeInfo"
    response = requests.get(url)
    response.raise_for_status()
    data = response.json()
    return {
        symbol_info["symbol"]
        for symbol_info in data["symbols"]
        if symbol_info["status"] == "TRADING"
    }


def monitor_new_symbols(config: ChainConfig, poll_interval=60):
    known_symbols = fetch_active_binance_symbols()
    print(f"Monitoring started. Found {len(known_symbols)} symbols initially.")

    while True:
        time.sleep(poll_interval)
        try:
            current_symbols = fetch_active_binance_symbols()
            new_symbols = current_symbols - known_symbols

            if new_symbols:
                on_new_symbols(config, new_symbols)
                known_symbols = current_symbols
        except requests.exceptions.RequestException as e:
            print(f"Error fetching symbols: {e}")
        except Exception as e:
            print(f"An unexpected error occurred: {e}")


if __name__ == "__main__":
    CONFIG_NAME = os.environ.get("CONFIG_NAME")
    if len(PRIVATE_KEY) == 0:
        raise ValueError("PRIVATE_KEY environment variable not set")
    config = None
    for c in chain_configs:
        if c.name == CONFIG_NAME:
            config = c
            break
    monitor_new_symbols(config, poll_interval=60)  # Check every 60 seconds
