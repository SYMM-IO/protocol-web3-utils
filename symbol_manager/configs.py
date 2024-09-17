from dataclasses import dataclass
from decimal import Decimal
import json
from typing import List


@dataclass
class ChainConfig:
    name: str
    hedger_url: str
    rpc_urls: List[str]
    symmio_address: str
    symmio_abi: List[dict]
    limited_symbol_adder_address: str
    limited_symbol_adder_abi: List[dict]
    default_fee: Decimal = Decimal("0.001000")


with open("abis/symmio.json") as f:
    symmio_abi = json.load(f)

with open("abis/limited_symbol_adder.json") as f:
    limited_symbol_adder_abi = json.load(f)

blast_config = ChainConfig(
    name="BLAST",
    hedger_url="https://blast-hedger.rasa.capital/contract-symbols",
    symmio_address="0x3d17f073cCb9c3764F105550B0BCF9550477D266",
    limited_symbol_adder_address="",
    rpc_urls=["https://rpc.blast.io"],
    symmio_abi=symmio_abi,
    limited_symbol_adder_abi=limited_symbol_adder_abi,
)

bnb_config = ChainConfig(
    name="BNB",
    hedger_url="https://alpha-hedger.rasa.capital/contract-symbols",
    symmio_address="0x9A9F48888600FC9c05f11E03Eab575EBB2Fc2c8f",
    limited_symbol_adder_address="",
    rpc_urls=[
        "https://binance.llamarpc.com",
        "https://rpc.ankr.com/bsc",
        "https://1rpc.io/bnb",
        "https://bsc.drpc.org",
    ],
    symmio_abi=symmio_abi,
    limited_symbol_adder_abi=limited_symbol_adder_abi,
)

arbitrum_config = ChainConfig(
    name="ARBITRUM",
    hedger_url="https://mantle-hedger.rasa.capital/contract-symbols",
    symmio_address="0x8F06459f184553e5d04F07F868720BDaCAB39395",
    limited_symbol_adder_address="",
    rpc_urls=[
        "https://arbitrum.llamarpc.com",
        "https://arb1.arbitrum.io/rpc",
        "https://rpc.ankr.com/arbitrum",
        "https://1rpc.io/arb",
    ],
    symmio_abi=symmio_abi,
    limited_symbol_adder_abi=limited_symbol_adder_abi,
)

base_config = ChainConfig(
    name="BASE",
    hedger_url="https://base-hedger82.rasa.capital/contract-symbols",
    symmio_address="0x91Cf2D8Ed503EC52768999aA6D8DBeA6e52dbe43",
    limited_symbol_adder_address="",
    rpc_urls=[
        "https://base.llamarpc.com",
        "https://mainnet.base.org",
        "https://1rpc.io/base",
        "https://base.drpc.org",
    ],
    symmio_abi=symmio_abi,
    limited_symbol_adder_abi=limited_symbol_adder_abi,
)

mantle_config = ChainConfig(
    name="MANTLE",
    hedger_url="https://mantle-hedger.rasa.capital/contract-symbols",
    symmio_address="0x2Ecc7da3Cc98d341F987C85c3D9FC198570838B5",
    limited_symbol_adder_address="",
    rpc_urls=[
        "https://rpc.mantle.xyz",
        "https://mantle.drpc.org",
        "https://rpc.ankr.com/mantle",
        "https://1rpc.io/mantle",
    ],
    symmio_abi=symmio_abi,
    limited_symbol_adder_abi=limited_symbol_adder_abi,
)

chain_configs = [mantle_config, base_config, bnb_config, arbitrum_config, blast_config]
