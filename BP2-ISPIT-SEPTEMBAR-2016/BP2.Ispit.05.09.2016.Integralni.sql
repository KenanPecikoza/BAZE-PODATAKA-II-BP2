CREATE DATABASE INTERGRALNI20192016
GO

USE INTERGRALNI20192016 

CREATE TABLE Narudzba(
	NarudzbaID INT CONSTRAINT PK_NarudzbaID PRIMARY KEY,
	Kupac NVARCHAR(40),
	PunaAdresa NVARCHAR(80),
	DatumNarudzbe DATE, 
	Prevoz MONEY,
	Uposlenik NVARCHAR(40),
	GradUposlenika NVARCHAR(30),
	DatumUposlenja DATE,
	BtGodStaza INT
)

CREATE TABLE Proizvod(
	ProizvodID INT CONSTRAINT PK_ProizvodID PRIMARY KEY,
	NazivProizvoda NVARCHAR(40),
	NazivDobavljaca NVARCHAR(40),
	StanjeNaSklad INT,
	NarucenaKol INT 	
)

CREATE TABLE DetaljiNarudzbe(
	NarudzbaID INT CONSTRAINT FK_NarudzbaID FOREIGN KEY REFERENCES Narudzba(NarudzbaID),
	ProizvodID INT CONSTRAINT FK_ProizvodID	FOREIGN KEY REFERENCES Proizvod(ProizvodID),
	CijenaProizvoda money,
	Kolicina INT NOT NULL,
	Popust REAL,
	CONSTRAINT PK_DetaljiNarudzbe PRIMARY KEY (NarudzbaID,ProizvodID)
)

INSERT INTO Narudzba
SELECT O.OrderID,C.CompanyName,C.Address+' - '+C.PostalCode+' - '+C.City,O.OrderDate,O.Freight,
	E.FirstName+' '+E.LastName,E.City,HireDate, DATEDIFF(YEAR,HireDate,GETDATE())
FROM NORTHWND.dbo.Orders AS O JOIN NORTHWND.dbo.Customers AS C 
	ON O.CustomerID=C.CustomerID JOIN NORTHWND.dbo.Employees AS E
	ON E.EmployeeID=O.EmployeeID

INSERT INTO Proizvod
SELECT P.ProductID, P.ProductName,S.CompanyName,P.UnitsInStock,P.UnitsOnOrder
FROM NORTHWND.dbo.Products AS P INNER JOIN NORTHWND.dbo.Suppliers AS S
	ON S.SupplierID =P.SupplierID

INSERT INTO DetaljiNarudzbe
SELECT OrderID,ProductID,FLOOR(UnitPrice), Quantity,Discount
FROM NORTHWND.dbo.[Order Details] 

ALTER TABLE Narudzba
ADD SifraUposlenika NVARCHAR(20) CONSTRAINT CH_SifraUposlenika CHECK(LEN(SifraUposlenika)=15)

UPDATE Narudzba
SET SifraUposlenika= LEFT(REVERSE(GradUposlenika+ ' ' + CAST(DatumUposlenja as NVARCHAR)),15)

ALTER TABLE Narudzba
DROP CONSTRAINT CH_SifraUposlenika

UPDATE Narudzba
SET SifraUposlenika= LEFT(NEWID(),20)
WHERE GradUposlenika LIKE '%d'

select * from Narudzba
GO

CREATE VIEW Zadatak4 AS
SELECT  N.Uposlenik,N.SifraUposlenika,COUNT(P.NazivProizvoda) as 'Ukupan broj proizvoda'
FROM Narudzba AS N INNER JOIN DetaljiNarudzbe AS DN 
	ON N.NarudzbaID=DN.NarudzbaID INNER JOIN Proizvod AS P
	ON P.ProizvodID=DN.ProizvodID
WHERE LEN(N.SifraUposlenika)=20 
GROUP BY N.Uposlenik,N.SifraUposlenika
HAVING  COUNT(P.NazivProizvoda)>2

GO

CREATE PROC ZADATAK5
AS 
BEGIN
UPDATE Narudzba
SET SifraUposlenika= LEFT(NEWID(),4)
WHERE LEN(SifraUposlenika)=20
END

EXEC ZADATAK5
GO

CREATE VIEW ZADATAK6
AS
SELECT NazivProizvoda, ROUND(SUM(DE.CijenaProizvoda*Kolicina *(1-DE.Popust)),2) AS Ukupno
FROM Proizvod AS P JOIN DetaljiNarudzbe AS DE
	ON P.ProizvodID=DE.ProizvodID
WHERE	P.NarucenaKol > 0
GROUP BY NazivProizvoda
HAVING SUM(DE.CijenaProizvoda*Kolicina *(1-DE.Popust))>10000
GO

SELECT *
FROM ZADATAK6
ORDER BY ZADATAK6.Ukupno DESC

GO
CREATE VIEW ZADATAK7a
AS
SELECT N.Kupac,P.NazivProizvoda, SUM(DE.CijenaProizvoda) AS 'Suma po cijeni'
FROM Narudzba as N INNER JOIN DetaljiNarudzbe AS DE
	ON DE.NarudzbaID=N.NarudzbaID INNER JOIN Proizvod AS P
	ON DE.ProizvodID=P.ProizvodID
WHERE  DE.CijenaProizvoda>(SELECT AVG(CijenaProizvoda)
								FROM DetaljiNarudzbe)
GROUP BY  N.Kupac,P.NazivProizvoda

SELECT *
FROM ZADATAK7a
ORDER BY 3

GO

CREATE PROC ZADATAK7b(
	@Kupac nvarchar(50) =null,
	@NazivProizvoda nvarchar(50)= null,
	@Suma MONEY= null
)
AS 
BEGIN
SELECT *
FROM ZADATAK7a AS Z
WHERE Z.[Suma po cijeni]>(SELECT AVG([Suma po cijeni]) FROM ZADATAK7a)
	AND( Kupac=@Kupac
	OR NazivProizvoda=@NazivProizvoda
	OR [Suma po cijeni]=@Suma)
ORDER BY [Suma po cijeni] DESC
END

GO


EXEC ZADATAK7b @Kupac='Hanari Carnes'

EXEC ZADATAK7b @Suma=123

EXEC ZADATAK7b @NazivProizvoda = 'Côte de Blaye'


CREATE NONCLUSTERED INDEX ZADATAK9 
ON Proizvod(
	NazivDobavljaca ASC
)
INCLUDE (
	StanjeNaSklad,NarucenaKol
)

SELECT * FROM Proizvod
WHERE NazivDobavljaca = 'Pavlova, Ltd.' AND StanjeNaSklad > 10 AND NarucenaKol < 10


ALTER INDEX ZADATAK9 ON Proizvod
DISABLE

BACKUP DATABASE INTERGRALNI20192016
TO DISK ='Ispit_2019_06_24.bak'

GO 

CREATE PROC ZADATAK10
AS
BEGIN
DROP VIEW dbo.Zadatak4
DROP VIEW dbo.ZADATAK6
DROP VIEW dbo.ZADATAK7a
DROP PROC dbo.ZADATAK5
DROP PROC dbo.ZADATAK7b
END



EXEC ZADATAK10