CREATE DATABASE IB170078INTERGALNIPRIMJER
GO

USE IB170078INTERGALNIPRIMJER
GO

CREATE TABLE Studenti(
	StudentiID INT IDENTITY(1,1) CONSTRAINT PK_StudentiID PRIMARY KEY,
	BrojDosijea NVARCHAR(10) CONSTRAINT UQ_BrojDosijea UNIQUE NOT NULL,
	Ime NVARCHAR(35) NOT NULL,
	Prezime NVARCHAR(35) NOT NULL,
	GodinaStudija INT NOT NULL,
	NacinStudiranja NVARCHAR(10) CONSTRAINT DF_NacinStudiranja DEFAULT('Redovan'),
	Email NVARCHAR(50),
)

CREATE TABLE Predmeti(
	PredmetiID INT IDENTITY(1,1) CONSTRAINT PK_PredmetiID PRIMARY KEY,
	Naziv NVARCHAR(100) NOT NULL,
	Oznaka NVARCHAR(10) CONSTRAINT UQ_Oznaka UNIQUE NOT NULL,
)

CREATE TABLE Ocjene(
	PredmetiID INT CONSTRAINT FK_PredmetiID REFERENCES Predmeti(PredmetiID),
	StudentiID INT CONSTRAINT FK_StudentiID REFERENCES Studenti(StudentiID),
	Ocjena INT NOT NULL,
	Bodovi INT NOT NULL,
	DatumPolaganja DATE NOT NULL
	CONSTRAINT PK_OCJENE PRIMARY KEY(PredmetiID,StudentiID)
)

INSERT INTO Predmeti
VALUES ('Matematika','MM'),('Programiranje1','PRI'),('Programiranje2','PRII')

INSERT INTO Studenti (BrojDosijea,Ime,Prezime,GodinaStudija,Email)
SELECT	C.AccountNumber,P.FirstName,P.LastName,2,E.EmailAddress
FROM AdventureWorks2014.Person.Person AS P JOIN AdventureWorks2014.Person.EmailAddress AS E
	ON P.BusinessEntityID=E.BusinessEntityID JOIN AdventureWorks2014.Sales.Customer AS C
	ON C.PersonID=P.BusinessEntityID
GO

CREATE PROC ZADATAK3
 @PredmetiID INT ,
 @StudentiID INT ,
 @Ocjena INT ,
 @Bodovi INT 
 AS 
 BEGIN 
 INSERT INTO Ocjene
 VALUES(@PredmetiID,@StudentiID,@Ocjena,@Bodovi,GETDATE())
 END



 EXEC ZADATAK3 1,1,8,80

 EXEC ZADATAK3 2,1,8,80

 EXEC ZADATAK3 3,1,8,80

 EXEC ZADATAK3 1,2,8,80

 EXEC ZADATAK3 2,5,7,70

 SELECT * FROM Ocjene

GO

--UBACITI TABELE POMOĆU GUIA


CREATE NONCLUSTERED INDEX  ZADATAK9 
ON Person.Person(
	LastName,
	FirstName
)
INCLUDE(
	Title
)
GO


SELECT FirstName,LastName,Title  
FROM Person.Person
WHERE Title LIKE 'Mr.'

ALTER INDEX ZADATAK9 ON Person.Person
DISABLE

GO

CREATE CLUSTERED INDEX ZADATAK5e
ON Sales.CreditCard (
	CreditCardID
)

CREATE NONCLUSTERED INDEX ZADATAK5d
ON Sales.CreditCard (
	ExpMonth,
	ExpYear
)
GO

CREATE VIEW ZADATAK6
AS 
SELECT LastName,FirstName,CardNumber,CardType
FROM Person.Person AS P JOIN Sales.PersonCreditCard AS PCC
	ON PCC.BusinessEntityID=P.BusinessEntityID JOIN Sales.CreditCard AS CC
	ON CC.CreditCardID=PCC.CreditCardID
WHERE CardType LIKE 'Vista'
GO

BACKUP DATABASE IB170078INTERGALNIPRIMJER 
TO DISK ='IB170078INTERGALNIPRIMJER.bak'

go

CREATE PROC ZADATAK9A
	@Ime NVARCHAR(30)=NULL,
	@Prezime NVARCHAR(30)=NULL,
	@BrojKartice NVARCHAR(25)=NULL
AS
BEGIN
SELECT *
FROM ZADATAK6
WHERE ((LastName=@Prezime ) 
	OR(LastName=@Prezime AND FirstName=@Ime)
	OR(LastName=@Prezime AND FirstName=@Ime AND CardNumber=@BrojKartice))
	OR( ISNULL(@Ime, '') ='' AND ISNULL(@Prezime, '') =''  AND ISNULL(@BrojKartice, '') ='' )
END

EXEC ZADATAK9A @Prezime='Acevedo',@Ime='Humberto',@BrojKartice='11119140395645'
EXEC ZADATAK9A @Prezime='Adams',@Ime ='Carla'
EXEC ZADATAK9A


drop proc ZADATAK9A

GO

CREATE PROC BRISANJE
	@BrojKartice NVARCHAR(25)=NULL

AS
BEGIN
DELETE FROM Sales.PersonCreditCard 
	FROM  Sales.PersonCreditCard AS PCC JOIN Sales.CreditCard AS CC
		ON	PCC.CreditCardID=CC.CreditCardID
	WHERE CC.CardNumber=@BrojKartice

DELETE FROM Sales.CreditCard
	WHERE CardNumber=@BrojKartice
END

EXEC  BRISANJE '11117010076386'

SELECT * 
FROM Sales.CreditCard AS CC JOIN Sales.PersonCreditCard AS PCC
	ON PCC.CreditCardID=CC.CreditCardID

SELECT * FROM Sales.PersonCreditCard

USE master
GO
DROP DATABASE IB170078INTERGALNIPRIMJER