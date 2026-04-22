SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF

go


Alter table ContReg add Procesado bit NULL default 0 with values
go
Alter table ContReg add NumUpdate int NULL 
go

CREATE NONCLUSTERED INDEX idx_Procesado
ON ContReg (Empresa, Cuenta, ContactoEspecifico, Procesado);
go

CREATE NONCLUSTERED INDEX idx_Contacto
ON MovReg (Empresa, Modulo, Id, Contacto);
go