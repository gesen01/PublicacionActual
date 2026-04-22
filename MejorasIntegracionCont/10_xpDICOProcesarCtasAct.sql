SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--DECLARE @OK INT, @OKRef VARCHAR(255)
--EXEC xpDICOProcesarCtasAct '02',1,@OK OUTPUT,@OKRef OUTPUT
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpDICOProcesarCtasAct')
DROP PROCEDURE xpDICOProcesarCtasAct
GO
CREATE PROCEDURE xpDICOProcesarCtasAct
@Empresa	VARCHAR(5),
@TieneHist	BIT,
@OK			INT				OUTPUT,
@OKRef		VARCHAR(255)	OUTPUT
AS
BEGIN
	DECLARE @Cuenta			VARCHAR(15),
			@NumCtas		INT,
			@Modulo			VARCHAR(5),
			@Consecutivo	INT=1,
			@Valida			INT,
			@ValidaRef		VARCHAR(255)
			
			
	DECLARE @Ctas TABLE (
		ID			INT		IDENTITY(1,1)	NOT NULL,
		Cuenta		VARCHAR(15)	NULL,
		Modulo		VARCHAR(5)	NULL
	)
	
	INSERT INTO @Ctas
	SELECT Cuenta,Modulo
	FROM DICOCtasActualizar
	WHERE Procesado=0
	AND Empresa=@Empresa
	
			
	SELECT @NumCtas=COUNT(ID)
	FROM @Ctas
	
	WHILE @Consecutivo <= @NumCtas
	BEGIN
				
		SELECT @Cuenta=Cuenta
			  ,@Modulo=Modulo
		FROM @Ctas
		WHERE ID=@Consecutivo
		
		BEGIN TRAN
		
		BEGIN TRY
			--Ejecutable que permite realizar la actuallizacion del contreg de la cuenta extraida de la tabla de configuracion
					
			EXEC xpDICOActContactosIC @Empresa,@Modulo,@Cuenta,@TieneHist,0,@Valida OUTPUT, @ValidaRef OUTPUT
				
			UPDATE DICOCtasActualizar SET Procesado=1
			WHERE Procesado=0
			AND Cuenta=@Cuenta
			AND Modulo=@Modulo			
		
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
			BEGIN
				SELECT @OK=@Valida,
					   @OKRef=@ValidaRef
			   
				ROLLBACK TRAN	
			END
		END CATCH
		
		IF @@TRANCOUNT > 0 AND @OK IS NULL
			COMMIT TRAN
		ELSE
			SELECT CAST(@OK AS VARCHAR(10))+' - '+@OKRef	
		
		SET @Consecutivo=@Consecutivo+1
		
	END
RETURN
END