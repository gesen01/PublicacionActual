
[Forma]
Clave=DICOEspecificarTableroIC
Icono=0
Modulos=(Todos)
Nombre=Especifcar Datos
VentanaTipoMarco=Normal
VentanaPosicionInicial=Centrado
VentanaEscCerrar=S
VentanaEstadoInicial=Normal
BarraAcciones=S
AccionesTamanoBoton=15x5
AccionesCentro=S
AccionesDivision=S

ListaCarpetas=Ficha
CarpetaPrincipal=Ficha
PosicionInicialIzquierda=443
PosicionInicialArriba=302
PosicionInicialAlturaCliente=125
PosicionInicialAncho=479
ListaAcciones=(Lista)
ExpresionesAlMostrar=Asigna(Info.Cuenta,<T>(TODOS)<T>)
ExpresionesAlActivar=Asigna(Info.Cuenta,<T>(TODOS)<T>)
[Ficha]
Estilo=Ficha
Clave=Ficha
PermiteEditar=S
AlineacionAutomatica=S
AcomodarTexto=S
MostrarConteoRegistros=S
Zona=A1
Vista=(Variables)
Fuente={Tahoma, 8, Negro, []}
FichaEspacioEntreLineas=6
FichaEspacioNombres=100
FichaEspacioNombresAuto=S
FichaNombres=Izquierda
FichaAlineacion=Izquierda
FichaColorFondo=Plata
FichaAlineacionDerecha=S
CampoColorLetras=Negro
CampoColorFondo=Blanco
ListaEnCaptura=(Lista)

CarpetaVisible=S
[Ficha.ListaEnCaptura]
(Inicio)=Info.FechaD
Info.FechaD=Info.FechaA
Info.FechaA=Info.Cuenta
Info.Cuenta=(Fin)

[Ficha.Info.FechaD]
Carpeta=Ficha
Clave=Info.FechaD
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=20
ColorFondo=Blanco

[Ficha.Info.FechaA]
Carpeta=Ficha
Clave=Info.FechaA
Editar=S
ValidaNombre=S
3D=S
Tamano=20
ColorFondo=Blanco

[Ficha.Info.Cuenta]
Carpeta=Ficha
Clave=Info.Cuenta
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=20
ColorFondo=Blanco

[Lista.Columnas]
0=-2

1=-2
2=-2
3=-2
4=-2
5=-2
6=-2
7=-2
8=244
9=-2
[Acciones.Aceptar.Asignar]
Nombre=Asignar
Boton=0
TipoAccion=Controles Captura
ClaveAccion=Variables Asignar
Activo=S
Visible=S

[Acciones.Aceptar.AceptarVen]
Nombre=AceptarVen
Boton=0
TipoAccion=Ventana
ClaveAccion=Aceptar
Activo=S
Visible=S

[Acciones.Aceptar]
Nombre=Aceptar
Boton=0
NombreEnBoton=S
NombreDesplegar=&Aceptar
Multiple=S
EnBarraAcciones=S
ListaAccionesMultiples=(Lista)

Activo=S
Visible=S

[Acciones.Cancelar]
Nombre=Cancelar
Boton=0
NombreEnBoton=S
NombreDesplegar=&Cancelar
EnBarraAcciones=S
TipoAccion=Ventana
ClaveAccion=Cancelar
Activo=S
Visible=S








[Acciones.Aceptar.Proc]
Nombre=Proc
Boton=0
TipoAccion=Expresion
Expresion=EjecutarSQL(<T>xpDICOTableroIC :nEstacion, :tEmpresa, :tFechaD, :tFechaA, :tCta<T>,EstacionTrabajo,Empresa,FechaFormatoServidor(Info.FechaD),FechaFormatoServidor(Info.FechaA),Info.Cuenta)  
Activo=S
Visible=S

[Acciones.Aceptar.Tablero]
Nombre=Tablero
Boton=0
TipoAccion=Expresion
Expresion=Forma(<T>DICOTableroIC<T>)
Activo=S
Visible=S

[Acciones.Aceptar.ListaAccionesMultiples]
(Inicio)=Asignar
Asignar=Proc
Proc=AceptarVen
AceptarVen=Tablero
Tablero=(Fin)























[Forma.ListaAcciones]
(Inicio)=Aceptar
Aceptar=Cancelar
Cancelar=(Fin)
