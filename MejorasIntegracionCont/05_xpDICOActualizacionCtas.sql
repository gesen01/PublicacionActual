SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpDICOActualizacionCtas')
DROP PROCEDURE xpDICOActualizacionCtas
GO
CREATE PROCEDURE xpDICOActualizacionCtas
@Empresa	VARCHAR(5),
@TieneHist	BIT=0,
@TieneCtrl	BIT=0,
@OK			INT	OUTPUT,
@OKref		VARCHAR(255) OUTPUT
AS
BEGIN
		
BEGIN TRAN

BEGIN TRY

/****************************************************************************************************/
/*VENTAS*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID 
Join movFlujo mf ON mf.Omodulo = 'VTAS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
JOIN Venta m ON mf.OID = m.ID
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0)) 
BEGIN

	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Cliente 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'VTAS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN BajioHist.dbo.Venta m (NOLOCK) ON mf.OID = m.ID
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		--d.Ejercicio = 2009 AND 
		d.ContactoEspecifico IS NULL
	END

	Update ContD SET ContactoEspecifico = m.Cliente 
	--SELECT *
	FROM ContD d (NOLOCK) 
	JOIN cont c  (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'VTAS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
	JOIN Venta m (NOLOCK) ON mf.OID = m.ID
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	d.ContactoEspecifico IS NULL
END
/****************************************************************************************************/
/*COMPRAS*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID 
Join movFlujo mf ON mf.Omodulo = 'COMS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
JOIN Compra m ON mf.OID = m.ID
WHERE d.Cuenta  IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0))
BEGIN
	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Proveedor 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'COMS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN BajioHist.dbo.Compra m (NOLOCK) ON mf.OID = m.ID
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		--d.Ejercicio = 2009 AND 
		d.ContactoEspecifico IS NULL
	END
	Update ContD SET ContactoEspecifico = m.Proveedor 
	--SELECT *
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'COMS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
	JOIN Compra m (NOLOCK) ON mf.OID = m.ID
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	d.ContactoEspecifico IS NULL
END
/****************************************************************************************************/
/*COMPRAS QUE POR ALGUNA RAZON NO EXISTE EN TABLA COMPRA(NI EN HISTORICO) BUSCAR EN SU POSTERIOR FLUJO DE CXP QUE SI EXISTE*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID  Join movFlujo mf ON mf.Omodulo = 'COMS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
Join movFlujo mfC ON mf.Omodulo = 'COMS'  AND mfc.Dmodulo = 'CXP' AND mf.OID = mfc.DID WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0))
BEGIN
	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m2.Proveedor 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'COMS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		LEFT JOIN BajioHist.dbo.Compra m (NOLOCK) ON mf.OID = m.ID
		Join movFlujo mfC ON mf.Omodulo = 'COMS'  AND mfc.Dmodulo = 'CXP' AND mf.OID = mfc.DID 
		JOIN BajioHist.dbo.CXP m2 (NOLOCK) ON mfc.dID = m2.ID
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		m.ID IS NULL AND
		--d.Ejercicio = 2009 AND 
		d.ContactoEspecifico IS NULL

	END
	Update ContD SET ContactoEspecifico = m2.Proveedor 
	--select *
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'COMS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
	LEFT JOIN Compra m (NOLOCK) ON mf.OID = m.ID
	Join movFlujo mfC ON mf.Omodulo = 'COMS'  AND mfc.Dmodulo = 'CXP' AND mf.OID = mfc.DID 
	JOIN CXP m2 (NOLOCK) ON mfc.dID = m2.ID
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	m.ID IS NULL AND
	--d.Ejercicio = 2009 AND 
	d.ContactoEspecifico IS NULL
END
/****************************************************************************************************/
/*GASTOS*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID Join movFlujo mf ON mf.Omodulo = 'GAS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0))
BEGIN
	Update d SET ContactoEspecifico = m.Acreedor 
	--SELECT * 
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'GAS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
	JOIN Gasto m (NOLOCK) ON mf.OID = m.ID
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	d.ContactoEspecifico IS NULL

	IF @TieneHist=1
	BEGIN
		Update d SET ContactoEspecifico = m.Acreedor 
		--SELECT * 
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'GAS'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN BajioHist.dbo.Gasto m (NOLOCK) ON mf.OID = m.ID
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) --AND D.Ejercicio= 2012
		AND d.ContactoEspecifico IS NULL
	END
END
/****************************************************************************************************/
/*CXC MOVIMIENTOS QUE NOOO SON ENDOSO*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM  ContD d
JOIN cont c ON d.ID = c.ID  Join movFlujo mf ON mf.Omodulo = 'CXC'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov <> 'Endoso' 
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) ) 
BEGIN
	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Cliente 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'CXC'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov <> 'Endoso'
		JOIN BajioHist.dbo.CXC m (NOLOCK) ON mf.OID = m.ID
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		--d.Ejercicio = 2009 AND 
		d.ContactoEspecifico IS NULL

	END
	Update ContD SET ContactoEspecifico = m.Cliente 
	--select *
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'CXC'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov <> 'Endoso'
	JOIN CXC m (NOLOCK) ON mf.OID = m.ID
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	d.ContactoEspecifico IS NULL
END
/****************************************************************************************************/
/*CXC Los ENDOSOS DEL CLIENTE AL QUE SE LE CARGA LA DEUDA DEBE IS NOT NULL */
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID Join movFlujo mf ON mf.Omodulo = 'CXC'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso' 
WHERE d.Cuenta  IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0)) 
BEGIN
	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Cliente 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'CXC'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
		JOIN BajioHist.dbo.CXC m  (NOLOCK) ON mf.OID = m.ID AND m.Estatus = 'CONCLUIDO'
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		--d.Ejercicio = 2009 AND 
		--d.ContactoEspecifico IS NULL AND 
		d.Debe IS NOT NULL AND d.Haber IS NULL

	END
	Update ContD SET ContactoEspecifico = m.Cliente 
	--select *
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'CXC'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
	JOIN CXC m (NOLOCK) ON mf.OID = m.ID AND m.Estatus = 'CONCLUIDO'
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	--d.ContactoEspecifico IS NULL AND 
	d.Debe IS NOT NULL AND d.Haber IS NULL
END
/****************************************************************************************************/
/*CXC Los ENDOSOS DEL CLIENTE AL QUE SE LE QUITA LA DEUDA "HABER IS NOT NULL", SE BUSCA EL ANTECEDENTE DEL ENDOSO POR ESO OTRO MOV FLUJO */
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM  ContD d
JOIN cont c ON d.ID = c.ID Join movFlujo mf ON mf.Omodulo = 'CXC'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
JOIN MovFlujo mfo ON mfo.Omodulo = 'CXC'  AND mfo.Dmodulo = 'CXC' AND mfo.DID = mf.OID WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0)) 
BEGIN
	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Cliente 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'CXC'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
		JOIN MovFlujo mfo ON mfo.Omodulo = 'CXC'  AND mfo.Dmodulo = 'CXC' AND mfo.DID = mf.OID
		JOIN BajioHist.dbo.CXC m (NOLOCK) ON mfo.OID = m.ID AND m.Estatus = 'CONCLUIDO'
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		--d.Ejercicio = 2009 AND 
		--d.ContactoEspecifico IS NULL AND 
		d.Haber IS NOT NULL AND d.Debe IS NULL

	END

	Update ContD SET ContactoEspecifico = m.Cliente 
	--select *
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'CXC'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
	JOIN MovFlujo mfo ON mfo.Omodulo = 'CXC'  AND mfo.Dmodulo = 'CXC' AND mfo.DID = mf.OID
	JOIN CXC m (NOLOCK) ON mfo.OID = m.ID AND m.Estatus = 'CONCLUIDO'
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	--d.ContactoEspecifico IS NULL AND 
	d.Haber IS NOT NULL AND d.Debe IS NULL
END

/****************************************************************************************************/
/*CXP MOVIMIENTOS QUE NOOO SON ENDOSO*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID  Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov <> 'Endoso' 
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0))
BEGIN
	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Proveedor 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov <> 'Endoso'
		JOIN BajioHist.dbo.CXP m (NOLOCK) ON mf.OID = m.ID
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		--d.Ejercicio = 2009 AND 
		d.ContactoEspecifico IS NULL


	END
	Update ContD SET ContactoEspecifico = m.Proveedor 
	--select *
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov <> 'Endoso'
	JOIN CXP m (NOLOCK) ON mf.OID = m.ID
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	d.ContactoEspecifico IS NULL
END
/****************************************************************************************************/
/*CXP Los ENDOSOS DEL PROVEEDOR AL QUE SE LE CARGA LA DEUDA HABER IS NOT NULL */
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso' 
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0))
BEGIN
	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Proveedor 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
		JOIN BajioHist.dbo.CXP m  (NOLOCK) ON mf.OID = m.ID AND m.Estatus = 'CONCLUIDO'
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		--d.Ejercicio = 2009 AND 
		--d.ContactoEspecifico IS NULL AND 
		d.Haber IS NOT NULL AND d.Debe IS NULL

	END
	Update ContD SET ContactoEspecifico = m.Proveedor 
	--select *
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
	JOIN CXP m (NOLOCK) ON mf.OID = m.ID AND m.Estatus = 'CONCLUIDO'
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	--d.ContactoEspecifico IS NULL AND 
	d.Haber IS NOT NULL AND d.Debe IS NULL
END
/****************************************************************************************************/
/*CXP Los ENDOSOS DEL PROVEEDOR AL QUE SE LE QUITA LA DEUDA "DEBE IS NOT NULL", SE BUSCA EL ANTECEDENTE DEL ENDOSO POR ESO OTRO MOV FLUJO */
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
JOIN MovFlujo mfo ON mfo.Omodulo = 'CXP'  AND mfo.Dmodulo = 'CXP' AND mfo.DID = mf.OID  
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) ) 
BEGIN
	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Proveedor 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
		JOIN MovFlujo mfo ON mfo.Omodulo = 'CXP'  AND mfo.Dmodulo = 'CXP' AND mfo.DID = mf.OID
		JOIN BajioHist.dbo.CXP m (NOLOCK) ON mfo.OID = m.ID AND m.Estatus = 'CONCLUIDO'
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		--d.Ejercicio = 2009 AND 
		--d.ContactoEspecifico IS NULL AND 
		d.Debe IS NOT NULL AND d.Haber IS NULL

	END

	Update ContD SET ContactoEspecifico = m.Proveedor 
	--select *
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'CXP'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID AND mf.Omov = 'Endoso'
	JOIN MovFlujo mfo ON mfo.Omodulo = 'CXP'  AND mfo.Dmodulo = 'CXP' AND mfo.DID = mf.OID
	JOIN CXP m (NOLOCK) ON mfo.OID = m.ID AND m.Estatus = 'CONCLUIDO'
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	--d.ContactoEspecifico IS NULL AND 
	d.Debe IS NOT NULL AND d.Haber IS NULL
END 
/****************************************************************************************************/
/*DINERO CON ORIGEN CXP CON CUENTAS DIFERENTES*/
/****************************************************************************************************/
IF EXISTS(SELECT 1 FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN DineroD dd ON dd.ID=mf.OID
		JOIN Dinero do ON dd.Aplica=do.Mov AND dd.AplicaID=do.MovID AND c.Empresa=do.Empresa
		jOIN MovFlujo mfoc ON  mfoc.Omodulo = 'CXP'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = do.id
		JOIN CXP m (NOLOCK) ON mfoc.OID = m.ID AND m.Proveedor=do.Contacto
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0))
BEGIN
	Update ContD SET ContactoEspecifico =do.Contacto
	--SELECT d.ID,do.Contacto
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN DineroD dd ON dd.ID=mf.OID
		JOIN Dinero do ON dd.Aplica=do.Mov AND dd.AplicaID=do.MovID AND c.Empresa=do.Empresa
		jOIN MovFlujo mfoc ON  mfoc.Omodulo = 'CXP'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = do.id
		JOIN CXP m (NOLOCK) ON mfoc.OID = m.ID AND m.Proveedor=do.Contacto
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
			d.ContactoEspecifico IS NULL
	
	IF @TieneHist=1
	BEGIN
		
	Update ContD SET ContactoEspecifico =do.Contacto
	--SELECT d.ID,do.Contacto
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN DineroD dd ON dd.ID=mf.OID
		JOIN Dinero do ON dd.Aplica=do.Mov AND dd.AplicaID=do.MovID AND c.Empresa=do.Empresa
		jOIN MovFlujo mfoc ON  mfoc.Omodulo = 'CXP'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = do.id
		JOIN BajioHist.dbo.CXP m (NOLOCK) ON mfoc.OID = m.ID AND m.Proveedor=do.Contacto
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
			d.ContactoEspecifico IS NULL
	END
END
/****************************************************************************************************/
/*DINERO CON ORIGEN CXP*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID 
Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
JOIN MovFlujo mfo ON mfo.Omodulo = 'DIN'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
JOIN MovFlujo mfoc ON mfoc.Omodulo = 'CXP'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = mfo.OID  
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0))
BEGIN
	
	Update ContD SET ContactoEspecifico = m.Proveedor 
	--select *
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
	JOIN MovFlujo mfo ON mfo.Omodulo = 'DIN'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
	JOIN MovFlujo mfoc ON mfoc.Omodulo = 'CXP'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = mfo.OID
	JOIN CXP m (NOLOCK) ON mfoc.OID = m.ID 
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	d.ContactoEspecifico IS NULL


	IF @TieneHist=1
	BEGIN
		
		Update ContD SET ContactoEspecifico = m.Proveedor 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN MovFlujo mfo ON mfo.Omodulo = 'DIN'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
		JOIN MovFlujo mfoc ON mfoc.Omodulo = 'CXP'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = mfo.OID
		JOIN BajioHist.dbo.CXP m (NOLOCK) ON mfoc.OID = m.ID 
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		--d.Ejercicio = 2009 AND 
		d.ContactoEspecifico IS NULL 

	END
END
/****************************************************************************************************/
/*DINERO CON ORIGEN CXC CON CUENTAS DIFERENTES */
/****************************************************************************************************/
IF EXISTS(SELECT 1 FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN DineroD dd ON dd.ID=mf.OID
		JOIN Dinero do ON dd.Aplica=do.Mov AND dd.AplicaID=do.MovID AND c.Empresa=do.Empresa
		jOIN MovFlujo mfoc ON  mfoc.Omodulo = 'CXC'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = do.id
		JOIN CXC m (NOLOCK) ON mfoc.OID = m.ID AND m.Cliente=do.Contacto
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) )
BEGIN
	Update ContD SET ContactoEspecifico=do.Contacto
	--SELECT d.ID,do.Contacto
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN DineroD dd ON dd.ID=mf.OID
		JOIN Dinero do ON dd.Aplica=do.Mov AND dd.AplicaID=do.MovID AND c.Empresa=do.Empresa
		jOIN MovFlujo mfoc ON  mfoc.Omodulo = 'CXC'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = do.id
		JOIN CXC m (NOLOCK) ON mfoc.OID = m.ID AND m.Cliente=do.Contacto
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) 
		AND d.ContactoEspecifico IS NULL
		
		IF @TieneHist=1
		BEGIN
			Update ContD SET ContactoEspecifico=do.Contacto
		--SELECT d.ID,do.Contacto
			FROM ContD d (NOLOCK)
			JOIN cont c (NOLOCK) ON d.ID = c.ID 
			Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
			JOIN DineroD dd ON dd.ID=mf.OID
			JOIN Dinero do ON dd.Aplica=do.Mov AND dd.AplicaID=do.MovID AND c.Empresa=do.Empresa
			jOIN MovFlujo mfoc ON  mfoc.Omodulo = 'CXC'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = do.id
			JOIN BajioHist.dbo.CXC (NOLOCK) ON mfoc.OID = m.ID AND m.Cliente=do.Contacto
			WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) 
			--AND d.ID=@id
			AND C.Empresa=@Empresa
			AND d.ContactoEspecifico IS NULL
		END
END
/****************************************************************************************************/
/*DINERO CON ORIGEN CXC*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID 
Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
JOIN MovFlujo mfo ON mfo.Omodulo = 'DIN'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
JOIN MovFlujo mfoc ON mfoc.Omodulo = 'CXC'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = mfo.OID 
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0)
)
BEGIN
		
	
	Update ContD SET ContactoEspecifico = m.Cliente 
	--select *
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
	JOIN MovFlujo mfo ON mfo.Omodulo = 'DIN'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
	JOIN MovFlujo mfoc ON mfoc.Omodulo = 'CXC'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = mfo.OID
	JOIN CXC m (NOLOCK) ON mfoc.OID = m.ID 
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	--d.Ejercicio = 2009 AND 
	d.ContactoEspecifico IS NULL

	IF @TieneHist=1
	BEGIN	
		Update ContD SET ContactoEspecifico = m.Cliente 
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK)ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN MovFlujo mfo ON mfo.Omodulo = 'DIN'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
		JOIN MovFlujo mfoc ON mfoc.Omodulo = 'CXC'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = mfo.OID
		JOIN BajioHist.dbo.CXC m (NOLOCK) ON mfoc.OID = m.ID 
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		--d.Ejercicio = 2009 AND 
		d.ContactoEspecifico IS NULL 

	END
END
/****************************************************************************************************/
/*DINERO CON ORIGEN GASTO*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID 
Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
JOIN MovFlujo mfo ON mfo.Omodulo = 'DIN'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
JOIN MovFlujo mfoc ON mfoc.Omodulo = 'GAS'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = mfo.OID  
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0))
BEGIN
	Update ContD SET ContactoEspecifico = m.Acreedor
	--SELECT mfoc.*, c.Estatus, d.ContactoEspecifico--, m.Acreedor,*
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
	JOIN MovFlujo mfo ON mfo.Omodulo = 'DIN'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
	JOIN MovFlujo mfoc ON mfoc.Omodulo = 'GAS'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = mfo.OID
	JOIN Gasto m (NOLOCK) ON mfoc.OID = m.ID 
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	d.ContactoEspecifico IS NULL 

	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Acreedor
		--SELECT mfoc.*, c.Estatus, d.ContactoEspecifico--, m.Acreedor,*
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN MovFlujo mfo ON mfo.Omodulo = 'DIN'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
		JOIN MovFlujo mfoc ON mfoc.Omodulo = 'GAS'  AND mfoc.Dmodulo = 'DIN' AND mfoc.DID = mfo.OID
		JOIN BajioHist.dbo.Gasto m (NOLOCK) ON mfoc.OID = m.ID 
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		d.ContactoEspecifico IS NULL 

	END
END
/****************************************************************************************************/
/*DINERO CON ORIGEN VENTA SIN SOLICITUD INGRESOS*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID 
Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
JOIN MovFlujo mfo ON mfo.Omodulo = 'VTAS'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID 
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) )
BEGIN
	Update ContD SET ContactoEspecifico = m.Cliente
	--SELECT mfo.*, c.Estatus, d.ContactoEspecifico--, m.Acreedor,*
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
	JOIN MovFlujo mfo ON mfo.Omodulo = 'VTAS'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
	JOIN Venta m (NOLOCK) ON mfo.OID = m.ID 
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	d.ContactoEspecifico IS NULL


	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Cliente
		--SELECT mfoc.*, c.Estatus, d.ContactoEspecifico--, m.Acreedor,*
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN MovFlujo mfo ON mfo.Omodulo = 'VTAS'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
		JOIN BajioHist.dbo.Venta m (NOLOCK) ON mfo.OID = m.ID 
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		d.ContactoEspecifico IS NULL 

	END
END
/****************************************************************************************************/
/*DINERO CON ORIGEN CXC SIN SOLICITUD INGRESOS*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID 
Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
JOIN MovFlujo mfo ON mfo.Omodulo = 'CXC'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID 
WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) )
BEGIN
	Update ContD SET ContactoEspecifico = m.Cliente
	--SELECT mfo.*, c.Estatus, d.ContactoEspecifico--, m.Acreedor,*
	FROM ContD d (NOLOCK)
	JOIN cont c (NOLOCK) ON d.ID = c.ID 
	Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
	JOIN MovFlujo mfo ON mfo.Omodulo = 'CXC'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
	JOIN CXC m (NOLOCK) ON mfo.OID = m.ID 
	WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
	d.ContactoEspecifico IS NULL 

	IF @TieneHist=1
	BEGIN
		Update ContD SET ContactoEspecifico = m.Cliente
		--SELECT mfoc.*, c.Estatus, d.ContactoEspecifico--, m.Acreedor,*
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID 
		Join movFlujo mf ON mf.Omodulo = 'DIN'  AND mf.Dmodulo = 'CONT' AND mf.DID = c.ID 
		JOIN MovFlujo mfo ON mfo.Omodulo = 'CXC'  AND mfo.Dmodulo = 'DIN' AND mfo.DID = mf.OID
		JOIN BajioHist.dbo.CXC m (NOLOCK) ON mfo.OID = m.ID 
		WHERE d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) AND
		d.ContactoEspecifico IS NULL 

	END
END
/****************************************************************************************************/
/*SI AUN HAY NULO PASAR DEL CONTACTO ENCABEZADO A DETALLE, SE DA EN POLIZAS DIRECTAS*/
/****************************************************************************************************/
UPDATE d SET d.ContactoEspecifico = c.Contacto
FROM  ContD d (NOLOCK)
join Cont c (NOLOCK) ON d.ID = c.ID 
WHERE d.ContactoEspecifico IS NULL
AND d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) 
AND c.Estatus = 'CONCLUIDO'


/****************************************************************************************************/
/*SI AUN HAY NULO PASAR DEL CONTACTO DE CONTREG A CONTD */
/****************************************************************************************************/
UPDATE d SET d.ContactoEspecifico = c.Contacto
FROM  ContREg cr (NOLOCK)
JOIN ContD d (NOLOCK) ON d.ID = cr.ID AND d.Cuenta = cr.Cuenta AND (d.Haber = cr.Haber OR d.Debe = cr.HAber)
join Cont c (NOLOCK) ON d.ID = c.ID 
WHERE d.ContactoEspecifico IS NULL
AND cr.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0) 
--AND d.Id = 1246211
AND c.Estatus = 'CONCLUIDO'

/****************************************************************************************************/
/* YA TENIENDO EL CONTACTO COPIAR EL CONTACTO DE LA POLIZA ORIGEN A LA POLIZA DE LA CONTROLADORA (INTERCOMPAÑIA)*/
/****************************************************************************************************/
IF EXISTS (SELECT 1 FROM ContD d
JOIN cont c ON d.ID = c.ID AND c.OrigenTipo = 'CTRL/E' JOIN ContD do ON ISNUMERIC(c.OrigenID) = 1 AND do.ID = CONVERT(int, c.OrigenID) 
WHERE  d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0))
BEGIN
	IF @TieneCtrl=1
	BEGIN
		Update d SET ContactoEspecifico = do.ContactoEspecifico
		--select *
		FROM ContD d (NOLOCK)
		JOIN cont c (NOLOCK) ON d.ID = c.ID AND c.OrigenTipo = 'CTRL/E'
		--JOIN ContD do ON do.ID = TRY_CONVERT(int, c.OrigenID) AND d.Cuenta = do.Cuenta
		JOIN ContD do (NOLOCK) ON ISNUMERIC(c.OrigenID) = 1 AND do.ID = CONVERT(int, c.OrigenID)
		WHERE  d.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0)
		AND d.ContactoEspecifico IS NULL

	END
END

/****************************************************************************************************/
/* COPIAR EL CONTACTO DE CONTD (DETALLE) A CONTREG*/
/****************************************************************************************************/
Update cr SET ContactoEspecifico = d.ContactoEspecifico
--SELECT top 1000 * 
FROM  ContREg cr
JOIN ContD d ON d.ID = cr.ID AND d.Cuenta = cr.Cuenta --AND (d.Haber = cr.Haber OR d.Debe = cr.HAber)
WHERE cr.ContactoEspecifico IS NULL
AND cr.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0)

/****************************************************************************************************/
/* SI AUN HAY NULO EN CONTREG COPIAR EL CONTACTO DE CONT (ENCABEZADO) A CONTREG*/
/****************************************************************************************************/
UPDATE cr SET cr.ContactoEspecifico = c.Contacto
FROM  ContREg cr
JOIN ContD d ON d.ID = cr.ID AND d.Cuenta = cr.Cuenta --AND (d.Haber = cr.Haber OR d.Debe = cr.HAber)
join Cont c ON d.ID = c.ID 
WHERE cr.ContactoEspecifico IS NULL
AND cr.Cuenta IN (SELECT Cuenta FROM DICOCtasActualizar WHERE Procesado=0)
--AND d.Id = 1246211
AND c.Estatus = 'CONCLUIDO'


/*INSERTAR A UNA TABLA DE PASO LOS IDS QUE TIENEN DIFERENTE MODULO ENTRE CONT Y CONTREG*/
	select C.ID, r.Modulo, r.ModuloID, c.OrigenTipo, c.Origen, c.OrigenId, c.Contacto, r.ContactoEspecifico, 'ModuloOk'= '', 'ModuloIdOk'= 0 
	INTO #ContModuloDiF 
	from ContReg r
	join Cont c on c.ID = r.ID
	WHERE ISNULL(c.OrigenTipo, 'CONT') <> ISNULL(r.Modulo,'CONT')  


/*RASTREAR MODULO Y MODULOID DE LA TABLA MOV*/
	UPDATE #ContModuloDiF SET ModuloOk =  m.Modulo, ModuloIDOk = m.ID  FROM #ContModuloDiF d
	Join Mov m ON d.OrigenTipo = m.Modulo AND d.Origen = m.Mov and d.OrigenID = m.MovID


/*RASTREAR MODULO Y MODULOID DE LA TABLA MOVFLUJO*/
	UPDATE #ContModuloDiF SET ModuloOk =  m.OModulo, ModuloIDOk = m.OID FROM #ContModuloDiF d
	Join MovFlujo m ON 'CONT' = m.DModulo AND d.ID = m.DID 


/*ACTUALIZAR CONTACTO, MODULO Y MODULOID DE LOS DATOS ENCONTRADOS*/
	UPDATE ContReg SET Modulo = d.ModuloOK , ModuloID = d.ModuloIDOk, ContactoEspecifico = d.Contacto
	FROM ContReg r 
	JOIN #ContModuloDiF d ON r.ID = d.ID 

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
	SELECT 'PROCESO CONCLUIDO'
	
	UPDATE DICOCtasActualizar SET Procesado=1
	WHERE Procesado=0

	
	COMMIT TRAN
END
ELSE
	SELECT CAST(@OK AS VARCHAR(20))+' - '+@OKref 
	
RETURN
END