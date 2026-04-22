SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF

go

--DROP TABLE ContRegRespaldo
/****** Contabilidad (Registro) ******/
if not exists (select * from SysTabla where SysTabla = 'ContRegRespaldo') 
INSERT INTO SysTabla (SysTabla,Tipo,Modulo) VALUES ('ContRegRespaldo','Movimiento','CONT') 
if not exists (select * from sysobjects where id = object_id('dbo.ContRegRespaldo') and type = 'U') 
CREATE TABLE dbo.ContRegRespaldo (
		ID			int 	    	NOT NULL,
		RID			int 	    	NOT NULL,

		Empresa			varchar(5)		NULL,
       	Sucursal		int		NULL,
		Modulo			varchar(5)		NULL,
		ModuloID		int		NULL,	 	
       	ModuloRenglon		float		NULL,
       	ModuloRenglonSub	int		NULL,

       	Cuenta			varchar(20) 	NULL, 
       	SubCuenta 		varchar(50) 	NULL,
       	Concepto		varchar(50) 	NULL,
       	Debe			money		NULL,
       	Haber			money		NULL,
		ContactoEspecifico	varchar(10)	NULL,
       	SubCuenta2 		varchar(50) 	NULL,
       	SubCuenta3 		varchar(50) 	NULL,
		FechaRespaldo	datetime default GETDATE()
	--CONSTRAINT priContRegRespaldo PRIMARY KEY CLUSTERED (ID)
)
GO
EXEC spALTER_TABLE 'ContRegRespaldo', 'ContactoEspecifico', 'varchar(10) NULL'
go
EXEC spALTER_TABLE 'ContRegRespaldo', 'SubCuenta2', 'varchar(50) NULL'
go
EXEC spALTER_TABLE 'ContRegRespaldo', 'SubCuenta3', 'varchar(50) NULL'
GO
EXEC spADD_INDEX 'ContRegRespaldo', 'Cuenta', 'Cuenta, Empresa'
GO


INSERT INTO ContRegRespaldo (ID,RID,Empresa,Sucursal,Modulo,ModuloID,ModuloRenglon,ModuloRenglonSub,Cuenta,SubCuenta,Concepto,Debe,Haber,ContactoEspecifico,SubCuenta2,SubCuenta3)
SELECT ID,RID,Empresa,Sucursal,Modulo,ModuloID,ModuloRenglon,ModuloRenglonSub,Cuenta,SubCuenta,Concepto,Debe,Haber,ContactoEspecifico,SubCuenta2,SubCuenta3 FROM
ContReg (NOLOCK)

go


--/**************************************/
--/*RESPALDO DE CONTREG DESPUES DE LA ACTUALIZACION SIN EL MODULO DE DINERO*/
----DROP TABLE ContRegRespaldo
--/****** Contabilidad (Registro) ******/
--if not exists (select * from SysTabla where SysTabla = 'ContRegRespaldo2') 
--INSERT INTO SysTabla (SysTabla,Tipo,Modulo) VALUES ('ContRegRespaldo2','Movimiento','CONT') 
--if not exists (select * from sysobjects where id = object_id('dbo.ContRegRespaldo2') and type = 'U') 
--CREATE TABLE dbo.ContRegRespaldo2 (
--		ID			int 	    	NOT NULL,
--		RID			int 	    	NOT NULL,

--		Empresa			varchar(5)		NULL,
--       	Sucursal		int		NULL,
--		Modulo			varchar(5)		NULL,
--		ModuloID		int		NULL,	 	
--       	ModuloRenglon		float		NULL,
--       	ModuloRenglonSub	int		NULL,

--       	Cuenta			varchar(20) 	NULL, 
--       	SubCuenta 		varchar(50) 	NULL,
--       	Concepto		varchar(50) 	NULL,
--       	Debe			money		NULL,
--       	Haber			money		NULL,
--		ContactoEspecifico	varchar(10)	NULL,
--       	SubCuenta2 		varchar(50) 	NULL,
--       	SubCuenta3 		varchar(50) 	NULL,
--		FechaRespaldo	datetime default GETDATE()
--	CONSTRAINT priContRegRespaldo2 PRIMARY KEY CLUSTERED (ID, RID)
--)
--GO
--EXEC spALTER_TABLE 'ContRegRespaldo2', 'ContactoEspecifico', 'varchar(10) NULL'
--EXEC spALTER_TABLE 'ContRegRespaldo2', 'SubCuenta2', 'varchar(50) NULL'
--EXEC spALTER_TABLE 'ContRegRespaldo2', 'SubCuenta3', 'varchar(50) NULL'
--GO
--EXEC spADD_INDEX 'ContRegRespaldo2', 'Cuenta', 'Cuenta, Empresa'
--GO


--INSERT INTO ContRegRespaldo2 (ID,RID,Empresa,Sucursal,Modulo,ModuloID,ModuloRenglon,ModuloRenglonSub,Cuenta,SubCuenta,Concepto,Debe,Haber,ContactoEspecifico,SubCuenta2,SubCuenta3)
--SELECT ID,RID,Empresa,Sucursal,Modulo,ModuloID,ModuloRenglon,ModuloRenglonSub,Cuenta,SubCuenta,Concepto,Debe,Haber,ContactoEspecifico,SubCuenta2,SubCuenta3 FROM
--ContReg (NOLOCK)

--go