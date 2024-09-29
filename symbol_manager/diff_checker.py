from decimal import Decimal
from typing import List, Dict, Set
import requests
from web3 import Web3
from configs import ChainConfig, arbitrum_config
from tqdm import tqdm
from web3_collections import MultiEndpointHTTPProvider


def fetch_hedger_symbols(url: str) -> List[dict]:
    response = requests.get(url)
    response.raise_for_status()
    return response.json()["symbols"]


def fetch_symbols_from_contract(contract) -> List[dict]:
    symbols = contract.functions.getSymbols(0, 400).call()
    return [
        {
            "symbol_id": int(symbol[0]),
            "name": symbol[1],
            "isValid": symbol[2],
            "minAcceptableQuoteValue": str(symbol[3]),
            "minAcceptablePortionLF": str(symbol[4]),
            "tradingFee": str(symbol[5]),
            "maxLeverage": str(symbol[6]),
            "fundingRateEpochDuration": str(symbol[7]),
            "fundingRateWindowTime": str(symbol[8]),
        }
        for symbol in symbols
    ]


def fetch_force_close_gap_ratio(contract, symbol_id: int):
    return contract.functions.forceCloseGapRatio(symbol_id).call()


def fetch_active_binance_futures_symbols() -> Set[str]:
    url = "https://fapi.binance.com/fapi/v1/exchangeInfo"
    response = requests.get(url)
    response.raise_for_status()
    data = response.json()
    return {
        symbol["symbol"] for symbol in data["symbols"] if symbol["status"] == "TRADING"
    }


def process_chain_data(config: ChainConfig):
    # Create Web3 instance and contract once
    w3 = Web3(MultiEndpointHTTPProvider(config.rpc_urls))
    contract = w3.eth.contract(address=config.symmio_address, abi=config.symmio_abi)

    # Fetch data from URL
    hedger_symbols = fetch_hedger_symbols(config.hedger_url)

    # Fetch data from smart contract
    contract_symbols = fetch_symbols_from_contract(contract)

    # Fetch active Binance futures symbols
    active_binance_symbols = fetch_active_binance_futures_symbols()

    # Create dictionaries for both datasets
    hedger_id_to_fee: Dict[int, str] = {
        item["symbol_id"]: item["hedger_fee_open"] for item in hedger_symbols
    }
    hedger_id_to_name: Dict[int, str] = {
        item["symbol_id"]: item["name"] for item in hedger_symbols
    }
    hedger_fee_to_name: Dict[str, str] = {
        item["name"]: item["hedger_fee_open"] for item in hedger_symbols
    }
    contract_id_to_name: Dict[int, str] = {
        item["symbol_id"]: item["name"] for item in contract_symbols
    }
    contract_name_to_id: Dict[int, str] = {
        item["name"]: item["symbol_id"] for item in contract_symbols
    }

    print(f"Chain: {config.name}")
    print(f"Hedger symbols: {len(hedger_id_to_fee)}, Contract symbols: {len(contract_id_to_name)}")

    # Symbols in hedger but not in contract
    hedger_only = set(hedger_id_to_fee.keys()) - set(contract_id_to_name.keys())
    print("\nSymbols in hedger but not in contract:")
    for symbol_id in hedger_only:
        print(f"Symbol ID: {symbol_id}")

    # Symbols in contract but not in hedger
    contract_only = set(contract_id_to_name.keys()) - set(hedger_id_to_fee.keys())
    print("\nSymbols in contract but not in hedger:")
    for symbol_id in contract_only:
        print(f"Symbol ID: {symbol_id}, Name: {contract_id_to_name[symbol_id]}")

    # Check for delisted Binance futures symbols that are still valid in the contract
    print("\nDelisted Binance futures symbols that are still valid in the contract:")
    delisted_but_valid = [
        symbol
        for symbol in contract_symbols
        if symbol["isValid"] and symbol["name"] not in active_binance_symbols
    ]
    if delisted_but_valid:
        for symbol in delisted_but_valid:
            print(f"Symbol ID: {symbol['symbol_id']}, Name: {symbol['name']}")
    else:
        print("No delisted symbols found that are still valid in the contract.")

    print("\nChecking differences between forceCloseGapRatios of contract and hedger")
    diff = [[], []]
    not_set = [[], []]
    with tqdm(total=len(hedger_id_to_fee)) as bar:
        for symbol_id, ratio in hedger_id_to_fee.items():
            scaled_ratio = int(Decimal(ratio) * 10**18)
            symbol_name = hedger_id_to_name[symbol_id]
            if symbol_name not in contract_name_to_id:
                continue
            contract_gap_ratio = fetch_force_close_gap_ratio(
                contract, contract_name_to_id[symbol_name]
            )
            if contract_gap_ratio == 0:
                not_set[0].append(contract_name_to_id[symbol_name])
                not_set[1].append(scaled_ratio)
            elif contract_gap_ratio != scaled_ratio:
                diff[0].append(contract_name_to_id[symbol_name])
                diff[1].append(scaled_ratio)
            bar.update(1)

    print("\nDifferences found:")
    print(diff)
    print("\nSymbols not set:")
    print(not_set)

    # Calculate fees for contract symbols
    ids = []
    fees = []
    for item in contract_symbols:
        name = item["name"]
        fee = Decimal(hedger_fee_to_name.get(name, config.default_fee))
        ids.append(int(item["symbol_id"]))
        fees.append(int(fee * 10**18))

    # print("\nFees for contract symbols:")
    # for symbol_id, fee in zip(ids, fees):
    #     print(f"Symbol ID: {symbol_id}, Fee: {fee}")


if __name__ == "__main__":
    process_chain_data(arbitrum_config)
