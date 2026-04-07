-- =========================================
-- DATABASE
-- =========================================
CREATE DATABASE etheria_global;
-- Conectarse luego con \c etheria_global;

-- =========================================
-- EXTENSIONES
-- =========================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================================
-- ENUMS
-- =========================================
CREATE TYPE tipo_orden_enum AS ENUM ('venta', 'compra');
CREATE TYPE tipo_movimiento_enum AS ENUM ('Debito', 'Credito');
CREATE TYPE estado_cuenta_enum AS ENUM ('pendiente', 'completado', 'cancelado');

-- =========================================
-- TABLAS BASE
-- =========================================

CREATE TABLE Usuarios (
    usuarioID SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    segundoApellido VARCHAR(50),
    email VARCHAR(100) NOT NULL UNIQUE,
    contraseñaHASH TEXT NOT NULL,
    creado TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultimoLogin TIMESTAMP,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Roles (
    roleID SERIAL PRIMARY KEY,
    rolNombre VARCHAR(40) NOT NULL,
    descripcion VARCHAR(500),
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE RolesXUsuario (
    usuarioID INT NOT NULL,
    roleID INT NOT NULL,
    asignado TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (usuarioID, roleID),
    FOREIGN KEY (usuarioID) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION,
    FOREIGN KEY (roleID) REFERENCES Roles(roleID) ON DELETE NO ACTION
);

CREATE TABLE Tablas (
    tablaID SERIAL PRIMARY KEY,
    nombreTabla VARCHAR(50) NOT NULL,
    creado TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Acciones (
    accionID SERIAL PRIMARY KEY,
    nombreAccion VARCHAR(10) NOT NULL
);

-- =========================================
-- PERMISOS (Sistema)
-- =========================================
CREATE TABLE PermisosSistema (
    permisoID SERIAL PRIMARY KEY,
    tablaID INT NOT NULL,
    accionID INT NOT NULL,
    FOREIGN KEY (tablaID) REFERENCES Tablas(tablaID) ON DELETE NO ACTION,
    FOREIGN KEY (accionID) REFERENCES Acciones(accionID) ON DELETE NO ACTION
);

CREATE TABLE PermisosXRole (
    roleID INT NOT NULL,
    permisoID INT NOT NULL,
    PRIMARY KEY (roleID, permisoID),
    FOREIGN KEY (roleID) REFERENCES Roles(roleID) ON DELETE NO ACTION,
    FOREIGN KEY (permisoID) REFERENCES PermisosSistema(permisoID) ON DELETE NO ACTION
);

-- =========================================
-- GEOGRAFÍA
-- =========================================
CREATE TABLE Paises (
    paisID SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    codigoISO VARCHAR(3) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE NivelesGeograficos (
    nivelID SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    orden INT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE DivisionesGeograficas (
    divisionID SERIAL PRIMARY KEY,
    paisID INT NOT NULL,
    nivelID INT NOT NULL,
    padreID INT,
    nombre VARCHAR(100) NOT NULL,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID) ON DELETE NO ACTION,
    FOREIGN KEY (nivelID) REFERENCES NivelesGeograficos(nivelID) ON DELETE NO ACTION,
    FOREIGN KEY (padreID) REFERENCES DivisionesGeograficas(divisionID) ON DELETE NO ACTION
);

CREATE TABLE Direcciones (
    direccionID SERIAL PRIMARY KEY,
    divisionID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    calle VARCHAR(150),
    numero VARCHAR(20),
    referencia VARCHAR(500),
    codigoPostal VARCHAR(20),
    direccionCompleta TEXT NOT NULL,
    fechaCreacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (divisionID) REFERENCES DivisionesGeograficas(divisionID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION
);

-- =========================================
-- LOGÍSTICA
-- =========================================
CREATE TABLE TiposCentroLogistico (
    tipoID SERIAL PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

CREATE TABLE CentrosLogisticos (
    centroLogisticoID SERIAL PRIMARY KEY,
    tipoID INT NOT NULL,
    direccionID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    telefono VARCHAR(20),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (tipoID) REFERENCES TiposCentroLogistico(tipoID) ON DELETE NO ACTION,
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION
);

-- =========================================
-- CONTACTOS
-- =========================================
CREATE TABLE Contactos (
    contactoID SERIAL PRIMARY KEY,
    usuarioModificacion INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    segundoApellido VARCHAR(50),
    email VARCHAR(100),
    numero VARCHAR(20),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION
);

-- =========================================
-- PROVEEDORES
-- =========================================
CREATE TABLE Proveedores (
    proveedorID SERIAL PRIMARY KEY,
    direccionID INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID) ON DELETE NO ACTION
);

CREATE TABLE ContactosProveedor (
    proveedorID INT NOT NULL,
    contactoID INT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (proveedorID, contactoID),
    FOREIGN KEY (proveedorID) REFERENCES Proveedores(proveedorID) ON DELETE NO ACTION,
    FOREIGN KEY (contactoID) REFERENCES Contactos(contactoID) ON DELETE NO ACTION
);

-- =========================================
-- MONEDAS
-- =========================================
CREATE TABLE Monedas (
    monedaID SERIAL PRIMARY KEY,
    usuarioModificacion INT NOT NULL,
    paisID INT NOT NULL,
    simboloMoneda VARCHAR(10) NOT NULL,
    nombreMoneda VARCHAR(50) NOT NULL,
    tiempoCreacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID) ON DELETE NO ACTION
);

CREATE TABLE TiposCambio (
    tipoCambioID SERIAL PRIMARY KEY,
    usuarioModificacion INT NOT NULL,
    moneda1ID INT NOT NULL,
    moneda2ID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    tiempoCreacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultimaActualizacion TIMESTAMP,
    checksum VARCHAR(100),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION,
    FOREIGN KEY (moneda1ID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION,
    FOREIGN KEY (moneda2ID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION
);

CREATE TABLE HistorialCambiosMonedas (
    historialCambioID SERIAL PRIMARY KEY,
    moneda1ID INT NOT NULL,
    moneda2ID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    fechaInicio TIMESTAMP NOT NULL,
    fechaFin TIMESTAMP,
    tipoCambio DECIMAL(18,6) NOT NULL,
    checksum VARCHAR(100),
    horaCambio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (moneda1ID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (moneda2ID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);

-- =========================================
-- PRODUCTOS
-- =========================================
CREATE TABLE Categorias (
    categoriaID SERIAL PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Productos (
    productoID SERIAL PRIMARY KEY,
    categoriaID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    proveedorID INT NOT NULL,
    nombre VARCHAR(40) NOT NULL,
    descripcion VARCHAR(200),
    descripcionManejo VARCHAR(200),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (categoriaID) REFERENCES Categorias(categoriaID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (proveedorID) REFERENCES Proveedores(proveedorID)
);

CREATE TABLE Caracteristicas (
    caracteristicaID SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

CREATE TABLE ValorCaracteristicas (
    productoID INT NOT NULL,
    caracteristicaID INT NOT NULL,
    valor VARCHAR(50),
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (productoID, caracteristicaID),
    FOREIGN KEY (productoID) REFERENCES Productos(productoID),
    FOREIGN KEY (caracteristicaID) REFERENCES Caracteristicas(caracteristicaID)
);

-- =========================================
-- LOTES
-- =========================================
CREATE TABLE Lotes (
    loteID SERIAL PRIMARY KEY,
    productoID INT NOT NULL,
    precio DECIMAL(18,6) NOT NULL,
    ingredientes VARCHAR(500),
    fechaFabricacion TIMESTAMP NOT NULL,
    fechaVencimiento TIMESTAMP,
    FOREIGN KEY (productoID) REFERENCES Productos(productoID)
);

-- =========================================
-- ORDENES
-- =========================================
CREATE TABLE EstadosOrdenes (
    estadoID SERIAL PRIMARY KEY,
    nombre VARCHAR(10) NOT NULL
);

CREATE TABLE Ordenes (
    ordenID SERIAL PRIMARY KEY,
    estadoID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    direccionEnvioID INT NOT NULL,
    direccionEntregaID INT NOT NULL,
    tipoOrden tipo_orden_enum NOT NULL,
    numeroOrden VARCHAR(30) NOT NULL,
    precioFinal DECIMAL(18,6) NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (estadoID) REFERENCES EstadosOrdenes(estadoID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (direccionEnvioID) REFERENCES Direcciones(direccionID),
    FOREIGN KEY (direccionEntregaID) REFERENCES Direcciones(direccionID)
);

CREATE TABLE TiposPermisos (
    tipoPermisoID SERIAL PRIMARY KEY,
    nombreTipoPermiso VARCHAR(20) NOT NULL
);

CREATE TABLE Permisos (
    permisoID SERIAL PRIMARY KEY,
    paisID INT NOT NULL,
    tipoPermisoID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    nombrePermiso VARCHAR(20) NOT NULL,
    costo DECIMAL(18,6),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID),
    FOREIGN KEY (tipoPermisoID) REFERENCES TiposPermisos(tipoPermisoID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);

CREATE TABLE ImpuestosPais (
    impuestoID SERIAL PRIMARY KEY,
    paisID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    porcentaje DECIMAL(5,2) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);

CREATE TABLE OrdenDetalles (
    ordenDetalleID SERIAL PRIMARY KEY,
    ordenID INT NOT NULL,
    loteID INT NOT NULL,
    impuestoID INT NOT NULL,
    permisoID INT NOT NULL,
    cantidad INT NOT NULL,
    descuento DECIMAL(18,6),
    costoEnvio DECIMAL(18,6),
    precioLoteFinal DECIMAL(18,6) NOT NULL,
    checksum TEXT,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID),
    FOREIGN KEY (loteID) REFERENCES Lotes(loteID),
    FOREIGN KEY (impuestoID) REFERENCES ImpuestosPais(impuestoID),
    FOREIGN KEY (permisoID) REFERENCES Permisos(permisoID)
);

-- =========================================
-- TRAZABILIDAD
-- =========================================
CREATE TABLE TrazabilidadOrden (
    trazabilidadID SERIAL PRIMARY KEY,
    ordenID INT NOT NULL,
    centroLogisticoID INT NOT NULL,
    direccionID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    estadoID INT NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID),
    FOREIGN KEY (centroLogisticoID) REFERENCES CentrosLogisticos(centroLogisticoID),
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (estadoID) REFERENCES EstadosOrdenes(estadoID)
);

-- =========================================
-- TRANSACCIONES
-- =========================================
CREATE TABLE EstadoTransacciones (
    estadoTransaccionID SERIAL PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

CREATE TABLE TipoTransacciones (
    tipoID SERIAL PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);

CREATE TABLE Transacciones (
    transaccionID SERIAL PRIMARY KEY,
    monedaID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    tipoID INT NOT NULL,
    estadoTransaccionID INT NOT NULL,
    ordenID INT NOT NULL,
    monto DECIMAL(18,6) NOT NULL,
    descripcion TEXT,
    fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    checksum TEXT,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (tipoID) REFERENCES TipoTransacciones(tipoID),
    FOREIGN KEY (estadoTransaccionID) REFERENCES EstadoTransacciones(estadoTransaccionID),
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID)
);

-- =========================================
-- INVENTARIO Y FINANZAS
-- =========================================
CREATE TABLE Inventarios (
    inventarioID SERIAL PRIMARY KEY,
    loteID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    cantidadDisponible INT NOT NULL,
    ultimaActualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loteID) REFERENCES Lotes(loteID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);

CREATE TABLE EstadosCuenta (
    estadoCuentaID SERIAL PRIMARY KEY,
    ordenID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    tipoMovimiento tipo_movimiento_enum NOT NULL,
    estado estado_cuenta_enum NOT NULL,
    monto DECIMAL(18,6) NOT NULL,
    fechaRegistro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    checksum TEXT,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID),
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID)
);

CREATE TABLE BalanceNeto (
    balanceID SERIAL PRIMARY KEY,
    saldo DECIMAL(18,6) NOT NULL,
    ultimaActualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================================
-- LOGS
-- =========================================
CREATE TABLE Logs (
    logID SERIAL PRIMARY KEY,
    usuarioModificacion INT,
    tablaID INT NOT NULL,
    accionID INT NOT NULL,
    objetoAfectadoID INT NOT NULL,
    datosViejos JSON,
    datosNuevos JSON,
    hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    error TEXT,
    checksum TEXT,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID),
    FOREIGN KEY (tablaID) REFERENCES Tablas(tablaID),
    FOREIGN KEY (accionID) REFERENCES Acciones(accionID)
);