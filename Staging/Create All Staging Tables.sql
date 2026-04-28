-- STG_Book
CREATE TABLE STG_Book (
    book_id         INT,
    title           NVARCHAR(400),
    isbn13          VARCHAR(20),
    language_id     INT,
    num_pages       INT,
    publication_date DATE,
    publisher_id    INT,
    ETL_LoadDate    DATETIME DEFAULT GETDATE()
);

-- STG_Author
CREATE TABLE STG_Author (
    author_id    INT,
    author_name  NVARCHAR(200),
    ETL_LoadDate DATETIME DEFAULT GETDATE()
);

-- STG_Book_Author
CREATE TABLE STG_Book_Author (
    book_id      INT,
    author_id    INT,
    ETL_LoadDate DATETIME DEFAULT GETDATE()
);

-- STG_Book_Language (embedded in book dim but staged separately)
CREATE TABLE STG_Book_Language (
    language_id   INT,
    language_code VARCHAR(10),
    language_name NVARCHAR(100),
    ETL_LoadDate  DATETIME DEFAULT GETDATE()
);

-- STG_Publisher
CREATE TABLE STG_Publisher (
    publisher_id   INT,
    publisher_name NVARCHAR(400),
    ETL_LoadDate   DATETIME DEFAULT GETDATE()
);

-- STG_Customer
CREATE TABLE STG_Customer (
    customer_id  INT,
    first_name   NVARCHAR(200),
    last_name    NVARCHAR(200),
    email        NVARCHAR(350),
    ETL_LoadDate DATETIME DEFAULT GETDATE()
);

-- STG_Customer_Address
CREATE TABLE STG_Customer_Address (
    customer_id  INT,
    address_id   INT,
    status_id    INT,
    ETL_LoadDate DATETIME DEFAULT GETDATE()
);

-- STG_Address
CREATE TABLE STG_Address (
    address_id     INT,
    street_number  NVARCHAR(20),
    street_name    NVARCHAR(200),
    city           NVARCHAR(100),
    country_id     INT,
    ETL_LoadDate   DATETIME DEFAULT GETDATE()
);

-- STG_Address_Status
CREATE TABLE STG_Address_Status (
    status_id      INT,
    address_status NVARCHAR(100),
    ETL_LoadDate   DATETIME DEFAULT GETDATE()
);

-- STG_Country
CREATE TABLE STG_Country (
    country_id   INT,
    country_name NVARCHAR(200),
    ETL_LoadDate DATETIME DEFAULT GETDATE()
);

-- STG_Cust_Order
CREATE TABLE STG_Cust_Order (
    order_id           INT,
    order_date         DATETIME,
    customer_id        INT,
    shipping_method_id INT,
    dest_address_id    INT,
    ETL_LoadDate       DATETIME DEFAULT GETDATE()
);

-- STG_Order_Line
CREATE TABLE STG_Order_Line (
    line_id      INT,
    order_id     INT,
    book_id      INT,
    price        DECIMAL(10,2),
    ETL_LoadDate DATETIME DEFAULT GETDATE()
);

-- STG_Shipping_Method
CREATE TABLE STG_Shipping_Method (
    method_id    INT,
    method_name  NVARCHAR(100),
    cost         DECIMAL(10,2),
    ETL_LoadDate DATETIME DEFAULT GETDATE()
);

-- STG_Order_History
CREATE TABLE STG_Order_History (
    history_id   INT,
    order_id     INT,
    status_id    INT,
    status_date  DATETIME,
    ETL_LoadDate DATETIME DEFAULT GETDATE()
);

-- STG_Order_Status
CREATE TABLE STG_Order_Status (
    status_id    INT,
    status_value NVARCHAR(100),
    ETL_LoadDate DATETIME DEFAULT GETDATE()
);
