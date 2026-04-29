Motor de base de datos PostgradeSQL: 18
Nombre Base de datos:  Etheria Global: Sourcing & Logistics
Contexto: Esta empresa se encarga de la cadena de suministro. Importan productos naturales y curativos exóticos de todo el mundo (bebidas, alimentos, cosmética dermatológica, capilar, aromaterapia, jabones y aceites esenciales).
Todos los productos son de gama alta y poseen propiedades medicinales/saludables.
Se importan en "bulk" (cajas sin marca ni etiquetado) en dólares (USD).
Todo llega a un centro logístico en la costa Caribe de Nicaragua.

# Tables:

/*---------------Seguridad y acceso---------------*/
## Usuarios
- usuarioID (PK)
- nombreUsuario varchar(50)
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

## PermisosSistema
- permisoID (PK)
- nombrePermiso varchar (30)
- descripcion varchar (200)

## PermisosXRole
- roleID (FK)
- permisoID (FK)

/*---------------Auditoria y Sistema---------------*/

(Crear un script par que cree todas las tablas del proyecto)
## Tablas (por tablas me refiero a todas la tablas del proyecto)
- tablaID (PK)
- nombreTabla varchar(50)
- creado timestamp

## Acciones
- accionID (PK)
- nombreAccion varchar(10) (CREATE, READ, UPDATE, DELETE)

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

/*---------------Geografía y Direcciones---------------*/

## Paises
- paisID (PK)  
- nombrePais varchar(30)
- codigoISO varchar (3)
- activo boolean

## NivelesGeograficos
- nivelID (PK)
- nombreNGeografico varchar(50)
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
- geoposicion geography
- referencia varchar(500)
- codigoPostal varchar(20)
- direccionCompleta text (Generado automáticamente en el script, hagarrando los datos de division id y creando un texto pasando por todas las autoreferencias hasta llegar al nivelID es 1, a demas de calle, número y referencia)
- fechaCreacion timestamp
- activo boolean

/*---------------Logistica---------------*/

## TiposCentroLogistico
- tipoID (PK)
- nombreTipoCLogistico varchar(20) (Puerto, Aeropuerto, Empresa Repartidora)

## CentrosLogisticos
- centroLogisticoID (PK)
- tipoID (FK)
- direccionID (FK)
- contactoID (FK)
- usuarioModificacion (FK)
- nombreCentroLogistico varchar(50)
- telefono varchar(20)
- activo boolean

/*---------------Monedas---------------*/

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
- moneda2ID (FK)
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

/*---------------Permisos de Importacion---------------*/

## TiposPermisos
- tipoPermisoID (FK)
- nombreTipoPermiso varchar(20)

## PermisosImportacion 
- permisoID (PK)
- paisID (FK)
- tipoPermisoID (FK)
- usuarioModificacion (FK)
- monedaID (FK)
- tipoCambioID (FK)
- tipoCambio decimal(18,6) 
- nombrePermiso varchar(20)
- descripcion varchar(200)
- urlDocumentacion text
- costo decimal(18,6)
- activo boolean

/*---------------Productos---------------*/

## Categorias
- categoriaID (PK)
- nombreCategoriaP varchar(20)
- activo boolean

## Productos
- productoID (PK)
- categoriaID (FK)
- usuarioModificacion (FK)
- proveedorID (FK)
- nombreProducto varchar(40)
- descripcion varchar(200)
- descripcionManejo varchar(200)
- activo boolean

## Caracteristicas
- caracteristicaID (PK)
- nombreCaracteristicaP varchar(50)

## ValorCaracteristicas
- productoID: FK
- caracteristicaID: FK
- valor: varchar(50)
- deleted: boolean

/*---------------Proveedores y Contactos---------------*/

## Proveedores
- proveedorID (PK)
- direccionID (FK)
- nombreProveedor varchar(50)
- activo boolean

## ContactosProveedor
- proveedorID (FK)
- contactoID (FK)
- activo boolean

## TiposContactos
- tipoContactoID (PK)
- nombreTipoContacto varchar(20)

## Contactos
- contactoID (PK)
- tipoContactoID (FK)
- usuarioModificacion (FK)
- nombreContacto varchar(50)
- apellido varchar(50)
- segundoApellido varchar(50)
- activo boolean

## TiposTelefonos (casa, trabajo, personal)
- tipoTelefonoID (PK)
- nombreTipoTelefono varchar(20)

## TelefonosContactos
- telefonoContactoID (PK)
- contactoID (FK)
- tipoTelefonosID (FK)
- usuarioModificacion (FK)
- numeroContacto varchar (20)
- activo boolean

## CorreosContactos
- correoCantactoID (PK)
- contactoID (FK)
- usuarioModificacion (FK)
- correo varchar (50)
- activo boolean

/*---------------Inventario y Lotes---------------*/

## Lotes
- loteID (PK)
- productoID (FK)
- cantidadProductoLoteInicial int
- cantidadProductoLoteDisponible int
- fechaFabricacion timestamp
- fechaVencimiento timestamp (puede ser nulo)

## tipoMovimientosInvetariosID
- tipoMovimientoInvetarioID (PK)
- nombreTipoMovimientoInventario varchar (20)

## MovimientosInventario
- movimientoID (PK)
- loteID (FK)
- usuarioModificacion (FK)
- tipoMovimientoInvetarioID (FK)
- cantidad int
- fecha timestamp

## Inventarios
- inventarioID (PK)
- loteID (FK)
- usuarioModificacion (FK)
- cantidadDisponible int
- ultimaActualizacion timestamp

/*---------------Precios---------------*/

## HistorialPreciosProducto
- historialPrecioID (PK)
- productoID (FK)
- precio decimal(18,6)
- monedaID (FK)
- fechaInicio timestamp
- fechaFin timestamp
- activo boolean

/*---------------Ordenes---------------*/

## EstadosOrdenes
- estadoID (PK)
- nombreEstadoOrden varchar(10)

## TiposOrden
- tipoOrdenID (PK)
- nombre varchar(20)

## Ordenes
- ordenID (PK) 
- estadoID (FK)
- tipoOrdenID (FK)
- usuarioModificacion (FK)
- direccionEnvioID (FK)
- direccionEntregaID (FK)
- monedaID (FK)
- tipoCambioID (FK)
- tipoCambio decimal(18,6)
- numeroOrden varchar(30)
- precioFinal decimal(18,6) 
- fecha timestamp

(se nececita un script que cada que se cree una orden detalle, se sume el precioLoteFinal al precioFinal del orden)
## OrdenDetalles
- ordenDetalleID (PK)
- ordenID (FK)
- productoID (FK)
- loteID (FK) (Verificar mendiante un trigger, a la hora de crear un orden detalle, que se escoja automaticamente el lote mas actiguo del producto, a demas de que si en ese lote hay menos productos disponibles del que se requiere, se cree automaticamente una ordendetalle nueva, con los mismos datos pero ajustando la cantidad segun corresponda, ademas de restar automaticamente en el lote o sumar segun el tipo del ordenID.TipoOrden)
- monedaID (FK)
- tipoCambioID (FK)
- tipoCambio decimal(18,6) 
- cantidad int
- descuentoFinal decimal(18,6)
- costoEnvio decimal(18,6)
- precioLoteFinal decimal(18,6) (calcular, segun todos los impuestos, costos de permisos y descuentos meidante un trigger)
- checksum text

## OrdenDetalleImpuestos
- ordenDetalleID (FK)
- impuestoID (FK)

## OrdenDetallePermisos
- ordenDetalleID (FK)
- permisoID (FK)

## OrdenDetalleDescuentos
- ordenDetalleDescuentoID (PK)
- ordenDetalleID (FK)
- monedaID (FK)
- tipoCambioID (FK)
- tipoCambio decimal(18,6) 
- descripcion varchar(100)
- monto decimal(18,6)

/*---------------Trazaabilidad De Ordenes---------------*/

## TrazabilidadOrden
- trazabilidadID (PK)
- ordenID (FK)
- centroLogisticoID (FK)
- direccionID (FK)
- usuarioModificacion (FK)
- estadoID (FK)
- fecha timestamp

/*---------------Impuestos---------------*/

## ImpuestosPais
- impuestoID (PK)
- paisID (FK)
- usuarioModificacion (FK)
- monedaID (FK)
- tipoCambioID (FK)
- tipoCambio decimal(18,6) 
- nombre varchar(50)
- valaor decimal(5,2)
- tipo enum('porcentaje','monto_fijo')
- fechaInicio timestamp
- fechaFin timestamp
- activo boolean

/*---------------Transacciones y Finanzas---------------*/

## EstadadoTransacciones
- estadoTransaccionID (PK)
- nombreEstadoTransac varchar(20)

## TipoTransacciones
- tipoID (PK)
- nombreTipoTransac varchar(20)

## Transacciones
- transaccionID (PK)
- monedaID (FK)
- usuarioModificacion (FK)
- tipoID (FK)
- estadoTransaccionID (FK)
- ordenID (FK)
- tipoCambioID (FK)
- tipoCambio decimal(18,6) 
- monto decimal(18,6)
- descripcion text
- fecha timestamp
- checksum text

/*---------------Estados de Cuenta---------------*/

(cada que se crea una orden, se crea automaticamente un estado de cuenta, cada que se actualiza un estado de cuenta en el apartado de estado, se actualiza el balance neto solamente si se cambia a comletado)

## EstadosCuenta
- estadoCuentaID (PK)
- ordenID (FK)
- usuarioModificacion (FK)
- tipoMovimiento enum ('Debito', 'Credito', segun el tipoOrden)
- estado enum (pendiente, completado, cancelado)
- monedaID (FK)
- tipoCambioID (FK)
- tipoCambio decimal(18,6)
- monto decimal(18,6)
- fechaRegistro timestamp
- checksum text

## BalanceNeto
- balanceID (PK)
- saldo decimal(18,6)
- ultimaActualización timestamp

Todas las tablas FKs correctas NOT NULL en todo (excepto donde explícitamente aplica NULL) CHECK de monedas
On deleted no action para las fk
