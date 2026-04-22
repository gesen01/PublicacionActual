
[Forma]
Clave=DICOTableroIC
Icono=0
Modulos=(Todos)
Nombre=Tablero de Polizas a Integración Cont
VentanaTipoMarco=Normal
VentanaPosicionInicial=Centrado
VentanaEscCerrar=S
VentanaEstadoInicial=Normal
BarraHerramientas=S
AccionesTamanoBoton=15x5
AccionesDerecha=S

ListaCarpetas=Lista
CarpetaPrincipal=Lista
PosicionInicialIzquierda=199
PosicionInicialArriba=128
PosicionInicialAlturaCliente=472
PosicionInicialAncho=967
ListaAcciones=(Lista)
[Lista]
Estilo=Iconos
Clave=Lista
Filtros=S
BusquedaRapidaControles=S
AlineacionAutomatica=S
AcomodarTexto=S
MostrarConteoRegistros=S
Zona=A1
Vista=DICOTableroIC
Fuente={Tahoma, 8, Negro, []}
CampoColorLetras=Negro
CampoColorFondo=Blanco
ListaEnCaptura=(Lista)

FiltroPredefinido=S
FiltroNullNombre=(sin clasificar)
FiltroEnOrden=S
FiltroTodoNombre=(Todo)
FiltroAncho=20
FiltroRespetar=S
FiltroTipo=General
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
CarpetaVisible=S
PestanaOtroNombre=S
PestanaNombre=Tablero Int Cont

IconosCampo=(sin Icono)
IconosEstilo=Detalles
IconosAlineacion=de Arriba hacia Abajo
IconosConSenales=S
IconosSubTitulo=<T>Consecutivo<T>
ElementosPorPaginaEsp=200
IconosSeleccionPorLlave=S
IconosSeleccionMultiple=S
IconosNombre=DICOTableroIC.ID
FiltroGeneral=DICOTableroIC.Estacion={EstacionTrabajo}<BR>AND DICOTableroIC.Tipo<><T>SinDiferencia<T>
[Lista.DICOTableroIC.FechaContable]
Carpeta=Lista
Clave=DICOTableroIC.FechaContable
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco

[Lista.DICOTableroIC.Estatus]
Carpeta=Lista
Clave=DICOTableroIC.Estatus
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=15
ColorFondo=Blanco

[Lista.DICOTableroIC.DebeContReg]
Carpeta=Lista
Clave=DICOTableroIC.DebeContReg
Editar=S
Totalizador=1
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco

[Lista.DICOTableroIC.HaberContReg]
Carpeta=Lista
Clave=DICOTableroIC.HaberContReg
Editar=S
Totalizador=1
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco

[Lista.DICOTableroIC.DebeCont]
Carpeta=Lista
Clave=DICOTableroIC.DebeCont
Editar=S
Totalizador=1
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco

[Lista.DICOTableroIC.HaberCont]
Carpeta=Lista
Clave=DICOTableroIC.HaberCont
Editar=S
Totalizador=1
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco

[Lista.DICOTableroIC.DifDebe]
Carpeta=Lista
Clave=DICOTableroIC.DifDebe
Editar=S
Totalizador=1
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco

[Lista.DICOTableroIC.DifHaber]
Carpeta=Lista
Clave=DICOTableroIC.DifHaber
Editar=S
Totalizador=1
LineaNueva=S
ValidaNombre=S
3D=S
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

[Acciones.Procesar]
Nombre=Procesar
Boton=92
NombreEnBoton=S
NombreDesplegar=&Procesar
EnBarraHerramientas=S
TipoAccion=Expresion
Activo=S
Visible=S


EspacioPrevio=S

Expresion=RegistrarSeleccion(<T>Lista<T>)<BR>ProcesarSQL(<T>EXEC xpDICOCorrecionIC  :nEstacion,:tEmpresa,1<T>,EstacionTrabajo,Empresa)<BR>ActualizarVista
[Acciones.Excel]
Nombre=Excel
Boton=67
NombreDesplegar=&Excel
EnBarraHerramientas=S
Carpeta=(Carpeta principal)
TipoAccion=Controles Captura
ClaveAccion=Enviar a Excel
Activo=S
Visible=S


EspacioPrevio=S
[Acciones.Personalizar]
Nombre=Personalizar
Boton=45
NombreDesplegar=&Personalizar
EnBarraHerramientas=S
Carpeta=(Carpeta principal)
TipoAccion=Controles Captura
ClaveAccion=Mostrar Campos
Activo=S
Visible=S














[Acciones.Seleccionar]
Nombre=Seleccionar
Boton=70
NombreEnBoton=S
NombreDesplegar=&Seleccionar Todo
EnBarraHerramientas=S
TipoAccion=Controles Captura
ClaveAccion=Seleccionar Todo
Activo=S
Visible=S

































[Lista.DICOTableroIC.Tipo]
Carpeta=Lista
Clave=DICOTableroIC.Tipo
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=15
ColorFondo=Blanco


























[Lista.ListaEnCaptura]
(Inicio)=Movimiento
Movimiento=DICOTableroIC.FechaContable
DICOTableroIC.FechaContable=DICOTableroIC.Estatus
DICOTableroIC.Estatus=DICOTableroIC.DebeCont
DICOTableroIC.DebeCont=DICOTableroIC.HaberCont
DICOTableroIC.HaberCont=DICOTableroIC.DebeContReg
DICOTableroIC.DebeContReg=DICOTableroIC.HaberContReg
DICOTableroIC.HaberContReg=DICOTableroIC.DifDebe
DICOTableroIC.DifDebe=DICOTableroIC.DifHaber
DICOTableroIC.DifHaber=DICOTableroIC.Tipo
DICOTableroIC.Tipo=(Fin)

[Lista.Movimiento]
Carpeta=Lista
Clave=Movimiento
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=150
ColorFondo=Blanco

[Forma.ListaAcciones]
(Inicio)=Cerrar
Cerrar=Procesar
Procesar=Seleccionar
Seleccionar=Excel
Excel=Personalizar
Personalizar=(Fin)
