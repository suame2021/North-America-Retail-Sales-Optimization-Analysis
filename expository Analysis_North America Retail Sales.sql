SELECT * FROM [Sales Retail]
/* Creating Fact and Dimention Tables
To create DimCustomer Table feom Sales Retal Table*/

SELECT * INTO DimCustomer
FROM
(SELECT Customer_ID, Customer_Name, Segment FROM [Sales Retail])
AS DimC

-- Removing duplicates from DimCustomer with CTE
WITH CTE_DimC
 AS
 (SELECT Customer_ID, Customer_Name, Segment, ROW_NUMBER() OVER ( PARTITION BY  Customer_ID, Customer_Name, Segment ORDER BY Customer_ID) AS RowNum
 FROM 
 DimCustomer)
 DELETE FROM CTE_DimC
 WHERE RowNum > 1

--To create DimProduct Table feom Sales Retal Table

 SELECT * INTO DimProduct
FROM
 (SELECT Product_ID,Category, Sub_Category,Product_Name FROM [Sales Retail])
 AS DimP

 -- Removing duplicates from DimProduct with CTE
 WITH CTE_DimP
 AS
 (SELECT  Product_ID,Category, Sub_Category,Product_Name, ROW_NUMBER() OVER ( PARTITION BY  Product_ID,Category, Sub_Category,Product_Name ORDER BY Product_ID) AS RowNum
 FROM 
 DimProduct)
 DELETE FROM CTE_DimP
 WHERE RowNum > 1

 --To create DimLocation Table feom Sales Retal Table

SELECT * INTO DimLocation
FROM
(SELECT Postal_Code, Country, State, City, Region FROM [Sales Retail])
AS DimL

-- Removing duplicates from DimLocation with CTE
WITH CTE_DimL
 AS
 (SELECT Postal_Code, Country, State, City, Region, ROW_NUMBER() OVER ( PARTITION BY  Postal_Code, Country, State, City, Region ORDER BY Postal_Code) AS RowNum
 FROM 
 DimLocation)
 DELETE FROM CTE_DimL
 WHERE RowNum > 1

 --To create SalesRetailFact Table feom Sales Retal Table
SELECT * INTO SalesRetailFact
FROM
 (SELECT Order_ID,Order_Date,Ship_Date,Customer_ID,Ship_Mode,Postal_Code,Product_ID,Retail_Sales_People,Returned,Sales,Quantity,Discount,Profit FROM [Sales Retail])
 AS SRF
 SELECT * FROM SalesRetailFact

 -- Duplicates are not meant to be removed from Facts Table

 -- To create a serrogate Key ProductKey that will serve as the unique identifier of the DimProduct Table

 ALTER TABLE DimProduct
 ADD ProductKey INT IDENTITY (1,1) PRIMARY KEY

  -- To add Nd update the unique identifier of the DimProduct Table to the SalesRetailFact Table

 ALTER TABLE SalesRetailFact
 ADD ProductKey INT

 UPDATE SalesRetailFact
 SET ProductKey = DimProduct.ProductKey
 FROM SalesRetailFact
 JOIN DimProduct
 ON SalesRetailFact.Product_ID = DimProduct.Product_ID

--To drop the column Product_ID the DimProduct Table and SalesRetailFact Table
 ALTER TABLE SalesRetailFact
 DROP COLUMN Product_ID

  ALTER TABLE DimProduct
 DROP COLUMN Product_ID

  -- To create a serrogate Key Row_ID that will serve as the unique identifier of the DimProduct Table

  ALTER TABLE SalesRetailFact
 ADD ROW_ID INT IDENTITY (1,1) 


 --Project Expository Analysis
--1. What was the Average delivery days for different product subcategory?

SELECT dp.Sub_Category,AVG( DATEDIFF(DAY,srf.Order_Date,srf.Ship_Date)) AS AvgDiliveryDays
FROM SalesRetailFact AS srf
LEFT JOIN DimProduct AS dp
ON
srf.ProductKey = dp.ProductKey
GROUP BY Sub_Category
ORDER BY AvgDiliveryDays DESC

/* It takes Averagely 36 Days to get Table Products deliverd to Customers
35 Days for Furnishings and 32 Days for both Chairs and Bookcases Product respectively to be deliverd to Customer*/

--2. What was the Average delivery days for each segment ?

SELECT dc.Segment,AVG( DATEDIFF(DAY,srf.Order_Date,srf.Ship_Date)) AS AvgDiliveryDays
FROM SalesRetailFact AS srf
LEFT JOIN DimCustomer AS dc
ON
srf.Customer_ID = dc.Customer_ID
GROUP BY Segment
ORDER BY AvgDiliveryDays DESC

/* It takes an Average delivery days of 35 days to get products delivered to the Coporate Segemrnt 
and an Average of 34 and 31 days to get products delivered to the Consumer and Home Office Segments respectively*/

--3.What are the Top 5 Fastest delivered products and Top 5 slowest delivered products?

SELECT	TOP 5( dp.Product_Name), DATEDIFF(DAY,srf.Order_Date,srf.Ship_Date) AS DiliveryDays
FROM SalesRetailFact AS srf
LEFT JOIN DimProduct AS dp
ON
srf.ProductKey = dp.ProductKey
ORDER BY DiliveryDays 

/* The Top 5 Fastest delivered products are
Sauder Camden County Barrister Bookcase, Planked Cherry Finish
Sauder Inglewood Library Bookcases
O'Sullivan 2-Shelf Heavy-Duty Bookcases
O'Sullivan Plantations 2-Door Library in Landvery Oak
O'Sullivan Plantations 2-Door Library in Landvery Oak 
and are all dilivered within a day.*/

SELECT	TOP 5( dp.Product_Name), DATEDIFF(DAY,srf.Order_Date,srf.Ship_Date) AS DiliveryDays
FROM SalesRetailFact AS srf
LEFT JOIN DimProduct AS dp
ON
srf.ProductKey = dp.ProductKey
ORDER BY DiliveryDays DESC

/* The Top 5  products with Slow Delivery rates which took 214 days to be delivered to customers are;
Bush Mission Pointe Library
Hon Multipurpose Stacking Arm Chairs
Global Ergonomic Managers Chair
Tensor Brushed Steel Torchiere Floor Lamp
Howard Miller 11-1/2" Diameter Brentwood Wall Clock */

--4. Which product Subcategory generate most profit?

SELECT dp.Sub_Category,ROUND(SUM(srf.Profit),2) AS TotalProfit
FROM SalesRetailFact AS srf
LEFT JOIN DimProduct AS dp
ON
srf.ProductKey = dp.ProductKey
WHERE srf.Profit > 0
GROUP BY dp.Sub_Category
ORDER BY TotalProfit DESC
/* The Subcategory Chair generated the highest profit of $36,471.1 and 
the least profit comes from the  Subcategory tables */

--5. Which segment generates the most profit?

SELECT dc.Segment,ROUND (SUM(srf.Profit),2) AS TotlProfit
FROM SalesRetailFact AS srf
LEFT JOIN DimCustomer AS dc
ON
srf.Customer_ID = dc.Customer_ID
WHERE srf.Profit > 0
GROUP BY Segment
ORDER BY TotlProfit DESC

/* The Consumer segment generates the hightest profit of approximatly $35,427
 and 
the least profit comes from the customers in the Home office segment */


--6. Which Top 5 customers made the most profit?

SELECT	TOP 5( dc.Customer_Name), ROUND (SUM(srf.Profit),2) AS TotalProfit
FROM SalesRetailFact AS srf
LEFT JOIN DimCustomer AS dc
ON
srf.Customer_ID = dc.Customer_ID
WHERE srf.Profit > 0
GROUP BY dc.Customer_Name
ORDER BY TotalProfit DESC

/* Top 5 customers making the most profit for the firm are;
Laura Armstrong
Joe Elijah
Seth Vernon
Quincy Jones
Maria Etezadi
*/

--7. What is the total number of products by Subcategory

SELECT Sub_Category, COUNT (Product_Name) AS TotalProduct
FROM DimProduct
GROUP BY Sub_Category
ORDER BY TotalProduct DESC

/* The Furnishing Subcategory has a total of 186 products which is the Subcategory with the highest products 
while Chairs Subcategory has 87 products, Bookcases Subcategory has 48 products and 
Tables Subcategory has a total of 34 profucts */