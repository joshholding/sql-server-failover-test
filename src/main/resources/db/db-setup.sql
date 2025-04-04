/***************************************************
** STEP 1: Execute on PRINCIPAL DB
*****************************************************/
-- create db
CREATE DATABASE jtest;
GO
ALTER DATABASE jtest SET RECOVERY FULL;
GO

-- create jtest user
USE [master]
GO
CREATE LOGIN [jtest] WITH PASSWORD = 'jtest', SID = 0x6104AA7E87A15B4EB0A95FA3B5D7C22F, DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

USE jtest
GO
CREATE USER [jtest] FOR LOGIN [jtest] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE db_owner ADD MEMBER jtest
GO

BACKUP DATABASE jtest TO DISK = '\\sql_principal\bak\jtest.bak' WITH FORMAT;
GO
BACKUP LOG jtest TO DISK = '\\sql_principal\bak\jtest.trn';
GO


/***************************************************
** STEP 2: Execute on MIRROR DB
*****************************************************/
-- create logins and restore db
USE [master]
GO
CREATE LOGIN [jtest] WITH PASSWORD = 'jtest', SID = 0x6104AA7E87A15B4EB0A95FA3B5D7C22F, DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

RESTORE DATABASE jtest FROM DISK = '\\sql_principal\bak\jtest.bak'
WITH NORECOVERY
GO

-- restore log
RESTORE LOG jtest FROM DISK = '\\sql_principal\bak\jtest.trn'
WITH FILE=1, NORECOVERY;
GO

-- configure mirror's partners
ALTER DATABASE jtest SET PARTNER = 'TCP://sql_principal:5022';  
GO

/***************************************************
** STEP 3: Execute on PRINCIPAL DB
*****************************************************/
-- configure mirror partner
ALTER DATABASE jtest SET PARTNER = 'TCP://sql_mirror:5022';  
GO