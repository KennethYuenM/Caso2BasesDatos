Motor de base de datos PostgradeSQL: 18
Nombre Base de datos:  Etheria Global: Sourcing & Logistics
Contexto: Esta empresa se encarga de la cadena de suministro. Importan productos naturales y curativos exóticos de todo el mundo (bebidas, alimentos, cosmética dermatológica, capilar, aromaterapia, jabones y aceites esenciales).
Todos los productos son de gama alta y poseen propiedades medicinales/saludables.
Se importan en "bulk" (cajas sin marca ni etiquetado) en dólares (USD).
Todo llega a un centro logístico en la costa Caribe de Nicaragua.

# Tables:

## Usuarios
- usuarioID (PK)
- nombre varchar(50)
- apellido varchar(50)
- segundoApellido varchar(50)
- email varchar(100)
- contraseñaHASH text
- creado timestamp
- actualizado timestamp
- ultimoLogin timestamp
- activo boolean

## Roles 
- roleID (PK)
- rolNombre varchar(40)
- descripcion varchar(500)
- activo boolean

## RolesXUsuario
- usuarioID (FK)
- roleID (FK)
- asignado timestamp

(Crear un script par que cree todas las tablas del proyecto)
## Tablas (por tablas me refiero a todas la tablas del proyecto)
- tablaID (PK)
- nombreTabla varchar(50)
- creado timestamp

## Acciones
- accionID (PK)
- nombreAccion varchar(10) (CREATE, READ, UPDATE, DELETE)

## PermisosSistema
- permisoID (PK)
- tablaID (FK)
- accionID (FK)

## PermisosXRole
- roleID (FK)
- permisoID (FK)

## Paises
- paisID (PK)  
- nombre varchar(30)
- codigoISO varchar (3)
- activo boolean

## NivelesGeograficos
- nivelID (PK)
- nombre varchar(50)
- orden int (Jerarquía 1 = más alto después del país)
- activo boolean

## DivisionesGeograficas
- divisionID (PK)
- paisID (FK)
- nivelID (FK)
- padreID (FK) (División padre auto-relación jerárquica puede ser nulo, solo si el nivelID.orden es = 1)
- nombre varchar(100)

## Direcciones
- direccionID (PK)
- divisionID (FK)
- usuarioModificacion (FK) (Usuario que insertó la direccion)
- calle varchar (150)
- número varchar(20)
- referencia varchar(500)
- codigoPostal varchar(20)
- direccionCompleta text (Generado automáticamente en el script, hagarrando los datos de division id y creando un texto pasando por todas las autoreferencias hasta llegar al nivelID es 1, a demas de calle, número y referencia)
- fechaCreacion timestamp
- activo boolean

## CentrosLogisticos
- centroLogisticoID (PK)
- tipoID (FK)
- direccionID (FK) (Direccion principal, pero unica de un centro de distribución)
- usuarioModificacion (FK)
- nombre varchar(50)
- telefono varchar(20)
- activo boolean

## ContactosProveedor
- centroLogisticoID (FK)
- contactoID (FK)
- activo boolean

## TiposCentroLogistico
- tipoID (PK)
- nombre varchar(20) (Puerto, Aeropuerto, Empresa Repartidora)

## Monedas
- monedaID (PK)
- usuarioModificacion (FK)
- paisID (FK)
- simboloMoneda varchar(10)
- nombreMoneda varchar(50)
- tiempoCreacion timestamp
- activo boolean

## TiposCambio
- tipoCambioID (PK)
- usuarioModificacion (FK)
- moneda1ID (FK)
- moneda2ID (FK) (validar con trigger que moneda 1 y 2 no sean iguales y un try cath)
- tipoCambio decimal(18,6)
- tiempoCreacion timestamp
- ultimaActualizacion timestamp
- checksum varchar(100)
- activo boolean

(cuando se actualice TiposCambio crear historial con triggerCambios
ademas de actualizar la anterior fechaFin)
## HistorialCambiosMonedas
- histotalCambioID (PK)
- moneda1ID (FK)
- moneda2ID (FK)
- tipoCambioID (FK)
- usuarioModificacion (FK)
- fechaInicio timestamp
- fechaFin timestamp (en caso de ser la ultima poner en el año en 9999)
- tipoCambio decimal(18,6)
- checksum varchar(100)
- horaCambio timestamp

(todo lo que se haga en la base de datos, cada insercion y actualizacion debe pasar por logs con scipts, incluyendo los cualquier begin y exception)
## Logs
- logID (PK)
- usuarioModificacion (FK) (puede ser nulo en ciertos casos)
- tablaID (FK)
- accionID (FK)
- objetoAfectadoID int
- datosViejos JSON
- datosNuevos JSON
- hora timestamp
- error text
- checksum text

(investigando, cada país tiene su forma de cobrar y sumar los premisos, para simplificarlo
simplemente tiene un campo, que seria el cobro por el tramite por producto)
## PermisosImportacion 
- permisoID (PK)
- paisID (FK)
- tipoPermisoID (FK)
- usuarioModificacion (FK)
- nombrePermiso varchar(20)
- costo decimal(18,6)
- activo boolean

## TiposPermisos
- tipoPermisoID (FK)
- nombreTipoPermiso varchar(20)


## Productos
- productoID (PK)
- categoriaID (FK)
- usuarioModificacion (FK)
- proveedorID (FK)
- nombre varchar(40)
- descripcion varchar(200)
- descripcionManejo varchar(200)
- activo boolean

## Categorias
- categoriaID (PK)
- nombre varchar(20)
- activo boolean

## ValorCaracteristicas
- productoID: FK
- caracteristicaID: FK
- valor: varchar(50)
- deleted: boolean

## Caracteristicas
- caracteristicaID (PK)
- nombre varchar(50)

## Proveedores
- proveedorID (PK)
- direccionID (FK)
- nombre varchar(50)
- activo boolean

## Contactos
- contactoID (PK)
- usuarioModificacion (FK)
- nombre varchar(50)
- apellido varchar(50)
- segundoApellido varchar(50)
- email varchar(100)
- número varchar (20)
- activo boolean

## ContactosProveedor
- proveedorID (FK)
- contactoID (FK)
- activo boolean

## Lotes (nota, lotes ya es en si un hitorial de precios)
- loteID (PK)
- productoID (FK)
- precio decimal(18,6)
- ingredientes varchar(500)
- fechaFabricacion timestamp
- fechaVencimiento timestamp (puede ser nulo)

## EstadosOrdenes
- estadoID (PK)
- nombre varchar(10)

## Ordenes
- ordenID (PK) (es necesario agregar codigoOrden, o se puede dejar solo con el id?)
- estadoID (FK)
- usuarioModificacion (FK)
- direccionEnvioID (FK)
- direccionEntregaID (FK)
- tipoOrden enum(venta, compra)
- numeroOrden varchar(30)
- precioFinal decimal(18,6) 
- fecha timestamp

(se nececita un script que cada que se cree una orden detalle, se sume el precioLoteFinal al precioFinal del orden)
## OrdenDetalles
- ordenDetalleID (PK)
- ordenID (FK)
- loteID (FK)
- impuestoID (FK)
- permisoID (FK) 
- cantidad int
- descuento decimal(18,6)
- costoEnvio decimal(18,6)
- precioLoteFinal decimal(18,6) (se calcula con el ((costo del lote - descuento) + impuesto + permisos + costoEnvio)* cantidad)
- checksum text

## ImpuestosPais
- impuestoID (PK)
- paisID (FK)
- usuarioModificacion (FK)
- porcentaje decimal(5,2)
- activo boolean

## TrazabilidadOrden
- trazabilidadID (PK)
- ordenID (FK)
- centroLogisticoID (FK)
- direccionID (FK)
- usuarioModificacion (FK)
- estadoID (FK)
- fecha timestamp

## Transacciones
- transaccionID (PK)
- monedaID (FK)
- usuarioModificacion (FK)
- tipoID (FK)
- estadoTransaccionID (FK)
- ordenID (FK)
- monto decimal(18,6)
- descripcion text
- fecha timestamp
- checksum text

## EstadadoTransacciones
- estadoTransaccionID (PK)
- nombre varchar(20)

## TipoTransacciones
- tipoID (PK)
- nombre varchar(20)

## Inventarios
- inventarioID (PK)
- loteID (FK)
- usuarioModificacion (FK)
- cantidadDisponible int
- ultimaActualizacion timestamp

(cada que se crea una orden, se crea automaticamente un estado de cuenta, cada que se actualiza un estado de cuenta en el apartado de estado, se actualiza el balance neto solamente si se cambia a comletado)
## EstadosCuenta
- estadoCuentaID (PK)
- ordenID (FK)
- usuarioModificacion (FK)
- tipoMovimiento enum ('Debito', 'Credito', segun el tipoOrden)
- estado enum (pendiente, completado, cancelado)
- monto decimal(18,6)
- fechaRegistro timestamp
- checksum text

## BalanceNeto
- balanceID (PK)
- saldo decimal(18,6)
- ultimaActualización timestamp

On deleted no action para las fk