import os
import pandas as pd

from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine

DATA_DIR = Path("data/raw")

load_dotenv()

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

tables = {
    "stg_customers": "olist_customers_dataset.csv",
    "stg_orders": "olist_orders_dataset.csv",
    "stg_order_items": "olist_order_items_dataset.csv",
    "stg_products": "olist_products_dataset.csv",
    "stg_payments": "olist_order_payments_dataset.csv",
    "stg_reviews": "olist_order_reviews_dataset.csv",
    "stg_sellers": "olist_sellers_dataset.csv",
    "stg_category_translation": "product_category_name_translation.csv",
}

for table_name, file_name in tables.items():
    df = pd.read_csv(DATA_DIR / file_name)

    df.to_sql(
        table_name,
        engine,
        if_exists="replace",
        index=False
    )

    print(f"Loaded {table_name}: {len(df):,} rows")