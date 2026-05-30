# 📦 Panduan Lengkap: Cloud Data Warehouse AZKO
### Untuk AI IDE (GitHub Copilot / Antigravity)

> **Stack:** MySQL (PlanetScale) → Python ETL → PostgreSQL DWH (Neon.tech) → Metabase Cloud  
> **Otomasi:** GitHub Actions (scheduled ETL harian, gratis)  
> **Biaya:** Rp 0 — semua menggunakan free tier

---

## 🗺️ Arsitektur Keseluruhan

```
┌─────────────────────────────────────────────────────────────────────┐
│                      GITHUB ACTIONS (Free)                          │
│   Cron: tiap hari jam 01.00 UTC                                     │
│   ┌──────────────────┐        ┌──────────────────────────────────┐  │
│   │ generate_data.py │──────► │        etl_pipeline.py           │  │
│   │ (dummy data baru)│        │ Extract → Transform → Load       │  │
│   └──────────────────┘        └──────────────┬───────────────────┘  │
└──────────────────────────────────────────────┼──────────────────────┘
                                               │
          ┌────────────────────────────────────┼──────────────────┐
          ▼                                    ▼                  │
┌──────────────────────┐           ┌───────────────────────────┐  │
│  PLANETSCALE (Free)  │           │     NEON.TECH (Free)      │  │
│  MySQL — OLTP source │           │  PostgreSQL — Data         │  │
│  3 database:         │           │  Warehouse (Star Schema)   │  │
│  • azko_sales_db     │           │  Schema: dw                │  │
│  • azko_warehouse_db │           │  Fact + 7 Dimensi          │  │
│  • azko_marketing_db │           └───────────────┬───────────┘  │
└──────────────────────┘                           │              │
                                                   ▼              │
                                    ┌──────────────────────────┐  │
                                    │  METABASE CLOUD (Free)   │  │
                                    │  Dashboard & Visualisasi │  │
                                    └──────────────────────────┘  │
```

---

## 📁 Struktur Folder Project

```
azko-dwh/
├── .github/
│   └── workflows/
│       └── etl.yml                  # Jadwal otomatis GitHub Actions
├── src/
│   ├── oltp/
│   │   ├── schema_sales.sql         # DDL azko_sales_db (sudah ada)
│   │   ├── schema_warehouse.sql     # DDL azko_warehouse_db (sudah ada)
│   │   └── schema_marketing.sql     # DDL azko_marketing_db (sudah ada)
│   ├── dwh/
│   │   └── schema_dw.sql            # DDL Star Schema di Neon
│   ├── generate_data.py             # Script dummy data (sudah ada)
│   └── etl_pipeline.py              # ETL OLTP → DWH
├── requirements.txt
├── .env.example                     # Template environment variables
└── README.md
```

---

## ✅ FASE 0 — Persiapan Akun & Repository

### Langkah 0.1 — Buat Akun (semua gratis)

| Platform | Link | Kegunaan |
|---|---|---|
| **GitHub** | https://github.com | Repo + CI/CD otomatis |
| **PlanetScale** | https://planetscale.com | MySQL cloud (OLTP) |
| **Neon.tech** | https://neon.tech | PostgreSQL cloud (DWH) |
| **Metabase Cloud** | https://www.metabase.com/start/oss/ | Dashboard BI |

## ✅ FASE 1 — Setup Database OLTP di PlanetScale (MySQL)

> **Catatan:** PlanetScale mengganti model free tier-nya. Alternatif MySQL gratis yang stabil:
> - **Railway.app** (MySQL, $5 kredit/bulan gratis) — **Direkomendasikan**
> - **Aiven.io** (MySQL, 1 bulan trial gratis)
> - **Clever Cloud** (MySQL, free tier permanen)
>
> Jika menggunakan Railway: buat 3 service MySQL terpisah untuk tiap database.

### Langkah 1.1 — Buat 3 Database MySQL

Di platform pilihan, buat 3 database:
- `azko_sales_db`
- `azko_warehouse_db`  
- `azko_marketing_db`

### Langkah 1.2 — Jalankan DDL SQL

Jalankan SQL DDL yang sudah kalian buat (schema_sales.sql, schema_warehouse.sql, schema_marketing.sql) di masing-masing database.

### Langkah 1.3 — Catat Credentials

Simpan credentials berikut (akan dipakai di GitHub Secrets):

```
SALES_DB_HOST=<host dari platform>
SALES_DB_PORT=3306
SALES_DB_USER=<username>
SALES_DB_PASS=<password>
SALES_DB_NAME=azko_sales_db

WAREHOUSE_DB_HOST=<host>
WAREHOUSE_DB_PORT=3306
WAREHOUSE_DB_USER=<username>
WAREHOUSE_DB_PASS=<password>
WAREHOUSE_DB_NAME=azko_warehouse_db

MARKETING_DB_HOST=<host>
MARKETING_DB_PORT=3306
MARKETING_DB_USER=<username>
MARKETING_DB_PASS=<password>
MARKETING_DB_NAME=azko_marketing_db
```

---

## ✅ FASE 2 — Setup Data Warehouse di Neon.tech (PostgreSQL)

### Langkah 2.1 — Buat Project di Neon

1. Daftar di https://neon.tech
2. Klik **"New Project"** → nama: `azko-dwh`
3. Region: pilih **Singapore** (terdekat dari Indonesia)
4. Salin **Connection String** format:
   ```
   postgresql://username:password@ep-xxx.ap-southeast-1.aws.neon.tech/neondb
   ```

### Langkah 2.2 — Buat Schema Data Warehouse

Jalankan SQL berikut di Neon SQL Editor (atau via psql):

```sql
-- File: src/dwh/schema_dw.sql

-- ═══════════════════════════════════════════════════════
-- DIMENSI
-- ═══════════════════════════════════════════════════════

CREATE TABLE dim_time (
    time_key        SERIAL PRIMARY KEY,
    full_date       DATE NOT NULL,
    day             INT,
    month           INT,
    month_name      VARCHAR(20),
    quarter         INT,
    year            INT,
    week_of_year    INT,
    day_of_week     INT,
    day_name        VARCHAR(15),
    is_weekend      BOOLEAN
);

CREATE TABLE dim_product (
    product_key     SERIAL PRIMARY KEY,
    product_id      VARCHAR(10),        -- Natural Key dari OLTP
    product_name    VARCHAR(150),
    category        VARCHAR(100),
    brand           VARCHAR(100),
    unit_price      DECIMAL(15,2),
    cost_price      DECIMAL(15,2),
    product_status  VARCHAR(20)
);

CREATE TABLE dim_customer (
    customer_key    SERIAL PRIMARY KEY,
    customer_id     VARCHAR(10),
    customer_name   VARCHAR(100),
    gender          VARCHAR(10),
    age             INT,
    age_group       VARCHAR(25),        -- Derived: Youth / Adult / Middle / Senior
    city            VARCHAR(100),
    membership_level VARCHAR(20),
    registration_date DATE
);

CREATE TABLE dim_store (
    store_key       SERIAL PRIMARY KEY,
    store_id        VARCHAR(10),
    store_name      VARCHAR(100),
    store_type      VARCHAR(30),
    city            VARCHAR(100),
    province        VARCHAR(100),
    region          VARCHAR(50)
);

CREATE TABLE dim_supplier (
    supplier_key    SERIAL PRIMARY KEY,
    supplier_id     VARCHAR(10),
    supplier_name   VARCHAR(100),
    supplier_city   VARCHAR(100),
    supplier_category VARCHAR(100),
    supplier_status VARCHAR(20)
);

CREATE TABLE dim_promotion (
    promotion_key   SERIAL PRIMARY KEY,
    campaign_id     VARCHAR(10),
    campaign_name   VARCHAR(150),
    campaign_type   VARCHAR(30),
    channel         VARCHAR(50),
    target_segment  VARCHAR(100),
    -- SCD Type 2
    effective_date  DATE,
    expiry_date     DATE,
    is_current      BOOLEAN DEFAULT TRUE
);

CREATE TABLE dim_payment_method (
    payment_key     SERIAL PRIMARY KEY,
    payment_method  VARCHAR(30),
    payment_type    VARCHAR(20)         -- cash / digital / card
);

-- ═══════════════════════════════════════════════════════
-- FACT TABLE
-- ═══════════════════════════════════════════════════════

CREATE TABLE fact_sales (
    sales_key       BIGSERIAL PRIMARY KEY,
    -- Foreign Keys ke Dimensi
    time_key        INT REFERENCES dim_time(time_key),
    product_key     INT REFERENCES dim_product(product_key),
    customer_key    INT REFERENCES dim_customer(customer_key),
    store_key       INT REFERENCES dim_store(store_key),
    promotion_key   INT REFERENCES dim_promotion(promotion_key),
    supplier_key    INT REFERENCES dim_supplier(supplier_key),
    payment_key     INT REFERENCES dim_payment_method(payment_key),
    -- Degenerate Dimension
    transaction_id  VARCHAR(15),
    detail_id       VARCHAR(15),
    -- Measures / Ukuran
    quantity_sold   INT,
    unit_price      DECIMAL(15,2),
    discount_amount DECIMAL(15,2),
    total_sales     DECIMAL(15,2),      -- sebelum diskon
    final_sales     DECIMAL(15,2),      -- setelah diskon
    cost_amount     DECIMAL(15,2),      -- modal
    gross_profit    DECIMAL(15,2)       -- final_sales - cost_amount
);

-- Index untuk performa query analitik
CREATE INDEX idx_fact_time     ON fact_sales(time_key);
CREATE INDEX idx_fact_product  ON fact_sales(product_key);
CREATE INDEX idx_fact_customer ON fact_sales(customer_key);
CREATE INDEX idx_fact_store    ON fact_sales(store_key);
```

### Langkah 2.3 — Catat Connection String Neon

```
DWH_DATABASE_URL=postgresql://user:password@ep-xxx.ap-southeast-1.aws.neon.tech/neondb
```

---

## ✅ FASE 3 — Update Script Python untuk Cloud

### Langkah 3.1 — Buat File `.env.example`

```bash
# File: .env.example
# Salin file ini menjadi .env dan isi nilai sebenarnya
# JANGAN commit file .env ke Git!

# ── OLTP: Sales DB (MySQL) ──────────────────────
SALES_DB_HOST=
SALES_DB_PORT=3306
SALES_DB_USER=
SALES_DB_PASS=
SALES_DB_NAME=azko_sales_db

# ── OLTP: Warehouse DB (MySQL) ──────────────────
WAREHOUSE_DB_HOST=
WAREHOUSE_DB_PORT=3306
WAREHOUSE_DB_USER=
WAREHOUSE_DB_PASS=
WAREHOUSE_DB_NAME=azko_warehouse_db

# ── OLTP: Marketing DB (MySQL) ──────────────────
MARKETING_DB_HOST=
MARKETING_DB_PORT=3306
MARKETING_DB_USER=
MARKETING_DB_PASS=
MARKETING_DB_NAME=azko_marketing_db

# ── DWH: Neon PostgreSQL ─────────────────────────
DWH_DATABASE_URL=
```

Tambahkan `.env` ke `.gitignore`:
```
.env
__pycache__/
*.pyc
```

### Langkah 3.2 — Update `generate_data.py`

Ganti bagian connection di awal file dengan environment variables:

```python
# Tambahkan di bagian atas file, GANTIKAN hardcoded credentials
import os
from dotenv import load_dotenv

load_dotenv()

MYSQL_USER     = os.getenv("SALES_DB_USER")
MYSQL_PASSWORD = os.getenv("SALES_DB_PASS")
MYSQL_HOST     = os.getenv("SALES_DB_HOST")
MYSQL_PORT     = os.getenv("SALES_DB_PORT", "3306")

WH_USER     = os.getenv("WAREHOUSE_DB_USER")
WH_PASSWORD = os.getenv("WAREHOUSE_DB_PASS")
WH_HOST     = os.getenv("WAREHOUSE_DB_HOST")
WH_PORT     = os.getenv("WAREHOUSE_DB_PORT", "3306")

MKT_USER     = os.getenv("MARKETING_DB_USER")
MKT_PASSWORD = os.getenv("MARKETING_DB_PASS")
MKT_HOST     = os.getenv("MARKETING_DB_HOST")
MKT_PORT     = os.getenv("MARKETING_DB_PORT", "3306")

sales_engine = create_engine(
    f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/azko_sales_db"
)
warehouse_engine = create_engine(
    f"mysql+pymysql://{WH_USER}:{WH_PASSWORD}@{WH_HOST}:{WH_PORT}/azko_warehouse_db"
)
marketing_engine = create_engine(
    f"mysql+pymysql://{MKT_USER}:{MKT_PASSWORD}@{MKT_HOST}:{MKT_PORT}/azko_marketing_db"
)
```

### Langkah 3.3 — Buat `etl_pipeline.py`

```python
# File: src/etl_pipeline.py
"""
ETL Pipeline: Extract dari MySQL OLTP → Transform → Load ke PostgreSQL DWH
Dijalankan oleh GitHub Actions tiap hari otomatis.
"""

import os
import logging
from datetime import datetime, timedelta
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
import pandas as pd

load_dotenv()
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

# ── Koneksi ───────────────────────────────────────────────────────────────────

def get_sales_engine():
    return create_engine(
        f"mysql+pymysql://{os.getenv('SALES_DB_USER')}:{os.getenv('SALES_DB_PASS')}"
        f"@{os.getenv('SALES_DB_HOST')}:{os.getenv('SALES_DB_PORT', 3306)}/azko_sales_db"
    )

def get_warehouse_engine():
    return create_engine(
        f"mysql+pymysql://{os.getenv('WAREHOUSE_DB_USER')}:{os.getenv('WAREHOUSE_DB_PASS')}"
        f"@{os.getenv('WAREHOUSE_DB_HOST')}:{os.getenv('WAREHOUSE_DB_PORT', 3306)}/azko_warehouse_db"
    )

def get_marketing_engine():
    return create_engine(
        f"mysql+pymysql://{os.getenv('MARKETING_DB_USER')}:{os.getenv('MARKETING_DB_PASS')}"
        f"@{os.getenv('MARKETING_DB_HOST')}:{os.getenv('MARKETING_DB_PORT', 3306)}/azko_marketing_db"
    )

def get_dwh_engine():
    return create_engine(os.getenv("DWH_DATABASE_URL"))


# ── LOAD dim_time ─────────────────────────────────────────────────────────────

def load_dim_time(dwh):
    log.info("Loading dim_time...")
    month_names = ["Januari","Februari","Maret","April","Mei","Juni",
                   "Juli","Agustus","September","Oktober","November","Desember"]
    day_names   = ["Senin","Selasa","Rabu","Kamis","Jumat","Sabtu","Minggu"]

    rows = []
    for i in range(730):  # 2 tahun: 2025-2026
        d = datetime(2025, 1, 1) + timedelta(days=i)
        rows.append({
            "full_date":    d.date(),
            "day":          d.day,
            "month":        d.month,
            "month_name":   month_names[d.month - 1],
            "quarter":      (d.month - 1) // 3 + 1,
            "year":         d.year,
            "week_of_year": d.isocalendar()[1],
            "day_of_week":  d.weekday(),
            "day_name":     day_names[d.weekday()],
            "is_weekend":   d.weekday() >= 5
        })

    df = pd.DataFrame(rows)
    with dwh.begin() as conn:
        conn.execute(text("DELETE FROM dim_time"))
    df.to_sql("dim_time", dwh, if_exists="append", index=False)
    log.info(f"  ✓ dim_time: {len(df)} baris")


# ── LOAD dim_product ──────────────────────────────────────────────────────────

def load_dim_product(wh_engine, dwh):
    log.info("Loading dim_product...")
    df = pd.read_sql("SELECT * FROM products", wh_engine)
    df = df.rename(columns={"product_id": "product_id"})
    df = df[["product_id","product_name","category","brand",
             "unit_price","cost_price","product_status"]]

    with dwh.begin() as conn:
        conn.execute(text("DELETE FROM dim_product"))
    df.to_sql("dim_product", dwh, if_exists="append", index=False)
    log.info(f"  ✓ dim_product: {len(df)} baris")


# ── LOAD dim_customer ─────────────────────────────────────────────────────────

def load_dim_customer(sales_engine, dwh):
    log.info("Loading dim_customer...")
    df = pd.read_sql("SELECT * FROM customers", sales_engine)

    def age_group(age):
        if age < 26:   return "Youth (< 26)"
        if age < 40:   return "Adult (26-39)"
        if age < 55:   return "Middle (40-54)"
        return "Senior (55+)"

    df["age_group"] = df["age"].apply(age_group)
    df = df[["customer_id","customer_name","gender","age","age_group",
             "city","membership_level","registration_date"]]

    with dwh.begin() as conn:
        conn.execute(text("DELETE FROM dim_customer"))
    df.to_sql("dim_customer", dwh, if_exists="append", index=False)
    log.info(f"  ✓ dim_customer: {len(df)} baris")


# ── LOAD dim_store ────────────────────────────────────────────────────────────

def load_dim_store(sales_engine, dwh):
    log.info("Loading dim_store...")
    df = pd.read_sql("SELECT * FROM stores", sales_engine)
    df = df[["store_id","store_name","store_type","city","province","region"]]

    with dwh.begin() as conn:
        conn.execute(text("DELETE FROM dim_store"))
    df.to_sql("dim_store", dwh, if_exists="append", index=False)
    log.info(f"  ✓ dim_store: {len(df)} baris")


# ── LOAD dim_supplier ─────────────────────────────────────────────────────────

def load_dim_supplier(wh_engine, dwh):
    log.info("Loading dim_supplier...")
    df = pd.read_sql("SELECT * FROM suppliers", wh_engine)
    df = df[["supplier_id","supplier_name","supplier_city",
             "supplier_category","supplier_status"]]

    with dwh.begin() as conn:
        conn.execute(text("DELETE FROM dim_supplier"))
    df.to_sql("dim_supplier", dwh, if_exists="append", index=False)
    log.info(f"  ✓ dim_supplier: {len(df)} baris")


# ── LOAD dim_promotion ────────────────────────────────────────────────────────

def load_dim_promotion(mkt_engine, dwh):
    log.info("Loading dim_promotion...")
    df = pd.read_sql("SELECT * FROM marketing_campaigns", mkt_engine)
    df = df.rename(columns={"start_date": "effective_date", "end_date": "expiry_date"})
    df = df[["campaign_id","campaign_name","campaign_type",
             "channel","target_segment","effective_date","expiry_date"]]
    df["is_current"] = True

    with dwh.begin() as conn:
        conn.execute(text("DELETE FROM dim_promotion WHERE campaign_id != 'NO_PROMO'"))

    # Pastikan row "No Promotion" ada
    with dwh.begin() as conn:
        conn.execute(text("""
            INSERT INTO dim_promotion
                (campaign_id, campaign_name, campaign_type, channel,
                 target_segment, effective_date, expiry_date, is_current)
            VALUES ('NO_PROMO','No Promotion','none','none',
                    'All','2000-01-01','2099-12-31',TRUE)
            ON CONFLICT DO NOTHING
        """))

    df.to_sql("dim_promotion", dwh, if_exists="append", index=False)
    log.info(f"  ✓ dim_promotion: {len(df)} baris")


# ── LOAD dim_payment_method ───────────────────────────────────────────────────

def load_dim_payment_method(dwh):
    log.info("Loading dim_payment_method...")
    payment_map = [
        ("Cash",          "cash"),
        ("Debit Card",    "card"),
        ("Credit Card",   "card"),
        ("E-Wallet",      "digital"),
        ("Bank Transfer", "digital"),
    ]
    df = pd.DataFrame(payment_map, columns=["payment_method","payment_type"])

    with dwh.begin() as conn:
        conn.execute(text("DELETE FROM dim_payment_method"))
    df.to_sql("dim_payment_method", dwh, if_exists="append", index=False)
    log.info(f"  ✓ dim_payment_method: {len(df)} baris")


# ── LOAD fact_sales ───────────────────────────────────────────────────────────

def load_fact_sales(sales_engine, wh_engine, mkt_engine, dwh):
    log.info("Loading fact_sales (proses utama)...")

    # Extract dari OLTP
    trx   = pd.read_sql("SELECT * FROM sales_transactions WHERE transaction_status = 'Success'", sales_engine)
    dtl   = pd.read_sql("SELECT * FROM sales_transaction_details", sales_engine)
    prods = pd.read_sql("SELECT product_id, cost_price, supplier_id FROM products", wh_engine)
    promo = pd.read_sql(
        "SELECT transaction_id, campaign_id FROM promotion_usage GROUP BY transaction_id, campaign_id",
        mkt_engine
    )

    # Join detail → transaksi → produk
    df = dtl.merge(trx[["transaction_id","transaction_date","store_id",
                         "customer_id","payment_method"]], on="transaction_id")
    df = df.merge(prods, on="product_id")

    # Tambahkan promo (left join — transaksi tanpa promo → NO_PROMO)
    df = df.merge(promo, on="transaction_id", how="left")
    df["campaign_id"] = df["campaign_id"].fillna("NO_PROMO")

    # ── Lookup Keys dari Dimensi ──────────────────────────────────────────────

    def get_lookup(table, id_col, key_col, engine):
        return pd.read_sql(f"SELECT {id_col}, {key_col} FROM {table}", engine)

    time_lkp    = pd.read_sql("SELECT time_key, full_date FROM dim_time", dwh)
    time_lkp["full_date"] = pd.to_datetime(time_lkp["full_date"]).dt.date
    prod_lkp    = pd.read_sql("SELECT product_key, product_id FROM dim_product", dwh)
    cust_lkp    = pd.read_sql("SELECT customer_key, customer_id FROM dim_customer", dwh)
    store_lkp   = pd.read_sql("SELECT store_key, store_id FROM dim_store", dwh)
    supp_lkp    = pd.read_sql("SELECT supplier_key, supplier_id FROM dim_supplier", dwh)
    promo_lkp   = pd.read_sql("SELECT promotion_key, campaign_id FROM dim_promotion WHERE is_current = TRUE", dwh)
    pay_lkp     = pd.read_sql("SELECT payment_key, payment_method FROM dim_payment_method", dwh)

    # Normalisasi tipe data untuk join
    df["transaction_date"] = pd.to_datetime(df["transaction_date"]).dt.date

    df = (df
        .merge(time_lkp,  left_on="transaction_date", right_on="full_date")
        .merge(prod_lkp,  on="product_id")
        .merge(cust_lkp,  on="customer_id")
        .merge(store_lkp, on="store_id")
        .merge(supp_lkp,  on="supplier_id")
        .merge(promo_lkp, on="campaign_id")
        .merge(pay_lkp,   on="payment_method")
    )

    # ── Hitung Measures ───────────────────────────────────────────────────────
    df["cost_amount"]     = df["cost_price"] * df["quantity"]
    df["total_sales"]     = df["unit_price"]  * df["quantity"]
    df["discount_amount"] = df["discount_per_item"] * df["quantity"]
    df["final_sales"]     = df["subtotal"]
    df["gross_profit"]    = df["final_sales"] - df["cost_amount"]

    # ── Pilih Kolom Final ─────────────────────────────────────────────────────
    fact = df[[
        "time_key","product_key","customer_key","store_key",
        "promotion_key","supplier_key","payment_key",
        "transaction_id","detail_id",
        "quantity","unit_price","discount_amount",
        "total_sales","final_sales","cost_amount","gross_profit"
    ]].rename(columns={"quantity": "quantity_sold"})

    with dwh.begin() as conn:
        conn.execute(text("DELETE FROM fact_sales"))
    fact.to_sql("fact_sales", dwh, if_exists="append", index=False, chunksize=1000)
    log.info(f"  ✓ fact_sales: {len(fact)} baris")


# ── Main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    log.info("═══ AZKO DWH ETL Pipeline Dimulai ═══")

    sales     = get_sales_engine()
    warehouse = get_warehouse_engine()
    marketing = get_marketing_engine()
    dwh       = get_dwh_engine()

    load_dim_time(dwh)
    load_dim_product(warehouse, dwh)
    load_dim_customer(sales, dwh)
    load_dim_store(sales, dwh)
    load_dim_supplier(warehouse, dwh)
    load_dim_promotion(marketing, dwh)
    load_dim_payment_method(dwh)
    load_fact_sales(sales, warehouse, marketing, dwh)

    log.info("═══ ETL Selesai! Data Warehouse siap. ═══")
```

### Langkah 3.4 — Buat `requirements.txt`

```
faker==24.0.0
sqlalchemy==2.0.29
pymysql==1.1.0
psycopg2-binary==2.9.9
pandas==2.2.1
python-dotenv==1.0.1
```

---

## ✅ FASE 4 — Setup GitHub Actions (Otomasi ETL)

### Langkah 4.1 — Simpan Credentials di GitHub Secrets

1. Buka repo GitHub kalian
2. **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
3. Tambahkan semua secrets berikut (nama harus PERSIS sama):

```
SALES_DB_HOST
SALES_DB_PORT
SALES_DB_USER
SALES_DB_PASS

WAREHOUSE_DB_HOST
WAREHOUSE_DB_PORT
WAREHOUSE_DB_USER
WAREHOUSE_DB_PASS

MARKETING_DB_HOST
MARKETING_DB_PORT
MARKETING_DB_USER
MARKETING_DB_PASS

DWH_DATABASE_URL
```

### Langkah 4.2 — Buat File Workflow

```yaml
# File: .github/workflows/etl.yml

name: AZKO DWH — ETL Pipeline Harian

on:
  # ── Jadwal otomatis: tiap hari jam 08.00 WIB (01.00 UTC) ──
  schedule:
    - cron: "0 1 * * *"

  # ── Bisa dijalankan manual dari tab Actions ──
  workflow_dispatch:
    inputs:
      generate_new_data:
        description: "Generate data dummy baru dulu? (true/false)"
        required: false
        default: "false"

jobs:
  etl:
    name: Run ETL Pipeline
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      # 1. Checkout kode
      - name: Checkout repository
        uses: actions/checkout@v4

      # 2. Setup Python
      - name: Setup Python 3.11
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"
          cache: "pip"

      # 3. Install dependencies
      - name: Install dependencies
        run: pip install -r requirements.txt

      # 4. (Opsional) Generate data dummy baru
      - name: Generate dummy data
        if: github.event.inputs.generate_new_data == 'true' || github.event_name == 'schedule'
        run: python src/generate_data.py
        env:
          SALES_DB_HOST:      ${{ secrets.SALES_DB_HOST }}
          SALES_DB_PORT:      ${{ secrets.SALES_DB_PORT }}
          SALES_DB_USER:      ${{ secrets.SALES_DB_USER }}
          SALES_DB_PASS:      ${{ secrets.SALES_DB_PASS }}
          WAREHOUSE_DB_HOST:  ${{ secrets.WAREHOUSE_DB_HOST }}
          WAREHOUSE_DB_PORT:  ${{ secrets.WAREHOUSE_DB_PORT }}
          WAREHOUSE_DB_USER:  ${{ secrets.WAREHOUSE_DB_USER }}
          WAREHOUSE_DB_PASS:  ${{ secrets.WAREHOUSE_DB_PASS }}
          MARKETING_DB_HOST:  ${{ secrets.MARKETING_DB_HOST }}
          MARKETING_DB_PORT:  ${{ secrets.MARKETING_DB_PORT }}
          MARKETING_DB_USER:  ${{ secrets.MARKETING_DB_USER }}
          MARKETING_DB_PASS:  ${{ secrets.MARKETING_DB_PASS }}

      # 5. Jalankan ETL
      - name: Run ETL pipeline
        run: python src/etl_pipeline.py
        env:
          SALES_DB_HOST:      ${{ secrets.SALES_DB_HOST }}
          SALES_DB_PORT:      ${{ secrets.SALES_DB_PORT }}
          SALES_DB_USER:      ${{ secrets.SALES_DB_USER }}
          SALES_DB_PASS:      ${{ secrets.SALES_DB_PASS }}
          WAREHOUSE_DB_HOST:  ${{ secrets.WAREHOUSE_DB_HOST }}
          WAREHOUSE_DB_PORT:  ${{ secrets.WAREHOUSE_DB_PORT }}
          WAREHOUSE_DB_USER:  ${{ secrets.WAREHOUSE_DB_USER }}
          WAREHOUSE_DB_PASS:  ${{ secrets.WAREHOUSE_DB_PASS }}
          MARKETING_DB_HOST:  ${{ secrets.MARKETING_DB_HOST }}
          MARKETING_DB_PORT:  ${{ secrets.MARKETING_DB_PORT }}
          MARKETING_DB_USER:  ${{ secrets.MARKETING_DB_USER }}
          MARKETING_DB_PASS:  ${{ secrets.MARKETING_DB_PASS }}
          DWH_DATABASE_URL:   ${{ secrets.DWH_DATABASE_URL }}

      # 6. Notifikasi status (opsional tapi bagus untuk laporan)
      - name: ETL status summary
        if: always()
        run: |
          echo "──────────────────────────────"
          echo "ETL selesai: $(date '+%Y-%m-%d %H:%M:%S UTC')"
          echo "Status job: ${{ job.status }}"
          echo "──────────────────────────────"
```

---

## ✅ FASE 5 — Setup Metabase Cloud (Dashboard BI)

### Langkah 5.1 — Akses Metabase

Pilih salah satu opsi:

**Opsi A — Metabase Cloud (paling mudah):**
1. Daftar di https://www.metabase.com/start/oss/
2. Pilih **"Metabase Cloud"** → Free trial 14 hari (cukup untuk demo project)

**Opsi B — Self-hosted di Railway (gratis permanen):**
1. Di Railway.app, buat service baru
2. Pilih template **Metabase** (sudah tersedia)
3. Deploy → akses via URL yang diberikan Railway

### Langkah 5.2 — Connect ke Neon PostgreSQL

1. Masuk Metabase → **Settings** → **Admin** → **Databases** → **Add Database**
2. Pilih **PostgreSQL**
3. Isi form:
   ```
   Display name : AZKO Data Warehouse
   Host         : <host dari Neon, contoh: ep-xxx.ap-southeast-1.aws.neon.tech>
   Port         : 5432
   Database     : neondb
   Username     : <dari Neon>
   Password     : <dari Neon>
   ```
4. Klik **Save** → tunggu sync selesai

### Langkah 5.3 — Buat Dashboard "AZKO Analytics"

Buat Questions berikut lalu simpan ke 1 Dashboard:

| # | Nama Card | Tipe Visualisasi | Query Dasar |
|---|---|---|---|
| 1 | Total Revenue 2025 | Big Number | `SUM(final_sales)` dari fact_sales |
| 2 | Trend Penjualan Bulanan | Line Chart | `GROUP BY year, month` |
| 3 | Top 10 Produk Terlaku | Bar Chart | `GROUP BY product_name ORDER BY SUM(quantity_sold) DESC LIMIT 10` |
| 4 | Revenue per Kota | Map / Bar | `JOIN dim_store GROUP BY city` |
| 5 | Efektivitas Promosi | Bar Chart | `JOIN dim_promotion GROUP BY campaign_name` |
| 6 | Distribusi Metode Pembayaran | Pie Chart | `JOIN dim_payment_method GROUP BY payment_method` |
| 7 | Segmentasi Membership | Bar Chart | `JOIN dim_customer GROUP BY membership_level` |

---

## ✅ FASE 6 — Query Analitik Siap Pakai

Jalankan di Neon SQL Editor atau Metabase untuk mengecek hasil DWH:

```sql
-- ── A. Rekap Penjualan Bulanan ────────────────────────────────────────
SELECT
    t.year, t.month, t.month_name,
    COUNT(DISTINCT f.transaction_id)            AS total_transaksi,
    SUM(f.quantity_sold)                        AS total_qty,
    SUM(f.final_sales)                          AS total_revenue,
    SUM(f.gross_profit)                         AS total_profit,
    ROUND(SUM(f.gross_profit) /
          NULLIF(SUM(f.final_sales),0) * 100, 2) AS margin_pct
FROM fact_sales f
JOIN dim_time t ON f.time_key = t.time_key
GROUP BY t.year, t.month, t.month_name
ORDER BY t.year, t.month;

-- ── B. Top 10 Produk Terlaris ─────────────────────────────────────────
SELECT
    p.product_name, p.category, p.brand,
    SUM(f.quantity_sold)  AS total_terjual,
    SUM(f.final_sales)    AS total_revenue,
    SUM(f.gross_profit)   AS total_profit
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_name, p.category, p.brand
ORDER BY total_terjual DESC
LIMIT 10;

-- ── C. Revenue & Profit per Cabang ───────────────────────────────────
SELECT
    s.store_name, s.city, s.province,
    COUNT(DISTINCT f.transaction_id) AS total_transaksi,
    SUM(f.final_sales)               AS total_revenue,
    SUM(f.gross_profit)              AS total_profit
FROM fact_sales f
JOIN dim_store s ON f.store_key = s.store_key
GROUP BY s.store_name, s.city, s.province
ORDER BY total_revenue DESC;

-- ── D. Efektivitas Campaign Promosi ──────────────────────────────────
SELECT
    pr.campaign_name, pr.campaign_type, pr.channel,
    COUNT(DISTINCT f.transaction_id) AS pakai_promo,
    SUM(f.discount_amount)           AS total_diskon,
    SUM(f.final_sales)               AS revenue_dari_promo,
    ROUND(SUM(f.final_sales) /
          NULLIF(SUM(f.discount_amount),0), 2) AS roi_ratio
FROM fact_sales f
JOIN dim_promotion pr ON f.promotion_key = pr.promotion_key
WHERE pr.campaign_id != 'NO_PROMO'
GROUP BY pr.campaign_name, pr.campaign_type, pr.channel
ORDER BY revenue_dari_promo DESC;

-- ── E. Segmentasi Pelanggan ───────────────────────────────────────────
SELECT
    c.membership_level, c.age_group, c.gender,
    COUNT(DISTINCT f.transaction_id) AS jumlah_transaksi,
    SUM(f.final_sales)               AS total_belanja,
    ROUND(AVG(f.final_sales), 2)     AS avg_per_transaksi
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY c.membership_level, c.age_group, c.gender
ORDER BY total_belanja DESC;

-- ── F. Analisis Metode Pembayaran ─────────────────────────────────────
SELECT
    pm.payment_method, pm.payment_type,
    COUNT(DISTINCT f.transaction_id)                  AS jumlah_transaksi,
    SUM(f.final_sales)                                AS total_revenue,
    ROUND(100.0 * SUM(f.final_sales) /
          SUM(SUM(f.final_sales)) OVER (), 2)         AS pct_share
FROM fact_sales f
JOIN dim_payment_method pm ON f.payment_key = pm.payment_key
GROUP BY pm.payment_method, pm.payment_type
ORDER BY total_revenue DESC;

-- ── G. Kontribusi Supplier ────────────────────────────────────────────
SELECT
    su.supplier_name, su.supplier_city, su.supplier_category,
    SUM(f.quantity_sold) AS total_unit_terjual,
    SUM(f.final_sales)   AS total_revenue,
    SUM(f.gross_profit)  AS total_profit
FROM fact_sales f
JOIN dim_supplier su ON f.supplier_key = su.supplier_key
GROUP BY su.supplier_name, su.supplier_city, su.supplier_category
ORDER BY total_revenue DESC
LIMIT 10;

-- ── H. Penjualan per Kategori per Kuartal ─────────────────────────────
SELECT
    t.year, t.quarter, p.category,
    SUM(f.final_sales)  AS revenue,
    SUM(f.gross_profit) AS profit
FROM fact_sales f
JOIN dim_time t    ON f.time_key    = t.time_key
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY t.year, t.quarter, p.category
ORDER BY t.year, t.quarter, revenue DESC;
```

---

## 🚀 Urutan Pengerjaan (Checklist Tim)

```
[ ] Fase 0 — Semua anggota buat akun GitHub, Railway, Neon, Metabase
[ ] Fase 0 — Buat repo GitHub, invite semua anggota sebagai Collaborator
[ ] Fase 1 — Setup 3 MySQL database di Railway, jalankan DDL SQL
[ ] Fase 1 — Simpan semua credentials MySQL
[ ] Fase 2 — Buat project di Neon, jalankan schema_dw.sql
[ ] Fase 2 — Simpan DWH_DATABASE_URL
[ ] Fase 3 — Update generate_data.py pakai env vars
[ ] Fase 3 — Buat etl_pipeline.py & requirements.txt
[ ] Fase 3 — Test lokal dulu: buat .env dari .env.example, isi, lalu jalankan
[ ] Fase 4 — Masukkan semua secrets ke GitHub repository
[ ] Fase 4 — Buat .github/workflows/etl.yml
[ ] Fase 4 — Trigger manual pertama dari tab Actions, cek log
[ ] Fase 5 — Connect Metabase ke Neon
[ ] Fase 5 — Buat 7 card dashboard, kumpulkan jadi 1 Dashboard "AZKO Analytics"
[ ] Fase 6 — Verifikasi semua query analitik berjalan benar
[ ] Final  — Screenshot dashboard untuk laporan
```

---

## ⚠️ Troubleshooting Umum

| Masalah | Kemungkinan Penyebab | Solusi |
|---|---|---|
| `Connection refused` ke MySQL | Host/port salah, atau IP tidak di-whitelist | Cek settings Railway, tambahkan IP `0.0.0.0/0` di allowed connections |
| ETL gagal di GitHub Actions | Secret belum ditambahkan | Cek Settings → Secrets, pastikan nama persis sama |
| `SSL required` di Neon | Neon wajib SSL | Tambahkan `?sslmode=require` di akhir DWH_DATABASE_URL |
| Data kosong di Metabase | ETL belum pernah berhasil jalan | Jalankan manual dari tab Actions, baca log error |
| `ON CONFLICT DO NOTHING` error | Syntax PostgreSQL, bukan MySQL | Pastikan query ini hanya dijalankan di Neon (PostgreSQL), bukan MySQL |

---

*Dokumen ini dibuat untuk Project Data Warehouse AZKO*  
*Teknik Informatika — Universitas Padjadjaran, 2026*
