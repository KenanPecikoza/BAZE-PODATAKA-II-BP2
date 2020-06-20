CREATE DATABASE IB170027
--ON(NAME=,FILENAME='.../.mdf',SIZE=,MAXSIZE=,FILEGROWTH=)
--LOG ON(NAME=,FILENAME='.../.ldf',SIZE=,MAXSIZE=,FILEGROWTH=)

USE IB170027
GO

CREATE TABLE Klijenti
(
	KlijentID INT IDENTITY(1,1) CONSTRAINT PK_KlijentID PRIMARY KEY,
	Ime NVARCHAR(50) NOT NULL,
	Prezime NVARCHAR(50) NOT NULL,
	Drzava NVARCHAR(50) NOT NULL,
	Grad NVARCHAR(50) NOT NULL,
	Email NVARCHAR(50) NOT NULL,
	Telefon NVARCHAR(50) NOT NULL,
)

CREATE TABLE Izleti
(
	IzletID INT IDENTITY(1,1) CONSTRAINT PK_IzletID PRIMARY KEY,
	Sifra NVARCHAR(10) NOT NULL,
	Naziv NVARCHAR(100) NOT NULL,
	DatumPolaska DATE NOT NULL,
	DatumPovratka DATE NOT NULL,
	Cijena DECIMAL(18,2) NOT NULL,
	Opis NVARCHAR(MAX) NULL
)

CREATE TABLE Prijave
(
	KlijentID INT NOT NULL CONSTRAINT FK_KlijentID FOREIGN KEY REFERENCES Klijenti(KlijentID),
	IzletID INT NOT NULL CONSTRAINT FK_IzletID FOREIGN KEY REFERENCES Izleti(IzletID),
	CONSTRAINT PK_KlijentID_IzletID PRIMARY KEY(KlijentID,IzletID),
	Datum DATETIME NOT NULL,
	BrojOdraslih INT NOT NULL,
	BrojDjece INT NOT NULL
)

--CREATE TYPE NekiTip
--FROM INT NOT NULL

INSERT INTO Klijenti
SELECT P.FirstName,P.LastName,CR.CountryRegionCode,A.City,EA.EmailAddress,PP.PhoneNumber
FROM AdventureWorks2014.Person.Person P INNER JOIN AdventureWorks2014.Person.BusinessEntity BE
	ON P.BusinessEntityID=BE.BusinessEntityID
	INNER JOIN AdventureWorks2014.Person.BusinessEntityAddress BEA
	ON BE.BusinessEntityID=BEA.BusinessEntityID
	INNER JOIN AdventureWorks2014.Person.Address A
	ON BEA.AddressID=A.AddressID 
	INNER JOIN AdventureWorks2014.Person.StateProvince SP
	ON A.StateProvinceID=SP.StateProvinceID
	INNER JOIN AdventureWorks2014.Person.CountryRegion CR
	ON SP.CountryRegionCode=CR.CountryRegionCode
	INNER JOIN AdventureWorks2014.Person.EmailAddress EA
	ON P.BusinessEntityID=EA.BusinessEntityID
	INNER JOIN AdventureWorks2014.Person.PersonPhone PP
	ON P.BusinessEntityID=PP.BusinessEntityID
	INNER JOIN AdventureWorks2014.HumanResources.Employee E
	ON P.BusinessEntityID=E.BusinessEntityID
WHERE E.JobTitle LIKE '%Sales%'

SELECT * FROM Klijenti

INSERT INTO Izleti
VALUES ('1235','Izlet1','20190801','2019-10-01',50.00,NULL),
		('5325','Izlet2','1/10/2019','15/10/2019',70.40,'opis'),
		('5355','Izlet3','20/12/2018','01/01/2019',220.50,NULL)

SELECT * FROM Izleti

GO
CREATE PROC UnosPrijave
	@Klijent int,@Izlet int,@BrojOdraslih int,@BrojDjece int
AS
BEGIN
	INSERT INTO Prijave
	VALUES(@Klijent,@Izlet,GETDATE(),@BrojOdraslih,@BrojDjece)
END

EXEC UnosPrijave 1,2,12,20
EXEC UnosPrijave 1,8,125,203
EXEC UnosPrijave 1,9,53,26
EXEC UnosPrijave 2,9,47,275
EXEC UnosPrijave 4,2,472,20
EXEC UnosPrijave 6,8,152,720
EXEC UnosPrijave 7,9,152,270
EXEC UnosPrijave 8,8,12,207
EXEC UnosPrijave 8,2,6,25
EXEC UnosPrijave 10,8,12,20

SELECT * FROM Prijave

CREATE UNIQUE NONCLUSTERED INDEX IX_Email
ON Klijenti(Email)

INSERT INTO Klijenti
VALUES('Ajdin','Catic','BIH','Mostar','brian3@adventure-works.com','2314145')

UPDATE Izleti
SET Cijena-=Cijena*0.10
FROM Izleti I
WHERE 3<(SELECT COUNT(IzletID)
		FROM Prijave 
		WHERE I.IzletID=IzletID)

GO
CREATE VIEW PodaciIzlet
AS
SELECT I.Sifra,I.Naziv,CONVERT(NVARCHAR,I.DatumPolaska,104) AS DatumPolaska,CONVERT(NVARCHAR,I.DatumPovratka,104) AS DatumPovratka,I.Cijena,
		COUNT(P.IzletID) AS BrojPrijava,SUM(P.BrojDjece+P.BrojOdraslih)AS 'Ukupan broj putnika',
		SUM(P.BrojDjece) AS 'Ukupan broj djece',SUM(P.BrojOdraslih) AS 'Ukupan broj odraslih'
FROM Izleti I INNER JOIN Prijave P
	ON I.IzletID=P.IzletID
GROUP BY I.IzletID,I.Sifra,I.Naziv,CONVERT(NVARCHAR,I.DatumPolaska,104),CONVERT(NVARCHAR,I.DatumPovratka,104),I.Cijena
GO

SELECT * FROM PodaciIzlet

GO
CREATE PROC PrikazZarade
	@sifra nvarchar(10)
AS
BEGIN
	SELECT I.Naziv,SUM(I.Cijena * P.BrojOdraslih) AS 'Zarada od odraslih',SUM(I.Cijena*P.BrojDjece) AS 'Zarada od dijece',
			SUM(I.Cijena*P.BrojDjece)-SUM(I.Cijena*P.BrojDjece)*0.5 AS 'Popust za djecu',
			(SUM(I.Cijena * P.BrojOdraslih)+SUM(I.Cijena*P.BrojDjece)) AS 'Ukupna zarada'
	FROM Izleti I INNER JOIN Prijave P
		ON I.IzletID=P.IzletID
	WHERE I.Sifra=@sifra
	GROUP BY I.IzletID,I.Naziv
END

EXEC PrikazZarade '1235'

CREATE TABLE IzletHistorijaCijena
(
	IzletID INT NOT NULL,
	DatumIzmjene DATETIME NOT NULL,
	StaraCijena DECIMAL(18,2) NOT NULL,
	NovaCijena DECIMAL(18,2) NOT NULL
)

SELECT * FROM IzletHistorijaCijena

GO
CREATE TRIGGER trig_PracenjePromjena
ON Izleti
AFTER UPDATE AS
BEGIN
	INSERT INTO IzletHistorijaCijena
	SELECT Iz.IzletID,GETDATE(),D.Cijena,I.Cijena
	FROM Izleti Iz INNER JOIN inserted I
		ON Iz.IzletID=I.IzletID 
		INNER JOIN deleted D
		ON Iz.IzletID=D.IzletID
END

SELECT I.Naziv,I.DatumPolaska,I.DatumPovratka,I.Cijena,IHC.DatumIzmjene,IHC.StaraCijena,IHC.NovaCijena
FROM Izleti I INNER JOIN IzletHistorijaCijena IHC
	ON I.IzletID=IHC.IzletID
WHERE I.IzletID=8

DELETE FROM Prijave
FROM Klijenti K LEFT JOIN Prijave P
	ON K.KlijentID=P.KlijentID
WHERE P.KlijentID IS NULL

DELETE FROM Klijenti
WHERE KlijentID NOT IN(SELECT P.KlijentID
						FROM Prijave P)

SELECT * FROM Klijenti

BACKUP DATABASE IB170027
TO DISK = 'C:\BP2\Backup\FulBak.bak'


BACKUP DATABASE IB170027
TO DISK = 'C:\BP2\Backup\FulBak.bak'
WITH DIFFERENTIAL

GO
USE master
GO

DROP DATABASE IB170027