SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--EXEC xpDICOFixContRegJob '09',0
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpDICOFixContRegJob')
DROP PROCEDURE xpDICOFixContRegJob
GO
--Este proceso automatiza la correccion de polizas entre cont y cont reg, con lo cual el proceso manual ya no seria necesario
CREATE PROCEDURE xpDICOFixContRegJob
@Empresa	VARCHAR(5),
@Silencio	BIT --Este b1t si se prende mostrara el tablero con todas las diferencias por lo que no se recomienda si se va a procesar toda la tabla de cuentas a corregir
AS
BEGIN
	
DECLARE @Cuenta			VARCHAR(35),
		@Consecutivo	INT=1,
		@NumCtas		INT,
		@Estacion		INT

DECLARE @Ctas TABLE (
	ID			INT	IDENTITY(1,1)	NOT NULL,
	Cuenta		VARCHAR(35)
) 


INSERT INTO @Ctas
SELECT DISTINCT Cuenta
FROM DICOCtasActualizar
WHERE Empresa=@Empresa
AND Procesado=1


SELECT @NumCtas=COUNT(ID)
FROM @Ctas AS c

SELECT @Estacion=@@SPID

WHILE @Consecutivo <= @NumCtas
BEGIN
	
	SELECT @Cuenta=c.Cuenta
	FROM @Ctas AS c
	WHERE id=@Consecutivo
	
	--Esta primer ejecusion llena la tabla DICOTableroIC con todas polizas con diferencias de la cuenta especificada
	EXEC xpDICOTableroJobIC @Estacion,@Empresa,@Cuenta,1,0,@Silencio,0
	
	--Se valida que la tabla con diferencias tenga datos y ejecuta el proceso de correccion
	IF EXISTS(SELECT 1 FROM DICOTableroIC WHERE Estacion=@Estacion)
		EXEC xpDICOTableroJobIC @Estacion,@Empresa,@Cuenta,0,1,@Silencio,0
	
	
	SET @Consecutivo=@Consecutivo+1
	
END
RETURN
END

