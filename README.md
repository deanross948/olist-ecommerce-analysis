# Olist E-Commerce Analytics

Customer and revenue analytics project built on 100,000+ real Brazilian 
e-commerce orders across 9 relational tables.

## Tools
- MySQL / MySQL Workbench
- Power BI
- Dataset: [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) via Kaggle

## Business Questions Answered
- Where is revenue leaking and how much is at risk?
- Which customers are worth retaining?
- How are sellers performing across regions?
- What does delivery performance look like across 100k+ orders?

## Key Findings
- 91.9% of orders arrived early — indicating systematic estimate padding
- Only 5.7% of customers qualify as high-value (>$500 lifetime spend)
- 6.7% late delivery rate represents $1.2M+ revenue at churn risk
- Repeat customer rate under 3% — significant retention opportunity

## How to Run
1. Download dataset from Kaggle (link above)
2. Run `schema/create_tables.sql` in MySQL Workbench
3. Load CSVs using `LOAD DATA LOCAL INFILE`
4. Run analysis scripts in `/analysis` folder in order

## Dashboard
Power BI dashboard covering executive overview, customer segmentation,
seller performance, and delivery analysis. 
