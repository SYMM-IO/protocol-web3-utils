import json
import time
import pandas as pd
from web3 import Web3
from web3.middleware import geth_poa_middleware
import os

w3 = Web3(Web3.HTTPProvider("https://mantle.drpc.org"))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)

USDE_contract_address = "0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34"
with open("abi.json", "r") as f:
    USDE_abi = json.load(f)

USDE_contract = w3.eth.contract(address=USDE_contract_address, abi=USDE_abi)
address_to_check = "0x2Ecc7da3Cc98d341F987C85c3D9FC198570838B5"
cache_file = "block_cache.json"


# Function to load cache
def load_cache():
    if os.path.exists(cache_file):
        with open(cache_file, "r") as f:
            return json.load(f)
    return {}


# Function to save cache
def save_cache(cache):
    with open(cache_file, "w") as f:
        json.dump(cache, f)


# Function to get the nearest block to a specific timestamp
def get_nearest_block(timestamp, cache):
    if str(timestamp) in cache:
        return cache[str(timestamp)]

    latest_block = w3.eth.get_block("latest")
    start_block = 0
    end_block = latest_block["number"]

    while start_block <= end_block:
        mid_block = (start_block + end_block) // 2
        mid_block_timestamp = w3.eth.get_block(mid_block)["timestamp"]

        if mid_block_timestamp < timestamp:
            start_block = mid_block + 1
        elif mid_block_timestamp > timestamp:
            end_block = mid_block - 1
        else:
            cache[str(timestamp)] = mid_block
            save_cache(cache)
            return mid_block

    nearest_block = (
        start_block
        if abs(w3.eth.get_block(start_block)["timestamp"] - timestamp)
        < abs(w3.eth.get_block(end_block)["timestamp"] - timestamp)
        else end_block
    )
    cache[str(timestamp)] = nearest_block
    save_cache(cache)
    return nearest_block


# Function to get USDE balance at a specific block
def get_USDE_balance_at_block(address, block_number):
    return USDE_contract.functions.balanceOf(address).call(
        block_identifier=block_number
    )


# Generate timestamps for each day at 00:00 UTC for the past couple of months
end_date = pd.Timestamp.utcnow().normalize()
start_date = end_date - pd.DateOffset(months=4)
timestamps = pd.date_range(start=start_date, end=end_date, freq="D").normalize()

# Load cache
cache = load_cache()

# Dictionary to hold balances and block numbers
balances = []

for timestamp in timestamps:
    unix_timestamp = int(timestamp.timestamp())
    block_number = get_nearest_block(unix_timestamp, cache)
    print(f"Nearest block is: {block_number}")
    balance = get_USDE_balance_at_block(address_to_check, block_number)
    print(f"Balance: {balance}")
    balances.append((timestamp.strftime("%Y-%m-%d"), block_number, balance / 10**18))

# Convert balances to a DataFrame and display
df = pd.DataFrame(balances, columns=["Date", "Block Number", "USDE Balance"])
print(df)

# If you want to save the data to a CSV file
df.to_csv("USDE_balances.csv", index=False)
