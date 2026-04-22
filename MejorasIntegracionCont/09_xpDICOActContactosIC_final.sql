SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpDICOActContactosIC')
DROP PROCEDURE xpDICOActContactosIC
GO
CREATE PROCEDURE xpDICOActContactosIC
@Empresa	VARCHAR(5),
@Modulo		VARCHAR(5),
@Cuenta		VARCHAR(15),
@TieneHist	BIT=0,
@Silencio	BIT=0,
@OK			INT	OUTPUT,
@OKref		VARCHAR(255) OUTPUT
AS
BEGIN
		DECLARE @CxEndosos TABLE(
				Empresa		VARCHAR(5),
				ID			INT,
				Mov			VARCHAR(20),
				MovID		VARCHAR(20),
				Estatus		VARCHAR(10),
				Cliente		VARCHAR(10),
				Proveedor	VARCHAR(10),
				IDAplica	INT,
				MovAplica	VARCHAR(20),
				MovIDAplica	VARCHAR(20),
				EstatusAplica	VARCHAR(10),
				ClienteAplica	VARCHAR(10),
				ProveedorAplica	VARCHAR(10)
		)
		
		DECLARE @PolizasProcesadas TABLE(
				ID		INT  NULL,
			    Cuenta	VARCHAR(15) NULL	
		)
BEGIN TRAN
BEGIN TRY
/****************************************************************************************************/
/*ENDOSOS EN CXP */
/****************************************************************************************************/
IF @Modulo='CXP'
BEGIN
	INSERT INTO @CxEndosos(Empresa,ID,Mov,MovID,Estatus,Proveedor,IDAplica,MovAplica,MovIDAplica,EstatusAplica,ProveedorAplica)
	SELECT p.Empresa, p.ID, p.Mov, p.MovID,  p.Estatus, p.proveedor, 'IDAplica' = po.ID, 'MovAplica' = po.Mov, 'MovIDAplica' = po.MovID, 'EstatusAplica' = po.Estatus, 'ProveedorAplica' = po.Proveedor 
	FROM Cxp p 
	JOIN MovTipo mt ON p.Mov = mt.Mov AND mt.Modulo = 'CXP' AND mt.Clave = 'CXP.FAC'
	JOIN Cxp po ON p.MovAplica = po.Mov AND p.MovAplicaID = po.MovID AND p.empresa = po.Empresa

	IF @TieneHist=1
	BEGIN
		INSERT INTO @CxEndosos(Empresa,ID,Mov,MovID,Estatus,Proveedor,IDAplica,MovAplica,MovIDAplica,EstatusAplica,ProveedorAplica)
		SELECT p.Empresa, p.ID, p.Mov, p.MovID,  p.Estatus, p.proveedor, 'IDAplica' = po.ID, 'MovAplica' = po.Mov, 'MovIDAplica' = po.MovID, 'EstatusAplica' = po.Estatus, 'ProveedorAplica' = po.Proveedor 
		FROM Cxp p 
		JOIN MovTipo mt ON p.Mov = mt.Mov AND mt.Modulo = 'CXP' AND mt.Clave = 'CXP.FAC'
		JOIN CentroHist.dbo.Cxp po ON p.MovAplica = po.Mov AND p.MovAplicaID = po.MovID AND p.empresa = po.Empresa

		INSERT INTO @CxEndosos(Empresa,ID,Mov,MovID,Estatus,Proveedor,IDAplica,MovAplica,MovIDAplica,EstatusAplica,ProveedorAplica)
		SELECT p.Empresa, p.ID, p.Mov, p.MovID,  p.Estatus, p.proveedor, 'IDAplica' = po.ID, 'MovAplica' = po.Mov, 'MovIDAplica' = po.MovID, 'EstatusAplica' = po.Estatus, 'ProveedorAplica' = po.Proveedor 
		FROM CentroHist.dbo.Cxp p 
		JOIN MovTipo mt ON p.Mov = mt.Mov AND mt.Modulo = 'CXP' AND mt.Clave = 'CXP.FAC'
		JOIN Cxp po ON p.MovAplica = po.Mov AND p.MovAplicaID = po.MovID AND p.empresa = po.Empresa

		INSERT INTO @CxEndosos(Empresa,ID,Mov,MovID,Estatus,Proveedor,IDAplica,MovAplica,MovIDAplica,EstatusAplica,ClienteAplica)
		SELECT p.Empresa, p.ID, p.Mov, p.MovID,  p.Estatus, p.proveedor, 'IDAplica' = po.ID, 'MovAplica' = po.Mov, 'MovIDAplica' = po.MovID, 'EstatusAplica' = po.Estatus, 'ProveedorAplica' = po.Proveedor 
		FROM CentroHist.dbo.Cxp p 
		JOIN MovTipo mt ON p.Mov = mt.Mov AND mt.Modulo = 'CXP' AND mt.Clave = 'CXP.FAC'
		JOIN CentroHist.dbo.Cxp po ON p.MovAplica = po.Mov AND p.MovAplicaID = po.MovID AND p.empresa = po.Empresa
	END	

		UPDATE ContReg  SET ContactoEspecifico = m.Proveedor, Procesado = 1,  NumUpdate = 1
			FROM ContD d (NOLOCK)
			JOIN cont c (NOLOCK) ON d.ID = c.ID 
			Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
			JOIN @CxEndosos m ON mf.OID = m.ID-- AND m.Estatus = 'CONCLUIDO'
			JOIN ContReg r on  r.ID = c.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
			WHERE r.Cuenta=@Cuenta 
			AND NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
			AND d.Haber IS NOT NULL AND d.Debe IS NULL
			AND c.Empresa = @Empresa
			AND r.Procesado = 0


		UPDATE ContReg  SET ContactoEspecifico = m.ProveedorAplica,  Procesado = 1,  NumUpdate = 1
			FROM ContD d (NOLOCK)
			JOIN cont c (NOLOCK) ON d.ID = c.ID 
			Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
			JOIN @CxEndosos m ON mf.OID = m.ID --AND m.Estatus = 'CONCLUIDO'
			JOIN ContReg r on  r.ID = c.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
			WHERE r.Cuenta=@Cuenta
			AND NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
			AND d.Debe IS NOT NULL AND d.Haber IS NULL
			AND c.Empresa = @Empresa
			AND r.Procesado = 0
			
			
		UPDATE d SET d.Logico2=1
			FROM ContD d (NOLOCK)
			JOIN cont c (NOLOCK) ON d.ID = c.ID 
			Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
			JOIN @CxEndosos m ON mf.OID = m.ID-- AND m.Estatus = 'CONCLUIDO'
			JOIN ContReg r on  r.ID = c.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
			WHERE r.Cuenta=@Cuenta 
			AND NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
			AND d.Haber IS NOT NULL AND d.Debe IS NULL
			AND c.Empresa = @Empresa
			AND r.Procesado = 1
			
		UPDATE d SET d.Logico2=1
			FROM ContD d (NOLOCK)
			JOIN cont c (NOLOCK) ON d.ID = c.ID 
			Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
			JOIN @CxEndosos m ON mf.OID = m.ID --AND m.Estatus = 'CONCLUIDO'
			JOIN ContReg r on  r.ID = c.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
			WHERE r.Cuenta=@Cuenta
			AND NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
			AND d.Debe IS NOT NULL AND d.Haber IS NULL
			AND c.Empresa = @Empresa
			AND r.Procesado = 1
	
	DELETE FROM @CxEndosos
END
/****************************************************************************************************/
/*ENDOSOS EN CXC */
/****************************************************************************************************/
IF @Modulo='CXP'
BEGIN
	INSERT INTO @CxEndosos(Empresa,ID,Mov,MovID,Estatus,Cliente,IDAplica,MovAplica,MovIDAplica,EstatusAplica,ClienteAplica)
	SELECT p.Empresa, p.ID, p.Mov, p.MovID,  p.Estatus, p.Cliente, 'IDAplica' = po.ID, 'MovAplica' = po.Mov, 'MovIDAplica' = po.MovID, 'EstatusAplica' = po.Estatus, 'ClienteAplica' = po.Cliente 
	FROM Cxc p 
	JOIN MovTipo mt ON p.Mov = mt.Mov AND mt.Modulo = 'Cxc' AND mt.Clave = 'Cxc.FAC'
	JOIN Cxc po ON p.MovAplica = po.Mov AND p.MovAplicaID = po.MovID AND p.empresa = po.Empresa

	IF @TieneHist=1
	BEGIN
		INSERT INTO @CxEndosos(Empresa,ID,Mov,MovID,Estatus,Cliente,IDAplica,MovAplica,MovIDAplica,EstatusAplica,ClienteAplica)
		SELECT p.Empresa, p.ID, p.Mov, p.MovID,  p.Estatus, p.Cliente, 'IDAplica' = po.ID, 'MovAplica' = po.Mov, 'MovIDAplica' = po.MovID, 'EstatusAplica' = po.Estatus, 'ClienteAplica' = po.Cliente 
		FROM Cxc p 
		JOIN MovTipo mt ON p.Mov = mt.Mov AND mt.Modulo = 'Cxc' AND mt.Clave = 'Cxc.FAC'
		JOIN CentroHist.dbo.Cxc po ON p.MovAplica = po.Mov AND p.MovAplicaID = po.MovID AND p.empresa = po.Empresa

		INSERT INTO @CxEndosos(Empresa,ID,Mov,MovID,Estatus,Cliente,IDAplica,MovAplica,MovIDAplica,EstatusAplica,ClienteAplica)
		SELECT p.Empresa, p.ID, p.Mov, p.MovID,  p.Estatus, p.Cliente, 'IDAplica' = po.ID, 'MovAplica' = po.Mov, 'MovIDAplica' = po.MovID, 'EstatusAplica' = po.Estatus, 'ClienteAplica' = po.Cliente 
		FROM CentroHist.dbo.Cxc p 
		JOIN MovTipo mt ON p.Mov = mt.Mov AND mt.Modulo = 'Cxc' AND mt.Clave = 'Cxc.FAC'
		JOIN Cxc po ON p.MovAplica = po.Mov AND p.MovAplicaID = po.MovID AND p.empresa = po.Empresa

		INSERT INTO @CxEndosos(Empresa,ID,Mov,MovID,Estatus,Cliente,IDAplica,MovAplica,MovIDAplica,EstatusAplica,ClienteAplica)
		SELECT p.Empresa, p.ID, p.Mov, p.MovID,  p.Estatus, p.Cliente, 'IDAplica' = po.ID, 'MovAplica' = po.Mov, 'MovIDAplica' = po.MovID, 'EstatusAplica' = po.Estatus, 'ClienteAplica' = po.Cliente 
		FROM CentroHist.dbo.Cxc p 
		JOIN MovTipo mt ON p.Mov = mt.Mov AND mt.Modulo = 'Cxc' AND mt.Clave = 'Cxc.FAC'
		JOIN CentroHist.dbo.Cxc po ON p.MovAplica = po.Mov AND p.MovAplicaID = po.MovID AND p.empresa = po.Empresa
	END	
	 --Actualilza los datos de ContReg para los endosos de CXC
	UPDATE ContReg  SET ContactoEspecifico = m.ClienteAplica, Procesado = 1,  NumUpdate = 2
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'Cxc'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
		JOIN @CxEndosos m  ON mf.OID = m.ID-- AND m.Estatus = 'CONCLUIDO'
		JOIN ContReg r on  r.ID = c.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
		WHERE r.Cuenta=@Cuenta
		AND NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
		AND d.Haber IS NOT NULL AND d.Debe IS NULL
		AND c.Empresa = @Empresa
		AND Procesado = 0


	UPDATE ContReg  SET ContactoEspecifico = m.Cliente, Procesado = 1,  NumUpdate = 2
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'Cxc'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
		JOIN @CxEndosos m ON mf.OID = m.ID --AND m.Estatus = 'CONCLUIDO'
		JOIN ContReg r on  r.ID = c.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
		WHERE r.Cuenta=@Cuenta
		AND NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
		AND d.Debe IS NOT NULL AND d.Haber IS NULL
		AND c.Empresa = @Empresa
		AND Procesado = 0
		
	--Actualiza los detalles de los renglones del detalle de las polizas con los endodosos usados
	UPDATE d SET d.Logico2=1
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'Cxc'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
		JOIN @CxEndosos m ON mf.OID = m.ID-- AND m.Estatus = 'CONCLUIDO'
		JOIN ContReg r on  r.ID = c.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
		WHERE r.Cuenta=@Cuenta
		AND NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
		AND d.Haber IS NOT NULL AND d.Debe IS NULL
		AND c.Empresa = @Empresa
		AND Procesado = 1
			
	UPDATE d SET d.Logico2=1
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'Cxc'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
		JOIN @CxEndosos m ON mf.OID = m.ID --AND m.Estatus = 'CONCLUIDO'
		JOIN ContReg r on  r.ID = c.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
		WHERE r.Cuenta=@Cuenta
		AND NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
		AND d.Debe IS NOT NULL AND d.Haber IS NULL
		AND c.Empresa = @Empresa
		AND Procesado = 0
	
	DELETE FROM @CxEndosos
END
 /****************************************************************************************************/
/*ACTUALIZA CONTACTO DE CONTD A CONTREG */
/****************************************************************************************************/
IF EXISTS(SELECT 1 FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	JOIN ContReg r on  r.ID = d.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
	WHERE NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	 
	AND d.ContactoEspecifico IS NOT NULL
	AND c.Empresa = @Empresa
    AND r.Cuenta=@Cuenta
	AND Procesado = 0)
BEGIN
	UPDATE ContReg  SET ContactoEspecifico = d.ContactoEspecifico, Procesado = 1,  NumUpdate = 3
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	JOIN ContReg r on  r.ID = d.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
	WHERE NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	 
	AND d.ContactoEspecifico IS NOT NULL
	AND c.Empresa = @Empresa
    AND r.Cuenta =@Cuenta
	AND Procesado = 0
	
	UPDATE d SET Logico2=1
    FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	JOIN ContReg r on  r.ID = d.ID and r.Cuenta = d.Cuenta AND ISNULL(r.Debe,0) = ISNULL(d.Debe,0) AND ISNULL(r.Haber,0) = ISNULL(d.Haber,0)
	WHERE NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	 
	AND d.ContactoEspecifico IS NOT NULL
	AND c.Empresa = @Empresa
    AND r.Cuenta =@Cuenta
	AND Procesado = 1
END
 /****************************************************************************************************/
/*ACTUALIZA CONTACTO DE MOVREG A CONTREG */
/****************************************************************************************************/
IF EXISTS(SELECT 1 FROM ContReg r 
	JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
	WHERE NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
	AND m.Contacto IS NOT NULL
    AND r.Empresa = @Empresa
    AND r.Cuenta =@Cuenta
    AND Procesado=0)
BEGIN
	
	INSERT INTO @PolizasProcesadas
	SELECT r.ID,r.Cuenta
	FROM ContReg r 
	JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
	WHERE NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
	AND m.Contacto IS NOT NULL
    AND r.Empresa = @Empresa
    AND r.Cuenta =@Cuenta
	AND Procesado = 0
	
	UPDATE ContReg  SET ContactoEspecifico = m.Contacto, Procesado = 1,  NumUpdate = 4
	FROM ContReg r 
	JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
	WHERE NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	
	AND m.Contacto IS NOT NULL
    AND r.Empresa = @Empresa
    AND r.Cuenta =@Cuenta
	AND Procesado = 0
	
	UPDATE d SET Logico2=1
	FROM ContD d
	JOIN @PolizasProcesadas AS pp ON pp.ID = d.ID AND pp.Cuenta = d.Cuenta
	
	DELETE FROM @PolizasProcesadas
END
 /****************************************************************************************************/
/*ACTUALIZA CONTACTO DE CONT A CONTREG */
/****************************************************************************************************/
IF EXISTS(SELECT 1 FROM cont c 
	JOIN ContReg r on  r.ID = c.ID 
    WHERE NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	 
	AND (c.Contacto IS NOT NULL OR c.ContactoAplica IS NOT NULL)
    AND c.Empresa = @Empresa
    AND r.Cuenta=@Cuenta
	AND Procesado = 0)
BEGIN
	INSERT INTO @PolizasProcesadas
	SELECT c.ID,r.Cuenta
	FROM cont c 
	JOIN ContReg r on  r.ID = c.ID 
    WHERE NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	 
	AND (c.Contacto IS NOT NULL OR c.ContactoAplica IS NOT NULL)
    AND c.Empresa = @Empresa
    AND r.Cuenta=@Cuenta
	AND Procesado = 0
	
	UPDATE ContReg  SET ContactoEspecifico = ISNULL(c.Contacto,c.ContactoAplica), Procesado = 1,  NumUpdate = 5
	--select c.Contacto, c.ContactoAplica,r.ContactoEspecifico, *
	FROM cont c 
	JOIN ContReg r on  r.ID = c.ID 
	WHERE NULLIF(LTRIM(r.ContactoEspecifico),'') IS NULL 	 
	AND (c.Contacto IS NOT NULL OR c.ContactoAplica IS NOT NULL)
    AND c.Empresa = @Empresa
    AND r.Cuenta =@Cuenta
	AND Procesado = 0
	
	UPDATE d SET Logico2=1
	FROM ContD AS d
	JOIN @PolizasProcesadas AS pp ON pp.ID = d.ID AND pp.Cuenta = d.Cuenta
END
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
	BEGIN
		SELECT @OK=1000010,
			   @OKRef=ERROR_MESSAGE()  

		ROLLBACK TRAN	
	END
END CATCH

IF @OK IS NULL AND  @@TRANCOUNT > 0
BEGIN
	
	IF @Silencio=1
		SELECT 'PROCESO CONCLUIDO'
		
	COMMIT TRAN
END
ELSE
	SELECT CAST(@OK AS VARCHAR(20))+' - '+@OKref 
RETURN
END
GO
