import requests
from datetime import datetime, timezone
from decimal import Decimal
import csv


def parse_date_to_timestamp(date_str):
    """Converts a date string to a Unix timestamp in UTC."""
    dt = datetime.strptime(date_str, "%Y-%m-%d")
    dt = dt.replace(tzinfo=timezone.utc)
    timestamp = int(dt.timestamp())
    print(f"Converted date '{date_str}' to UTC timestamp '{timestamp}'.")
    return timestamp


def fetch_accounts(subgraph_url, page_size=1000):
    """Fetches all accounts from the subgraph and builds an account-to-user mapping."""
    account_to_user = {}
    last_timestamp = 0
    total_accounts = 0
    batch_number = 1
    while True:
        print(
            f"Fetching accounts batch #{batch_number} from subgraph '{subgraph_url}'."
        )
        variables = {"last_timestamp": last_timestamp, "page_size": page_size}
        query = """
        query ($last_timestamp: BigInt!, $page_size: Int!) {
          accounts(
            first: $page_size,
            where: {timestamp_gt: $last_timestamp},
            orderBy: timestamp,
            orderDirection: asc
          ) {
            id
            account
            user
            timestamp
          }
        }
        """
        response = requests.post(
            subgraph_url, json={"query": query, "variables": variables}
        )
        if response.status_code != 200:
            print(f"Query failed with status code {response.status_code}.")
            print(response.text)
            break
        data = response.json()
        if "errors" in data:
            print("Errors in response:")
            print(data["errors"])
            break
        accounts = data["data"]["accounts"]
        if not accounts:
            print("No more accounts to fetch.")
            break
        print(f"Fetched {len(accounts)} accounts in batch #{batch_number}.")
        total_accounts += len(accounts)
        for account_entry in accounts:
            account = account_entry["account"]
            user = account_entry["user"]
            account_to_user[account] = user
            last_timestamp = account_entry["timestamp"]
        if len(accounts) < page_size:
            print("Reached the last batch of accounts.")
            break
        batch_number += 1
    print(f"Total accounts fetched: {total_accounts}")
    return account_to_user


def fetch_trade_volumes(
    subgraph_url,
    account_to_user,
    start_timestamp,
    end_timestamp,
    quote_statuses=None,
    page_size=1000,
):
    """Fetches trade histories and calculates total traded volume per user."""
    user_trade_volumes = {}
    last_timestamp = start_timestamp - 1
    processed_ids = set()
    total_trades = 0
    batch_number = 1
    while True:
        print(f"Fetching trades batch #{batch_number} from subgraph '{subgraph_url}'.")
        variables = {
            "last_timestamp": str(last_timestamp),
            "end_timestamp": str(end_timestamp),
            "page_size": page_size,
        }
        query = """
        query ($last_timestamp: BigInt!, $end_timestamp: BigInt!, $page_size: Int!) {
          tradeHistories(
            first: $page_size,
            where: {timestamp_gte: $last_timestamp, timestamp_lte: $end_timestamp},
            orderBy: timestamp,
            orderDirection: asc
          ) {
            id
            account
            quoteStatus
            volume
            timestamp
          }
        }
        """
        response = requests.post(
            subgraph_url, json={"query": query, "variables": variables}
        )
        if response.status_code != 200:
            print(f"Query failed with status code {response.status_code}.")
            print(response.text)
            break
        data = response.json()
        if "errors" in data:
            print("Errors in response:")
            print(data["errors"])
            break
        trade_histories = data["data"]["tradeHistories"]
        if not trade_histories:
            print("No more trades to fetch.")
            break
        print(f"Fetched {len(trade_histories)} trades in batch #{batch_number}.")
        total_trades += len(trade_histories)
        for trade in trade_histories:
            current_timestamp = int(trade["timestamp"])
            # If same timestamp, check if id is already processed
            if current_timestamp == last_timestamp:
                if trade["id"] in processed_ids:
                    continue  # Skip duplicate
                else:
                    processed_ids.add(trade["id"])
            else:
                # New timestamp encountered
                last_timestamp = current_timestamp
                processed_ids = set()
                processed_ids.add(trade["id"])
            # Filter by quoteStatus if provided
            if quote_statuses and trade["quoteStatus"] not in quote_statuses:
                continue
            account = trade["account"]
            volume = Decimal(trade["volume"])
            user = account_to_user.get(account, "Unknown")
            user_trade_volumes[user] = user_trade_volumes.get(user, Decimal(0)) + volume
        if len(trade_histories) < page_size:
            print("Reached the last batch of trades.")
            break
        batch_number += 1
    print(f"Total trades fetched: {total_trades}")
    return user_trade_volumes


def main(subgraph_urls, start_date, end_date):
    """Main function to process each subgraph and output the total traded volume per user."""
    print(f"Starting processing from {start_date} to {end_date}.")
    start_timestamp = parse_date_to_timestamp(start_date)
    end_timestamp = parse_date_to_timestamp(end_date)
    total_user_volumes = {}
    for idx, subgraph_url in enumerate(subgraph_urls, 1):
        print(f"\nProcessing subgraph #{idx}/{len(subgraph_urls)}: {subgraph_url}")
        account_to_user = fetch_accounts(subgraph_url)
        print(f"Total accounts fetched from subgraph #{idx}: {len(account_to_user)}")
        quote_statuses = None
        user_trade_volumes = fetch_trade_volumes(
            subgraph_url,
            account_to_user,
            start_timestamp,
            end_timestamp,
            quote_statuses,
        )
        print(
            f"Total users with trade volumes in subgraph #{idx}: {len(user_trade_volumes)}"
        )
        # Aggregate volumes per user across subgraphs
        for user, volume in user_trade_volumes.items():
            total_user_volumes[user] = total_user_volumes.get(user, Decimal(0)) + volume

    print("\nAggregating and writing total volumes per user to 'user_volumes.csv'.")
    with open("user_volumes.csv", "w", newline="") as csv_file:
        fieldnames = ["user", "total_volume"]
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)

        writer.writeheader()
        for user, total_volume in total_user_volumes.items():
            writer.writerow(
                {"user": user, "total_volume": str(total_volume / Decimal(1e18))}
            )
    print("Finished writing to 'user_volumes.csv'.")
    print("Processing completed successfully.")


if __name__ == "__main__":
    # Replace with your actual subgraph URLs
    subgraph_urls = [
        "https://api.goldsky.com/api/public/project_cm1hfr4527p0f01u85mz499u8/subgraphs/arbitrum_analytics/latest/gn",
        "https://api.goldsky.com/api/public/project_cm1hfr4527p0f01u85mz499u8/subgraphs/mantle_analytics/latest/gn",
        "https://api.goldsky.com/api/public/project_cm1hfr4527p0f01u85mz499u8/subgraphs/bnb_analytics/latest/gn",
        "https://api.goldsky.com/api/public/project_cm1hfr4527p0f01u85mz499u8/subgraphs/base_analytics/latest/gn",
        "https://api.goldsky.com/api/public/project_cm1hfr4527p0f01u85mz499u8/subgraphs/blast_analytics/latest/gn",
        "https://api.goldsky.com/api/public/project_cm1hfr4527p0f01u85mz499u8/subgraphs/mode_analytics/latest/gn",
        "https://api.goldsky.com/api/public/project_cm1hfr4527p0f01u85mz499u8/subgraphs/iota_analytics/latest/gn",
    ]
    # Define your start and end dates
    start_date = "2024-06-03"
    end_date = "2024-11-04"
    main(subgraph_urls, start_date, end_date)
