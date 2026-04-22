SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF

go
--EXEC spDICODesgloseContactoSI '1656','210-100-000','02',NULL,2026,1,13,NULL,999,1
--SELECT * FROM DICODesgloseContactoSI WHERE Estacion=1
---PROCEDURE----
/**************** spDICODesgloseContactoSI ****************/
if exists (select * from sysobjects where id = object_id('dbo.spDICODesgloseContactoSI') and type = 'P') drop procedure dbo.spDICODesgloseContactoSI
GO
CREATE PROCEDURE [dbo].[spDICODesgloseContactoSI]  
@Filtro   VARCHAR(20),  
@Cuenta   CHAR(15),  
@Empresa  CHAR(5),  
@Sucursal  INT,  
@Ejercicio  INT,  
@PeriodoD  INT,  
@PeriodoA  INT,  
@Moneda   CHAR(20),  
@SPID   INT,  
@Debug bit = 0  
AS  
BEGIN  
  
--GON/JDLS 16/04/2024 - para homologar y evitar casos donde el Ejercicio o Periodo está en blanco, se filtra por la FechaContable  
DECLARE @FechaI datetime  
  
--Se arman las Fechas Inicial y Final a partir de los parametros de Ejercicio y Periodo Inicial y Final del filtro  
SELECT  @FechaI = CAST(@Ejercicio AS VARCHAR(5))+IIF(@PeriodoD<10,'0','')+CAST(@PeriodoD AS VARCHAR(5))+'01'  
SELECT @FechaI=DATEADD(dd,-(DAY(@FechaI)-1),@FechaI)  
  
--iGGR. Se trunca la tabla del desglose de los saldos iniciales que no tienen contacto o sin tipo contacto  
DELETE FROM  DICODesgloseContactoSI WHERE Estacion=@SPID  
  
IF @Debug=1  
SELECT @FechaI
--GON/JDLS 16/04/2024 - para homologar y evitar casos donde el Ejercicio o Periodo está en blanco, se filtra por la FechaContable  
  
/******IGGR********/  
--Se agregan tablas tipo tabla para insertar los consecutivos de las polizas para el saldo inicial y para las polizas del mes  
DECLARE @ContTSI TABLE(  
 ID   INT,   
 Cuenta  VARCHAR(25),  
 Modulo  VARCHAR(10),  
 Contacto VARCHAR(15),  
 ContactoTipo VARCHAR(15),
 Debe		FLOAT,
 Haber		FLOAT  
)  

--Se agregan los movimientos registrados en mov reg del contacto seleccionado
DECLARE @MovRegContacto	TABLE(
	ID			INT,
	Modulo		VARCHAR(7),
	Empresa		VARCHAR(5),
	Sucursal	INT,
	ContactoTipo	VARCHAR(20)
)

INSERT INTO @MovRegContacto
SELECT DISTINCT ID,mr.Modulo,mr.Empresa,Sucursal,mr.CtoTipo
FROM MovReg AS mr
WHERE mr.Contacto=@Filtro

IF @Debug=1
	SELECT *
	FROM @MovRegContacto


--IGGR. Tabla que almacenara las cuentas corregidas
DECLARE @CtasCorregidas TABLE(
	Cuenta		VARCHAR(35)	
)
INSERT INTO @CtasCorregidas
SELECT DISTINCT Cuenta FROM DICOCtasActualizar

--IGGR. Se valida si la cuenta seleccionada a desplegar esta o no dentro de la lista de cuentas corregidas
	IF EXISTS(SELECT 1 FROM @CtasCorregidas AS cc WHERE cc.Cuenta=@Cuenta)
	BEGIN
					INSERT INTO @ContTSI 
					SELECT c.ID,r.Cuenta,c.OrigenTipo,ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''),
									ISNULL(ISNULL(m.ContactoTipo, c.ContactoTipo),''),ISNULL(r.Debe,0),ISNULL(r.Haber,0)
					FROM ContReg r
					JOIN Cont c ON c.ID = r.ID 
					--AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
					 LEFT OUTER JOIN @MovRegContacto m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
					 LEFT OUTER JOIN MovTipo mt ON     mt.mov = c.mov
					 WHERE mt.modulo = 'CONT' AND
					mt.clave in  ('CONT.P','CONT.C') AND---losd se agregan las polizas de cierre
					c.Estatus = 'CONCLUIDO' AND
					  r.Cuenta = @Cuenta AND r.empresa = @Empresa
					 AND ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),'')=@Filtro
					AND ISNULL(c.Sucursal, '') = ISNULL(ISNULL(@Sucursal, c.Sucursal), '')
					AND 
					   (
						(c.Ejercicio < @ejercicio) 
						OR 
						(c.Ejercicio = @ejercicio AND c.Periodo <= (@PeriodoD - 1)) 
						)
					AND c.FechaContable < @FechaI -- Armando
					--GROUP BY ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''), c.ContactoTipo
  END
  ELSE
					INSERT INTO @ContTSI  
					SELECT DISTINCT c.ID,r.Cuenta,c.OrigenTipo,ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),''),
									ISNULL(ISNULL(m.ContactoTipo, c.ContactoTipo),''),ISNULL(r.Debe,0),ISNULL(r.Haber,0)
					FROM ContReg r
					JOIN @MovRegContacto m ON r.Modulo = m.Modulo AND r.ModuloID = m.ID AND r.Empresa = m.Empresa
					JOIN Cont c ON c.ID = r.ID AND ISNULL(c.OrigenTipo, 'CONT') = r.Modulo  -- Armando
					WHERE r.Cuenta = @Cuenta AND r.empresa = @Empresa
					AND ISNULL(m.Sucursal, '') = ISNULL(ISNULL(@Sucursal, m.Sucursal), '')
					AND ISNULL(ISNULL(r.ContactoEspecifico, c.Contacto),'')=@Filtro
					AND c.FechaContable < @FechaI -- Armando  
IF @Debug=1  
 SELECT '@ContTSI',* FROM @ContTSI  
  
/*****Fin IGGR******/  

IF @Debug=1  
BEGIN  
   
 SELECT c.ID,c.Contacto,c.ContactoTipo,c.Cuenta,c.Debe,c.Haber  
 FROM @ContTSI c  
 --JOIN ContReg r ON c.ID=r.ID AND c.Cuenta=r.Cuenta AND c.Empresa=r.Empresa 
 WHERE c.Contacto=@Filtro
 --where ISNULL(IIF(r.ContactoEspecifico='',NULL,r.ContactoEspecifico),c.Contacto)='100055'  
 --WHERE ISNULL(c.Contacto,IIF(r.ContactoEspecifico='',NULL,r.ContactoEspecifico)) is null  
 
 SELECT SUM(ISNULL(c.Debe,0)-ISNULL(c.Haber,0)) AS 'Saldo Inicial'
  FROM @ContTSI c  
 --JOIN ContReg r ON c.ID=r.ID AND c.Cuenta=r.Cuenta AND c.Empresa=r.Empresa 
 WHERE c.Contacto=@Filtro
 
 
END  
--SELECt * FROM MovTipo where modulo='CONT'  
  
INSERT INTO DICODesgloseContactoSI  
SELECT @spid,c.ID,@Empresa,c.Contacto,ISNULL(c.ContactoTipo,''),c.Cuenta,@Sucursal,ISNULL(c.Debe,0),ISNULL(c.Haber,0)  
 FROM @ContTSI c  
 --JOIN ContReg r ON c.ID=r.ID AND c.Cuenta=r.Cuenta AND c.Empresa=r.Empresa  
  
END  

GO


