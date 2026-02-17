CREATE TABLE Customer (
    CustomerID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    CustomerFN VARCHAR NOT NULL,
    CustomerLN VARCHAR NOT NULL,
    CustomerDOB TEXT NOT NULL,
    TotalPoints INTEGER NOT NULL,
    CustomerStreet VARCHAR NOT NULL,
    CustomerCity VARCHAR NOT NULL,
    CustomerState VARCHAR NOT NULL,
    CustomerZIP INTEGER NOT NULL);

CREATE TABLE Product (
    ProductID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ProductBrand VARCHAR NOT NULL,
    ProductDescription VARCHAR NOT NULL,
    ProductType VARCHAR NOT NULL,
    ProductRetailPrice DECIMAL (5,2) NOT NULL,
    ProductUnit VARCHAR NOT NULL,
    PointsPerEach INTEGER NOT NULL);

CREATE TABLE Vendor (
    VendorID INTEGER NOT NULL,
    VendorName VARCHAR NOT NULL,
    VendorAddress VARCHAR NOT NULL,
    VendorCity VARCHAR NOT NULL,
    VendorState VARCHAR NOT NULL,
    VendorZip INTEGER NOT NULL,
    CONSTRAINT Vendor_PK PRIMARY KEY (VendorID));

CREATE TABLE Restock (
    RestockID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    VendorID INTEGER NOT NULL,
    Quantity INTEGER NOT NULL,
    DatePurchased DATE NOT NULL,
    ExpirationDate DATE NOT NULL,
    RestockPrice DECIMAL (5,2) NOT NULL,
    CONSTRAINT Restock_PK PRIMARY KEY (RestockID),
    CONSTRAINT Product_FK1 FOREIGN KEY (ProductID) References Product(ProductID) on update cascade on delete restrict,
    CONSTRAINT Vendor_FK2 FOREIGN KEY (VendorID) References Vendor(VendorID) on update cascade on delete restrict);

CREATE TABLE InStock (
    StockID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    VendorID INTEGER NOT NULL,
    Description VARCHAR NOT NULL,
    Quantity INTEGER NOT NULL,
    DatePurchased DATE NOT NULL,
    ExpirationDate DATE NOT NULL,
    CONSTRAINT InStock_PK PRIMARY KEY (StockID),
    CONSTRAINT Product_FK1 FOREIGN KEY (ProductID) References Product(ProductID) on update cascade on delete restrict,
    CONSTRAINT Vendor_FK2 FOREIGN KEY (VendorID) References Vendor(VendorID) on update cascade on delete restrict);

CREATE TABLE Receipt (
    ReceiptID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    CustomerID INTEGER NOT NULL,
    ReceiptDate DATE NOT NULL,
    ReceiptAmt DECIMAL (5,2) NOT NULL,
    TotalPointsEarned INTEGER NOT NULL,
    PayMethod VARCHAR NOT NULL,
    CONSTRAINT Customer_FK FOREIGN KEY (CustomerID) References Customer(CustomerID));

CREATE TABLE ReceiptItem (
    ReceiptID INTEGER NOT NULL,
    ReceiptItemID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    ProductRetailPrice DECIMAL (5,2) NOT NULL,
    NumberPurchased INTEGER NOT NULL,
    PointsEarnedDetail INTEGER NOT NULL,
CONSTRAINT ReceiptID FOREIGN KEY (ReceiptID) References Receipt(ReceiptID),
CONSTRAINT ProductID FOREIGN KEY (ProductID) REFERENCES Product(ProductID));

-- #1: Transaction total by date
SELECT ReceiptDate AS Date, ROUND(SUM(Receipt.ReceiptAmt),2) AS Total
    FROM Receipt
GROUP BY ReceiptDate;

-- #2: Total Spent by each customer (to see who spends the most, least)
SELECT Customer.CustomerFN, Customer.CustomerLN, SUM(Receipt.ReceiptAmt) AS [Total Spent]
FROM Receipt
JOIN Customer on Customer.CustomerID = Receipt.CustomerID
GROUP BY Receipt.CustomerID
ORDER BY "Total Spent" DESC;

-- #3: Most popular payment method
SELECT PayMethod, COUNT(*) AS [# of times used]
    FROM Receipt
GROUP BY PayMethod
ORDER BY COUNT(PayMethod) DESC;

-- #4: Total restock cost by product
SELECT Product.ProductDescription, round(RestockPrice*Quantity, '2') AS [Total Cost]
    FROM Product
JOIN Restock on Product.ProductID = Restock.ProductID
GROUP BY Product.ProductID
ORDER BY "Total Cost";

-- #5: Total retail value of current products in stock
SELECT sum(ProductRetailPrice*Quantity) AS [Total Retail Value of In Stock Products]
    FROM Product
JOIN InStock on Product.ProductID = InStock.ProductID

-- #6: Top 5 Most Profitable Products
SELECT Product.ProductDescription, ROUND(TOTAL(Product.ProductRetailPrice - Restock.RestockPrice), 2) AS [Total Profit]
    FROM ReceiptItem
JOIN Product on Product.ProductID = ReceiptItem.ProductID
JOIN Restock on Product.ProductID = Restock.ProductID
GROUP BY ReceiptItem.ProductID
ORDER BY "Total Profit" DESC
LIMIT 5;

-- #7: Average Transaction Amount
SELECT Round(AVG(ReceiptAmt),2) AS [Average Transaction Amount]
FROM Receipt;

-- #8: Most Used Vendor
SELECT Vendor.VendorName as [Vendor], COUNT(Vendor.VendorID) AS [Times Used]
    FROM Vendor
    JOIN InStock ON InStock.VendorID = Vendor.VendorID
    JOIN Restock ON Restock.VendorID = Vendor.VendorID
GROUP BY Vendor.VendorName
ORDER BY COUNT(Vendor.VendorID) DESC;

-- #9: Total Number of Transactions by Each Customer
SELECT CustomerFN, CustomerLN,
    (SELECT COUNT(*) as [Number of receipts]
FROM Receipt
WHERE Receipt.CustomerID = Customer.CustomerID)
FROM Customer;

-- #10: Find Total Number of Loyalty Points for Duke Danielson and Update Customer Table
SELECT Customer.CustomerFN, Customer.CustomerLN, SUM(Receipt.TotalPointsEarned) AS [Points Earned]
    FROM Customer
    JOIN Receipt ON Customer.CustomerID = Receipt.CustomerID
WHERE Customer.CustomerID = '5';

UPDATE Customer
SET TotalPoints = '113'
WHERE CustomerID = 5;

-- #11: Find which and how many in-stock products that have already expired or will expire within the next 2 weeks (today: 12-3-2024)
SELECT Description, ExpirationDate, Quantity
    FROM InStock
WHERE InStock.ExpirationDate < '2024-12-17'
ORDER BY ExpirationDate ASC;
