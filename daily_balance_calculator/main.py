import json
import os
from datetime import datetime, timezone
from decimal import Decimal

import pandas as pd
import requests
from multicallable import Multicallable
from web3 import Web3
from web3.middleware import geth_poa_middleware

from local_settings import RPC, COLLATERAL_ADDRESS, SYMMIO_ADDRESS, HEDGER_ADDR, LIQUIDATORS, SUBGRAPH, ADDRESS_TO_CHECK

# Constants
CACHE_FILE = "block_cache.json"
BALANCE_CACHE_FILE = "balance_cache.json"

# Web3 setup
w3 = Web3(Web3.HTTPProvider(RPC))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)


# Contract setup
def load_abi(filename):
    with open(filename, "r") as f:
        return json.load(f)


USDE_ABI = load_abi("abi.json")
SYMMIO_ABI = load_abi("symmio_abi.json")

USDE_contract = w3.eth.contract(address=COLLATERAL_ADDRESS, abi=USDE_ABI)
symmio_multicallable = Multicallable(w3.to_checksum_address(SYMMIO_ADDRESS), SYMMIO_ABI, w3)


# Caching functions
def load_cache(filename):
    if os.path.exists(filename):
        with open(filename, "r") as f:
            return json.load(f)
    return {}


def save_cache(cache, filename):
    with open(filename, "w") as f:
        json.dump(cache, f)


block_cache = load_cache(CACHE_FILE)
balance_cache = load_cache(BALANCE_CACHE_FILE)


def get_nearest_block(timestamp):
    if str(timestamp) in block_cache:
        return block_cache[str(timestamp)]

    latest_block = w3.eth.get_block("latest")
    start_block, end_block = 0, latest_block["number"]

    while start_block <= end_block:
        mid_block = (start_block + end_block) // 2
        mid_block_timestamp = w3.eth.get_block(mid_block)["timestamp"]

        if mid_block_timestamp < timestamp:
            start_block = mid_block + 1
        elif mid_block_timestamp > timestamp:
            end_block = mid_block - 1
        else:
            block_cache[str(timestamp)] = mid_block
            save_cache(block_cache, CACHE_FILE)
            return mid_block

    nearest_block = (
        start_block
        if abs(w3.eth.get_block(start_block)["timestamp"] - timestamp) < abs(
            w3.eth.get_block(end_block)["timestamp"] - timestamp)
        else end_block
    )
    block_cache[str(timestamp)] = nearest_block
    save_cache(block_cache, CACHE_FILE)
    return nearest_block


def get_USDE_balance_at_block(address, block_number):
    cache_key = f"USDE_{address}_{block_number}"
    if cache_key in balance_cache:
        return int(balance_cache[cache_key])

    balance = USDE_contract.functions.balanceOf(address).call(block_identifier=block_number)
    balance_cache[cache_key] = balance
    save_cache(balance_cache, BALANCE_CACHE_FILE)
    return balance


def get_hedger_allocated_balance(accounts, block_number):
    cache_key = f"hedger_allocated_{block_number}"
    if cache_key in balance_cache:
        return int(balance_cache[cache_key])

    chunk_size = 150
    total_allocated_balance = Decimal(0)
    pages_count = len(accounts) // chunk_size if len(accounts) > chunk_size else 1
    allocated_balances = symmio_multicallable.allocatedBalanceOfPartyB(
        [(HEDGER_ADDR, w3.to_checksum_address(a["id"])) for a in accounts]).call(
        block_identifier=block_number, n=pages_count, progress_bar=True
    )
    total_allocated_balance += Decimal(sum(allocated_balances))

    balance_cache[cache_key] = str(total_allocated_balance)
    save_cache(balance_cache, BALANCE_CACHE_FILE)
    return total_allocated_balance


def get_hedger_balance(block_number):
    cache_key = f"hedger_{block_number}"
    if cache_key in balance_cache:
        return int(balance_cache[cache_key])

    balance = symmio_multicallable.balanceOf([HEDGER_ADDR]).call(block_identifier=block_number)[0]
    balance_cache[cache_key] = str(balance)
    save_cache(balance_cache, BALANCE_CACHE_FILE)
    return balance


def get_liquidators_balance(block_number):
    cache_key = f"liquidators_{block_number}"
    if cache_key in balance_cache:
        return int(balance_cache[cache_key])

    balance = sum(symmio_multicallable.allocatedBalanceOfPartyA(LIQUIDATORS).call(block_identifier=block_number))
    balance_cache[cache_key] = str(balance)
    save_cache(balance_cache, BALANCE_CACHE_FILE)
    return balance


def fetch_accounts_from_subgraph(last_timestamp=0, page_size=1000):
    query = """
    query MyQuery($lastTimestamp: BigInt!, $pageSize: Int!) {
      accounts(
        first: $pageSize, 
        where: {timestamp_gt: $lastTimestamp}, 
        orderBy: timestamp, 
        orderDirection: asc
      ) {
        id
        timestamp
      }
    }
    """
    variables = {"lastTimestamp": str(last_timestamp), "pageSize": page_size}

    all_accounts = []
    while True:
        response = requests.post(SUBGRAPH, json={"query": query, "variables": variables})
        data = response.json()
        accounts = data["data"]["accounts"]
        all_accounts.extend(accounts)

        if len(accounts) < page_size:
            break

        variables["lastTimestamp"] = accounts[-1]["timestamp"]

    return all_accounts


def main():
    start_date = datetime(2024, 4, 2, 16, 17, 2, tzinfo=timezone.utc)
    end_date = pd.Timestamp.now(tz=timezone.utc).normalize()
    timestamps = pd.date_range(start=start_date, end=end_date, freq="D").normalize()

    balances = []

    print("Fetching accounts...")
    accounts = fetch_accounts_from_subgraph()
    print(f"Total accounts fetched: {len(accounts)}")

    for timestamp in timestamps:
        print("--------------------------------------------------------------------")
        unix_timestamp = int(timestamp.timestamp())
        block_number = get_nearest_block(unix_timestamp)
        print(f"Nearest block is: {block_number}")

        balance = get_USDE_balance_at_block(ADDRESS_TO_CHECK, block_number)
        print(f"Balance: {balance}")

        hedger_balance = hedger_allocated_balance = liquidators_balance = 0
        if balance > 0:
            hedger_allocated_balance = get_hedger_allocated_balance(accounts, block_number)
            print(f"Hedger Allocated Balance: {hedger_allocated_balance}")

            hedger_balance = get_hedger_balance(block_number)
            print(f"Hedger Balance: {hedger_balance}")

            liquidators_balance = get_liquidators_balance(block_number)
            print(f"Liquidators balance: {liquidators_balance}")

        our_balance = hedger_balance + hedger_allocated_balance + liquidators_balance
        users_balance = balance - our_balance
        balances.append(
            (
                timestamp.strftime("%Y-%m-%d"),
                block_number,
                hedger_balance / 10 ** 18,
                hedger_allocated_balance / 10 ** 18,
                liquidators_balance / 10 ** 18,
                users_balance / 10 ** 18,
                our_balance / 10 ** 18,
                balance / 10 ** 18,
            )
        )

    df = pd.DataFrame(
        balances,
        columns=[
            "Date",
            "Block Number",
            "Hedger Balance",
            "Hedger Allocated Balance",
            "Liquidators Balance",
            "Users Balance",
            "Our Balance",
            "Total Balance",
        ],
    )
    print(df)

    df.to_csv("Balances.csv", index=False)


if __name__ == "__main__":
    main()
