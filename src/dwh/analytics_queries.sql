-- ═══════════════════════════════════════════════════════
-- XYZ DWH — Query Analitik
-- Target: Neon.tech PostgreSQL / Preset
-- ═══════════════════════════════════════════════════════

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
    pr.campaign_name,
    pr.campaign_type,
    pr.channel,
    COUNT(DISTINCT f.transaction_id) AS pakai_promo,
    SUM(f.discount_amount) AS total_diskon,
    SUM(f.final_sales) AS revenue_dari_promo,
    ROUND(
        SUM(f.final_sales) /
        NULLIF(SUM(f.discount_amount),0),
        2
    ) AS roi_ratio
FROM fact_sales f
JOIN dim_promotion pr
    ON f.promotion_key = pr.promotion_key
WHERE pr.campaign_id != 'NO_PROMO'
GROUP BY
    pr.campaign_name,
    pr.campaign_type,
    pr.channel
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
    t.year || ' Q' || t.quarter AS periode, -- Menggabungkan jadi "2025 Q1", "2025 Q2", dst.
    p.category,
    SUM(f.final_sales)  AS revenue,
    SUM(f.gross_profit) AS profit
FROM fact_sales f
JOIN dim_time t    ON f.time_key    = t.time_key
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY t.year, t.quarter, p.category
ORDER BY t.year, t.quarter, revenue DESC;
