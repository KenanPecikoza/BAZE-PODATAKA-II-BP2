USE master

CREATE DATABASE IB170078
go
use IB170078
go

CREATE TABLE Autori(
	AutoriID NVARCHAR (11) CONSTRAINT PK_AutoriID PRIMARY KEY,
	Prezime NVARCHAR(25) NOT NULL,
	Ime NVARCHAR(25) NOT NULL,
	ZipKod NVARCHAR(5) NULL,
	DatumKreiranjaZapisa DATE NOT NULL CONSTRAINT DF_DatumKreirA DEFAULT(GETDATE()),
	DatummModifikovanjaZapisa DATE NULL, 
)

CREATE TABLE Izdavaci(
	IzdavaciID NVARCHAR(4) CONSTRAINT PK_Izdavaci PRIMARY KEY,
	Nazvi NVARCHAR(100) NOT NULL CONSTRAINT UQ_Naziv UNIQUE,
	Biljeske NVARCHAR(1000) CONSTRAINT DF_BiljeskeI DEFAULT('Lorem ipsum'),
	DatumKreiranjaZapisa DATE NOT NULL CONSTRAINT DF_DatumKreirI DEFAULT(GETDATE()),
	DatumModifikovanjaZapisa DATE NULL,	
)

CREATE TABLE Naslovi(
	NasloviID NVARCHAR(6) CONSTRAINT PK_NasloviID PRIMARY KEY,
	IzdavaciID NVARCHAR(4) CONSTRAINT FK_Izdavaci FOREIGN KEY REFERENCES Izdavaci(IzdavaciID),
	Nalov NVARCHAR(100) NOT NULL,
	Cijena MONEY,
	Biljeske NVARCHAR(1000) CONSTRAINT DF_BiljeskeN DEFAULT('The quick brown fox jumps over the lazy'),
	DatumIzadavanja DATE NOT NULL CONSTRAINT DF_DatumIzdN DEFAULT(GETDATE()),
	DatumKreiranjaZapisa DATE NOT NULL CONSTRAINT DF_DatumKreirN DEFAULT(GETDATE()),
	DatumModifikovanjaZapisa DATE NULL	
)

CREATE TABLE NasloviAutori (
	AutorID NVARCHAR(11) CONSTRAINT FK_AutoriID FOREIGN KEY REFERENCES Autori(AutoriID),
	NasloviID NVARCHAR(6) CONSTRAINT FK_NasloviID FOREIGN KEY REFERENCES Naslovi(NasloviID),
	DatumKreiranjaZapisa DATE NOT NULL CONSTRAINT DF_DatumKreirNA DEFAULT(GETDATE()),
	DatumModifikovanjaZapisa DATE NULL	
	CONSTRAINT PK_NasloviAutori PRIMARY KEY(AutorID,NasloviID)
)


INSERT INTO Autori(AutoriID,Prezime,Ime,ZipKod)
SELECT A.au_id,A.au_lname,A.au_fname,A.zip
FROM pubs.dbo.authors AS A
ORDER BY NEWID()

SELECT * FROM Autori

INSERT INTO Izdavaci(IzdavaciID,Nazvi,Biljeske)
SELECT P.pub_id,P.pub_name,SUBSTRING(I.pr_info,0,100)
FROM pubs.dbo.publishers as P JOIN pubs.dbo.pub_info AS I
	ON I.pub_id=P.pub_id
ORDER BY NEWID()

SELECT * FROM Autori

INSERT INTO Naslovi (NasloviID,IzdavaciID,Nalov,Cijena,Biljeske,DatumIzadavanja)
SELECT T.title_id,T.pub_id,T.title,T.price,T.notes,T.pubdate
FROM pubs.dbo.titles AS T
WHERE T.notes is not null

SELECT * FROM Naslovi

INSERT INTO NasloviAutori (AutorID,NasloviID)
SELECT TA.au_id,TA.title_id
FROM pubs.dbo.titleauthor as TA

CREATE TABLE Gradovi(
	GradID INT IDENTITY(1,2) CONSTRAINT PK_GradID PRIMARY KEY,
	Naziv NVARCHAR(100) not null CONSTRAINT UQ_Nazivg UNIQUE,
	DatumKreiranjaZapisa DATE NOT NULL CONSTRAINT DF_DatumKreirG DEFAULT(GETDATE()),
	DatumModifikovanjaZapisa DATE NULL	
)

INSERT INTO Gradovi(Naziv)
SELECT DISTINCT  A.city
FROM pubs.dbo.authors A
go
SELECT * FROM Gradovi

ALTER TABLE Autori
ADD GradID INT CONSTRAINT FK_GradoviA FOREIGN KEY REFERENCES Gradovi(GradID)
GO

CREATE PROC ModifikujAutore1
AS 
BEGIN 
UPDATE TOP (5)Autori 

SET GradID=(SELECT GradID
			FROM Gradovi
			WHERE Naziv LIKE 'Salt Lake City')
END

EXEC ModifikujAutore1

SELECT * FROM Autori
GO 

CREATE PROC ModifikujAutore2
AS 
BEGIN 
UPDATE Autori 

SET GradID=(SELECT GradID
			FROM Gradovi
			WHERE Naziv LIKE 'Oakland')
	WHERE GradID is  null
END



EXEC ModifikujAutore2

SELECT * FROM Autori
GO 

CREATE VIEW POGLED
AS 
SELECT Ime+' '+Prezime AS 'Ime i prezime', G.Naziv,N.Nalov,N.Cijena,N.Biljeske,I.Nazvi
FROM Autori as A JOIN Gradovi as G
	ON A.GradID=G.GradID JOIN NasloviAutori AS NA
	ON NA.AutorID=A.AutoriID JOIN Naslovi AS N
	ON NA.NasloviID=N.NasloviID JOIN Izdavaci AS I
	ON I.IzdavaciID=N.IzdavaciID
WHERE N.Cijena>5 AND I.Nazvi NOT LIKE '%&%' AND G.Naziv LIKE 'Salt Lake City'


SELECT *
FROM POGLED


ALTER TABLE Autori 
ADD EMAIL NVARCHAR(100)

GO

CREATE PROC MOD_EMAIL1
AS 
BEGIN
UPDATE Autori
SET EMAIL=Ime+'.'+Prezime+'@edu.fit.ba'
		FROM Autori A JOIN Gradovi G
			ON	A.GradID=G.GradID	
	WHERE G.Naziv LIKE 'Salt Lake City'
END
GO


CREATE PROC MOD_EMAIL
AS 
BEGIN
UPDATE Autori
SET EMAIL=Prezime+'.'+Ime+'@edu.fit.ba'
		FROM Autori A JOIN Gradovi G
			ON	A.GradID=G.GradID	
	WHERE G.Naziv LIKE 'Oakland'
END

EXEC MOD_EMAIL
EXEC MOD_EMAIL1

 
SELECT ISNULL(PP.Title,'NA')AS Titula,PP.LastName,PP.FirstName,PPH.PhoneNumber,CC.CardNumber,
		PP.FirstName+'.'+PP.LastName AS UserName,
		LEFT(LOWER(REPLACE(NEWID(),'.','7')),24) AS Password
	--INTO #temp
FROM AdventureWorks2014.Person.Person  as PP JOIN AdventureWorks2014.Person.PersonPhone as PPH
	ON PP.BusinessEntityID= PPH.BusinessEntityID  LEFT JOIN  AdventureWorks2014.Sales.PersonCreditCard AS PCC
	ON PCC.BusinessEntityID= PP.BusinessEntityID LEFT JOIN AdventureWorks2014.Sales.CreditCard AS CC
	ON CC.CreditCardID=PCC.CreditCardID
ORDER BY PP.LastName, PP.FirstName


CREATE NONCLUSTERED INDEX IX_ImePrezime ON
	#temp (LastName, FirstName) INCLUDE (UserName)

select LastName, FirstName, UserName
from #temp
where LastName like 'C%'

SELECT * FROM #temp
go

CREATE PROC Obrisi
AS
BEGIN
DELETE FROM #temp 
	WHERE CardNumber is not null

END

exec Obrisi


BACKUP DATABASE IB170078
 TO DISK ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\back123.bak'
 --WITH DIFFERENTIAL

DROP TABLE #temp
go
CREATE PROC ObrisiSve
as 
begin
	delete from NasloviAutori
	delete from Naslovi
	delete from Izdavaci
	delete from Autori
	delete from Gradovi
end

go

exec ObrisiSve

use master
go

drop database IB170078

restore database IB170078
from disk ='C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\Backup\back123.bak'

use IB170078
go

select * from Autori

