# 📚 BookSales-DataWarehouse
### End-to-End Data Warehouse for GravityBooks — OLTP → Staging → DWH → OLAP

> A complete Business Intelligence solution built on SQL Server, SSIS, and SSAS.  
> Covers the full data engineering lifecycle: ETL design, star schema modeling, SCD handling, and multidimensional cube analysis.
 
---
 
## 🏗️ Architecture
 
```
┌──────────────────────┐       SSIS ETL        ┌──────────────────────┐      SSIS ETL       ┌──────────────────────┐
│    OLTP Source       │ ───────────────────►  │    Staging Area      │ ──────────────────► │   Data Warehouse     │
│  (GravityBooks DB)   │                        │    (Raw Layer)       │                      │   (Star Schema)      │
└──────────────────────┘                        └──────────────────────┘                      └──────────┬───────────┘
                                                                                                         │
                                                                                                  SSAS Processing
                                                                                                         │
                                                                                                         ▼
                                                                                              ┌──────────────────────┐
                                                                                              │     OLAP Cube        │
                                                                                              │  (Multidimensional)  │
                                                                                              └──────────────────────┘
```
 
---
 
## ⭐ Star Schema Design
 
The DWH uses a **galaxy schema** — two fact tables sharing conformed dimensions.
 
### Fact Tables
 
| Table | Description | Key Measures |
|---|---|---|
| `Fact_Order_Line` | One row per order line item | Unit_Price, Quantity, Shipping_Cost |
| `Fact_Order_Status_History` | Tracks every status change per order | Days_To_Ship, Days_To_Deliver, Total_Order_Value |
 
### Dimension Tables
 
| Table | SCD Type | Description |
|---|---|---|
| `Dim_Date` | Static | Full calendar 2000–2040 with Day, Week, Month, Quarter, Year, Is_Weekend |
| `Dim_Book` | Type 1 | Title, ISBN13, Num_Pages, Publication_Date, Language, Publisher |
| `Dim_Author` | Type 1 | Author_ID_BK, Author_Name |
| `Dim_Customer` | Type 2 | First/Last Name, Email — full history with Start_Date, End_Date, Is_Current |
| `Dim_Address` | Type 2 | Street, City, Country — versioned for address changes |
| `Dim_Shipping_Method` | Type 2 | Method_Name, Cost — versioned for pricing changes |
| `Dim_Order_Status` | Type 0 | Fixed reference values — insert only, never updated |
| `Bridge_Book_Author` | N/A | Many-to-many bridge between Dim_Book and Dim_Author |
 
> **SCD Type 2 columns added by ETL at runtime:** `Start_Date`, `End_Date`, `Is_Current`
 
---
 
## 🔄 SSIS ETL Pipeline — 11 Packages
 
### Package Inventory
 
| # | Package | Type | SCD | Runs After |
|---|---|---|---|---|
| 01 | `MASTER_Load_DWH` | Orchestrator | — | — |
| 02 | `DIM_Load_Date` | Dimension | — | Manual (once) |
| 03 | `DIM_Load_OrderStatus` | Dimension | Type 0 | DIM_Load_Date |
| 04 | `DIM_Load_Author` | Dimension | Type 1 | DIM_Load_Date |
| 05 | `DIM_Load_Book` | Dimension | Type 1 | DIM_Load_Author |
| 06 | `DIM_Load_Customer` | Dimension | Type 2 | DIM_Load_Date |
| 07 | `DIM_Load_Address` | Dimension | Type 2 | DIM_Load_Date |
| 08 | `DIM_Load_ShippingMethod` | Dimension | Type 2 | DIM_Load_Date |
| 09 | `BRIDGE_Load_BookAuthor` | Bridge | — | DIM_Load_Book + DIM_Load_Author |
| 10 | `FACT_Load_OrderLine` | Fact | — | All Dims + Bridge |
| 11 | `FACT_Load_OrderStatusHistory` | Fact | — | All Dims |
 
### Execution Flow
 
```
DIM_Load_Date
      │
      ├──► DIM_Load_OrderStatus
      ├──► DIM_Load_Author ──► DIM_Load_Book ──┐
      ├──► DIM_Load_Customer                    ├──► BRIDGE_Load_BookAuthor ──┐
      ├──► DIM_Load_Address                     │                              │
      └──► DIM_Load_ShippingMethod ─────────────┘                              │
                                                                                ▼
                                                                   FACT_Load_OrderLine
                                                                                │
                                                                   FACT_Load_OrderStatusHistory
                                                                                │
                                                                   📧 Email Notification (Success)
```
 
### SCD Strategy
 
| SCD Type | Behavior | Packages |
|---|---|---|
| **Type 0** | Insert new rows only — existing rows never touched | DIM_Load_OrderStatus |
| **Type 1** | New → INSERT, Changed → UPDATE (overwrite, no history) | DIM_Load_Author, DIM_Load_Book |
| **Type 2** | New → INSERT, Changed → expire old row + insert new version | DIM_Load_Customer, DIM_Load_Address, DIM_Load_ShippingMethod |
 
### Data Flow Pattern (used across all packages)
 
```
OLE DB Source (OLTP)
       │
   Lookup (match Business Key in DWH)
       │
  Conditional Split
       ├── NEW (no match)       → OLE DB Destination (INSERT)
       ├── CHANGED (cols differ) → OLE DB Command (UPDATE / SCD2 expire + insert)
       └── UNCHANGED            → discard
```
 
---
 
## 📊 SSAS OLAP Cube
 
- **Measures:** Total Sales, Order Count, Average Order Value, Units Sold, Days to Ship, Days to Deliver
- **Dimensions:** Book, Author, Customer, Address, Date, Shipping Method, Order Status
- **Hierarchies:**
  - Date → Year → Quarter → Month → Day
  - Book → Language → Publisher → Title
  - Address → Country → City
---
 
## 🗂️ Repository Structure
 
```
BookSales-DataWarehouse/
│
├── 📁 OLTP/
│   └── GravityBooks_OLTP_Schema.sql
│
├── 📁 DWH/
│   ├── DWH_DDL.sql
│   └── DWH_Schema_Diagram.png
│
├── 📁 SSIS/
│   ├── GravityBooks_SSIS.sln
│   └── Packages/
│       ├── MASTER_Load_DWH.dtsx
│       ├── DIM_Load_Date.dtsx
│       ├── DIM_Load_OrderStatus.dtsx
│       ├── DIM_Load_Author.dtsx
│       ├── DIM_Load_Book.dtsx
│       ├── DIM_Load_Customer.dtsx
│       ├── DIM_Load_Address.dtsx
│       ├── DIM_Load_ShippingMethod.dtsx
│       ├── BRIDGE_Load_BookAuthor.dtsx
│       ├── FACT_Load_OrderLine.dtsx
│       └── FACT_Load_OrderStatusHistory.dtsx
│
├── 📁 SSAS/
│   ├── GravityBooks_SSAS.sln
│   └── GravityBooks_Cube.cube
│
└── README.md
```
 
---
 
## 🛠️ Technologies Used
 
| Technology | Purpose |
|---|---|
| **SQL Server 2019+** | OLTP source & DWH target databases |
| **SSIS** (SQL Server Integration Services) | 11-package ETL pipeline |
| **SSAS** (SQL Server Analysis Services) | OLAP cube & multidimensional analysis |
| **T-SQL** | DDL, transformations, stored procedures |
| **Visual Studio + SSDT** | SSIS & SSAS development |
| **SQL Server Agent** | Daily scheduled execution |
 
---
 
## 🚀 Getting Started
 
### Prerequisites
- SQL Server 2019 or later
- SQL Server Integration Services (SSIS)
- SQL Server Analysis Services (SSAS)
- Visual Studio 2019+ with SQL Server Data Tools (SSDT)
### Setup Steps
 
**1. Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/BookSales-DataWarehouse.git
cd BookSales-DataWarehouse
```
 
**2. Create & populate the OLTP database**
```sql
EXECUTE OLTP/GravityBooks_OLTP_Schema.sql
```
 
**3. Create the DWH database**
```sql
EXECUTE DWH/DWH_DDL.sql
```
 
**4. Configure SSIS connections**
- Open `SSIS/GravityBooks_SSIS.sln` in Visual Studio
- Update `GravityBooks_OLTP` and `GravityBooks_DWH` connection managers with your server name
**5. Run the ETL**
- Run `DIM_Load_Date.dtsx` once manually (populates the static date dimension)
- Then run `MASTER_Load_DWH.dtsx` to orchestrate all remaining packages
**6. Deploy the SSAS Cube**
- Open `SSAS/GravityBooks_SSAS.sln`, deploy and process the cube
- Connect via Excel, Power BI, or SSMS for analysis
---
 
## 📬 Contact
 
**Your Name**  
📧 your.email@example.com  
💼 [LinkedIn](https://linkedin.com/in/yourprofile)  
🐙 [GitHub](https://github.com/YOUR_USERNAME)
 
---
*Built with ❤️, T-SQL, and a lot of Conditional Splits*
