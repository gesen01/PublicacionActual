IF EXISTS(SELECT name 
	  FROM 	 sysobjects 
	  WHERE  name = N'DICOContIC_log' 
	  AND 	 type = 'U')
    DROP TABLE DICOContIC_log
GO

CREATE TABLE DICOContIC_log (
	   ContID		INT		 NOT NULL,
	   Empresa	VARCHAR(10) NULL,
	   FechaProcesamiento  DATETIME	NULL
)
GO