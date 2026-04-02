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
- roleID (PK)
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
- usuarioID (FK) (Usuario que insertó la direccion)
- calle varchar (150)
- número varchar(50)
- ciudadID (FK)
- referencia text
- codigoPostal varchar(20)
- direccionCompleta text (Generado automáticamente en el script)
- fechaCreacion timestamp
- activo boolean

## Puertos
- puertoID (PK)
- nombre varchar(50)
- direccionID (FK)
- telefono varchar (20)
- activo boolean

## AeroPuertos
- aeroPuertoID (PK)
- nombre varchar(50)
- direccionID (FK)
- telefono varchar (20)
- activo boolean

## Monedas
- monedaID (PK)
- usuarioID (FK)
- paisID (FK)
- simboloMoneda varchar(10)
- nombreMoneda varchar(50)
- tiempoCreacion timestamp
- activo boolean

## TiposCambio
- tipoCambioID (PK)
- usuarioID (FK)
- moneda1ID (FK)
- moneda2ID (FK) (validar con trigger que moneda 1 y 2 no sean iguales)
- tipoCambio DECIMAL(18,6)
- tiempoCreacion timestamp
- ultimaActualizacion timestamp
- checksum VARCHAR(100)
- activo boolean

(cuando se actualice TiposCambio crear historial con triggerCambios
ademas de actualizar la anterior fechaFin)
## HitorialCambios
- histotalCambioID (PK)
- moneda1ID (FK)
- moneda2ID (FK)
- tipoCambioID (PK)
- usuarioID (FK)
- fechaInicio timestamp
- fechaFin timestamp (en caso de ser la ultima por el año en 9999)
- tipoCambio DECIMAL(18,6)
- checksum VARCHAR(100)
- horaCambio timestamp

(todo lo que se haga en la base de datos, cada insercion y actualizacion debe pasar por logs con scipts, incluyendo los cualquier begin y exception)
## Logs
- logID (PK)
- usuarioID (FK)
- tablaID (FK)
- accionID (FK)
- objetoAfectadoID int
- datosViejos JSON
- datosNuevos JSON
- hora timestamp
- checksum text

















