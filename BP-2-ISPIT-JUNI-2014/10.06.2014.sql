CREATE DATABASE IB170078JUNI2014
GO

USE IB170078JUNI2014
GO

CREATE TABLE Studenti(
	StudentiID INT IDENTITY(1,1) CONSTRAINT PK_StudentiID PRIMARY KEY,
	BrojDosijea	NVARCHAR(10) CONSTRAINT UQ_BrojDosijea UNIQUE NOT NULL,
	Ime NVARCHAR(35) NOT NULL,
	Prezime NVARCHAR(35) NOT NULL,
	GodinaStudija INT NOT NULL,
	NacinStudiranja NVARCHAR(10) CONSTRAINT DF_NacinStudiranja DEFAULT('Redovan') NOT NULL,
	Email NVARCHAR(50) NULL
)

CREATE TABLE Nastava(
	NastavaID INT IDENTITY(1,1) CONSTRAINT PK_NastavaID PRIMARY KEY,
	Datum DATE NOT NULL,
	Predmet NVARCHAR(20) NOT NULL,
	Nastavnik NVARCHAR(50) NOT NULL,
	Ucionica NVARCHAR(20) NOT NULL
)

CREATE TABLE Prisustvo(
	PrisustvoID INT IDENTITY(1,1) CONSTRAINT PK_Prisustvo PRIMARY KEY,
	StudentiID INT  CONSTRAINT FK_StudentiID FOREIGN KEY REFERENCES Studenti(StudentiID),
	NastavaID INT  CONSTRAINT FK_NastavaID FOREIGN KEY REFERENCES Nastava(NastavaID),
)

ALTER TABLE Nastava
DROP COLUMN Predmet

CREATE TABLE Predmeti(
	PredmetiID INT IDENTITY(1,1) CONSTRAINT PK_Predmeti PRIMARY KEY,
	Naziv NVARCHAR(30) CONSTRAINT UQ_NazivPredmeti UNIQUE NOT NULL	
)

ALTER TABLE Nastava
ADD PredmetiID INT CONSTRAINT FK_PredmetiID FOREIGN KEY REFERENCES Predmeti(PredmetiID) NOT NULL

INSERT INTO Predmeti
VALUES ('ProgramiranjeI'),('ProgramiranjeII'),('ProgramiranjeIII')

INSERT INTO Studenti(BrojDosijea,Ime,Prezime,GodinaStudija,Email)
SELECT TOP 10 LEFT(Phone,3),FirstName,LastName,2,EmailAddress
FROM AdventureWorksLT2012.SalesLT.Customer

GO

CREATE PROC usp_Studenti_Update 
	@BrojDosijea INT ,
	@NacinStudiranja NVARCHAR(10)
AS
BEGIN
	UPDATE Studenti
	SET NacinStudiranja =@NacinStudiranja
	WHERE BrojDosijea=@BrojDosijea
END
GO

EXEC usp_Studenti_Update 170,'DL'
GO

CREATE PROC usp_Nastava_insert
	@Nastavnik NVARCHAR(50),
	@Ucionica NVARCHAR(20),
	@PredmetID INT,
	@Datum datetime 
AS
BEGIN
INSERT INTO Nastava(Datum,Nastavnik,Ucionica,PredmetiID)
VALUES(@Datum,@Nastavnik,@Ucionica,@PredmetID)

INSERT INTO Prisustvo
SELECT StudentiID ,(SELECT NastavaID 
					FROM Nastava
					WHERE PredmetiID=@PredmetID)
FROM Studenti
WHERE StudentiID IN(SELECT StudentiID
					FROM Studenti)
END


GO


EXEC usp_Nastava_insert 'Ajdin Catic','Ucionica7',3,'11.12.1998'

EXEC usp_Nastava_insert 'Ajdin Catic','Ucionica3',2,'11.12.1998'

DECLARE @date1 datetime = GETDATE();

EXEC usp_Nastava_insert @Nastavnik='kenan',@Ucionica='uc7',@PredmetID=1, @Datum= @date1

select * from Nastava

GO
CREATE PROC usp_Prisustvo_Delete
	@NastavaID INT,
	@StudentiID INT
AS
BEGIN
	DELETE FROM Prisustvo
	WHERE NastavaID=@NastavaID AND StudentiID=@StudentiID
END
GO

EXEC usp_Prisustvo_Delete 1,1
GO

CREATE VIEW view_Studenti_Nastava
AS
SELECT S.BrojDosijea,S.Ime,S.Prezime,N.Datum,Ucionica,Nastavnik,PRE.Naziv
FROM Studenti AS S JOIN Prisustvo AS P
	ON S.StudentiID =P.PrisustvoID JOIN Nastava AS N
	ON N.NastavaID=P.NastavaID JOIN Predmeti AS PRE 
	ON PRE.PredmetiID =N.PredmetiID

SELECT * FROM view_Studenti_Nastava