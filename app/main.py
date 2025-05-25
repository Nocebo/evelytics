import pandas as pd
from sqlalchemy import create_engine
import requests
import io
from dotenv import load_dotenv
import os

# Load configuration from .env file
load_dotenv()
DB_USER = os.getenv("POSTGRES_USER")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD")
DB_HOST = os.getenv("POSTGRES_HOST")
DB_PORT = os.getenv("POSTGRES_PORT")
DB_NAME = os.getenv("POSTGRES_DB")


def fetch_csv_sources():
    """Fetch CSV URL and table name pairs from the civisar.tables column in the database."""
    engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    query = "SELECT url, tablename FROM civisar.tables;"
    df = pd.read_sql(query, engine)
    return list(df.itertuples(index=False, name=None))


def import_csv_to_postgresql(csv_url, table_name):
    # Step 1: Fetch CSV from URL
    response = requests.get(csv_url)
    response.raise_for_status()  # Raises an error for bad responses

    # Step 2: Load CSV into a DataFrame
    csv_data = io.StringIO(response.text)
    df = pd.read_csv(csv_data)

    # Step 3: Connect to PostgreSQL
    engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

    # Step 4: Import DataFrame into PostgreSQL
    df.to_sql(table_name, engine, if_exists='replace', index=False)

    print(f"Data imported successfully into table '{table_name}'.")

def simplie_insert():
    """A simple function to insert data into a table."""
    response = requests.get("https://www.fuzzwork.co.uk/dump/latest/chrFactions.csv")
    response.raise_for_status()  # Raises an error for bad responses

    # Step 2: Load CSV into a DataFrame
    csv_data = io.StringIO(response.text)
    df = pd.read_csv(csv_data)
    # Step 3: Connect to PostgreSQL
    engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
    # Step 4: Import DataFrame into PostgreSQL
    df.to_sql("chrFactions", engine, if_exists='replace', index=False)
    print("Data imported successfully into table 'chrFactions'.")

if __name__ == "__main__":
    
    #call simplie_insert()
    # Uncomment the following line to run the simple insert function
    simplie_insert()
    
    # # Get CSV sources from the database
    # csv_sources = fetch_csv_sources()

    # for url, table in csv_sources:
    #     print(f"Processing {url} into {table}...")
    #     import_csv_to_postgresql(url, table)
