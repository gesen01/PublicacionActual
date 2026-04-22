CREATE TABLE DICODesgloseContactoSI(
	Estacion		INT				NOT NULL,
	ID				INT				NOT NULL,
	Empresa			VARCHAR(10)		NULL,
	Contacto		VARCHAR(10)		NULL,
	ContactoTipo	VARCHAR(15)		NULL,
	Cuenta			VARCHAR(30)		NULL,
	Sucursal		INT				NULL,
	Debe			FLOAT			NULL,
	Haber			FLOAT			NULL
)