SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--EXEC spDWHVerDesgloseCuenta 'Contacto','210-100-000','02',NULL,2025,1,13,'Pesos','20250101'
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='spDWHVerDesgloseCuenta')
DROP PROCEDURE spDWHVerDesgloseCuenta
GO

CREATE PROCEDURE     spDWHVerDesgloseCuenta

@Filtro 		VARCHAR(20),
@Cuenta			CHAR(15),
@Empresa		CHAR(5),
@Sucursal		INT,
@Ejercicio		INT,
@PeriodoD		INT,
@PeriodoA		INT,
@Moneda			CHAR(20),
@FechaSaldoInicial	DATETIME
AS
BEGIN
IF @Moneda	 IN ('','NULL','(Todas)','(Todos)', NULL) select @Moneda =  NULL
IF @Filtro = '' SELECT @Filtro = 'Contacto'
CREATE TABLE #Contacto(
Contacto	char(10)	NULL,
CtoTipo		varchar(20)	NULL)
CREATE TABLE #Movimiento(
Movimiento		char(20)	NULL)
CREATE TABLE #Proyecto(
Proyecto		varchar(50)	NULL)
CREATE TABLE #UEN(
UEN			int NULL)
CREATE TABLE #FE(
FechaEmision	datetime NULL)
CREATE TABLE #CC (
CentroCostos	varchar(20) NULL)
CREATE TABLE #CtaDin (
CuentaDinero	char(10) NULL)
CREATE TABLE #DWHSI(
Contacto		CHAR(10)	NULL,
Movimiento		char(20)	NULL,
CtoTipo		varchar(20)	NULL,
Proyecto		varchar(50)	NULL,
UEN			int		NULL,
FechaEmision	datetime	NULL,
CentroCostos	char(20)	NULL,
CuentaDinero	char(10)	NULL,
Saldo		float		NULL)
CREATE TABLE #DWH(
Contacto		CHAR(10)	NULL,
Movimiento		char(20)	NULL,
CtoTipo		VARCHAR(20)	NULL,
Debe		float		NULL,
Haber		float	NULL,
Proyecto		VARCHAR(50)	NULL,
UEN			INT		NULL,
FechaEmision	DATETIME	NULL,
CentroCostos	VARCHAR(20) 	NULL,
CuentaDinero	char(10)	NULL)

--IGGR. Tabla que almacenara las cuentas corregidas
DECLARE @CtasCorregidas TABLE(
	Cuenta		VARCHAR(35)	
)
INSERT INTO @CtasCorregidas
SELECT DISTINCT Cuenta FROM DICOCtasActualizar

/*      SELECT @Inicio = SUM(ISNULL(a2.Cargos,0))-SUM(ISNULL(a2.Abonos,0))
FROM Acum a2
WHERE a2.Empresa = @Empresa
AND a2.Rama = 'CONT'
AND a2.Ejercicio = @Ejercicio
AND a2.Periodo BETWEEN 0 AND @PeriodoD-1
AND a2.Cuenta = @Cuenta
AND ISNULL(a2.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, a2.Sucursal), 0)
AND a2.Moneda = @Moneda
*/
--IGGR. Toda la seccion de contacto se vera afectada por aquellas consultas que utiliza las cuentas corregidas y las naturales
IF @Filtro = 'Contacto'
BEGIN
	--IGGR. Se valida si la cuenta seleccionada a desplegar esta o no dentro de la lista de cuentas corregidas
	IF EXISTS(SELECT 1 FROM @CtasCorregidas AS cc WHERE cc.Cuenta=@Cuenta)
	BEGIN
		INSERT INTO #DWHSI(Contacto, CtoTipo, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero, Saldo)
					SELECT
					ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''),
					ISNULL(ISNULL(m.Ctotipo, c.ContactoTipo),''),
					--ISNULL(c.ContactoTipo, ''),
					'',
					'',
					'',
					'',
					'',
					SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0))
					FROM ContReg r
					JOIN Cont c ON c.ID = r.ID 
					--AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
					 LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
					 LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov
					 WHERE mt.modulo = 'CONT' AND
					mt.clave IN ('CONT.P','CONT.C') AND
					c.Estatus = 'CONCLUIDO' AND
					  r.Cuenta = @Cuenta AND r.empresa = @Empresa
					AND ISNULL(c.Sucursal, '') = ISNULL(ISNULL(@Sucursal, c.Sucursal), '')
					AND 
					   (
						(c.Ejercicio < @ejercicio) 
						OR 
						(c.Ejercicio = @ejercicio AND c.Periodo <= (@PeriodoD - 1)) 
						)
					AND c.FechaContable < @FechaSaldoInicial -- Armando
					--GROUP BY ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''), c.ContactoTipo
					GROUP BY ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''), ISNULL(ISNULL(m.Ctotipo, c.ContactoTipo),'')
					HAVING SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0)) <> 0
				
		INSERT INTO #DWH (Contacto, CtoTipo, Debe, Haber, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero)
				SELECT
				ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''),
				ISNULL(ISNULL(m.Ctotipo, c.ContactoTipo),''),
				--ISNULL(c.ContactoTipo, ''),
				Debe = SUM(ISNULL(r.Debe,0)),
				Haber = SUM(ISNULL(r.Haber,0)),
				NULL,
				NULL,
				NULL,
				NULL,
				NULL
				FROM
				Cont c
				LEFT OUTER JOIN ContReg r ON c.ID = r.ID  
				--AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo 
				AND r.Empresa = c.Empresa
				LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
				LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov
				WHERE  ISNULL(mt.modulo,'CONT') = 'CONT' AND
				mt.clave IN ('CONT.P','CONT.C') AND
				c.Estatus = 'CONCLUIDO' AND
				isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
				r.cuenta = @Cuenta AND r.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
				ISNULL(c.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, c.Sucursal), 0)
				--GROUP BY ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''), c.ContactoTipo
				GROUP BY ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''), ISNULL(ISNULL(m.Ctotipo, c.ContactoTipo),'')
	END 
	ELSE
	BEGIN
		INSERT INTO #DWHSI(Contacto, CtoTipo, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero, Saldo)
					SELECT
					ISNULL(ISNULL(r.ContactoEspecifico, m.Contacto),''),
					ISNULL(m.CtoTipo, ''),
					'',
					'',
					'',
					'',
					'',
					SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0))
					FROM ContReg r
					JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
					JOIN Cont c ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
					WHERE r.Cuenta = @Cuenta AND r.empresa = @Empresa
					AND ISNULL(m.Sucursal, '') = ISNULL(ISNULL(@Sucursal, m.Sucursal), '')
					AND c.FechaContable < @FechaSaldoInicial -- Armando
					GROUP BY ISNULL(ISNULL(r.ContactoEspecifico, m.Contacto),''), m.CtoTipo
					HAVING SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0)) <> 0
					
		INSERT INTO #DWH (Contacto, CtoTipo, Debe, Haber, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero)
				SELECT
				ISNULL(ISNULL(r.ContactoEspecifico, m.Contacto),''),
				ISNULL(m.CtoTipo, ''),
				Debe = SUM(ISNULL(r.Debe,0)),
				Haber = SUM(ISNULL(r.Haber,0)),
				NULL,
				NULL,
				NULL,
				NULL,
				NULL
				FROM
				Cont c
				LEFT OUTER JOIN ContReg r ON c.ID = r.ID  AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo AND r.Empresa = c.Empresa
				LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
				LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov
				WHERE  mt.modulo = 'CONT' AND
				mt.clave IN ('CONT.P','CONT.C') AND
				c.Estatus = 'CONCLUIDO' AND
				isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
				r.cuenta = @Cuenta AND r.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
				ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
				GROUP BY ISNULL(ISNULL(r.ContactoEspecifico, m.Contacto),''), m.CtoTipo
	END

INSERT INTO #Contacto (Contacto, CtoTipo)
SELECT DISTINCT ISNULL(Contacto,''), ISNULL(CtoTipo,'')
FROM #DWHSI
UNION
SELECT DISTINCT ISNULL(Contacto,''), ISNULL(CtoTipo,'')
FROM #DWH
SELECT c.Contacto,
'Nombre' = CASE WHEN c.CtoTipo = 'Cliente' THEN
(SELECT Nombre FROM Cte WHERE Cliente = c.Contacto)
ELSE
(SELECT Nombre FROM Prov WHERE Proveedor = c.Contacto)
END,
c.CtoTipo, d.Movimiento, /*'Inicio' = ISNULL(s.Saldo,0), */'Saldo' = ISNULL(s.Saldo,0), 'Debe' = ISNULL(d.Debe,0), 'Haber' = ISNULL(d.Haber,0), d.Proyecto, d.UEN, d.FechaEmision, d.CentroCostos, d.CuentaDinero, 'Descripcion' = Convert(char(100), '')
FROM #Contacto c
LEFT OUTER JOIN #DWHSI s ON c.Contacto = s.Contacto AND c.CtoTipo = s.CtoTipo
LEFT OUTER JOIN #DWH d ON c.Contacto = d.Contacto AND c.CtoTipo = d.CtoTipo
ORDER BY c.Contacto, c.CtoTipo

END
ELSE
IF @Filtro = 'Movimiento'
BEGIN
INSERT INTO #DWHSI(Movimiento, Saldo)
SELECT
m.Mov,
SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0))
FROM ContReg r
JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
JOIN Cont c ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
WHERE r.Cuenta = @Cuenta AND r.empresa = @Empresa
AND ISNULL(m.Sucursal, '') = ISNULL(ISNULL(@Sucursal, m.Sucursal), '')
AND c.FechaContable < @FechaSaldoInicial -- Armando
GROUP BY m.Mov
HAVING SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0)) <> 0
INSERT INTO #DWH (Movimiento, Debe, Haber)
SELECT
ISNULL(m.Mov, ''),
Debe = SUM(ISNULL(r.Debe,0)),
Haber = SUM(ISNULL(r.Haber,0))
FROM
Cont c
LEFT OUTER JOIN ContReg r ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo AND r.Empresa = c.Empresa
LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
LEFT OUTER JOIN MovTipo mt ON mt.mov = c.mov
WHERE mt.modulo = 'CONT' AND
mt.clave = 'CONT.P' AND
c.Estatus = 'CONCLUIDO' AND
isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
r.cuenta = @Cuenta AND r.Empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
GROUP BY ISNULL(m.Mov, '')
INSERT INTO #Movimiento (Movimiento)
SELECT DISTINCT ISNULL(Movimiento,'')
FROM #DWHSI
UNION
SELECT DISTINCT ISNULL(Movimiento,'')
FROM #DWH
SELECT d.Contacto, 'Nombre' = Convert(char(100), ''), d.CtoTipo, c.Movimiento,
/*'Inicio' = ISNULL(s.Saldo,0), */'Saldo' = ISNULL(s.Saldo,0), 'Debe' = ISNULL(d.Debe,0), 'Haber' = ISNULL(d.Haber,0), d.Proyecto, d.UEN, d.FechaEmision, d.CentroCostos, d.CuentaDinero, 'Descripcion' = Convert(char(100), '')
FROM #Movimiento c
LEFT OUTER JOIN #DWHSI s ON c.Movimiento = s.Movimiento
LEFT OUTER JOIN #DWH d ON c.Movimiento = d.Movimiento
ORDER BY c.Movimiento
END
ELSE
IF @Filtro = 'Proyecto'
BEGIN
INSERT INTO #DWHSI(Contacto, CtoTipo, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero, Saldo)
SELECT
'',
'',
ISNULL(m.Proyecto,''),
'',
'',
'',
'',
SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0))
FROM ContReg r
JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
JOIN Cont c ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
WHERE r.Cuenta = @Cuenta AND r.empresa = @Empresa
AND ISNULL(m.Sucursal, '') = ISNULL(ISNULL(@Sucursal, m.Sucursal), '')
AND c.FechaContable < @FechaSaldoInicial -- Armando
GROUP BY m.Proyecto
HAVING SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0)) <> 0
INSERT INTO #DWH (Contacto, CtoTipo, Debe, Haber, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero)
SELECT
NULL,
NULL,
Debe = SUM(ISNULL(r.Debe,0)),
Haber = SUM(ISNULL(r.Haber,0)),
ISNULL(m.Proyecto,''),
NULL,
NULL,
NULL,
NULL
FROM
Cont c
LEFT OUTER JOIN ContReg r ON c.ID = r.ID  AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo AND r.Empresa = c.Empresa
LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov AND
mt.modulo = 'CONT' AND
mt.clave = 'CONT.P'
WHERE  mt.modulo = 'CONT' AND
mt.clave = 'CONT.P' AND
c.Estatus = 'CONCLUIDO' AND
isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
r.cuenta = @Cuenta AND r.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
GROUP BY m.Proyecto
INSERT INTO #Proyecto
SELECT DISTINCT ISNULL(Proyecto,'')
FROM #DWHSI
UNION
SELECT DISTINCT ISNULL(Proyecto,'')
FROM #DWH
SELECT d.Contacto, 'Nombre' = Convert(char(100), ''), d.CtoTipo, d.Movimiento,
/*'Inicio' = ISNULL(@Inicio,0), */'Saldo' = ISNULL(s.Saldo,0), 'Debe' = ISNULL(d.Debe,0), 'Haber' = ISNULL(d.Haber,0), p.Proyecto, d.UEN, d.FechaEmision, d.CentroCostos, d.CuentaDinero, 'Descripcion' = Convert(char(100), '')
FROM #Proyecto p
LEFT OUTER JOIN #DWHSI s ON p.Proyecto = s.Proyecto
LEFT OUTER JOIN #DWH d ON p.Proyecto = d.Proyecto
ORDER BY p.Proyecto
END
ELSE
IF @Filtro = 'UEN'
BEGIN
	
	IF EXISTS(SELECT 1 FROM @CtasCorregidas AS cc WHERE cc.Cuenta=@Cuenta)
	BEGIN
		INSERT INTO #DWHSI(Contacto, CtoTipo, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero, Saldo)
				SELECT
					'',
					'',
					'',
					ISNULL(m.UEN,0),
					'',
					'',
					'',
					SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0))
					FROM ContReg r
					JOIN Cont c ON c.ID = r.ID 
					--AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
					 LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
					 LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov
					 WHERE mt.modulo = 'CONT' AND
					mt.clave IN ('CONT.P','CONT.C') AND
					c.Estatus = 'CONCLUIDO' AND
					  r.Cuenta = @Cuenta AND r.empresa = @Empresa
					AND ISNULL(c.Sucursal, '') = ISNULL(ISNULL(@Sucursal, c.Sucursal), '')
					AND 
					   (
						(c.Ejercicio < @ejercicio) 
						OR 
						(c.Ejercicio = @ejercicio AND c.Periodo <= (@PeriodoD - 1)) 
						)
					AND c.FechaContable < @FechaSaldoInicial -- Armando
					--GROUP BY ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''), c.ContactoTipo
					GROUP BY m.UEN
					HAVING SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0)) <> 0
				
		INSERT INTO #DWH (Contacto, CtoTipo, Debe, Haber, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero)
				SELECT
				NULL,
				NULL,
				Debe = SUM(ISNULL(r.Debe,0)),
				Haber = SUM(ISNULL(r.Haber,0)),
				NULL,
				ISNULL(m.UEN,0),
				NULL,
				NULL,
				NULL
				FROM
				Cont c
				LEFT OUTER JOIN ContReg r ON c.ID = r.ID  
				--AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo 
				AND r.Empresa = c.Empresa
				LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
				LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov
				WHERE  ISNULL(mt.modulo,'CONT') = 'CONT' AND
				mt.clave IN ('CONT.P','CONT.C') AND
				c.Estatus = 'CONCLUIDO' AND
				isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
				r.cuenta = @Cuenta AND r.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
				ISNULL(c.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, c.Sucursal), 0)
				GROUP BY m.UEN
	END 
	ELSE
	BEGIN
		INSERT INTO #DWHSI(Contacto, CtoTipo, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero, Saldo)
		SELECT
		'',
		'',
		'',
		ISNULL(m.UEN,0),
		'',
		'',
		'',
		SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0))
		FROM ContReg r
		JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
		JOIN Cont c ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
		WHERE r.Cuenta = @Cuenta AND r.empresa = @Empresa
		AND ISNULL(m.Sucursal, '') = ISNULL(ISNULL(@Sucursal, m.Sucursal), '')
		AND c.FechaContable < @FechaSaldoInicial -- Armando
		GROUP BY m.UEN
		HAVING SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0)) <> 0
		
		INSERT INTO #DWH (Contacto, CtoTipo, Debe, Haber, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero)
		SELECT
		NULL,
		NULL,
		Debe = SUM(ISNULL(r.Debe,0)),
		Haber = SUM(ISNULL(r.Haber,0)),
		NULL,
		ISNULL(m.UEN,0),
		NULL,
		NULL,
		NULL
		FROM
		Cont c
		LEFT OUTER JOIN ContReg r ON c.ID = r.ID  AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo AND r.Empresa = c.Empresa
		LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
		LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov AND
		mt.modulo = 'CONT' AND
		mt.clave = 'CONT.P'
		WHERE  mt.modulo = 'CONT' AND
		mt.clave = 'CONT.P' AND
		c.Estatus = 'CONCLUIDO' AND
		isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
		r.cuenta = @Cuenta AND r.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
		ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
		GROUP BY
		m.UEN
	END
	
INSERT INTO #UEN
SELECT DISTINCT ISNULL(UEN,0)
FROM #DWHSI
UNION
SELECT DISTINCT ISNULL(UEN,0)
FROM #DWH

SELECT d.Contacto, 'Nombre' = (SELECT Nombre FROM UEN WHERE UEN = u.UEN), d.CtoTipo, d.Movimiento,
/*'Inicio' = ISNULL(@Inicio,0), */'Saldo' = ISNULL(s.Saldo,0), 'Debe' = ISNULL(d.Debe,0), 'Haber' = ISNULL(d.Haber,0), d.Proyecto, u.UEN, d.FechaEmision, d.CentroCostos, d.CuentaDinero, 'Descripcion' = Convert(char(100), '')
FROM #UEN u
LEFT OUTER JOIN #DWHSI s ON u.UEN = s.UEN
LEFT OUTER JOIN #DWH d ON u.UEN = d.UEN
ORDER BY u.UEN
END
ELSE
IF @Filtro = 'FechaEmision'
BEGIN
INSERT INTO #DWHSI(Contacto, CtoTipo, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero, Saldo)
SELECT
'',
'',
'',
'',
m.FechaEmision,
'',
'',
SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0))
FROM ContReg r
JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
JOIN Cont c ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
WHERE r.Cuenta = @Cuenta AND r.empresa = @Empresa
AND ISNULL(m.Sucursal, '') = ISNULL(ISNULL(@Sucursal, m.Sucursal), '')
AND c.FechaContable < @FechaSaldoInicial -- Armando
GROUP BY m.FechaEmision
HAVING SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0)) <> 0
INSERT INTO #DWH (Contacto, CtoTipo, Debe, Haber, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero)
SELECT
NULL,
NULL,
Debe = SUM(ISNULL(r.Debe,0)),
Haber = SUM(ISNULL(r.Haber,0)),
NULL,
NULL,
m.FechaEmision,
NULL,
NULL
FROM Cont c
LEFT OUTER JOIN ContReg r ON c.ID = r.ID  AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo AND r.Empresa = c.Empresa
LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
LEFT OUTER JOIN MovTipo mt ON mt.mov = c.mov AND mt.modulo = 'CONT' AND mt.clave = 'CONT.P'
WHERE mt.modulo = 'CONT' AND
mt.clave = 'CONT.P' AND
c.Estatus = 'CONCLUIDO' AND
isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
r.cuenta = @Cuenta AND r.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
GROUP BY m.FechaEmision
ORDER BY m.FechaEmision
INSERT INTO #FE
SELECT DISTINCT ISNULL(FechaEmision,'')
FROM #DWHSI
UNION
SELECT DISTINCT ISNULL(FechaEmision,'')
FROM #DWH
SELECT d.Contacto, 'Nombre' = Convert(char(100), ''), d.CtoTipo, d.Movimiento,
/*'Inicio' = ISNULL(@Inicio,0), */'Saldo' = ISNULL(s.Saldo,0), 'Debe' = ISNULL(d.Debe,0), 'Haber' = ISNULL(d.Haber,0), d.Proyecto, d.UEN, f.FechaEmision, d.CentroCostos, d.CuentaDinero, 'Descripcion' = Convert(char(100), '')
FROM #FE f
LEFT OUTER JOIN #DWHSI s ON f.FechaEmision = s.FechaEmision
LEFT OUTER JOIN #DWH d ON f.FechaEmision = d.FechaEmision
ORDER BY f.FechaEmision
END
ELSE
IF @Filtro = 'CentroCostos'
BEGIN

	IF EXISTS(SELECT 1 FROM @CtasCorregidas AS cc WHERE cc.Cuenta=@Cuenta)
	BEGIN
		INSERT INTO #DWHSI(Contacto, CtoTipo, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero, Saldo)
		SELECT
		'',
		'',
		'',
		'',
		'',
		ISNULL(r.SubCuenta,''),
		'',
		SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0))
		FROM ContReg r
		JOIN Cont c ON c.ID = r.ID 
		--AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
		LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
		LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov
		WHERE mt.modulo = 'CONT' AND
		mt.clave IN ('CONT.P','CONT.C') AND
		c.Estatus = 'CONCLUIDO' AND
		 r.Cuenta = @Cuenta AND r.empresa = @Empresa
		AND ISNULL(c.Sucursal, '') = ISNULL(ISNULL(@Sucursal, c.Sucursal), '')
		AND 
		   (
			(c.Ejercicio < @ejercicio) 
		    OR 
			(c.Ejercicio = @ejercicio AND c.Periodo <= (@PeriodoD - 1)) 
		   )
		AND c.FechaContable < @FechaSaldoInicial -- Armando
		GROUP BY ISNULL(r.SubCuenta,'')
		HAVING SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0)) <> 0
		
		INSERT INTO #DWH (Contacto, CtoTipo, Debe, Haber, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero)
		SELECT
		NULL,
		NULL,
		Debe = SUM(ISNULL(r.Debe,0)),
		Haber = SUM(ISNULL(r.Haber,0)),
		NULL,
		NULL,
		NULL,
		ISNULL(r.SubCuenta,''),
		NULL
		FROM Cont c
		LEFT OUTER JOIN ContReg r ON c.ID = r.ID  
		--AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo 
		AND r.Empresa = c.Empresa
		LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
		LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov
		WHERE  ISNULL(mt.modulo,'CONT') = 'CONT' AND
		mt.clave IN ('CONT.P','CONT.C') AND
		c.Estatus = 'CONCLUIDO' AND
		isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
		r.cuenta = @Cuenta AND r.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
		ISNULL(c.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, c.Sucursal), 0)
		--GROUP BY ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''), c.ContactoTipo
		GROUP BY ISNULL(r.SubCuenta,'')	
	END
	ELSE
	BEGIN
		INSERT INTO #DWHSI(Contacto, CtoTipo, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero, Saldo)
		SELECT
		'',
		'',
		'',
		'',
		'',
		ISNULL(r.SubCuenta,''),
		'',
		SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0))
		FROM ContReg r
		JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
		JOIN Cont c ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
		WHERE r.Cuenta = @Cuenta AND r.empresa = @Empresa
		AND ISNULL(m.Sucursal, '') = ISNULL(ISNULL(@Sucursal, m.Sucursal), '')
		AND c.FechaContable < @FechaSaldoInicial -- Armando
		GROUP BY r.SubCuenta
		HAVING SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0)) <> 0

		INSERT INTO #DWH (Contacto, CtoTipo, Debe, Haber, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero)
		SELECT
		NULL,
		NULL,
		Debe = SUM(ISNULL(r.Debe,0)),
		Haber = SUM(ISNULL(r.Haber,0)),
		NULL,
		NULL,
		NULL,
		ISNULL(r.SubCuenta,''),
		NULL
		FROM Cont c
		LEFT OUTER JOIN ContReg r ON c.ID = r.ID  AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo AND r.Empresa = c.Empresa
		LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
		LEFT OUTER JOIN MovTipo mt ON mt.mov = c.mov AND mt.modulo = 'CONT' AND mt.clave = 'CONT.P'
		WHERE mt.modulo = 'CONT' AND
		mt.clave IN ('CONT.P','CONT.C') AND
		c.Estatus = 'CONCLUIDO' AND
		isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
		r.cuenta = @Cuenta AND r.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
		ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
		GROUP BY r.SubCuenta
	END

INSERT INTO #CC
SELECT DISTINCT ISNULL(CentroCostos,'')
FROM #DWHSI
UNION
SELECT DISTINCT ISNULL(CentroCostos,'')
FROM #DWH
SELECT d.Contacto, 'Nombre' = Convert(char(100), ''), d.CtoTipo, d.Movimiento,
/*'Inicio' = ISNULL(@Inicio,0), */'Saldo' = ISNULL(s.Saldo,0), 'Debe' = ISNULL(d.Debe,0), 'Haber' = ISNULL(d.Haber,0), d.Proyecto, d.UEN, d.FechaEmision, c.CentroCostos, d.CuentaDinero, 'Descripcion' = (SELECT Descripcion FROM CentroCostos WHERE CentroCostos = c.CentroCostos)
FROM #CC c
LEFT OUTER JOIN #DWHSI s ON c.CentroCostos = s.CentroCostos
LEFT OUTER JOIN #DWH d ON c.CentroCostos = d.CentroCostos
ORDER BY c.CentroCostos
END
ELSE
IF @Filtro = 'CuentaDinero'
BEGIN
INSERT INTO #DWHSI(Contacto, CtoTipo, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero, Saldo)
SELECT
'',
'',
'',
'',
'',
'',
ISNULL(m.CtaDinero,''),
SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0))
FROM ContReg r
JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
JOIN Cont c ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo 
WHERE r.Cuenta = @Cuenta AND r.empresa = @Empresa
AND ISNULL(m.Sucursal, '') = ISNULL(ISNULL(@Sucursal, m.Sucursal), '')
AND c.FechaContable < @FechaSaldoInicial -- Armando
GROUP BY m.CtaDinero
HAVING SUM(ISNULL(r.Debe,0) - ISNULL(r.Haber,0)) <> 0
INSERT INTO #DWH (Contacto, CtoTipo, Debe, Haber, Proyecto, UEN, FechaEmision, CentroCostos, CuentaDinero)
SELECT
NULL,
NULL,
Debe = SUM(ISNULL(r.Debe,0)),
Haber = SUM(ISNULL(r.Haber,0)),
NULL,
NULL,
NULL,
NULL,
ISNULL(m.CtaDinero,'')
FROM Cont c
LEFT OUTER JOIN ContReg r ON c.ID = r.ID  AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo AND r.Empresa = c.Empresa
LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
LEFT OUTER JOIN MovTipo mt ON mt.mov = c.mov AND mt.modulo = 'CONT' AND mt.clave = 'CONT.P'
WHERE mt.modulo = 'CONT' AND
mt.clave = 'CONT.P' AND
c.Estatus = 'CONCLUIDO' AND
isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
r.cuenta = @Cuenta AND r.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
GROUP BY m.CtaDinero
INSERT INTO #CtaDin
SELECT DISTINCT ISNULL(CuentaDinero,'')
FROM #DWHSI
UNION
SELECT DISTINCT ISNULL(CuentaDinero,'')
FROM #DWH
SELECT d.Contacto, 'Nombre' = Convert(char(100), ''), d.CtoTipo, d.Movimiento,
/*'Inicio' = ISNULL(@Inicio,0), */'Saldo' = ISNULL(s.Saldo,0), 'Debe' = ISNULL(d.Debe,0), 'Haber' = ISNULL(d.Haber,0), d.Proyecto, d.UEN, d.FechaEmision, d.CentroCostos,  c.CuentaDinero, 'Descripcion' = (SELECT Descripcion FROM CtaDinero WHERE CtaDinero =

 c.CuentaDinero)
FROM #CtaDin c
LEFT OUTER JOIN #DWHSI s ON c.CuentaDinero = s.CuentaDinero
LEFT OUTER JOIN #DWH d ON c.CuentaDinero = d.CuentaDinero
ORDER BY c.CuentaDinero
END
END

