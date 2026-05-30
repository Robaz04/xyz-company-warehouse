# 📦 Walkthrough: Cloud Data Warehouse AZKO

## Semua File yang Sudah Dibuat

Berikut struktur folder final setelah semua script dibuat:

```
azko-warehouse/
├── .github/
│   └── workflows/
│       └── etl.yml                  ← GitHub Actions: ETL otomatis harian
├── scripts/                         ← File lama (tetap ada)
│   ├── generate_dummy_data.py
│   ├── sales_tables.sql
│   ├── warehouse_tables.sql
│   └── marketing_tables.sql
├── src/                             ← File baru untuk cloud
│   ├── oltp/
│   │   ├── schema_sales.sql         ← DDL azko_sales_db
│   │   ├── schema_warehouse.sql     ← DDL azko_warehouse_db
│   │   └── schema_marketing.sql     ← DDL azko_marketing_db
│   ├── dwh/
│   │   ├── schema_dw.sql            ← Star Schema PostgreSQL (Neon)
│   │   └── analytics_queries.sql    ← 8 query analitik siap pakai
│   ├── generate_data.py             ← Data generator (cloud-ready)
│   └── etl_pipeline.py              ← ETL OLTP → DWH
├── .env.example                     ← Template credentials
├── .gitignore                       ← Ignore .env, __pycache__, etc.
└── requirements.txt                 ← Python dependencies
```

---

## File-file yang Dibuat

| # | File | Fungsi |
|---|---|---|
| 1 | [schema_sales.sql](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/src/oltp/schema_sales.sql) | DDL tabel OLTP Sales (MySQL) |
| 2 | [schema_warehouse.sql](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/src/oltp/schema_warehouse.sql) | DDL tabel OLTP Warehouse (MySQL) |
| 3 | [schema_marketing.sql](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/src/oltp/schema_marketing.sql) | DDL tabel OLTP Marketing (MySQL) |
| 4 | [schema_dw.sql](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/src/dwh/schema_dw.sql) | Star Schema DWH (PostgreSQL Neon) |
| 5 | [analytics_queries.sql](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/src/dwh/analytics_queries.sql) | 8 query analitik siap pakai |
| 6 | [generate_data.py](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/src/generate_data.py) | Generator dummy data (cloud-ready) |
| 7 | [etl_pipeline.py](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/src/etl_pipeline.py) | ETL Pipeline lengkap |
| 8 | [etl.yml](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/.github/workflows/etl.yml) | GitHub Actions workflow |
| 9 | [.env.example](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/.env.example) | Template environment variables |
| 10 | [.gitignore](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/.gitignore) | Git ignore rules |
| 11 | [requirements.txt](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/requirements.txt) | Python dependencies |

---

## 🗺️ Langkah-Langkah Setup Cloud (Step by Step)

---

### FASE 0 — Persiapan Akun & Repository

#### Langkah 0.1 — Buat Akun (semua gratis)

| Platform | Link | Kegunaan |
|---|---|---|
| **GitHub** | https://github.com | Repo + CI/CD otomatis |
| **Railway.app** | https://railway.app | MySQL cloud (OLTP) — ⭐ Direkomendasikan |
| **Neon.tech** | https://neon.tech | PostgreSQL cloud (DWH) |
| **Metabase** | https://metabase.com/start/oss/ | Dashboard BI |

> [!TIP]
> Railway memberikan $5 kredit gratis per bulan — cukup untuk project ini.
> Alternatif MySQL: **Aiven.io** (trial 1 bulan) atau **Clever Cloud** (free tier permanen).

#### Langkah 0.2 — Push Repository

```bash
cd azko-warehouse
git add .
git commit -m "feat: add cloud ETL pipeline and DWH schema"
git push origin main
```

---

### FASE 1 — Setup Database OLTP di Railway (MySQL)

#### Langkah 1.1 — Buat 3 Database MySQL di Railway

1. Login ke https://railway.app
2. Klik **"New Project"** → **"Provision MySQL"**
3. Ulangi 3 kali, beri nama:
   - `azko_sales_db`
   - `azko_warehouse_db`
   - `azko_marketing_db`

> [!IMPORTANT]
> Setiap database MySQL di Railway memiliki host, port, user, dan password **berbeda-beda**. Catat semuanya!

#### Langkah 1.2 — Jalankan DDL SQL

Untuk setiap database, buka tab **"Data"** atau gunakan MySQL client:

```bash
# Contoh pakai mysql CLI
mysql -h <host> -P <port> -u <user> -p<password> azko_sales_db < src/oltp/schema_sales.sql
mysql -h <host> -P <port> -u <user> -p<password> azko_warehouse_db < src/oltp/schema_warehouse.sql
mysql -h <host> -P <port> -u <user> -p<password> azko_marketing_db < src/oltp/schema_marketing.sql
```

Atau copy-paste isi SQL ke Railway SQL Editor.

#### Langkah 1.3 — Catat Credentials

Dari Dashboard Railway, klik tiap MySQL service → tab **"Connect"** → salin:

```
# Sales DB
SALES_DB_HOST=<dari Railway>
SALES_DB_PORT=<dari Railway, biasanya bukan 3306>
SALES_DB_USER=root
SALES_DB_PASS=<password>
SALES_DB_NAME=azko_sales_db

# Warehouse DB  
WAREHOUSE_DB_HOST=<dari Railway>
WAREHOUSE_DB_PORT=<dari Railway>
WAREHOUSE_DB_USER=root
WAREHOUSE_DB_PASS=<password>
WAREHOUSE_DB_NAME=azko_warehouse_db

# Marketing DB
MARKETING_DB_HOST=<dari Railway>
MARKETING_DB_PORT=<dari Railway>
MARKETING_DB_USER=root
MARKETING_DB_PASS=<password>
MARKETING_DB_NAME=azko_marketing_db
```

---

### FASE 2 — Setup Data Warehouse di Neon.tech (PostgreSQL)

#### Langkah 2.1 — Buat Project di Neon

1. Login ke https://neon.tech
2. Klik **"New Project"** → Nama: `azko-dwh`
3. Region: pilih **Singapore** (terdekat)
4. Salin **Connection String**:
   ```
   postgresql://username:password@ep-xxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
   ```

> [!WARNING]
> Pastikan tambahkan `?sslmode=require` di akhir URL! Neon mewajibkan SSL.

#### Langkah 2.2 — Buat Schema DWH

1. Di Neon Dashboard → buka **"SQL Editor"**
2. Copy-paste isi [schema_dw.sql](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/src/dwh/schema_dw.sql)
3. Klik **"Run"**

Ini akan membuat:
- 7 tabel dimensi: `dim_time`, `dim_product`, `dim_customer`, `dim_store`, `dim_supplier`, `dim_promotion`, `dim_payment_method`
- 1 tabel fakta: `fact_sales`
- 4 index untuk performa query

#### Langkah 2.3 — Catat Connection String

```
DWH_DATABASE_URL=postgresql://user:password@ep-xxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
```

---

### FASE 3 — Test Lokal (Opsional tapi Direkomendasikan)

#### Langkah 3.1 — Buat File `.env`

```bash
# Copy template
cp .env.example .env

# Edit dan isi credentials yang sudah dicatat
# Gunakan text editor favorit (VS Code, Notepad++, dll)
```

#### Langkah 3.2 — Install Dependencies

```bash
pip install -r requirements.txt
```

#### Langkah 3.3 — Generate Dummy Data

```bash
python src/generate_data.py
```

Output yang diharapkan:
```
═══ Generate dummy data berhasil! ═══
  Stores:              20
  Customers:           500
  Suppliers:           20
  Products:            100
  ...
```

#### Langkah 3.4 — Jalankan ETL Pipeline

```bash
python src/etl_pipeline.py
```

Output yang diharapkan:
```
AZKO DWH ETL Pipeline Dimulai
  ✓ dim_time: 730 baris
  ✓ dim_product: 100 baris
  ✓ dim_customer: 500 baris
  ✓ dim_store: 20 baris
  ✓ dim_supplier: 20 baris
  ✓ dim_promotion: 10 baris
  ✓ dim_payment_method: 5 baris
  ✓ fact_sales: ~2000+ baris
ETL Selesai! Data Warehouse siap.
```

---

### FASE 4 — Setup GitHub Actions (Otomasi ETL)

#### Langkah 4.1 — Tambahkan GitHub Secrets

1. Buka repo GitHub → **Settings** → **Secrets and variables** → **Actions**
2. Klik **"New repository secret"** untuk setiap variabel:

| Secret Name | Nilai |
|---|---|
| `SALES_DB_HOST` | Host MySQL Sales dari Railway |
| `SALES_DB_PORT` | Port MySQL Sales dari Railway |
| `SALES_DB_USER` | Username MySQL Sales |
| `SALES_DB_PASS` | Password MySQL Sales |
| `SALES_DB_NAME` | `azko_sales_db` |
| `WAREHOUSE_DB_HOST` | Host MySQL Warehouse dari Railway |
| `WAREHOUSE_DB_PORT` | Port MySQL Warehouse dari Railway |
| `WAREHOUSE_DB_USER` | Username MySQL Warehouse |
| `WAREHOUSE_DB_PASS` | Password MySQL Warehouse |
| `WAREHOUSE_DB_NAME` | `azko_warehouse_db` |
| `MARKETING_DB_HOST` | Host MySQL Marketing dari Railway |
| `MARKETING_DB_PORT` | Port MySQL Marketing dari Railway |
| `MARKETING_DB_USER` | Username MySQL Marketing |
| `MARKETING_DB_PASS` | Password MySQL Marketing |
| `MARKETING_DB_NAME` | `azko_marketing_db` |
| `DWH_DATABASE_URL` | Connection string Neon (lengkap dgn `?sslmode=require`) |

> [!CAUTION]
> Nama secret harus **PERSIS SAMA** seperti di tabel. Typo = ETL gagal.

#### Langkah 4.2 — Trigger Manual Pertama

1. Buka tab **"Actions"** di repo GitHub
2. Pilih workflow **"AZKO DWH — ETL Pipeline Harian"**
3. Klik **"Run workflow"** → set `generate_new_data` = `true`
4. Klik **"Run workflow"** (tombol hijau)
5. Tunggu selesai (~2-5 menit), cek log hijau ✓

> [!NOTE]
> Setelah ini, workflow akan berjalan otomatis setiap hari jam 08.00 WIB (01.00 UTC).
> Workflow juga bisa ditrigger manual kapan saja dari tab Actions.

---

### FASE 5 — Setup Metabase (Dashboard BI)

#### Langkah 5.1 — Pilih Platform Metabase

**Opsi A — Metabase Cloud (paling mudah):**
1. Daftar di https://www.metabase.com/start/oss/
2. Pilih **"Metabase Cloud"** → Free trial 14 hari

**Opsi B — Self-hosted di Railway (gratis permanen):**
1. Di Railway → **New Project** → pilih template **Metabase**
2. Deploy → akses via URL Railway

#### Langkah 5.2 — Connect ke Neon PostgreSQL

1. Login Metabase → **Settings** → **Admin** → **Databases** → **Add Database**
2. Pilih **PostgreSQL**
3. Isi:
   ```
   Display name : AZKO Data Warehouse
   Host         : ep-xxx.ap-southeast-1.aws.neon.tech
   Port         : 5432
   Database     : neondb
   Username     : <dari Neon>
   Password     : <dari Neon>
   ```
4. Klik **Save** → tunggu sync

#### Langkah 5.3 — Buat Dashboard

Buat 7 Questions dan kumpulkan ke 1 Dashboard **"AZKO Analytics"**:

| # | Card | Tipe | Query |
|---|---|---|---|
| 1 | Total Revenue 2025 | Big Number | `SUM(final_sales)` |
| 2 | Trend Penjualan Bulanan | Line Chart | Group by year, month |
| 3 | Top 10 Produk Terlaku | Bar Chart | Order by SUM(quantity_sold) DESC |
| 4 | Revenue per Kota | Bar Chart | Join dim_store, group by city |
| 5 | Efektivitas Promosi | Bar Chart | Join dim_promotion |
| 6 | Distribusi Pembayaran | Pie Chart | Join dim_payment_method |
| 7 | Segmentasi Membership | Bar Chart | Join dim_customer |

> [!TIP]
> Query SQL siap pakai untuk Metabase ada di [analytics_queries.sql](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/src/dwh/analytics_queries.sql)

---

### FASE 6 — Verifikasi

#### Langkah 6.1 — Cek Data di Neon SQL Editor

Jalankan query dari [analytics_queries.sql](file:///d:/KULIAH/SEMESTER%206/Data%20Warehouse/azko-warehouse/src/dwh/analytics_queries.sql) di Neon SQL Editor untuk memastikan data sudah masuk.

#### Langkah 6.2 — Screenshot Dashboard

Ambil screenshot dashboard Metabase untuk laporan.

---

## ⚠️ Troubleshooting

| Masalah | Penyebab | Solusi |
|---|---|---|
| `Connection refused` ke MySQL | Host/port salah | Cek settings Railway, pastikan pakai port yang benar (seringkali bukan 3306) |
| ETL gagal di GitHub Actions | Secret belum ditambahkan | Cek Settings → Secrets, pastikan nama persis sama |
| `SSL required` di Neon | Neon wajib SSL | Tambahkan `?sslmode=require` di akhir `DWH_DATABASE_URL` |
| Data kosong di Metabase | ETL belum berhasil | Trigger manual dari tab Actions, baca log error |
| `ON CONFLICT DO NOTHING` error | Syntax PostgreSQL | Query ini hanya untuk Neon (PostgreSQL), bukan MySQL |

---

## ✅ Checklist Pengerjaan

```
[ ] Fase 0 — Buat akun GitHub, Railway, Neon, Metabase
[ ] Fase 0 — Push repo ke GitHub
[ ] Fase 1 — Buat 3 MySQL database di Railway
[ ] Fase 1 — Jalankan DDL SQL di masing-masing database
[ ] Fase 1 — Catat semua credentials MySQL
[ ] Fase 2 — Buat project di Neon, jalankan schema_dw.sql
[ ] Fase 2 — Catat DWH_DATABASE_URL (dengan ?sslmode=require)
[ ] Fase 3 — Test lokal: buat .env, install deps, jalankan generate_data & ETL
[ ] Fase 4 — Masukkan semua secrets ke GitHub Secrets
[ ] Fase 4 — Trigger manual pertama dari tab Actions
[ ] Fase 5 — Connect Metabase ke Neon
[ ] Fase 5 — Buat 7 card dashboard
[ ] Fase 6 — Verifikasi query analitik
[ ] Final — Screenshot dashboard untuk laporan
```
