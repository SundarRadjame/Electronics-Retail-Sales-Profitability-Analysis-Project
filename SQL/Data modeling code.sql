-- ============================================================
-- Electronics Retailer Star Schema
-- Source: Complete DAX Practice Dataset (Kaggle)
-- Dimensions first, fact table last (FK order matters)
-- ============================================================

CREATE DATABASE IF NOT EXISTS retail_star_schema;
USE retail_star_schema;

-- ---------- DIM: Date ----------
CREATE TABLE DimDate (
    DateKey     INT PRIMARY KEY,          -- yyyymmdd format
    Date        DATE NOT NULL,
    Year        SMALLINT NOT NULL,
    Quarter     TINYINT NOT NULL,
    Month       TINYINT NOT NULL,
    MonthName   VARCHAR(10) NOT NULL,
    Day         TINYINT NOT NULL,
    DayOfWeek   TINYINT NOT NULL,         -- 1=Monday ... 7=Sunday
    IsWeekend   BOOLEAN NOT NULL,
    IsHoliday   BOOLEAN NOT NULL
);

-- ---------- DIM: Geography (role-playing dimension: used by Customer, Employee, and Sale) ----------
CREATE TABLE DimGeography (
    GeographyKey INT PRIMARY KEY,
    Country      VARCHAR(50) NOT NULL,
    Region       VARCHAR(20) NOT NULL,
    City         VARCHAR(50) NOT NULL
);

-- ---------- DIM: Customer ----------
CREATE TABLE DimCustomer (
    CustomerKey   INT PRIMARY KEY,
    CustomerName  VARCHAR(100) NOT NULL,
    Email         VARCHAR(100),
    Phone         VARCHAR(20),            -- kept as string; not used numerically
    SignupDate    DATE,
    GeographyKey  INT NOT NULL,
    LoyaltyTier   ENUM('Bronze','Silver','Gold','Platinum') NOT NULL,
    Gender        CHAR(1),
    FOREIGN KEY (GeographyKey) REFERENCES DimGeography(GeographyKey)
);

-- ---------- DIM: Employee ----------
CREATE TABLE DimEmployee (
    EmployeeKey   INT PRIMARY KEY,
    EmployeeName  VARCHAR(100) NOT NULL,
    HireDate      DATE,
    Role          VARCHAR(30) NOT NULL,
    GeographyKey  INT NOT NULL,
    FOREIGN KEY (GeographyKey) REFERENCES DimGeography(GeographyKey)
);

-- ---------- DIM: Product ----------
CREATE TABLE DimProduct (
    ProductKey    INT PRIMARY KEY,
    ProductName   VARCHAR(50) NOT NULL,
    Category      VARCHAR(30) NOT NULL,
    SubCategory   VARCHAR(30) NOT NULL,
    Color         VARCHAR(20),
    Size          VARCHAR(5) NULL,
    StandardCost  DECIMAL(10,2) NOT NULL,
    ListPrice     DECIMAL(10,2) NOT NULL
);

-- ---------- FACT: Sales ----------
CREATE TABLE FactSales (
    SalesKey       INT PRIMARY KEY,
    OrderDateKey   INT NOT NULL,
    ShipDateKey    INT NOT NULL,
    ProductKey     INT NOT NULL,
    CustomerKey    INT NOT NULL,
    EmployeeKey    INT NOT NULL,
    GeographyKey   INT NOT NULL,          -- location where the SALE occurred (distinct role from Customer's/Employee's geography)
    Quantity       INT NOT NULL,
    UnitPrice      DECIMAL(10,2) NOT NULL,
    Discount       DECIMAL(4,2) NOT NULL, -- observed range 0.00 - 0.20
    SalesAmount    DECIMAL(12,2) NOT NULL,
    TotalCost      DECIMAL(12,2) NOT NULL,
    Profit         DECIMAL(12,2) NOT NULL,
    Channel        VARCHAR(20) NOT NULL,       -- Retail, Online, Partner, Phone
    PaymentMethod  VARCHAR(20) NOT NULL,       -- Credit Card, PayPal, Bank Transfer, Cash
    OrderPriority  VARCHAR(10) NOT NULL,       -- High, Medium, Low

    FOREIGN KEY (OrderDateKey)  REFERENCES DimDate(DateKey),
    FOREIGN KEY (ShipDateKey)   REFERENCES DimDate(DateKey),
    FOREIGN KEY (ProductKey)    REFERENCES DimProduct(ProductKey),
    FOREIGN KEY (CustomerKey)   REFERENCES DimCustomer(CustomerKey),
    FOREIGN KEY (EmployeeKey)   REFERENCES DimEmployee(EmployeeKey),
    FOREIGN KEY (GeographyKey)  REFERENCES DimGeography(GeographyKey)
);
