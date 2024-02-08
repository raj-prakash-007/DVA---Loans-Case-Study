CREATE DATABASE LOANS
USE LOANS
/*
====================================================TASK 1=======================================================================*/

--Q.1 Write a query to print all the databases available in the SQL Server. - 1Marks

SELECT NAME FROM
SYS.DATABASES

--Q.1 ENDS


--Q.2 Write a query to print the names of the tables from the Loans database. - 1Marks

USE LOANS
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE='BASE TABLE';

--Q.2 ENDS


--Q.3 Write a query to print 5 records in each table - 1Marks

SELECT TOP 5* FROM Customer_Data
SELECT TOP 5* FROM Home_Loan_Data
SELECT TOP 5* FROM Loan_Records_Data
SELECT TOP 5* FROM Banker_Data

--Q.3 ENDS

/*
======================================================TASK 2============================================================================*/

--Q. Find the average loan term for loans not for semi-detached and townhome property types, and are in the following list of
 --cities: Sparks, Biloxi, Waco, Las Vegas, and Lansing.  (2 Marks)

SELECT property_type,city, AVG_LOAN_TERM FROM (
			SELECT property_type,country,city, AVG(loan_term) AS AVG_LOAN_TERM FROM Home_Loan_Data
			WHERE property_type NOT IN ('SEMI-DETACHED', 'TOWNHOME')
			AND city IN ('SPARKS','BILOXI','WACO','LAS VEGAS','LANSING')
			GROUP BY property_type,country,city
			) AS X

--Q. Find the customer ID, first name, last name, and email of customers whose email address contains
--the term 'amazon'.  (1 Marks)

SELECT customer_id,first_name,last_name,email FROM Customer_Data
WHERE email LIKE '%AMAZON%'

--Q. Find the city name and the corresponding average property value (using appropriate alias) for cities 
--where the average property value is greater than $3,000,000.  (1 Marks)

SELECT city,AVG(property_value) AS AVG_PROPERTY_VALUE FROM Home_Loan_Data
GROUP BY city
HAVING AVG(property_value)>3000000

--Q. Find the names of the top 3 cities (based on descending alphabetical order) and corresponding loan 
--percent (in ascending order) with the lowest average loan percent.  (2 Marks)

SELECT  TOP 3 city,loan_percent,AVG(loan_percent)AS AVG_LOAN_PERCENT FROM Home_Loan_Data
GROUP BY city,loan_percent
ORDER BY city DESC,loan_percent ASC

--Q. Find the average age of male bankers (years, rounded to 1 decimal place) based on the date they joined WBG  (2 Marks)

SELECT ROUND(AVG(AVG_AGE),1) AS AVG_AGE FROM(
SELECT CONVERT (FLOAT,(DATEDIFF(YEAR,dob,date_joined))) AS AVG_AGE FROM Banker_Data
WHERE gender='MALE') AS X

--Q. Find the number of home loans issued in San Francisco.  (1 Marks)
SELECT COUNT(loan_id)AS NO_OF_HOME_LOANS FROM Home_Loan_Data
WHERE city='San Francisco'

--Q. Find the ID, first name, and last name of the top 2 bankers (and corresponding transaction count) involved
--in the highest number of distinct loan records.  (2 Marks)

SELECT  TOP 2 A.banker_id ,first_name,last_name,COUNT(DISTINCT loan_id)AS NO_OF_LOANS  FROM Loan_Records_Data AS A
INNER JOIN Banker_Data AS B
ON A.banker_id=B.banker_id
GROUP BY first_name,last_name,A.banker_id
ORDER BY NO_OF_LOANS DESC

--Q. Find the average age (at the point of loan transaction, in years and nearest integer) of female customers
--who took a non-joint loan for townhomes.  (2 Marks)

SELECT AVG(DATEDIFF(YEAR,dob,transaction_date)) AS AVG_AGE FROM Customer_Data AS A
INNER JOIN Loan_Records_Data AS B
ON A.customer_id=B.customer_id
INNER JOIN Home_Loan_Data AS C
ON B.loan_id=C.loan_id
WHERE gender='FEMALE'
AND property_type LIKE 'TOWN%'
AND joint_loan='NO'


--Q. Find the maximum property value (using appropriate alias) of each property type, ordered by the maximum 
--property value in descending order.  (1 Marks)

SELECT property_type,MAX(property_value) AS MAX_PROPERTY_VALUE FROM Home_Loan_Data
GROUP BY property_type
ORDER BY MAX_PROPERTY_VALUE DESC

--Q. Find the total number of different cities for which home loans have been issued.  (1 Marks)

SELECT COUNT(DISTINCT city) AS NO_OF_CITIES FROM Home_Loan_Data



/*              
===========================================================	TASK 3=======================================================================================*/

--Q.Create a stored procedure called `recent_joiners` that returns the ID, concatenated full name, date of birth,
--and join date of bankers who joined within the recent 2 years (as of 1 Sep 2022) Call the stored procedure
--`recent_joiners` you created above (5 Marks)

CREATE PROCEDURE recent_joiners 
AS
		SELECT banker_id,first_name+' '+last_name AS FULL_NAME,dob,date_joined FROM Banker_Data
		WHERE date_joined>='2020/09/01'

	EXEC recent_joiners 


--Q. Create a stored procedure called `city_and_above_loan_amt` that takes in two parameters (city_name, loan_amt_cutoff) 
--that returns the full details of customers with loans for properties in the input city and with loan amount 
--greater than or equal to the input loan amount cutoff.  

CREATE PROCEDURE CITY_AND_ABOVE_LOAN_AMOUNT @CITY VARCHAR(15),@LOAN_AMT_CUTOFF MONEY
AS
	
			SELECT A.customer_id,A.first_name,A.last_name,A.email,A.gender,A.phone,A.dob,A.customer_since,
			(property_value*loan_percent)/100 AS LOAN_AMT FROM Customer_Data AS A
			INNER JOIN Loan_Records_Data AS B
			ON A.customer_id=B.customer_id
			INNER JOIN Home_Loan_Data AS C
			ON B.loan_id=C.loan_id 
			WHERE city=@CITY
			AND (property_value*loan_percent)/100 >=@LOAN_AMT_CUTOFF

EXEC CITY_AND_ABOVE_LOAN_AMOUNT @CITY='SAN FRANCISCO' ,@LOAN_AMT_CUTOFF=1500000
			


--Q. Find the number of bankers involved in loans where the loan amount is greater than the average loan amount.  (3 Marks)

SELECT  COUNT(BANKER_ID) AS NO_OF_BANKERS FROM(
SELECT banker_id,(property_value*loan_percent)/100 AS LOAN_AMT FROM Loan_Records_Data AS A
INNER JOIN Home_Loan_Data AS B
ON A.loan_id=B.loan_id
WHERE (property_value*loan_percent)/100>(SELECT AVG((property_value*loan_percent)/100) FROM Home_Loan_Data)
) AS X


--Q. Find the ID and full name (first name concatenated with last name) of customers who were served by bankers aged below 
--30 (as of 1 Aug 2022).  (3 Marks)

SELECT C.CUSTOMER_ID ,C.FIRST_NAME+' '+C.LAST_NAME AS FULL_NAME FROM Banker_Data AS A
INNER JOIN Loan_Records_Data AS B
ON A.BANKER_ID=B.banker_id
INNER JOIN Customer_Data AS C
ON B.customer_id=C.customer_id
WHERE DATEDIFF(YEAR,A.DOB,'2022/08/01')<30


--Q. Find the number of Chinese customers with joint loans with property values less than $2.1 million, and served by female
--bankers. (3 Marks)
SELECT COUNT(D.customer_id) AS NO_OF_CHINESE_CUSTOMERS FROM Banker_Data AS A
INNER JOIN Loan_Records_Data AS B
ON A.banker_id=B.banker_id
INNER JOIN Home_Loan_Data AS C
ON B.loan_id=C.loan_id
INNER JOIN Customer_Data AS D
ON B.customer_id=D.customer_id
WHERE D.nationality LIKE 'CHIN%'
AND joint_loan='YES' 
AND property_value<2100000
AND A.gender LIKE 'FEM%'

--Q. Find the top 3 transaction dates (and corresponding loan amount sum) for which the sum of loan amount issued on that
--date is the highest.  (3 Marks)

SELECT  TOP 3 transaction_date,SUM((property_value*loan_percent)/100) AS LOAN_AMT FROM Home_Loan_Data AS A
INNER JOIN Loan_Records_Data AS B
ON A.loan_id=B.loan_id
GROUP BY transaction_date
ORDER BY LOAN_AMT

--Q. Create a view called `dallas_townhomes_gte_1m` which returns all the details of loans involving properties of townhome
--type, located in Dallas, and have loan amount of >$1 million. (3 Marks)


CREATE VIEW DALLAS_TOWNHOMES_GTE_1M
AS 
		SELECT C.customer_id,A.loan_id,B.banker_id,C.first_name,C.last_name,C.email,C.phone,C.dob,C.customer_since,C.nationality FROM Home_Loan_Data AS A
		INNER JOIN Loan_Records_Data AS B
		ON A.loan_id=B.loan_id
		INNER JOIN Customer_Data AS C
		ON B.customer_id=C.customer_id
		WHERE property_type LIKE 'TOWNHOME%'
		AND 
		CITY LIKE 'DALLA%'
		AND (property_value*loan_percent)/100>1000000

SELECT * FROM DALLAS_TOWNHOMES_GTE_1M


--Q. Find the ID, first name and last name of customers with properties of value between $1.5 and $1.9 million, along with a new column 
--'tenure' that categorizes how long the customer has been with WBG. 

SELECT A.customer_id,A.first_name,A.last_name,C.property_value,
CASE 
	WHEN customer_since < '2015/01/01' THEN 'Long'
	WHEN customer_since BETWEEN '2015/01/01' AND '2019/01/01' THEN 'Mid'
	ELSE 'Short'
	END AS TENURE
FROM Customer_Data AS A
INNER JOIN Loan_Records_Data AS B
ON A.customer_id=B.customer_id
INNER JOIN Home_Loan_Data AS C
ON B.loan_id=C.loan_id
WHERE property_value BETWEEN 1500000 AND 1900000


--Q. Find the sum of the loan amounts ((i.e., property value x loan percent / 100) for each banker ID, excluding properties
--based in the cities of Dallas and Waco. The sum values should be rounded to nearest integer.  (3 Marks)


SELECT banker_id,CAST(SUM((property_value*loan_percent)/100)AS INT) AS TOTAL_LOAN_AMT FROM Home_Loan_Data AS A
INNER JOIN Loan_Records_Data AS B
ON A.loan_id=B.loan_id
WHERE city NOT IN ('DALLAS','WACO')
GROUP BY banker_id

