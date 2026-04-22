
[Forma]
Clave=DICODesgloseContactoSI
Icono=0
Modulos=(Todos)
Nombre=<T>Desglose Saldo Inicial<T>
VentanaTipoMarco=Normal
VentanaPosicionInicial=Centrado
VentanaEscCerrar=S
VentanaEstadoInicial=Normal
BarraHerramientas=S
AccionesTamanoBoton=15x5
AccionesDerecha=S

ListaCarpetas=Detalle
CarpetaPrincipal=Detalle
Comentarios=Lista(<T>Cuenta: <T>+Info.Cuenta, <T>Ejercicio:<T>+Info.Ejercicio, <T>Periodo:<T>+Info.PeriodoD+<T> - <T>+Info.PeriodoA, <T>Contacto: <T>+DICODesgloseContactoSI:DICODesgloseContactoSI.Contacto, Info.Moneda)
PosicionInicialIzquierda=149
PosicionInicialArriba=121
PosicionInicialAlturaCliente=486
PosicionInicialAncho=1068
Totalizadores=S
PosicionSec1=405
ListaAcciones=(Lista)
[Detalle]
Estilo=Hoja
Clave=Detalle
Filtros=S
AlineacionAutomatica=S
AcomodarTexto=S
MostrarConteoRegistros=S
Zona=A1
Vista=DICODesgloseContactoSI
Fuente={Tahoma, 8, Negro, []}
HojaTitulos=S
HojaMostrarColumnas=S
HojaMostrarRenglones=S
HojaColoresPorEstatus=S
HojaPermiteInsertar=S
HojaPermiteEliminar=S
HojaVistaOmision=Automática
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
CarpetaVisible=S

OtroOrden=S
ListaOrden=Cont.FechaEmision<TAB>(Acendente)
FiltroGeneral=DICODesgloseContactoSI.Estacion={EstacionTrabajo}<BR>AND ISNULL(DICODesgloseContactoSI.Contacto,<T><T>)={Si(ConDatos(Info.Contacto),Comillas(Info.Contacto),Comillas(<T><T>))}<BR>AND ISNULL(DICODesgloseContactoSI.ContactoTipo,<T><T>)={Si(ConDatos(Info.ContactoTipo),Comillas(Info.ContactoTipo),Comillas(<T><T>))}
[Detalle.Cont.FechaEmision]
Carpeta=Detalle
Clave=Cont.FechaEmision
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco

[Detalle.Cont.Referencia]
Carpeta=Detalle
Clave=Cont.Referencia
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=50
ColorFondo=Blanco

[Detalle.Cont.Observaciones]
Carpeta=Detalle
Clave=Cont.Observaciones
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=100
ColorFondo=Blanco

[Detalle.Cont.Mov]
Carpeta=Detalle
Clave=Cont.Mov
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=20
ColorFondo=Blanco

[Detalle.Cont.MovID]
Carpeta=Detalle
Clave=Cont.MovID
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=20
ColorFondo=Blanco

[Detalle.Cont.Origen]
Carpeta=Detalle
Clave=Cont.Origen
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=20
ColorFondo=Blanco

[Detalle.Cont.OrigenID]
Carpeta=Detalle
Clave=Cont.OrigenID
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=20
ColorFondo=Blanco

[Detalle.DICODesgloseContactoSI.Debe]
Carpeta=Detalle
Clave=DICODesgloseContactoSI.Debe
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco

[Detalle.DICODesgloseContactoSI.Haber]
Carpeta=Detalle
Clave=DICODesgloseContactoSI.Haber
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
ColorFondo=Blanco

[Detalle.Columnas]
FechaEmision=94
Referencia=128
Observaciones=178
Mov=124
MovID=64
Origen=124
OrigenID=64
Debe=64
Haber=64


[(Carpeta Totalizadores)]
Clave=(Carpeta Totalizadores)
AlineacionAutomatica=S
AcomodarTexto=S
MostrarConteoRegistros=S
Zona=B1
Fuente={Tahoma, 8, Negro, []}
FichaEspacioEntreLineas=6
FichaEspacioNombres=100
FichaEspacioNombresAuto=S
FichaNombres=Izquierda
FichaAlineacion=Izquierda
FichaColorFondo=Plata
FichaAlineacionDerecha=S
Totalizadores1=Debe<BR>Haber<BR>Final
Totalizadores2=Suma(DICODesgloseContactoSI:DICODesgloseContactoSI.Debe)<BR>Suma(DICODesgloseContactoSI:DICODesgloseContactoSI.Haber)<BR>Suma(DICODesgloseContactoSI:DICODesgloseContactoSI.Debe)-Suma(DICODesgloseContactoSI:DICODesgloseContactoSI.Haber)
Totalizadores3=(Monetario)<BR>(Monetario)<BR>(Monetario)
Totalizadores=S
CampoColorLetras=Negro
CampoColorFondo=Plata
CarpetaVisible=S

TotCarpetaRenglones=Detalle
ListaEnCaptura=(Lista)

[(Carpeta Totalizadores).Debe]
Carpeta=(Carpeta Totalizadores)
Clave=Debe
Editar=S
LineaNueva=S
ValidaNombre=S
3D=S
Tamano=15
ColorFondo=Plata

Efectos=[Negritas]
[(Carpeta Totalizadores).Haber]
Carpeta=(Carpeta Totalizadores)
Clave=Haber
Editar=S
ValidaNombre=S
3D=S
Tamano=15
ColorFondo=Plata

Efectos=[Negritas]
[(Carpeta Totalizadores).Final]
Carpeta=(Carpeta Totalizadores)
Clave=Final
Editar=S
ValidaNombre=S
3D=S
Tamano=15
ColorFondo=Plata

Efectos=[Negritas]
[(Carpeta Totalizadores).ListaEnCaptura]
(Inicio)=Debe
Debe=Haber
Haber=Final
Final=(Fin)


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

[Acciones.Poliza]
Nombre=Poliza
Boton=17
NombreEnBoton=S
NombreDesplegar=&Poliza
EnBarraHerramientas=S
Activo=S
Visible=S


EspacioPrevio=S
TipoAccion=Expresion
Expresion=Asigna(Info.ID,DICODesgloseContactoSI:Cont.ID)<BR>ReportePantalla(<T>CONT<T>, Info.ID)


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
[Acciones.Propiedades]
Nombre=Propiedades
Boton=35
NombreDesplegar=&Propiedades del movimiento
EnBarraHerramientas=S
TipoAccion=Formas
ClaveAccion=MovPropiedades
Activo=S
Visible=S






ConCondicion=S
EjecucionCondicion=ConDatos(DICODesgloseContactoSI:DICODesgloseContactoSI.ID)
Antes=S
AntesExpresiones=Asigna(Info.Modulo, <T>CONT<T>)<BR>Asigna(Info.ID, DICODesgloseContactoSI:DICODesgloseContactoSI.ID)


[Detalle.ListaEnCaptura]
(Inicio)=Cont.FechaEmision
Cont.FechaEmision=Cont.Referencia
Cont.Referencia=Cont.Observaciones
Cont.Observaciones=Cont.Mov
Cont.Mov=Cont.MovID
Cont.MovID=Cont.Origen
Cont.Origen=Cont.OrigenID
Cont.OrigenID=DICODesgloseContactoSI.Debe
DICODesgloseContactoSI.Debe=DICODesgloseContactoSI.Haber
DICODesgloseContactoSI.Haber=(Fin)



[Forma.ListaAcciones]
(Inicio)=Cerrar
Cerrar=Poliza
Poliza=Excel
Excel=Propiedades
Propiedades=(Fin)
