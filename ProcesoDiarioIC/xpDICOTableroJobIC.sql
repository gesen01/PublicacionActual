SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--EXEC xpDICOTableroIC 999,'05','20240401','20240430',NULL
--EXEC xpDICOTableroIC 999,'05','20231226','20231226','210-102-000'
--EXEC xpDICOTableroJobIC 999,'09','210-100-000',1,0,1,0
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpDICOTableroJobIC')
DROP PROCEDURE xpDICOTableroJobIC
GO
CREATE PROCEDURE xpDICOTableroJobIC
@Estacion	INT,
@Empresa	VARCHAR(10),
@Cuenta     VARCHAR(25)=NULL,
@VerTablero BIT,  --Mostrar polizas con diferencia
@Procesar   BIT,  --Regenerar polizas
@Silencio	BIT,  --Bit que permite ocultar el tablero de poliza a corregir cuando se ejecute con este bit apagado
@Debug		BIT	  --Depurar
AS
BEGIN
	CREATE TABLE #ContT_tbl (
    ID			    INT		  NOT NULL,                                                                                                                                                                             
    OrigenID        VARCHAR(30) NULL,
    FechaEmision	DATETIME	  NOT NULL,
    FechaContable   DATETIME    NULL,
    Empresa		    VARCHAR(10) NOT NULL,
    Sucursal		INT		  NOT NULL,
    Estatus			VARCHAR(15)	NULL,
    Modulo          VARCHAR(5)  NULL,
    Contacto        VARCHAR(20) NULL,
    Debe			FLOAT	  NULL,
    Haber			FLOAT	  NULL
	)



IF @Cuenta IN ('(TODOS)',NULL,'','(Todos)')
    SELECT @Cuenta=NULL

IF @VerTablero=1
BEGIN

DELETE FROM DICOTableroIC WHERE Estacion=@Estacion

INSERT INTO #ContT_tbl
SELECT c.ID,c.OrigenID,c.FechaEmision,c.FechaContable,c.Empresa,c.Sucursal
	 ,c.Estatus,c.OrigenTipo,c.Contacto
	 ,SUM(ISNULL(cd.Debe,0)) AS 'Debe'
	 ,SUM(ISNULL(cd.Haber,0)) AS 'Haber'
FROM dbo.Cont c WITH(NOLOCK)
JOIN dbo.ContD cd WITH(NOLOCK) ON cd.ID = c.ID
WHERE c.Empresa=@Empresa
AND c.Logico1=0
AND ISNULL(cd.Logico1,0)=0
AND c.Estatus='CONCLUIDO'
AND (ISNULL(@Cuenta,'')='' OR cd.cuenta=@Cuenta)
AND NOT EXISTS(SELECT 1 FROM DICOContIDIC d WHERE c.ID=d.ID AND cd.Cuenta=d.Cuenta)
GROUP BY c.ID,c.OrigenID,c.FechaEmision,c.Empresa,c.Sucursal
	,c.FechaContable,c.Estatus,c.OrigenTipo,c.Contacto
ORDER BY c.ID

IF @Debug=1
	SELECT * FROM #ContT_tbl  --WHERE ID=19232955 ORDER BY ID

INSERT INTO DICOTableroIC
--Extrae polizas que tienen diferencia entre Cont y ContReg
SELECT @Estacion,cr.ID, cr.Empresa,cr.Sucursal,ct.FechaEmision,ct.FechaContable,ct.Estatus,ct.Modulo,ct.OrigenID
    ,SUM(ISNULL(cr.Debe,0)) AS 'DebeContReg'
    ,SUM(ISNULL(cr.Haber,0)) AS 'HaberContReg'
    ,ct.Debe
    ,ct.Haber
    ,ROUND(ct.Debe-SUM(ISNULL(cr.Debe,0)),2) AS 'DiferenciaDebe'
    ,ROUND(ct.Haber-SUM(ISNULL(cr.Haber,0)),2) AS 'DiferenciaHaber'
	,'Diferencia-Cont/ContReg'
FROM #ContT_tbl ct 
LEFT JOIN ContReg AS cr WITH(NOLOCK) ON ct.ID = cr.ID 
WHERE cr.Empresa=@Empresa
AND (ISNULL(@Cuenta,'')='' OR cr.Cuenta=@Cuenta)
GROUP BY cr.ID, cr.Empresa,cr.Sucursal,ct.Debe,ct.Haber,ct.FechaEmision,ct.FechaContable,ct.Estatus,ct.OrigenID,ct.Modulo,ct.Contacto
HAVING (ABS(ROUND(ct.Debe-SUM(ISNULL(cr.Debe,0)),2))<>0 OR ABS(ROUND(ct.Haber-SUM(ISNULL(cr.Haber,0)),2))<>0)
UNION ALL
--Extrae Polizas que existen en Cont pero no en ContReg
SELECT @Estacion,ct.ID, ct.Empresa,ct.Sucursal,ct.FechaEmision,ct.FechaContable,ct.Estatus,ct.Modulo,ct.OrigenID
    ,0 AS 'DebeContReg'
    ,0 AS 'HaberContReg'
    ,ct.Debe
    ,ct.Haber
    ,ct.Debe-0 AS 'DiferenciaDebe'
    ,ct.Haber-0 AS 'DiferenciaHaber'
	,'ContRegNulo'
FROM #ContT_tbl ct 
WHERE ct.Empresa=@Empresa
AND NOT EXISTS(SELECT 1 FROM ContReg c WITH(NOLOCK) WHERE c.ID=ct.ID AND (ISNULL(@Cuenta,'')='' OR c.Cuenta=@Cuenta))
UNION ALL
--Extrae polizas cuyas cuentas no existan en ContReg y si en ContD
SELECT @Estacion,cr.ID, cr.Empresa,cr.Sucursal,NULL,NULL,NULL,cr.Modulo,CAST(cr.ModuloID AS VARCHAR(30))
    ,SUM(ISNULL(cr.Debe,0)) AS 'DebeContReg'
    ,SUM(ISNULL(cr.Haber,0)) AS 'HaberContReg'
    ,0
    ,0
    ,ROUND(0-SUM(ISNULL(cr.Debe,0)),2) AS 'DiferenciaDebe'
    ,ROUND(0-SUM(ISNULL(cr.Haber,0)),2) AS 'DiferenciaHaber'
	,'Diferencia-ContReg/Cont'
FROM  ContReg AS cr WITH(NOLOCK)
WHERE cr.Empresa=@Empresa
AND (ISNULL(@Cuenta,'')='' OR cr.Cuenta=@Cuenta)
AND NOT EXISTS(SELECT 1 FROM ContD cd WITH(NOLOCK) WHERE cr.ID=cd.ID AND cr.Cuenta=cd.Cuenta AND (ISNULL(@Cuenta,'')='' OR cr.Cuenta=@Cuenta))
GROUP BY cr.ID, cr.Empresa,cr.Sucursal,cr.Modulo,cr.ModuloID
UNION ALL
--Este caso muestra polizas cuyo modulo no sea igual entre la poliza y contreg
SELECT DISTINCT @Estacion, ct.ID, ct.Empresa, ct.Sucursal, ct.FechaEmision, ct.FechaContable, ct.Estatus,ct.Modulo,ct.OrigenID
       ,SUM(ISNULL(cr.Debe,0)) AS 'DebeContReg'
        ,SUM(ISNULL(cr.Haber,0)) AS 'HaberContReg'
       ,ct.Debe
       ,ct.Haber
       ,ROUND(ct.Debe-SUM(ISNULL(cr.Debe,0)),2) AS 'DiferenciaDebe'
       ,ROUND(ct.Haber-SUM(ISNULL(cr.Haber,0)),2) AS 'DiferenciaHaber'
      ,'ModuloIncorrecto'
FROM #ContT_tbl ct 
JOIN ContReg AS cr WITH(NOLOCK) ON cr.ID = ct.ID AND cr.Empresa = ct.Empresa AND cr.Sucursal = ct.Sucursal
WHERE ct.Modulo<>cr.Modulo
GROUP BY ct.ID, ct.Empresa, ct.Sucursal, ct.FechaEmision, ct.FechaContable, ct.Estatus,ct.Modulo,ct.OrigenID,ct.Debe,ct.Haber
UNION ALL
--Este caso muestra polizas cuyas empresas sean incorretas entre cont y contreg
SELECT DISTINCT @Estacion, ct.ID, ct.Empresa, ct.Sucursal, ct.FechaEmision, ct.FechaContable, ct.Estatus,ct.Modulo,ct.OrigenID
       ,SUM(ISNULL(cr.Debe,0)) AS 'DebeContReg'
        ,SUM(ISNULL(cr.Haber,0)) AS 'HaberContReg'
       ,ct.Debe
       ,ct.Haber
       ,ROUND(ct.Debe-SUM(ISNULL(cr.Debe,0)),2) AS 'DiferenciaDebe'
       ,ROUND(ct.Haber-SUM(ISNULL(cr.Haber,0)),2) AS 'DiferenciaHaber'
      ,'EmpresaIncorrecta'
FROM #ContT_tbl ct 
JOIN ContReg AS cr WITH(NOLOCK) ON cr.ID = ct.ID 
WHERE ct.Empresa<>cr.Empresa
GROUP BY ct.ID, ct.Empresa, ct.Sucursal, ct.FechaEmision, ct.FechaContable, ct.Estatus,ct.Modulo,ct.OrigenID,ct.Debe,ct.Haber

--SELECT @Estacion,C.ID,c.Empresa,c.Sucursal,c.FechaEmision,c.FechaContable,c.Estatus,c.Modulo,c.OrigenID
--	  ,c.Debe
--	  ,c.Haber
--	  ,cr.Debe
--	  ,cr.Haber
--	  ,0
--	  ,0
--	  ,'SinCtaContableContReg'
--FROM #ContCtasT_tbl c
----JOIN ContReg cr ON c.ID=cr.ID AND c.Empresa=cr.Empresa AND c.Sucursal=cr.Sucursal 
--WHERE EXISTS(SELECT 1 FROM ContReg c WHERE c.ID=cr.ID AND  c.Cuenta IS NULL)

IF @Silencio=1
	SELECT * FROM DICOTableroIC WHERE Estacion=@Estacion

END

IF @Procesar=1
BEGIN
	
	DELETE FROM ListaSt WHERE Estacion=@Estacion

	INSERT INTO ListaSt(Estacion,Clave)
	SELECT @Estacion,ID
	FROM  DICOTableroIC 
	WHERE Estacion=@Estacion
	AND Tipo <> 'SinDiferencia'

	IF EXISTS(SELECT 1 FROM ListaSt WHERE Estacion=@Estacion)
		EXEC xpDICOCorrecionIC  @Estacion,@Empresa,@Cuenta,0
		
    INSERT INTO DICOContIDIC
    SELECT d.ID,@Cuenta,d.FechaContable,@Empresa,CAST(GETDATE() AS DATE)
    FROM DICOTableroIC d
    WHERE NOT EXISTS(SELECT 1 FROM DICOContIDIC c WHERE d.ID=c.ID)
END

RETURN
END

