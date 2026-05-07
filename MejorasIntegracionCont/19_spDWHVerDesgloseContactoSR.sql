SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF

go

---PROCEDURE----
/**************** spDWHVerDesgloseContactoSR ****************/
if exists (select * from sysobjects where id = object_id('spDWHVerDesgloseContactoSR') and type = 'P') drop procedure spDWHVerDesgloseContactoSR
GO
CREATE PROCEDURE  spDWHVerDesgloseContactoSR

/*log de cambios*/
/*30 07 2024 se cambia m.Contacto por c.contacto por incidente reportado por gabriel en el que se estaba delsglosando el saldo incial en una pantalla que no correspondia dicho desgloce y mostraba contactos erroneos en el desgloce correo del 30 07 2024 */
/*20/11/2024 Se modifican las condiciones de extraccion de datos por tipo de contacto ya que no se tiene presente el contacto y el tipo de contacto en las tablas de cont si no en la tabla de mov reg */
/*05/05/2026 Actualiza la consulta del desglose de los movimientos de contacto con la finalidad de extraer la lista de movimientos que debera coincidir con el total de la pantalla general de los totales por cada contacto*/

@Filtro			VARCHAR(20),
@ValorContacto		CHAR(10),
@ValorMovimiento	CHAR(20),
@ValorProyecto		VARCHAR(50),
@ValorUEN		INT,
@ValorFechaEmision	DATETIME,
@ValorCC		VARCHAR(20),
-- @ValorCuentaDinero	CHAR(10),
@Cuenta			CHAR(15),
@Empresa		CHAR(5),
@Sucursal		INT,
@Ejercicio		INT,
@PeriodoD		INT,
@PeriodoA		INT,
@Moneda			CHAR(20),
@TipoCto		varchar(20),
@Spid           INT

AS
BEGIN
SET ANSI_NULLS OFF
DECLARE
@Contacto		CHAR(10),
@Movimiento		char(20),
@Proyecto		VARCHAR(50),
@UEN			INT,
@FechaEmision		DATETIME,
@CC		    	VARCHAR(20),
@CuentaDinero		char(10),
@ValorCuentaDinero	CHAR(10)

delete from  DesgloseDWH where SpidSQL = @Spid


SELECT @ValorContacto = RTRIM(@ValorContacto)
SELECT @ValorMovimiento = RTRIM(@ValorMovimiento)
SELECT @ValorProyecto = RTRIM(@ValorProyecto)
SELECT @ValorUEN = RTRIM(@ValorUEN)
SELECT @ValorCC = RTRIM(@ValorCC)
SELECT @ValorCuentaDinero = RTRIM(@ValorCuentaDinero)
IF @ValorProyecto IN ('NULL',NULL) SELECT @ValorProyecto = NULL
IF @ValorContacto IN ('NULL',NULL) SELECT @ValorContacto = ''
IF @ValorMovimiento IN ('NULL',NULL) SELECT @ValorMovimiento = ''
IF @ValorCC IN ('NULL',NULL) SELECT @ValorCC = NULL
IF @ValorCuentaDinero IN ('NULL',NULL) SELECT @ValorCuentaDinero = NULL
IF @Moneda IN ('','NULL','(Todos)','(Todas)',NULL) SELECT @Moneda = NULL
IF @Filtro = '' SELECT @Filtro = 'Contacto'
SELECT @Contacto 	= @ValorContacto
SELECT @Movimiento 	= @ValorMovimiento
SELECT @Proyecto 	= @ValorProyecto
SELECT @UEN 	   	= @ValorUEN
SELECT @FechaEmision 	= @ValorFechaEmision
SELECT @CC		= @ValorCC
SELECT @CuentaDinero  = @ValorCuentaDinero

--IGGR. Tabla que almacenara las cuentas corregidas
DECLARE @CtasCorregidas TABLE(
	Cuenta		VARCHAR(35)	
)
INSERT INTO @CtasCorregidas
SELECT DISTINCT Cuenta FROM DICOCtasActualizar


IF @Filtro = 'Contacto'
BEGIN

IF EXISTS(SELECT 1 FROM @CtasCorregidas AS cc WHERE cc.Cuenta=@Cuenta)
BEGIN
INSERT INTO DesgloseDWH
SELECT m.ID,
e.Empresa,
e.Nombre,
s.Sucursal,
s.Nombre,
m.Moneda,
ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''),
m.FechaEmision,
ISNULL(m.Proyecto,''),
ISNULL(m.UEN,''),
ISNULL(r.SubCuenta,''),
ISNULL(m.CtaDinero,''),
m.Modulo,
c.ID,
c.Mov,
c.movID,
c.Referencia,
c.Observaciones,
ISNULL(c.Origen,''),
ISNULL(c.OrigenID,''),
ISNULL(r.Debe,0),
ISNULL(r.Haber,0),
@Spid 
FROM Cont c
LEFT OUTER JOIN ContReg r ON c.ID = r.ID  
--AND ISNULL(c.OrigenTipo, 'CONT') = r.modulo 
AND r.Empresa = c.Empresa
LEFT OUTER JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov
JOIN Empresa e ON e.Empresa = c.Empresa
left JOIN Sucursal s ON s.Sucursal = c.Sucursal
WHERE  ISNULL(mt.modulo,'CONT') = 'CONT' 
AND mt.clave = 'CONT.P' AND
c.Estatus = 'CONCLUIDO' AND
isnull(c.Moneda,'') = isnull(isnull(@Moneda, c.Moneda),'') AND
r.cuenta = @Cuenta AND r.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA AND
ISNULL(c.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, c.Sucursal), 0)
AND ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),'')=@Contacto
END
ELSE
BEGIN
INSERT INTO DesgloseDWH
SELECT m.ID,
e.Empresa,
e.Nombre,
s.Sucursal,
s.Nombre,
m.Moneda,
ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''),
m.FechaEmision,
ISNULL(m.Proyecto,''),
ISNULL(m.UEN,''),
ISNULL(r.SubCuenta,''),
ISNULL(m.CtaDinero,''),
m.Modulo,
c.ID,
c.Mov,
c.movID,
c.Referencia,
c.Observaciones,
ISNULL(c.Origen,''),
ISNULL(c.OrigenID,''),
ISNULL(r.Debe,0),
ISNULL(r.Haber,0),
@Spid 
FROM Cont c
left JOIN ContReg r ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo AND r.Empresa = c.Empresa
left JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa AND r.Empresa = c.Empresa
AND ISNULL(c.Origen, c.Mov) = m.Mov AND ISNULL(c.OrigenID, c.MovID) = m.MovID AND ISNULL(c.OrigenTipo, 'CONT') = m.Modulo
AND c.Sucursal = m.Sucursal --AND c.Ejercicio = m.Ejercicio AND c.Periodo = m.Periodo -- Armando
JOIN Empresa e ON e.Empresa = c.Empresa
left JOIN Sucursal s ON s.Sucursal = c.Sucursal
WHERE c.Estatus = 'CONCLUIDO'
AND ISNULL(ISNULL(r.ContactoEspecifico, m.Contacto),'') = ISNULL(ISNULL(@Contacto, ISNULL(r.ContactoEspecifico, m.Contacto)), '') /*IGGR 20/11/2024*/
--AND ISNULL(m.CtoTipo,'') = ISNULL(@TipoCto,'') /*GON 23/08/2013*/
AND ISNULL(ISNULL(c.ContactoTipo,m.CtoTipo),'') = ISNULL(@TipoCto,'')  /*IGGR 20/11/2024*/
AND r.cuenta = @Cuenta AND c.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA -- Armando
AND ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
END

SELECT * FROM DesgloseDWH  where SpidSQL  = @Spid
END
ELSE


IF @Filtro = 'Movimiento'
BEGIN
INSERT INTO DesgloseDWH
SELECT m.ID,
e.Empresa,
e.Nombre,
s.Sucursal,
s.Nombre,
m.Moneda,
ISNULL(m.Contacto,''),
m.FechaEmision,
ISNULL(m.Proyecto,''),
ISNULL(m.UEN,''),
ISNULL(r.SubCuenta,''),
ISNULL(m.CtaDinero,''),
m.Modulo,
c.ID,
c.Mov,
c.MovID,
c.Referencia,
c.Observaciones,
ISNULL(c.Origen,''),
ISNULL(c.OrigenID,''),
ISNULL(r.Debe,0),
ISNULL(r.Haber,0),
@Spid
FROM Cont c
left JOIN ContReg r ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo AND r.Empresa = c.Empresa
left JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa AND r.Empresa = c.Empresa
AND ISNULL(c.Origen, c.Mov) = m.Mov AND ISNULL(c.OrigenID, c.MovID) = m.MovID AND ISNULL(c.OrigenTipo, 'CONT') = m.Modulo
AND c.Sucursal = m.Sucursal --AND c.Ejercicio = m.Ejercicio AND c.Periodo = m.Periodo -- Armando
JOIN Empresa e ON e.Empresa = c.Empresa
left JOIN Sucursal s ON s.Sucursal = c.Sucursal
WHERE c.Estatus = 'CONCLUIDO'
AND ISNULL(m.Mov, '') = ISNULL(ISNULL(@Movimiento, m.Mov), '')
AND r.cuenta = @Cuenta AND c.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA -- Armando
AND ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)


SELECT * FROM DesgloseDWH  where SpidSQL  = @Spid
END
ELSE


IF @Filtro = 'Proyecto'
BEGIN
INSERT INTO DesgloseDWH
SELECT m.ID,
e.Empresa,
e.Nombre,
s.Sucursal,
s.Nombre,
m.Moneda,
m.Contacto,
m.FechaEmision,
ISNULL(m.Proyecto,''),
ISNULL(m.UEN,''),
ISNULL(r.SubCuenta,''),
ISNULL(m.CtaDinero,''),
m.Modulo,
c.ID,
c.Mov,
c.MovID,
c.Referencia,
c.Observaciones,
ISNULL(c.Origen,''),
ISNULL(c.OrigenID,''),
ISNULL(r.Debe,0),
ISNULL(r.Haber,0),
@Spid
FROM Cont c
left JOIN ContReg r ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo AND r.Empresa = c.Empresa
left JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa AND r.Empresa = c.Empresa
AND ISNULL(c.Origen, c.Mov) = m.Mov AND ISNULL(c.OrigenID, c.MovID) = m.MovID AND ISNULL(c.OrigenTipo, 'CONT') = m.Modulo
AND c.Sucursal = m.Sucursal --AND c.Ejercicio = m.Ejercicio AND c.Periodo = m.Periodo -- Armando
JOIN Empresa e ON e.Empresa = c.Empresa
left JOIN Sucursal s ON s.Sucursal = c.Sucursal
WHERE c.Estatus = 'CONCLUIDO'
AND ISNULL(m.Proyecto, '') = ISNULL(ISNULL(@Proyecto, m.Proyecto), '')
AND r.cuenta = @Cuenta AND c.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA -- Armando
AND ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
SELECT * FROM DesgloseDWH  where SpidSQL  = @Spid
END
ELSE


IF @Filtro = 'UEN'
BEGIN
INSERT INTO DesgloseDWH
SELECT
m.ID,
e.Empresa,
e.Nombre,
s.Sucursal,
s.Nombre,
m.Moneda,
m.Contacto,
m.FechaEmision,
ISNULL(m.Proyecto,''),
ISNULL(m.UEN,''),
ISNULL(r.SubCuenta,''),
ISNULL(m.CtaDinero,''),
m.Modulo,
c.ID,
c.Mov,
c.MovID,
c.Referencia,
c.Observaciones,
ISNULL(c.Origen,''),
ISNULL(c.OrigenID,''),
ISNULL(r.Debe,0),
ISNULL(r.Haber,0),
@Spid
FROM
Cont c
left JOIN ContReg r ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo AND r.Empresa = c.Empresa
left JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa AND r.Empresa = c.Empresa
AND ISNULL(c.Origen, c.Mov) = m.Mov AND ISNULL(c.OrigenID, c.MovID) = m.MovID AND ISNULL(c.OrigenTipo, 'CONT') = m.Modulo
AND c.Sucursal = m.Sucursal --AND c.Ejercicio = m.Ejercicio AND c.Periodo = m.Periodo -- Armando
JOIN Empresa e ON e.Empresa = c.Empresa
left JOIN Sucursal s ON s.Sucursal = c.Sucursal
WHERE
c.Estatus = 'CONCLUIDO' AND
ISNULL(m.UEN, '') = ISNULL(ISNULL(@UEN, m.UEN), '') AND
r.cuenta = @Cuenta AND c.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA -- Armando
AND ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
SELECT * FROM DesgloseDWH  where SpidSQL  = @Spid
END
ELSE


IF @Filtro = 'FechaEmision'
BEGIN
INSERT INTO DesgloseDWH
SELECT
m.ID,
e.Empresa,
e.Nombre,
s.Sucursal,
s.Nombre,
m.Moneda,
m.Contacto,
m.FechaEmision,
ISNULL(m.Proyecto,''),
ISNULL(m.UEN,''),
ISNULL(r.SubCuenta,''),
ISNULL(m.CtaDinero,''),
m.Modulo,
c.ID,
c.Mov,
c.MovID,
c.Referencia,
c.Observaciones,
ISNULL(c.Origen,''),
ISNULL(c.OrigenID,''),
ISNULL(r.Debe,0),
ISNULL(r.Haber,0),
@Spid
FROM
Cont c
left JOIN ContReg r ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo AND r.Empresa = c.Empresa
left JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa AND r.Empresa = c.Empresa
AND ISNULL(c.Origen, c.Mov) = m.Mov AND ISNULL(c.OrigenID, c.MovID) = m.MovID AND ISNULL(c.OrigenTipo, 'CONT') = m.Modulo
AND c.Sucursal = m.Sucursal --AND c.Ejercicio = m.Ejercicio AND c.Periodo = m.Periodo -- Armando
JOIN Empresa e ON e.Empresa = c.Empresa
left JOIN Sucursal s ON s.Sucursal = c.Sucursal
WHERE
c.Estatus = 'CONCLUIDO' AND
m.FechaEmision = @FechaEmision AND
r.cuenta = @Cuenta AND c.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA -- Armando
AND ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
SELECT * FROM DesgloseDWH  where SpidSQL  = @Spid
END
ELSE

IF @Filtro = 'CentroCostos'
BEGIN

INSERT INTO DesgloseDWH
SELECT
m.ID,
e.Empresa,
e.Nombre,
s.Sucursal,
s.Nombre,
m.Moneda,
m.Contacto,
m.FechaEmision,
ISNULL(m.Proyecto,''),
ISNULL(m.UEN,''),
ISNULL(r.SubCuenta,''),
ISNULL(m.CtaDinero,''),
m.Modulo,
c.ID,
c.Mov,
c.MovID,
c.Referencia,
c.Observaciones,
ISNULL(c.Origen,''),
ISNULL(c.OrigenID,''),
ISNULL(r.Debe,0),
ISNULL(r.Haber,0),
@Spid
FROM
Cont c
left JOIN ContReg r ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo AND r.Empresa = c.Empresa
left JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa AND r.Empresa = c.Empresa
AND ISNULL(c.Origen, c.Mov) = m.Mov AND ISNULL(c.OrigenID, c.MovID) = m.MovID AND ISNULL(c.OrigenTipo, 'CONT') = m.Modulo
AND c.Sucursal = m.Sucursal --AND c.Ejercicio = m.Ejercicio AND c.Periodo = m.Periodo -- Armando
JOIN Empresa e ON e.Empresa = c.Empresa
left JOIN Sucursal s ON s.Sucursal = c.Sucursal
WHERE
c.Estatus = 'CONCLUIDO' AND
ISNULL(r.SubCuenta, '') = ISNULL(ISNULL(@CC, r.SubCuenta), '') AND
r.cuenta = @Cuenta AND c.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA -- Armando
AND ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
SELECT * FROM DesgloseDWH  where SpidSQL  = @Spid
END
ELSE


IF @Filtro = 'CuentaDinero'
BEGIN
INSERT INTO DesgloseDWH
SELECT
m.ID,
e.Empresa,
e.Nombre,
s.Sucursal,
s.Nombre,
m.Moneda,
m.Contacto,
m.FechaEmision,
ISNULL(m.Proyecto,''),
ISNULL(m.UEN,''),
ISNULL(r.SubCuenta,''),
ISNULL(m.CtaDinero,''),
m.Modulo,
c.ID,
c.Mov,
c.MovID,
c.Referencia,
c.Observaciones,
ISNULL(c.Origen,''),
ISNULL(c.OrigenID,''),
ISNULL(r.Debe,0),
ISNULL(r.Haber,0),
@Spid
FROM
Cont c
left JOIN ContReg r ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo AND r.Empresa = c.Empresa
left JOIN MovReg m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa AND r.Empresa = c.Empresa
AND ISNULL(c.Origen, c.Mov) = m.Mov AND ISNULL(c.OrigenID, c.MovID) = m.MovID AND ISNULL(c.OrigenTipo, 'CONT') = m.Modulo
AND c.Sucursal = m.Sucursal --AND c.Ejercicio = m.Ejercicio AND c.Periodo = m.Periodo -- Armando
JOIN Empresa e ON e.Empresa = c.Empresa
left JOIN Sucursal s ON s.Sucursal = c.Sucursal
WHERE
c.Estatus = 'CONCLUIDO' AND
ISNULL(m.CtaDinero, '') = ISNULL(ISNULL(@CuentaDinero, m.CtaDinero), '') AND
r.cuenta = @Cuenta AND c.empresa = @Empresa AND c.Ejercicio = @Ejercicio AND c.Periodo BETWEEN @PeriodoD AND @PeriodoA -- Armando 
AND ISNULL(m.Sucursal, 0) = ISNULL(ISNULL(@Sucursal, m.Sucursal), 0)
SELECT * FROM DesgloseDWH where SpidSQL  = @Spid
END
END





GO
