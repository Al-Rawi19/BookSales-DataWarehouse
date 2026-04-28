CREATE DATABASE Gravity_Books_DWH;
GO
USE Gravity_Books_DWH;
GO

--Dim_Date (Date Dimension)
CREATE TABLE Dim_Date (
    Date_PK_SK  INT           NOT NULL PRIMARY KEY,  -- Format: YYYYMMDD e.g. 20230115
    FullDate    DATE          NOT NULL,
    Day         TINYINT       NOT NULL,
    Month       TINYINT       NOT NULL,
    MonthName   NVARCHAR(20)  NOT NULL,
    Quarter     TINYINT       NOT NULL,
    Year        SMALLINT      NOT NULL,
    DayOfWeek   TINYINT       NOT NULL,
    DayName     NVARCHAR(20)  NOT NULL,
    IsWeekend   BIT           NOT NULL
);

-- Populate Dim_Date for years 2000-2030
DECLARE @StartDate DATE = '2000-01-01';
DECLARE @EndDate   DATE = '2030-12-31';
DECLARE @CurrDate  DATE = @StartDate;

WHILE @CurrDate <= @EndDate
BEGIN
    INSERT INTO Dim_Date
    SELECT
        CONVERT(INT, FORMAT(@CurrDate,'yyyyMMdd')) AS Date_PK_SK,
        @CurrDate                                  AS FullDate,
        DAY(@CurrDate)                             AS Day,
        MONTH(@CurrDate)                           AS Month,
        DATENAME(MONTH, @CurrDate)                 AS MonthName,
        DATEPART(QUARTER, @CurrDate)               AS Quarter,
        YEAR(@CurrDate)                            AS Year,
        DATEPART(WEEKDAY, @CurrDate)               AS DayOfWeek,
        DATENAME(WEEKDAY, @CurrDate)               AS DayName,
        CASE WHEN DATEPART(WEEKDAY,@CurrDate) IN (1,7) THEN 1 ELSE 0 END AS IsWeekend;
    SET @CurrDate = DATEADD(DAY, 1, @CurrDate);
END;
GO

--Dim_Book (SCD Type 2)
CREATE TABLE Dim_Book (
    Book_Pk_SK         INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Book_PK_BK         INT           NOT NULL,   -- Source: book.book_id
    title              NVARCHAR(400) NOT NULL,
    isbn13             VARCHAR(20)   NULL,
    Language_PK_BK     INT           NULL,       -- Source: book.language_id
    Language_Code      VARCHAR(10)   NULL,
    Language_name      NVARCHAR(100) NULL,
    num_pages          INT           NULL,
    Publisher_id_PK_BK INT           NULL,       -- Source: book.publisher_id
    Publisher_name     NVARCHAR(400) NULL,
    publication_date   DATE          NULL,
    -- SCD2 Columns
    St_Date            DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    End_Date           DATE          NULL,
    Is_Current         BIT           NOT NULL DEFAULT 1,
    SSC                VARCHAR(50)   NOT NULL DEFAULT 'GravityBooks'
);

--Dim_Author (SCD Type 2)
CREATE TABLE Dim_Author (
    Author_Pk_SK  INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Author_PK_BK  INT           NOT NULL,   -- Source: author.author_id
    Author_name   NVARCHAR(200) NOT NULL,
    -- SCD2 Columns
    St_Date       DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    End_Date      DATE          NULL,
    Is_Current    BIT           NOT NULL DEFAULT 1,
    SSC           VARCHAR(50)   NOT NULL DEFAULT 'GravityBooks'
);

--Dim_Book_Author (Bridge Table, SCD Type 2)
CREATE TABLE Dim_Book_Author (
    BookAuthor_PK_SK  INT  NOT NULL IDENTITY(1,1) PRIMARY KEY,
    FK_Book_Pk_SK     INT  NOT NULL,
    FK_Author_Pk_SK   INT  NOT NULL,
    -- SCD2 Columns
    St_Date           DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    End_Date          DATE NULL,
    Is_Current        BIT  NOT NULL DEFAULT 1,
    SSC               VARCHAR(50) NOT NULL DEFAULT 'GravityBooks',
    FOREIGN KEY (FK_Book_Pk_SK)   REFERENCES Dim_Book(Book_Pk_SK),
    FOREIGN KEY (FK_Author_Pk_SK) REFERENCES Dim_Author(Author_Pk_SK)
);

--Dim_Customer (SCD Type 2)
CREATE TABLE Dim_Customer (
    Customer_Pk_SK  INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Customer_PK_BK  INT           NOT NULL,   -- Source: customer.customer_id
    First_name      NVARCHAR(200) NULL,
    Last_name       NVARCHAR(200) NULL,
    email           NVARCHAR(350) NULL,
    -- SCD2 Columns
    St_Date         DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    End_Date        DATE          NULL,
    Is_Current      BIT           NOT NULL DEFAULT 1,
    SSC             VARCHAR(50)   NOT NULL DEFAULT 'GravityBooks'
);

--Dim_Address (SCD Type 2)
CREATE TABLE Dim_Address (
    Address_ID_Pk_SK  INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Address_ID_Pk_BK  INT           NOT NULL,   -- Source: address.address_id
    status_id_PK_BK   INT           NULL,
    Address_status    NVARCHAR(100) NULL,
    street_number     NVARCHAR(20)  NULL,
    Street_name       NVARCHAR(200) NULL,
    city              NVARCHAR(100) NULL,
    Country_id_BK     INT           NULL,
    Country_name      NVARCHAR(200) NULL,
    -- SCD2 Columns
    St_Date           DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    End_Date          DATE          NULL,
    Is_Current        BIT           NOT NULL DEFAULT 1,
    SSC               VARCHAR(50)   NOT NULL DEFAULT 'GravityBooks'
);

--Dim_Customer_Address (Bridge, SCD Type 2)
CREATE TABLE Dim_Customer_Address (
    CustAddr_PK_SK      INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    FK_Customer_Pk_SK   INT NOT NULL,
    FK_Address_ID_Pk_SK INT NOT NULL,
    -- SCD2 Columns
    St_Date   DATE       NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    End_Date  DATE       NULL,
    Is_Current BIT       NOT NULL DEFAULT 1,
    SSC       VARCHAR(50) NOT NULL DEFAULT 'GravityBooks',
    FOREIGN KEY (FK_Customer_Pk_SK)   REFERENCES Dim_Customer(Customer_Pk_SK),
    FOREIGN KEY (FK_Address_ID_Pk_SK) REFERENCES Dim_Address(Address_ID_Pk_SK)
);

--Dim_Shipping_Method (SCD Type 2)
CREATE TABLE Dim_Shipping_Method (
    method_Pk_SK  INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    method_PK_BK  INT           NOT NULL,   -- Source: shipping_method.method_id
    method_name   NVARCHAR(100) NOT NULL,
    cost          DECIMAL(10,2) NOT NULL,
    -- SCD2 Columns
    St_Date       DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    End_Date      DATE          NULL,
    Is_Current    BIT           NOT NULL DEFAULT 1,
    SSC           VARCHAR(50)   NOT NULL DEFAULT 'GravityBooks'
);

--Dim_Order_Line (SCD Type 2)
CREATE TABLE Dim_Order_Line (
    line_Pk_SK    INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    line_PK_BK    INT           NOT NULL,   -- Source: order_line.line_id
    FK_order_id   INT           NOT NULL,
    FK_Book_id    INT           NOT NULL,
    price         DECIMAL(10,2) NOT NULL,
    -- SCD2 Columns
    St_Date       DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    End_Date      DATE          NULL,
    Is_Current    BIT           NOT NULL DEFAULT 1,
    SSC           VARCHAR(50)   NOT NULL DEFAULT 'GravityBooks'
);

--Dim_Order_History (SCD Type 2)
CREATE TABLE Dim_Order_History (
    Histroy_Pk_SK    INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    History_PK_BK    INT           NOT NULL,   -- Source: order_history.history_id
    Status_id_PK_BK  INT           NOT NULL,
    status_value     NVARCHAR(100) NOT NULL,
    Status_date      DATETIME      NOT NULL,
    -- SCD2 Columns
    St_Date          DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    End_Date         DATE          NULL,
    Is_Current       BIT           NOT NULL DEFAULT 1,
    SSC              VARCHAR(50)   NOT NULL DEFAULT 'GravityBooks'
);

--Fact_Sales 
CREATE TABLE Fact_Sales (
    Fact_Sales_PK_SK   INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    -- Foreign Keys to Dimensions
    FK_Book_Pk_SK      INT           NOT NULL,
    FK_Date_PK_SK      INT           NOT NULL,
    FK_Histroy_PK_SK   INT           NOT NULL,
    FK_Customer_Pk_SK  INT           NOT NULL,
    FK_line_Pk_SK      INT           NOT NULL,
    FK_method_Pk_SK    INT           NOT NULL,
    -- Degenerate Dimension
    OrderID_PK_BK      INT           NOT NULL,  -- (DD) stored directly, no dim table
    -- Measures
    Total_price        DECIMAL(12,2) NOT NULL,
    Quantity           INT           NOT NULL DEFAULT 1,
    -- FK Constraints
    FOREIGN KEY (FK_Book_Pk_SK)     REFERENCES Dim_Book(Book_Pk_SK),
    FOREIGN KEY (FK_Date_PK_SK)     REFERENCES Dim_Date(Date_PK_SK),
    FOREIGN KEY (FK_Histroy_PK_SK)  REFERENCES Dim_Order_History(Histroy_Pk_SK),
    FOREIGN KEY (FK_Customer_Pk_SK) REFERENCES Dim_Customer(Customer_Pk_SK),
    FOREIGN KEY (FK_line_Pk_SK)     REFERENCES Dim_Order_Line(line_Pk_SK),
    FOREIGN KEY (FK_method_Pk_SK)   REFERENCES Dim_Shipping_Method(method_Pk_SK)
);

