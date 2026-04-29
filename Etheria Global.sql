/*==============================================================*/
/* DATABASE                                                     */
/*==============================================================*/

/*DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'etheria_global') THEN
        CREATE DATABASE etheria_global;
    END IF;
END $$;*/

-- Ejecutar luego:
-- \c etheria_global;


/*==============================================================*/
/* EXTENSIONS                                                   */
/*==============================================================*/

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;


/*==============================================================*/
/* SCHEMA                                                       */
/*==============================================================*/

CREATE SCHEMA IF NOT EXISTS core;
SET search_path TO core;


/*==============================================================*/
/* ENUMS                                                        */
/*==============================================================*/

CREATE TYPE tipo_impuesto AS ENUM ('porcentaje','monto_fijo');
CREATE TYPE tipo_movimiento_cuenta AS ENUM ('Debito','Credito');
CREATE TYPE estado_cuenta_enum AS ENUM ('pendiente','completado','cancelado');


/*==============================================================*/
/* 1. SEGURIDAD                                                 */
/*==============================================================*/

CREATE TABLE Usuarios (
    usuarioID SERIAL PRIMARY KEY,
    nombreUsuario VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    segundoApellido VARCHAR(50),
    email VARCHAR(100) UNIQUE NOT NULL,
    contraseñaHASH TEXT NOT NULL,
    creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado TIMESTAMP,
    ultimoLogin TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE Roles (
    roleID SERIAL PRIMARY KEY,
    rolNombre VARCHAR(40) NOT NULL,
    descripcion VARCHAR(500) NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE RolesXUsuario (
    usuarioID INT NOT NULL,
    roleID INT NOT NULL,
    asignado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (usuarioID, roleID),
    FOREIGN KEY (usuarioID) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (roleID) REFERENCES Roles(roleID)
);

CREATE TABLE PermisosSistema (
    permisoID SERIAL PRIMARY KEY,
    nombrePermiso VARCHAR(30) NOT NULL,
    descripcion VARCHAR(200)
);

CREATE TABLE PermisosXRole (
    roleID INT NOT NULL,
    permisoID INT NOT NULL,
    PRIMARY KEY (roleID, permisoID),
    FOREIGN KEY (roleID) REFERENCES Roles(roleID),
    FOREIGN KEY (permisoID) REFERENCES PermisosSistema(permisoID)
);


/*==============================================================*/
/* 2. AUDITORIA                                                 */
/*==============================================================*/

CREATE TABLE TablasSistema (
    tablaID SERIAL PRIMARY KEY,
    nombreTabla VARCHAR(50) UNIQUE NOT NULL,
    creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Acciones (
    accionID SERIAL PRIMARY KEY,
    nombreAccion VARCHAR(10) NOT NULL CHECK (nombreAccion IN ('CREATE','READ','UPDATE','DELETE'))
);

CREATE TABLE Logs (
    logID SERIAL PRIMARY KEY,
    usuarioModificacion INT,
    tablaID INT NOT NULL,
    accionID INT NOT NULL,
    objetoAfectadoID INT NOT NULL,
    datosViejos JSONB,
    datosNuevos JSONB,
    hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    error TEXT,
    checksum TEXT,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (tablaID) REFERENCES TablasSistema(tablaID),
    FOREIGN KEY (accionID) REFERENCES Acciones(accionID)
);


/*==============================================================*/
/* 3. GEOGRAFIA                                                 */
/*==============================================================*/

CREATE TABLE Paises (
    paisID SERIAL PRIMARY KEY,
    nombrePais VARCHAR(30) NOT NULL,
    codigoISO VARCHAR(3) UNIQUE NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE NivelesGeograficos (
    nivelID SERIAL PRIMARY KEY,
    nombreNGeografico VARCHAR(50) NOT NULL,
    orden INT NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE DivisionesGeograficas (
    divisionID SERIAL PRIMARY KEY,
    paisID INT NOT NULL,
    nivelID INT NOT NULL,
    padreID INT,
    nombre VARCHAR(100) NOT NULL,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID),
    FOREIGN KEY (nivelID) REFERENCES NivelesGeograficos(nivelID),
    FOREIGN KEY (padreID) REFERENCES DivisionesGeograficas(divisionID)
);

CREATE TABLE Direcciones (
    direccionID SERIAL PRIMARY KEY,
    divisionID INT NOT NULL,
    usuarioModificacion INT,
    calle VARCHAR(150),
    numero VARCHAR(20),
    geoposicion geography(Point,4326),
    referencia VARCHAR(500),
    codigoPostal VARCHAR(20) NOT NULL,
    direccionCompleta TEXT,
    fechaCreacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (divisionID) REFERENCES DivisionesGeograficas(divisionID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);


/*==============================================================*/
/* 4. CONTACTOS Y LOGISTICA                                     */
/*==============================================================*/

CREATE TABLE TiposContactos (
    tipoContactoID SERIAL PRIMARY KEY,
    nombreTipoContacto VARCHAR(20) NOT NULL
);

CREATE TABLE Contactos (
    contactoID SERIAL PRIMARY KEY,
    tipoContactoID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    nombreContacto VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    segundoApellido VARCHAR(50),
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (tipoContactoID) REFERENCES TiposContactos(tipoContactoID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);

CREATE TABLE TiposTelefonos (
    tipoTelefonoID SERIAL PRIMARY KEY,
    nombreTipoTelefono VARCHAR(20) NOT NULL
);

CREATE TABLE TelefonosContactos (
    telefonoContactoID SERIAL PRIMARY KEY,
    contactoID INT NOT NULL,
    tipoTelefonosID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    numeroContacto VARCHAR(20) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (contactoID) REFERENCES Contactos(contactoID),
    FOREIGN KEY (tipoTelefonosID) REFERENCES TiposTelefonos(tipoTelefonoID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);

CREATE TABLE CorreosContactos (
    correoCantactoID SERIAL PRIMARY KEY,
    contactoID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    correo VARCHAR(50) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (contactoID) REFERENCES Contactos(contactoID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);

CREATE TABLE TiposCentroLogistico (
    tipoID SERIAL PRIMARY KEY,
    nombreTipoCLogistico VARCHAR(20) NOT NULL
);

CREATE TABLE CentrosLogisticos (
    centroLogisticoID SERIAL PRIMARY KEY,
    tipoID INT NOT NULL,
    direccionID INT NOT NULL,
    contactoID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    nombreCentroLogistico VARCHAR(50) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (tipoID) REFERENCES TiposCentroLogistico(tipoID),
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID),
    FOREIGN KEY (contactoID) REFERENCES Contactos(contactoID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);


/*==============================================================*/
/* 5. PROVEEDORES                                               */
/*==============================================================*/

CREATE TABLE Proveedores (
    proveedorID SERIAL PRIMARY KEY,
    direccionID INT NOT NULL,
    nombreProveedor VARCHAR(50) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID)
);

CREATE TABLE ContactosProveedor (
    proveedorID INT NOT NULL,
    contactoID INT NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (proveedorID, contactoID),
    FOREIGN KEY (proveedorID) REFERENCES Proveedores(proveedorID),
    FOREIGN KEY (contactoID) REFERENCES Contactos(contactoID)
);


/*==============================================================*/
/* 6. PRODUCTOS                                                 */
/*==============================================================*/

CREATE TABLE Categorias (
    categoriaID SERIAL PRIMARY KEY,
    nombreCategoriaP VARCHAR(20) UNIQUE NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE Productos (
    productoID SERIAL PRIMARY KEY,
    categoriaID INT NOT NULL,
    usuarioModificacion INT,
    proveedorID INT NOT NULL,
    nombreProducto VARCHAR(40) NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    descripcionManejo VARCHAR(200) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (categoriaID) REFERENCES Categorias(categoriaID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (proveedorID) REFERENCES Proveedores(proveedorID)
);

CREATE TABLE Caracteristicas (
    caracteristicaID SERIAL PRIMARY KEY,
    nombreCaracteristicaP VARCHAR(50) NOT NULL
);

CREATE TABLE ValorCaracteristicas (
    productoID INT NOT NULL,
    caracteristicaID INT NOT NULL,
    valor VARCHAR(50) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (productoID, caracteristicaID),
    FOREIGN KEY (productoID) REFERENCES Productos(productoID),
    FOREIGN KEY (caracteristicaID) REFERENCES Caracteristicas(caracteristicaID)
);


/*==============================================================*/
/* 7. MONEDAS                                                   */
/*==============================================================*/

CREATE TABLE Monedas (
    monedaID SERIAL PRIMARY KEY,
    usuarioModificacion INT NOT NULL,
    paisID INT NOT NULL,
    simboloMoneda VARCHAR(10) NOT NULL,
    nombreMoneda VARCHAR(50) NOT NULL,
    tiempoCreacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (paisID) REFERENCES Paises(paisID)
);

CREATE TABLE TiposCambio (
    tipoCambioID SERIAL PRIMARY KEY,
    usuarioModificacion INT,
    moneda1ID INT NOT NULL,
    moneda2ID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL CHECK (tipoCambio > 0),
    tiempoCreacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimaActualizacion TIMESTAMP,
    checksum VARCHAR(100),
    activo BOOLEAN DEFAULT TRUE,
    CHECK (moneda1ID <> moneda2ID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (moneda1ID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (moneda2ID) REFERENCES Monedas(monedaID)
);

CREATE TABLE HistorialCambiosMonedas (
    histotalCambioID SERIAL PRIMARY KEY,
    moneda1ID INT NOT NULL,
    moneda2ID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    usuarioModificacion INT,
    fechaInicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fechaFin TIMESTAMP DEFAULT '9999-12-31 23:59:59'::timestamp,
    tipoCambio DECIMAL(18,6) NOT NULL,
    checksum VARCHAR(100),
    horaCambio TIMESTAMP,
    FOREIGN KEY (moneda1ID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (moneda2ID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);


/*==============================================================*/
/* 8. PERMISOS IMPORTACION                                      */
/*==============================================================*/

CREATE TABLE TiposPermisos (
    tipoPermisoID SERIAL PRIMARY KEY,
    nombreTipoPermiso VARCHAR(20) NOT NULL
);

CREATE TABLE PermisosImportacion (
    permisoID SERIAL PRIMARY KEY,
    paisID INT NOT NULL,
    tipoPermisoID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    nombrePermiso VARCHAR(20) NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    urlDocumentacion TEXT NOT NULL,
    costo DECIMAL(18,6) NOT NULL CHECK (costo >= 0),
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID),
    FOREIGN KEY (tipoPermisoID) REFERENCES TiposPermisos(tipoPermisoID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID)
);


/*==============================================================*/
/* 9. INVENTARIO                                                */
/*==============================================================*/

CREATE TABLE Lotes (
    loteID SERIAL PRIMARY KEY,
    productoID INT NOT NULL,
    cantidadProductoLoteInicial INT NOT NULL CHECK (cantidadProductoLoteInicial > 0),
    cantidadProductoLoteDisponible INT NOT NULL CHECK (cantidadProductoLoteDisponible <= cantidadProductoLoteInicial),
    fechaFabricacion TIMESTAMP NOT NULL,
    fechaVencimiento TIMESTAMP,
    FOREIGN KEY (productoID) REFERENCES Productos(productoID)
);

CREATE TABLE TipoMovimientosInventario (
    tipoMovimientoInvetarioID SERIAL PRIMARY KEY,
    nombreTipoMovimientoInventario VARCHAR(20) NOT NULL
);

CREATE TABLE MovimientosInventario (
    movimientoID SERIAL PRIMARY KEY,
    loteID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    tipoMovimientoInvetarioID INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loteID) REFERENCES Lotes(loteID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (tipoMovimientoInvetarioID) REFERENCES TipoMovimientosInventario(tipoMovimientoInvetarioID)
);

CREATE TABLE Inventarios (
    inventarioID SERIAL PRIMARY KEY,
    loteID INT NOT NULL,
    usuarioModificacion INT,
    cantidadDisponible INT NOT NULL CHECK (cantidadDisponible >= 0),
    ultimaActualizacion TIMESTAMP,
    FOREIGN KEY (loteID) REFERENCES Lotes(loteID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);


/*==============================================================*/
/* 10. PRECIOS                                                  */
/*==============================================================*/

CREATE TABLE HistorialPreciosProducto (
    historialPrecioID SERIAL PRIMARY KEY,
    productoID INT NOT NULL,
    precio DECIMAL(18,6) NOT NULL,
    monedaID INT NOT NULL,
    fechaInicio TIMESTAMP NOT NULL,
    fechaFin TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (productoID) REFERENCES Productos(productoID),
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID)
);


/*==============================================================*/
/* 11. ORDENES                                                  */
/*==============================================================*/

CREATE TABLE EstadosOrdenes (
    estadoID SERIAL PRIMARY KEY,
    nombreEstadoOrden VARCHAR(10) UNIQUE NOT NULL
);

CREATE TABLE TiposOrden (
    tipoOrdenID SERIAL PRIMARY KEY,
    nombre VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE Ordenes (
    ordenID SERIAL PRIMARY KEY,
    estadoID INT NOT NULL,
    tipoOrdenID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    direccionEnvioID INT NOT NULL,
    direccionEntregaID INT NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    numeroOrden VARCHAR(30) NOT NULL,
    precioFinal DECIMAL(18,6),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (estadoID) REFERENCES EstadosOrdenes(estadoID),
    FOREIGN KEY (tipoOrdenID) REFERENCES TiposOrden(tipoOrdenID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (direccionEnvioID) REFERENCES Direcciones(direccionID),
    FOREIGN KEY (direccionEntregaID) REFERENCES Direcciones(direccionID),
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID)
);

CREATE TABLE OrdenDetalles (
    ordenDetalleID SERIAL PRIMARY KEY,
    ordenID INT NOT NULL,
    productoID INT NOT NULL,
    loteID INT NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    descuentoFinal DECIMAL(18,6) DEFAULT 0,
    costoEnvio DECIMAL(18,6) NOT NULL,
    precioLoteFinal DECIMAL(18,6),
    checksum TEXT,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID),
    FOREIGN KEY (productoID) REFERENCES Productos(productoID),
    FOREIGN KEY (loteID) REFERENCES Lotes(loteID),
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID)
);

CREATE TABLE OrdenDetalleImpuestos (
    ordenDetalleID INT,
    impuestoID INT,
    PRIMARY KEY (ordenDetalleID, impuestoID),
    FOREIGN KEY (ordenDetalleID) REFERENCES OrdenDetalles(ordenDetalleID),
    FOREIGN KEY (impuestoID) REFERENCES ImpuestosPais(impuestoID)
);

CREATE TABLE OrdenDetallePermisos (
    ordenDetalleID INT,
    permisoID INT,
    PRIMARY KEY (ordenDetalleID, permisoID),
    FOREIGN KEY (ordenDetalleID) REFERENCES OrdenDetalles(ordenDetalleID),
    FOREIGN KEY (permisoID) REFERENCES PermisosImportacion(permisoID)
);

CREATE TABLE OrdenDetalleDescuentos (
    ordenDetalleDescuentoID SERIAL PRIMARY KEY,
    ordenDetalleID INT NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    monto DECIMAL(18,6) NOT NULL,
    FOREIGN KEY (ordenDetalleID) REFERENCES OrdenDetalles(ordenDetalleID),
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID)
);


/*==============================================================*/
/* 12. TRAZABILIDAD                                             */
/*==============================================================*/

CREATE TABLE TrazabilidadOrden (
    trazabilidadID SERIAL PRIMARY KEY,
    ordenID INT NOT NULL,
    centroLogisticoID INT NOT NULL,
    direccionID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    estadoID INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID),
    FOREIGN KEY (centroLogisticoID) REFERENCES CentrosLogisticos(centroLogisticoID),
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (estadoID) REFERENCES EstadosOrdenes(estadoID)
);


/*==============================================================*/
/* 13. IMPUESTOS                                                */
/*==============================================================*/

CREATE TABLE ImpuestosPais (
    impuestoID SERIAL PRIMARY KEY,
    paisID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    valor DECIMAL(5,2) NOT NULL,
    CHECK (
        (tipo = 'porcentaje' AND valor > 0 AND valor <= 100)
        OR
        (tipo = 'monto_fijo' AND valor > 0)
    ),
    tipo tipo_impuesto NOT NULL,
    fechaInicio TIMESTAMP NOT NULL,
    fechaFin TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID)
);


/*==============================================================*/
/* 14. TRANSACCIONES                                            */
/*==============================================================*/

CREATE TABLE EstadoTransacciones (
    estadoTransaccionID SERIAL PRIMARY KEY,
    nombreEstadoTransac VARCHAR(20) NOT NULL
);

CREATE TABLE TipoTransacciones (
    tipoID SERIAL PRIMARY KEY,
    nombreTipoTransac VARCHAR(20) NOT NULL
);

CREATE TABLE Transacciones (
    transaccionID SERIAL PRIMARY KEY,
    monedaID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    tipoID INT NOT NULL,
    estadoTransaccionID INT NOT NULL,
    ordenID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    monto DECIMAL(18,6) NOT NULL CHECK (monto > 0),
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checksum TEXT,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (tipoID) REFERENCES TipoTransacciones(tipoID),
    FOREIGN KEY (estadoTransaccionID) REFERENCES EstadoTransacciones(estadoTransaccionID),
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID),
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID)
);


/*==============================================================*/
/* 15. ESTADOS DE CUENTA                                        */
/*==============================================================*/

CREATE TABLE EstadosCuenta (
    estadoCuentaID SERIAL PRIMARY KEY,
    ordenID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    tipoMovimiento tipo_movimiento_cuenta NOT NULL,
    estado estado_cuenta_enum NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6),
    monto DECIMAL(18,6),
    fechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checksum TEXT,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID)
);

CREATE TABLE BalanceNeto (
    balanceID SERIAL PRIMARY KEY,
    saldo DECIMAL(18,6) NOT NULL,
    ultimaActualizacion TIMESTAMP
);