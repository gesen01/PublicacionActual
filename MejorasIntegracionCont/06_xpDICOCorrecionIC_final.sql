SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--EXEC xpDICOCorrecionIC  999,'04'
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='P' AND NAME='xpDICOCorrecionIC')
DROP PROCEDURE xpDICOCorrecionIC
GO
CREATE PROCEDURE xpDICOCorrecionIC
@Estacion		INT,
@Empresa		VARCHAR(10),
@Cuenta			VARCHAR(20)=NULL,
@Silencio		BIT=0
AS
BEGIN
	DECLARE @MovsCont TABLE (
		ID				INT IDENTITY(1,1) NOT NULL,
		Consecutivo		INT
	)
	
	DECLARE @ID				INT,
			@Contador		INT=1,
			@TotalReg		INT
			
	INSERT INTO @MovsCont
	SELECT Clave
	FROM ListaSt AS ls WITH(NOLOCK)
	WHERE ls.Estacion=@Estacion
	
	SELECT @TotalReg=COUNT(ID)
	FROM @MovsCont AS mc

	IF @TotalReg > 0
	BEGIN
		WHILE @Contador <= @TotalReg
		BEGIN
			SELECT @ID=mc.Consecutivo
			FROM @MovsCont AS mc
			WHERE ID=@Contador
			
			EXEC spDicoRegenerarRegistroContable @Empresa,@ID,@Silencio
			
			UPDATE DICOTableroIC SET Tipo='SinDiferencia'
			WHERE ID=@ID
			AND Estacion=@Estacion
			
			IF @Cuenta IS NOT NULL
				UPDATE ContD SET Logico1 = 1
				WHERE ID=@ID
				AND Cuenta=@Cuenta
			
			IF NOT EXISTS(SELECT 1 FROM DICOContIC_log WHERE ContID=@ID)
				INSERT INTO DICOContIC_log
				SELECT @ID,@Empresa,GETDATE()
						
			SET @Contador=@Contador+1
		END
		SELECT 'SE PROCESARON '+CAST(@TotalReg AS VARCHAR(20))+' REGISTROS'
	END
	ELSE
		SELECT 'NO SE OBTUVO NINGUN REGISTRO QUE PROCESAR'
		
RETURN
END

GO
