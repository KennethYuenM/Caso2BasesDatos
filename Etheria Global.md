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

## Permisos
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
- referencia text
- codigoPostal varchar(20)
- direccionCompleta text (Generado automáticamente en el script, hagarrando los datos de division id y creando un texto pasando por todas las autoreferencias hasta llegar al nivelID es 1, a demas de calle, número y referencia)
- fechaCreacion timestamp
- activo boolean

## CentrosLogisticos
- centroLogisticoID (PK)
- tipoID (FK)
- direccionID (FK)
- usuarioModificacion (FK)
- nombre varchar(50)
- telefono varchar(20)
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
## HitorialCambiosMonedas
- histotalCambioID (PK)
- moneda1ID (FK)
- moneda2ID (FK)
- tipoCambioID (FK)
- usuarioModificacion (FK)
- fechaInicio timestamp
- fechaFin timestamp (en caso de ser la ultima por el año en 9999)
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

## Productos
- productoID (PK)
- categoriaID (FK)
- marcaID (FK)
- usuarioModificacion (FK)
- nombre varchar(20)
- descripcion text
- descripcionManejo text
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

## Marcas
- marcaID (PK)
- nombre varchar(20)
- paisID (FK)
- activo boolean

## Proveedores
- proveedorID (PK)
- nombre varchar(30)
- direccionID (FK)
- activo boolean

## ProductoProveedor
- productoProveedorID (PK)
- productoID (FK)
- proveedorID (FK)
- activo boolean

## ContactosProveedor
- contactoID (PK)
- proveedorID (FK)
- usuarioModificacion (FK)
- nombre varchar(30)
- telefono varchar(20)
- email varchar(40)
- activo boolean

## Lotes (nota, lotes ya es en si un hitorial de precios)
- loteID (PK)
- productoProveedorID (FK)
- monedaID (FK)
- precio decimal(18,6)
- ingredientes text
- fechaFabricacion timestamp
- fechaVencimiento timestamp (puede ser nulo)

## EstadosOrdenes
- estadoID (PK)
- nombre varchar(10)

## Ordenes
- ordenID (PK)
- estadoID (FK)
- usuarioModificacion (FK)
- direccionEntregaID (FK)
- numeroOrden varchar(30)
- fecha timestamp

## OrdenDetalle
- ordenDetalleID (PK)
- loteID (FK)
- impuestoID (FK)
- cantidad int
- precioFinal decimal(18,6)
- descuento decimal(18,6)
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
- usuarioModificacion (FK)
- estadoID (FK)
- fecha timestamp

## Transacciones
- transaccionID (PK)
- monedaID (FK)
- usuarioModificacion (FK)
- tipoID (FK)
- referenciaTipoID (FK)
- estadoTransaccionID (FK)
- monto decimal(18,6)
- referenciaID int (ej: ordenID o loteID)
- descripcion text
- fecha timestamp

## EstadadoTransacciones
- estadoTransaccionID (PK)
- nombre varchar(20)

## TipoTransacciones
- tipoID (PK)
- nombre varchar(20)

## ReferenciasTipos
- referenciaTipoID (PK)
- nombre varchar(20)

## Inventario
- inventarioID (PK)
- loteID (FK)
- usuarioModificacion (FK)
- cantidadDisponible int
- ultimaActualizacion timestamp

On deleted no action para las fk