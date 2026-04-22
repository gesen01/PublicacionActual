SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--EXEC xpDICOTableroIC 999,'05','20240401','20240430',NULL
--EXEC xpDICOTableroIC 999,'05','20231226','20231226','210-102-000'
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpDICOTableroIC')
DROP PROCEDURE xpDICOTableroIC
GO
CREATE PROCEDURE xpDICOTableroIC
@Estacion	INT,
@Empresa	VARCHAR(10),
@FechaD		DATETIME,
@FechaA		DATETIME,
@Cuenta     VARCHAR(25)=NULL
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

	CREATE TABLE #ContCtasT_tbl (
    ID			    INT		  NOT NULL,
    OrigenID        VARCHAR(30) NULL,
    FechaEmision	DATETIME	  NOT NULL,
    FechaContable   DATETIME    NULL,
    Empresa		    VARCHAR(10) NOT NULL,
    Sucursal		INT		  NOT NULL,
    Estatus			VARCHAR(15)	NULL,
    Modulo          VARCHAR(5)  NULL,
	Cuenta			VARCHAR(25)	NULL,
    Debe			FLOAT	  NULL,
    Haber			FLOAT	  NULL
)

CREATE TABLE #IntegracionCont_tbl (
	ID              INT             NOT NULL,
	Empresa         VARCHAR(5)      NULL,
	Sucursal        INT             NULL,
	FechaEmision    DATETIME        NULL,
	FechaContable   DATETIME        NULL,
	Estatus         VARCHAR(15)     NULL,
	OrigenID        VARCHAR(30)     NULL,
	Modulo          VARCHAR(5)      NULL,
	Contacto        VARCHAR(20)     NULL,
	DebeContReg     FLOAT           NULL,
	HaberContReg    FLOAT			NULL,
	DebeCont		FLOAT			NULL,
	HaberCont       FLOAT           NULL,
	DifDebe         FLOAT           NULL,
	DifHaber		FLOAT			NULL	
)

DELETE FROM DICOTableroIC WHERE Estacion=@Estacion

IF @Cuenta IN ('(TODOS)',NULL,'','(Todos)')
    SELECT @Cuenta=NULL

INSERT INTO #ContT_tbl
SELECT c.ID,c.OrigenID,c.FechaEmision,c.FechaContable,c.Empresa,c.Sucursal
	 ,c.Estatus,c.OrigenTipo,c.Contacto
	 ,SUM(ISNULL(cd.Debe,0)) AS 'Debe'
	 ,SUM(ISNULL(cd.Haber,0)) AS 'Haber'
FROM dbo.Cont c WITH(NOLOCK)
JOIN dbo.ContD cd WITH(NOLOCK) ON cd.ID = c.ID
WHERE c.FechaContable BETWEEN @FechaD AND @FechaA
AND c.Empresa=@Empresa
AND c.Logico1=0
AND c.Estatus='CONCLUIDO'
AND (ISNULL(@Cuenta,'')='' OR cd.cuenta=@Cuenta)
GROUP BY c.ID,c.OrigenID,c.FechaEmision,c.Empresa,c.Sucursal
	,c.FechaContable,c.Estatus,c.OrigenTipo,c.Contacto
ORDER BY c.ID

--SELECT * FROM #ContT_tbl  WHERE ID=19232955 ORDER BY ID

INSERT INTO #ContCtasT_tbl
SELECT c.ID,c.OrigenID,c.FechaEmision,c.FechaContable,c.Empresa,c.Sucursal
	 ,c.Estatus,c.OrigenTipo,cd.Cuenta
	 ,SUM(ISNULL(cd.Debe,0)) AS 'Debe'
	 ,SUM(ISNULL(cd.Haber,0)) AS 'Haber'
FROM dbo.Cont c WITH(NOLOCK)
JOIN dbo.ContD cd WITH(NOLOCK) ON cd.ID = c.ID
WHERE c.FechaContable BETWEEN @FechaD AND @FechaA
AND c.Empresa=@Empresa
AND c.Logico1=0
AND c.Estatus='CONCLUIDO'
AND (ISNULL(@Cuenta,'')='' OR cd.cuenta=@Cuenta)
GROUP BY c.ID,c.OrigenID,c.FechaEmision,c.Empresa,c.Sucursal
	,c.FechaContable,c.Estatus,c.OrigenTipo,cd.Cuenta
ORDER BY c.ID

--SELECT * FROM #ContCtasT_tbl -- WHERE ID=3400231 ORDER BY ID


INSERT INTO #IntegracionCont_tbl
SELECT cr.ID, cr.Empresa,cr.Sucursal,ct.FechaEmision,ct.FechaContable,ct.Estatus,ct.OrigenID,ct.Modulo,ct.Contacto
    ,SUM(ISNULL(cr.Debe,0)) AS 'DebeContReg'
    ,SUM(ISNULL(cr.Haber,0)) AS 'HaberContReg'
    ,ct.Debe
    ,ct.Haber
    ,ROUND(ct.Debe-SUM(ISNULL(cr.Debe,0)),2) AS 'DiferenciaDebe'
    ,ROUND(ct.Haber-SUM(ISNULL(cr.Haber,0)),2) AS 'DiferenciaHaber'
FROM #ContT_tbl ct 
JOIN ContReg AS cr WITH(NOLOCK) ON ct.ID = cr.ID 
WHERE cr.Empresa=@Empresa
AND (ISNULL(@Cuenta,'')='' OR cr.Cuenta=@Cuenta)
GROUP BY cr.ID, cr.Empresa,cr.Sucursal,ct.Debe,ct.Haber,ct.FechaEmision,ct.FechaContable,ct.Estatus,ct.OrigenID,ct.Modulo,ct.Contacto
UNION ALL
SELECT ct.ID, ct.Empresa,ct.Sucursal,ct.FechaEmision,ct.FechaContable,ct.Estatus,ct.OrigenID,ct.Modulo,ct.Contacto
    ,0 AS 'DebeContReg'
    ,0 AS 'HaberContReg'
    ,ct.Debe
    ,ct.Haber
    ,ct.Debe-0 AS 'DiferenciaDebe'
    ,ct.Haber-0 AS 'DiferenciaHaber'
FROM #ContT_tbl ct 
WHERE ct.Empresa=@Empresa
AND NOT EXISTS(SELECT 1 FROM ContReg c WHERE c.ID=ct.ID AND (ISNULL(@Cuenta,'')='' OR c.Cuenta=@Cuenta))

--SELECT * FROM #IntegracionCont_tbl  where ID=19232955 ORDER BY ID

INSERT INTO DICOTableroIC
--Este caso valida que haya diferencia en el debe y haber entre contabilidad y contreg
SELECT @Estacion, i.ID, i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID,
       i.DebeContReg, i.HaberContReg
       ,i.DebeCont
       ,i.HaberCont
       ,i.DifDebe
       ,i.DifHaber
       ,IIF(ABS(i.DifDebe) > 0.1 OR ABS(i.DifHaber) > 0.1, 'ConDiferencia','SinDiferencia')
FROM #IntegracionCont_tbl i
WHERE IIF(ABS(i.DifDebe) > 0.1 OR ABS(i.DifHaber) > 0.1, 'ConDiferencia','SinDiferencia')='ConDiferencia'
UNION ALL
--Este caso muestra solo polizas que no tienen asignada cuenta en el contreg
SELECT DISTINCT @Estacion, i.ID, i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID,
       i.DebeContReg, i.HaberContReg, i.DebeCont, i.HaberCont, i.DifDebe,
       i.DifHaber
       ,'SinCuentaContReg'
FROM #IntegracionCont_tbl i
JOIN ContReg AS cr WITH(NOLOCK) ON cr.ID = i.ID AND cr.Empresa = i.Empresa AND cr.Sucursal = i.Sucursal
WHERE LTRIM(RTRIM(cr.Cuenta))=''
UNION ALL
--Este caso muestra polizas cuyo modulo no sea igual entre la poliza y contreg
SELECT DISTINCT @Estacion, i.ID, i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID,
       i.DebeContReg, i.HaberContReg
       ,i.DebeCont
       ,i.HaberCont
       ,i.DifDebe
       ,i.DifHaber
      ,'ModuloIncorrecto'
FROM #IntegracionCont_tbl i
JOIN ContReg AS cr WITH(NOLOCK) ON cr.ID = i.ID AND cr.Empresa = i.Empresa AND cr.Sucursal = i.Sucursal
WHERE i.Modulo<>cr.Modulo
UNION ALL
--Este caso muestra polizas donde el orien ID este vacio
SELECT @Estacion, i.ID, i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID,
       i.DebeContReg, i.HaberContReg, i.DebeCont, i.HaberCont, i.DifDebe,
       i.DifHaber
       ,'SinOrigenID'
FROM #IntegracionCont_tbl i
WHERE ISNULL(i.OrigenID,'')=''
AND ISNULL(i.Modulo,'')<>''
AND EXISTS(SELECT 1 FROM MovFlujo AS mf WITH(NOLOCK) WHERE i.ID=mf.DID AND i.Empresa=mf.Empresa AND i.Sucursal=mf.Sucursal AND mf.DModulo='CONT')
UNION ALL
--Este caso muestra polizas que no tienen modulo ni moduloID pero que existen en MovFlujo
SELECT DISTINCT @Estacion, i.ID, i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID,
       i.DebeContReg, i.HaberContReg, i.DebeCont, i.HaberCont, i.DifDebe,
       i.DifHaber
       ,'SinOrigenTipo'
FROM #IntegracionCont_tbl i
JOIN MovFlujo AS mf WITH(NOLOCK) ON mf.DID=i.ID AND mf.Empresa = i.Empresa AND mf.Sucursal = i.Sucursal AND mf.DModulo='CONT'
WHERE i.Modulo IS NULL
AND i.OrigenID IS NULL
AND mf.OModulo IS NOT NULL
AND mf.OMovID IS NOT NULL
UNION ALL
----Caso en donde se observan polizas que no tienen las mismas cuentas contables en cont y contreg
SELECT @Estacion, i.ID, i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID,
       SUM(ISNULL(r.Debe,0))
       ,SUM(ISNULL(r.Haber,0))
       ,SUM(i.Debe)
       ,SUM(i.Haber)
       ,NULL
       ,NULL,
       'CtaContDistinc'
FROM #ContCtasT_tbl i
LEFT JOIN ContReg r WITH(NOLOCK) ON i.ID=r.ID AND i.Cuenta=r.Cuenta
WHERE r.Cuenta IS NULL
GROUP BY i.ID, i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID
UNION ALL
SELECT @Estacion, ISNULL(i.ID,r.ID), i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID,
       SUM(r.Debe)
       ,SUM(r.Haber)
       ,SUM(ISNULL(i.Debe,0))
       ,SUM(ISNULL(i.Haber,0))
       ,NULL
       ,NULL
       ,'CtaContDistinc'
FROM ContReg r WITH(NOLOCK)
LEFT JOIN #ContCtasT_tbl i ON i.ID = r.ID AND r.Empresa = i.Empresa AND r.Cuenta=i.Cuenta
WHERE i.Cuenta <> r.Cuenta
GROUP BY ISNULL(i.ID,r.ID), i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID
--UNION ALL
----Polizas que no tienen moudulo y origen ID y no estan presentes en el movflujo
--SELECT @Estacion, i.ID, i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID,
--       i.DebeContReg, i.HaberContReg, i.DebeCont, i.HaberCont, i.DifDebe,
--       i.DifHaber
--       ,'SinOrigenID'
--FROM #IntegracionCont_tbl i
--WHERE ISNULL(i.OrigenID,'')=''
--AND ISNULL(i.Modulo,'')=''
--AND NOT EXISTS(SELECT 1 FROM MovFlujo AS mf WITH(NOLOCK) WHERE i.ID=mf.DID AND i.Empresa=mf.Empresa AND i.Sucursal=mf.Sucursal AND mf.DModulo='CONT')
--UNION ALL
----Polizas donde el contreg no tiene aplicado conacto especifico
--SELECT DISTINCT @Estacion, i.ID, i.Empresa, i.Sucursal, i.FechaEmision, i.FechaContable, i.Estatus,i.Modulo,i.OrigenID,
--       i.DebeContReg, i.HaberContReg, i.DebeCont, i.HaberCont, i.DifDebe,
--       i.DifHaber
--       ,'SinContacto'
--FROM #IntegracionCont_tbl i
--JOIN ContReg AS cr WITH(NOLOCK) ON cr.ID = i.ID AND cr.Empresa = i.Empresa AND cr.Sucursal = i.Sucursal
--WHERE LTRIM(RTRIM(cr.ContactoEspecifico)) IS NULL

RETURN
END

