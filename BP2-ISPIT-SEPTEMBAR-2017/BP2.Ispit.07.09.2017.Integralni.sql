CREATE DATABASE IB170078I09Septembar2017

USE IB170078I09Septembar2017

CREATE TABLE Klijenti (
	KlijentiID INT IDENTITY(1,1) CONSTRAINT PK_KlijentiID PRIMARY KEY,
	Ime nvarchar(50) NOT NULL,
	Prezime nvarchar(50) NOT NULL,
	Grad nvarchar(50) NOT NULL,
	Email nvarchar(50) NOT NULL,
	Telefon nvarchar(50) NOT NULL,
)

CREATE TABLE Racuni (
	RacuniID INT IDENTITY(1,1) CONSTRAINT PK_Klijenti PRIMARY KEY ,
	KlijentiID INT CONSTRAINT FK_KlijentiID FOREIGN KEY REFERENCES Klijenti(KlijentiID),
	DatumOtvaranja DATE  NOT NULL,
	TipRacuna nvarchar(50) NOT NULL,
	BrojRacuna nvarchar(16) NOT NULL,
	Stanje decimal(18,2) NOT NULL,

)

CREATE TABLE Transakcije (
	TransakcijeID INT IDENTITY(1,1) CONSTRAINT PK_TransakcijeID PRIMARY KEY,
	RacuniID INT CONSTRAINT FK_RacuniID FOREIGN KEY REFERENCES Racuni(RacuniID),
	Datum DATE NOT NULL,
	Primatelj nvarchar(50) NOT NULL,
	BrojRacunaPrimatelja nvarchar(50) NOT NULL,
	MjestoPrimatelja nvarchar(50) NOT NULL,
	AdresaPrimatelja nvarchar(50) NOT NULL,
	Svrha nvarchar(200),
	Iznos DECIMAL(18,2) NOT NULL
)

CREATE UNIQUE NONCLUSTERED INDEX XI_Email
ON Klijenti(Email)
GO

CREATE UNIQUE NONCLUSTERED INDEX XI_BrojRacuna
ON Racuni(BrojRacuna)
GO

CREATE PROC UnosRacuna
	@KlijentiID int,
	@TipRacuna nvarchar(50),
	@BrojRacuna nvarchar(16),
	@Stanje decimal(18,2)
AS 
BEGIN
INSERT INTO Racuni
VALUES(@KlijentiID,GETDATE(),@TipRacuna,@BrojRacuna,@Stanje)
END
GO


INSERT INTO Klijenti
SELECT DISTINCT SUBSTRING(C.ContactName,0,CHARINDEX(' ',C.ContactName))AS IME,
	SUBSTRING(C.ContactName,CHARINDEX(C.ContactName,' '),LEN(C.ContactName)),
	C.City, SUBSTRING(C.ContactName,0,CHARINDEX(' ',C.ContactName))+'.'+
	SUBSTRING(C.ContactName,CHARINDEX(' ',C.ContactName)+1,LEN(C.ContactName))+'@nortwind.ba',
	C.Phone
FROM NORTHWND.dbo.Customers AS C JOIN NORTHWND.dbo.Orders AS O
	ON C.CustomerID =O.CustomerID
WHERE YEAR(O.OrderDate)=1996

SELECT * FROM Klijenti


EXEC UnosRacuna 5,'DEVIZNI','1123089',120.2

EXEC UnosRacuna 5,'STEDNI','1223089',1120.2


EXEC UnosRacuna 6,'DEVIZNI','1231244',1122.4

EXEC UnosRacuna 55,'DEVIZNI','12231244',1122.4

EXEC UnosRacuna 55,'DEVIZNI','212231244',1222.4

EXEC UnosRacuna 22,'DEVIZNI','12237244',11242.4

EXEC UnosRacuna 15,'DEVIZNI','15231244',11222.4

EXEC UnosRacuna 35,'DEVIZNI','122344',10122.4

EXEC UnosRacuna 32,'DEVIZNI','1223124',11202.4

EXEC UnosRacuna 14,'DEVIZNI','1223244',11122.4

INSERT INTO Transakcije(RacuniID,Datum,Primatelj,BrojRacunaPrimatelja,MjestoPrimatelja,AdresaPrimatelja,Svrha,Iznos)
SELECT TOP 10 11,O.OrderDate,O.ShipName,
	CAST(O.OrderID AS NVARCHAR(20))+'00000123456',
	O.ShipCity,O.ShipAddress,NULL,OD.Quantity*OD.UnitPrice
FROM NORTHWND.dbo.Orders AS O JOIN NORTHWND.dbo.[Order Details] AS OD
	ON OD.OrderID=O.OrderID
ORDER BY NEWID()

SELECT *
FROM Klijenti AS K JOIN Racuni AS R
	ON K.KlijentiID=R.KlijentiID



UPDATE Racuni
SET Stanje+=500
FROM Racuni AS R JOIN Klijenti AS K
	ON K.KlijentiID=R.KlijentiID
WHERE K.Grad = 'Reims' AND MONTH(R.DatumOtvaranja)=6
GO

CREATE VIEW ZADATAK6
AS
	SELECT Ime+' '+Prezime AS 'Ime i prezime',Grad,Email,Telefon,R.TipRacuna,R.BrojRacuna,R.Stanje,
		T.Primatelj,T.BrojRacunaPrimatelja,T.Iznos
	FROM Klijenti AS K LEFT JOIN Racuni AS R 
		ON R.KlijentiID=K.KlijentiID LEFT JOIN Transakcije AS T
		ON T.RacuniID=R.RacuniID 

GO

CREATE PROC Zadatak7
	@BrojRacuna NVARCHAR(16) =NULL
AS 

SELECT [Ime i prezime],
	Grad,
	Telefon,
	ISNULL(BrojRacuna,'N/A'),
	ISNULL(CAST(Stanje AS nvarchar(50)),'N/A'),
	ISNULL(CAST(SUM(Iznos) AS nvarchar(50)),'N/A') AS [Ukupan iznos]
FROM ZADATAK6 as V
WHERE BrojRacuna=@BrojRacuna OR  @BrojRacuna IS NULL
GROUP BY [Ime i prezime],Grad,Telefon,BrojRacuna,Stanje

EXEC Zadatak7 '1223124'
EXEC Zadatak7
GO

CREATE PROC BrisanjeKlijenta 
	@KlijentiID int
as
BEGIN
	DELETE FROM T
	FROM Transakcije AS T JOIN Racuni AS R
		ON T.RacuniID=R.RacuniID
	WHERE R.KlijentiID=@KlijentiID

	DELETE FROM Racuni
	WHERE Racuni.KlijentiID=@KlijentiID

	DELETE FROM Klijenti 
	WHERE Klijenti.KlijentiID=@KlijentiID

END 

EXEC BrisanjeKlijenta 5
GO

CREATE PROC ZADATAK9
 @NazivGrada nvarchar(50),
 @Mjesec int,
 @Iznos decimal(18,2)
as
begin
UPDATE Racuni
SET Stanje+=@Iznos
FROM Racuni AS R JOIN Klijenti AS K
	ON K.KlijentiID=R.KlijentiID
WHERE K.Grad LIKE @NazivGrada AND MONTH(R.DatumOtvaranja)=@Mjesec
END

EXEC ZADATAK9 'Reims',6,20.2
GO

BACKUP DATABASE IB170078I09Septembar2017
TO DISK='D:\BP2\Backup\FullBack.bak'

BACKUP DATABASE IB170078I09Septembar2017
TO DISK='D:\BP2\Backup\FullBack.bak'
WITH DIFFERENTIAL

USE master
GO

DROP DATABASE IB170078I09Septembar2017

RESTORE DATABASE IB170078I09Septembar2017
FROM DISK ='D:\BP2\Backup\FullBack.bak'

USE IB170078I09Septembar2017

SELECT * FROM Klijenti









