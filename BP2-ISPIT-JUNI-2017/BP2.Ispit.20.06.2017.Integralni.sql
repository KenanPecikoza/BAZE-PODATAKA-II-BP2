
CREATE DATABASE IB170027
ON (NAME='Data' ,FILENAME='C:\BP2\Data.mdf')

LOG ON (NAME='Log' ,FILENAME='C:\BP2\Log.ldf')

USE IB170027
GO

CREATE TABLE Proizvodi
(
	ProizvodID INT IDENTITY(1,1) CONSTRAINT PK_ProizvodID PRIMARY KEY,
	Sifra NVARCHAR(25) NOT NULL CONSTRAINT UQ_Sifra UNIQUE,
	Naziv NVARCHAR(50) NOT NULL,
	Kategorija NVARCHAR(50) NOT NULL,
	Cijena DECIMAL(18,2) NOT NULL
)

CREATE TABLE Narudzbe
(
	NarudzbaID INT IDENTITY(1,1) CONSTRAINT PK_NarudzbaID PRIMARY KEY,
	BrojNarudzbe NVARCHAR(25) NOT NULL CONSTRAINT UQ_BrojNarudzbe UNIQUE,
	Datum DATE NOT NULL,
	Ukupno DECIMAL(18,2) NOT NULL
)

CREATE TABLE StavkeNarudzbe
(
	ProizvodID INT NOT NULL CONSTRAINT FK_ProizvodID FOREIGN KEY REFERENCES Proizvodi(ProizvodID),
	NarudzbaID INT NOT NULL CONSTRAINT FK_NarudzbaID FOREIGN KEY REFERENCES Narudzbe(NarudzbaID),
	CONSTRAINT PK_ProizvodID_NarudzbaID PRIMARY KEY(ProizvodID,NarudzbaID),
	Kolicina INT NOT NULL,
	Cijena DECIMAL(18,2) NOT NULL,
	Popust DECIMAL(18,2) NOT NULL,
	Iznos DECIMAL(18,2) NOT NULL
)

SET IDENTITY_INSERT Proizvodi ON
INSERT INTO Proizvodi(ProizvodID,Sifra,Naziv,Kategorija,Cijena)
SELECT DISTINCT P.ProductID,P.ProductNumber,P.Name,PC.Name,P.ListPrice
FROM AdventureWorks2014.Production.Product P INNER JOIN
	AdventureWorks2014.Production.ProductSubcategory PS
	ON P.ProductSubcategoryID=PS.ProductSubcategoryID
	INNER JOIN AdventureWorks2014.Production.ProductCategory PC
	ON PS.ProductCategoryID=PC.ProductCategoryID
	INNER JOIN AdventureWorks2014.Sales.SalesOrderDetail SOD
	ON P.ProductID=SOD.ProductID
	INNER JOIN AdventureWorks2014.Sales.SalesOrderHeader SOH
	ON SOD.SalesOrderID=SOH.SalesOrderID
WHERE YEAR(SOH.ShipDate)=2014
SET IDENTITY_INSERT Proizvodi OFF

SELECT * FROM Proizvodi

SET IDENTITY_INSERT Narudzbe ON
INSERT INTO Narudzbe(NarudzbaID,BrojNarudzbe,Datum,Ukupno)
SELECT SOH.SalesOrderID,SOH.SalesOrderNumber,SOH.OrderDate,SOH.TotalDue
FROM AdventureWorks2014.Sales.SalesOrderHeader SOH
WHERE YEAR(SOH.OrderDate)=2014
SET IDENTITY_INSERT Narudzbe OFF

SELECT * FROM Narudzbe

INSERT INTO StavkeNarudzbe
SELECT P.ProductID,SOD.SalesOrderID,SOD.OrderQty,SOD.UnitPrice,SOD.UnitPriceDiscount,SOD.LineTotal
FROM AdventureWorks2014.Sales.SalesOrderDetail SOD INNER JOIN AdventureWorks2014.Sales.SalesOrderHeader SOH
	ON SOD.SalesOrderID=SOH.SalesOrderID INNER JOIN AdventureWorks2014.Production.Product P
	ON SOD.ProductID=P.ProductID
WHERE YEAR(SOH.OrderDate)=2014

SELECT * FROM StavkeNarudzbe

CREATE TABLE Skladista
(
	SkladisteID INT IDENTITY(1,1) CONSTRAINT PK_SkladisteID PRIMARY KEY,
	Naziv NVARCHAR(50) NOT NULL
)

CREATE TABLE SkladistaProizvodi
(
	SkladisteID INT NOT NULL CONSTRAINT FK_SkladisteID_Skladiste FOREIGN KEY REFERENCES Skladista(SkladisteID),
	ProizvodID INT NOT NULL CONSTRAINT FK_ProizvodID_Skladiste FOREIGN KEY REFERENCES Proizvodi(ProizvodID),
	CONSTRAINT PK_SkladisteID_ProizvodID PRIMARY KEY(SkladisteID,ProizvodID),
	Kolicina INT NOT NULL
)

SELECT * FROM SkladistaProizvodi

INSERT INTO Skladista
VALUES ('Mostar'),('Sarajevo'),('Bugojno')

SELECT * FROM Skladista

INSERT INTO SkladistaProizvodi
SELECT 1,ProizvodID,0
FROM Proizvodi

INSERT INTO SkladistaProizvodi
SELECT 2,ProizvodID,0
FROM Proizvodi

INSERT INTO SkladistaProizvodi
SELECT 3,ProizvodID,0
FROM Proizvodi

GO
CREATE PROC IzmjenaStanja
	@ProizvodID int,@SkladisteID int,@Kolicina int
AS
BEGIN
	UPDATE SkladistaProizvodi
	SET Kolicina+=@Kolicina
	WHERE SkladisteID=@SkladisteID AND @ProizvodID=ProizvodID
END
GO	

EXEC IzmjenaStanja 707,1,200

SELECT * 
FROM SkladistaProizvodi
WHERE ProizvodID=707

CREATE NONCLUSTERED INDEX IX_Sif_Naziv
ON Proizvodi(Sifra,Naziv)

SELECT Sifra,Naziv
FROM Proizvodi
WHERE Sifra LIKE 'BB-7421'

GO
CREATE TRIGGER SprijeciBrisanje
ON Proizvodi
INSTEAD OF DELETE
AS
BEGIN
	PRINT 'Brisanje nije moguce'
	ROLLBACK;
END
GO

DELETE FROM Proizvodi
WHERE ProizvodID=707

GO
CREATE VIEW v1
AS
	SELECT P.Sifra,P.Naziv,P.Cijena,SUM(SN.Kolicina) AS Kolicina,SUM(SN.Cijena*SN.Kolicina) AS Zarada
	FROM Proizvodi P INNER JOIN StavkeNarudzbe SN
		ON P.ProizvodID=SN.ProizvodID
	GROUP BY P.Sifra,P.Naziv,P.Cijena
GO

SELECT * FROM v1

GO
CREATE PROC BySifra
	@Sifra nvarchar(25) = NULL
AS
BEGIN
	SELECT V.Kolicina,V.Zarada
	FROM v1 V
	WHERE V.Sifra=@Sifra OR @Sifra IS NULL
END
GO

EXEC BySifra 'HL-U509-R'
EXEC BySifra 

CREATE LOGIN student 
WITH PASSWORD='Password',
DEFAULT_DATABASE=[AdventureWorks2014]

CREATE USER aaa FOR LOGIN student
GRANT SELECT TO aaa

BACKUP DATABASE IB170027
TO DISK = 'C:\BP2\Backup\Back.bak'


BACKUP DATABASE IB170027
TO DISK = 'C:\BP2\Backup\Back.bak'
WITH DIFFERENTIAL

USE master
GO

DROP DATABASE IB170027