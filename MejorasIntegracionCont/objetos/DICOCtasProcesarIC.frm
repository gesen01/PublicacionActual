
[Forma]
Clave=DICOCtasProcesarIC
Icono=0
Modulos=(Todos)
Nombre=Cuentas - Integración Contable
VentanaTipoMarco=Normal
VentanaPosicionInicial=Centrado
VentanaEstadoInicial=Normal
BarraHerramientas=S
AccionesTamanoBoton=15x5
AccionesDerecha=S

ListaCarpetas=(Lista)
CarpetaPrincipal=Procesados
PosicionInicialIzquierda=383
PosicionInicialArriba=72
PosicionInicialAlturaCliente=584
PosicionInicialAncho=600
PosicionCol1=371
PosicionSec1=230
ListaAcciones=(Lista)
[SinProcesar]
Estilo=Iconos
Clave=SinProcesar
AlineacionAutomatica=S
AcomodarTexto=S
MostrarConteoRegistros=S
Zona=A1
Vista=DICOCtasProcesarIC
Fuente={Tahoma, 8, Negro, []}
CampoColorLetras=Negro
CampoColorFondo=Blanco
ListaEnCaptura=Procesado

CarpetaVisible=S
Pestana=S
PestanaOtroNombre=S
PestanaNombre=Sin Procesar

RefrescarAlEntrar=S
IconosCampo=(sin Icono)
IconosEstilo=Detalles
IconosAlineacion=de Arriba hacia Abajo
IconosConSenales=S
IconosSubTitulo=<T>Cuenta<T>
ElementosPorPaginaEsp=200
Filtros=S
FiltroPredefinido=S
FiltroNullNombre=(sin clasificar)
FiltroEnOrden=S
FiltroTodoNombre=(Todo)
FiltroAncho=20
FiltroRespetar=S
FiltroTipo=General
IconosNombre=DICOCtasProcesarIC:Cuenta
FiltroGeneral=vwDICOCtasProcesarIC.Procesado=0<BR>AND vwDICOCtasProcesarIC.Empresa=<T>{Empresa}<T>
[SinProcesar.Procesado]
Carpeta=SinProcesar
Clave=Procesado
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco

[SinProcesar.Columnas]
Cuenta=124
Procesado=64
0=153
1=193

[Procesados]
Estilo=Iconos
Clave=Procesados
Filtros=S
AlineacionAutomatica=S
AcomodarTexto=S
MostrarConteoRegistros=S
Zona=A1
Vista=DICOCtasProcesarIC
Fuente={Tahoma, 8, Negro, []}
CampoColorLetras=Negro
CampoColorFondo=Blanco
ListaEnCaptura=Procesado
FiltroPredefinido=S
FiltroNullNombre=(sin clasificar)
FiltroEnOrden=S
FiltroTodoNombre=(Todo)
FiltroAncho=20
FiltroRespetar=S
FiltroTipo=General
CarpetaVisible=S

Pestana=S
PestanaOtroNombre=S
PestanaNombre=Procesados
RefrescarAlEntrar=S
IconosCampo=(sin Icono)
IconosEstilo=Detalles
IconosAlineacion=de Arriba hacia Abajo
IconosConSenales=S
IconosSubTitulo=<T>Cuenta<T>
ElementosPorPaginaEsp=200
BusquedaRapidaControles=S
IconosNombre=DICOCtasProcesarIC:Cuenta
FiltroGeneral=vwDICOCtasProcesarIC.Procesado=1<BR>AND vwDICOCtasProcesarIC.Empresa=<T>{Empresa}<T>
FiltroModificarEstatus=S
FiltroCambiarPeriodo=S
FiltroBuscarEn=S
FiltroFechasCambiar=S
FiltroFechasNormal=S
FiltroFechasNombre=&Fecha
BusquedaRapida=S
BusquedaInicializar=S
BusquedaRespetarControles=S
BusquedaAncho=20
BusquedaEnLinea=S
[Procesados.Procesado]
Carpeta=Procesados
Clave=Procesado
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco


[Procesados.Columnas]
0=163
1=193


















Cuenta=124
Procesado=64


[Procesados.ListaEnCaptura]
(Inicio)=Cuenta
Cuenta=Procesado
Procesado=(Fin)




[SinProcesar.ListaEnCaptura]
(Inicio)=Cuenta
Cuenta=Procesado
Procesado=(Fin)










[Acciones.Cerrar]
Nombre=Cerrar
Boton=23
NombreEnBoton=S
NombreDesplegar=&Cerrar
EnBarraHerramientas=S
TipoAccion=Ventana
ClaveAccion=Cerrar
Activo=S
Visible=S


[Acciones.Agregar]
Nombre=Agregar
Boton=70
NombreEnBoton=S
NombreDesplegar=&Agregar Cta
EnBarraHerramientas=S
TipoAccion=Expresion
Activo=S
Visible=S



























Expresion=FormaModal(<T>DICOEspecificarCtaCont<T>)<BR>ProcesarSQL(<T>EXEC xpDICOAsignarCtasIC :tEmp,:tCta<T>,Empresa,Info.Cuenta)<BR>Forma.IrCarpeta(<T>SinProcesar<T>)<BR>Forma.ActualizarVista(<T>SinProcesar<T>)










[Forma.ListaCarpetas]
(Inicio)=Procesados
Procesados=SinProcesar
SinProcesar=(Fin)

[Forma.ListaAcciones]
(Inicio)=Cerrar
Cerrar=Agregar
Agregar=(Fin)
