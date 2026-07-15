import pandas as pd
from sqlalchemy import create_engine
 
# ---- update these ----
USER = "root"
PASSWORD = "ASD"
HOST = "localhost"
PORT = 3306
DB = "retail_star_schema"
# -----------------------
 
engine = create_engine(f"mysql+pymysql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DB}")
 
# Order matters: dimensions before the fact table
tables = [
    ("DimDate",     "DimDate.csv"),
    ("DimGeography","DimGeography.csv"),
    ("DimCustomer", "DimCustomer.csv"),
    ("DimEmployee", "DimEmployee.csv"),
    ("DimProduct",  "DimProduct.csv"),
    ("FactSales",   "FactSales.csv"),
]
 
for table_name, path in tables:
    df = pd.read_csv(path)
 
    # Booleans from CSV read as True/False strings - coerce explicitly for MySQL
    for col in df.columns:
        if df[col].dtype == bool:
            df[col] = df[col].astype(int)
 
    df.to_sql(table_name, engine, if_exists="append", index=False)
    print(f"Loaded {len(df):>7} rows into {table_name}")
 
print("Done.")