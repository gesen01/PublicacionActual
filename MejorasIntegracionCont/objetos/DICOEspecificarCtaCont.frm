
[Forma]
Clave=DICOEspecificarCtaCont
Icono=0
Modulos=(Todos)
Nombre=Especificar Cuenta Contable
VentanaTipoMarco=Normal
VentanaPosicionInicial=Centrado
VentanaEscCerrar=S
VentanaEstadoInicial=Normal
BarraAcciones=S
AccionesTamanoBoton=15x5

ListaCarpetas=Ficha
CarpetaPrincipal=Ficha
PosicionInicialIzquierda=488
PosicionInicialArriba=303
PosicionInicialAlturaCliente=122
PosicionInicialAncho=390
ListaAcciones=(Lista)
AccionesCentro=S
AccionesDivision=S
[Ficha]
Estilo=Ficha
Clave=Ficha
AlineacionAutomatica=S
AcomodarTexto=S
MostrarConteoRegistros=S
Zona=A1
Vista=(Variables)
Fuente={Tahoma, 8, Negro, []}
CampoColorLetras=Negro
CampoColorFondo=Blanco
ListaEnCaptura=Info.Cuenta
CarpetaVisible=S

FichaEspacioEntreLineas=0
FichaEspacioNombres=0
FichaColorFondo=Negro


FichaNombres=Arriba


PermiteEditar=S

[Acciones.Aceptar.Asignar]
Nombre=Asignar
Boton=0
TipoAccion=Controles Captura
ClaveAccion=Variables Asignar
Activo=S
Visible=S

[Acciones.Aceptar.Aceptar]
Nombre=Aceptar
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
[Acciones.Aceptar.ListaAccionesMultiples]
(Inicio)=Asignar
Asignar=Aceptar
Aceptar=(Fin)

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


[Ficha.ListaEnCaptura]
(Inicio)=Info.DICOCuentaCont
Info.DICOCuentaCont=Info.Cuenta
Info.Cuenta=(Fin)

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
0=207



[Forma.ListaAcciones]
(Inicio)=Aceptar
Aceptar=Cancelar
Cancelar=(Fin)
