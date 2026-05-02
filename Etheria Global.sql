CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_impuesto') THEN
        CREATE TYPE tipo_impuesto AS ENUM ('porcentaje','monto_fijo');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_movimiento_cuenta') THEN
        CREATE TYPE tipo_movimiento_cuenta AS ENUM ('Debito','Credito');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_cuenta_enum') THEN
        CREATE TYPE estado_cuenta_enum AS ENUM ('pendiente','completado','cancelado');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS Usuarios (
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

CREATE TABLE IF NOT EXISTS Roles (
    roleID SERIAL PRIMARY KEY,
    rolNombre VARCHAR(40) UNIQUE NOT NULL,
    descripcion VARCHAR(500) NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS RolesXUsuario (
    usuarioID INT NOT NULL,
    roleID INT NOT NULL,
    asignado TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (usuarioID, roleID),
    FOREIGN KEY (usuarioID) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (roleID) REFERENCES Roles(roleID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS PermisosSistema (
    permisoID SERIAL PRIMARY KEY,
    nombrePermiso VARCHAR(30) UNIQUE NOT NULL,
    descripcion VARCHAR(200)
);

CREATE TABLE IF NOT EXISTS PermisosXRole (
    roleID INT NOT NULL,
    permisoID INT NOT NULL,
    PRIMARY KEY (roleID, permisoID),
    FOREIGN KEY (roleID) REFERENCES Roles(roleID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (permisoID) REFERENCES PermisosSistema(permisoID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS TablasSistema (
    tablaID SERIAL PRIMARY KEY,
    nombreTabla VARCHAR(50) UNIQUE NOT NULL,
    creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Acciones (
    accionID SERIAL PRIMARY KEY,
    nombreAccion VARCHAR(10) UNIQUE NOT NULL CHECK (nombreAccion IN ('CREATE','UPDATE','DELETE','ERROR','READ'))
);

CREATE TABLE IF NOT EXISTS Logs (
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
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tablaID) REFERENCES TablasSistema(tablaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (accionID) REFERENCES Acciones(accionID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS Paises (
    paisID SERIAL PRIMARY KEY,
    nombrePais VARCHAR(30) NOT NULL,
    codigoISO VARCHAR(3) UNIQUE NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS NivelesGeograficos (
    nivelID SERIAL PRIMARY KEY,
    nombreNGeografico VARCHAR(50) UNIQUE NOT NULL,
    orden INT UNIQUE NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS DivisionesGeograficas (
    divisionID SERIAL PRIMARY KEY,
    paisID INT NOT NULL,
    nivelID INT NOT NULL,
    padreID INT,
    nombre VARCHAR(100) NOT NULL,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (nivelID) REFERENCES NivelesGeograficos(nivelID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (padreID) REFERENCES DivisionesGeograficas(divisionID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_divisiones_geograficas_unicas
ON DivisionesGeograficas(paisID, nivelID, COALESCE(padreID, 0), nombre);

CREATE TABLE IF NOT EXISTS Direcciones (
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
    FOREIGN KEY (divisionID) REFERENCES DivisionesGeograficas(divisionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS TiposContactos (
    tipoContactoID SERIAL PRIMARY KEY,
    nombreTipoContacto VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Contactos (
    contactoID SERIAL PRIMARY KEY,
    tipoContactoID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    nombreContacto VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    segundoApellido VARCHAR(50),
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (tipoContactoID) REFERENCES TiposContactos(tipoContactoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS TiposTelefonos (
    tipoTelefonoID SERIAL PRIMARY KEY,
    nombreTipoTelefono VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS TelefonosContactos (
    telefonoContactoID SERIAL PRIMARY KEY,
    contactoID INT NOT NULL,
    tipoTelefonosID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    numeroContacto VARCHAR(20) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (contactoID) REFERENCES Contactos(contactoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoTelefonosID) REFERENCES TiposTelefonos(tipoTelefonoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS CorreosContactos (
    correoContactoID SERIAL PRIMARY KEY,
    contactoID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    correo VARCHAR(50) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (contactoID) REFERENCES Contactos(contactoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS TiposCentroLogistico (
    tipoID SERIAL PRIMARY KEY,
    nombreTipoCLogistico VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS CentrosLogisticos (
    centroLogisticoID SERIAL PRIMARY KEY,
    tipoID INT NOT NULL,
    direccionID INT NOT NULL,
    contactoID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    nombreCentroLogistico VARCHAR(50) UNIQUE NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (tipoID) REFERENCES TiposCentroLogistico(tipoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (contactoID) REFERENCES Contactos(contactoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS Proveedores (
    proveedorID SERIAL PRIMARY KEY,
    direccionID INT NOT NULL,
    nombreProveedor VARCHAR(50) UNIQUE NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS ContactosProveedor (
    proveedorID INT NOT NULL,
    contactoID INT NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (proveedorID, contactoID),
    FOREIGN KEY (proveedorID) REFERENCES Proveedores(proveedorID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (contactoID) REFERENCES Contactos(contactoID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS Categorias (
    categoriaID SERIAL PRIMARY KEY,
    nombreCategoriaP VARCHAR(40) UNIQUE NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS Productos (
    productoID SERIAL PRIMARY KEY,
    categoriaID INT NOT NULL,
    usuarioModificacion INT,
    proveedorID INT NOT NULL,
    precio DECIMAL(18,6) NOT NULL CHECK (precio >= 0),
    nombreProducto VARCHAR(100) UNIQUE NOT NULL,
    descripcion VARCHAR(300) NOT NULL,
    descripcionManejo VARCHAR(300) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (categoriaID) REFERENCES Categorias(categoriaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (proveedorID) REFERENCES Proveedores(proveedorID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS Caracteristicas (
    caracteristicaID SERIAL PRIMARY KEY,
    nombreCaracteristicaP VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS ValorCaracteristicas (
    productoID INT NOT NULL,
    caracteristicaID INT NOT NULL,
    valor VARCHAR(50) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (productoID, caracteristicaID),
    FOREIGN KEY (productoID) REFERENCES Productos(productoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (caracteristicaID) REFERENCES Caracteristicas(caracteristicaID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS Monedas (
    monedaID SERIAL PRIMARY KEY,
    usuarioModificacion INT NOT NULL,
    paisID INT NOT NULL,
    simboloMoneda VARCHAR(10) NOT NULL,
    nombreMoneda VARCHAR(50) UNIQUE NOT NULL,
    tiempoCreacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS TiposCambio (
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
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (moneda1ID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (moneda2ID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_tiposcambio_par ON TiposCambio(moneda1ID, moneda2ID);

CREATE TABLE IF NOT EXISTS HistorialCambiosMonedas (
    historialCambioID SERIAL PRIMARY KEY,
    moneda1ID INT NOT NULL,
    moneda2ID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    usuarioModificacion INT,
    fechaInicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fechaFin TIMESTAMP DEFAULT '9999-12-31 23:59:59'::timestamp,
    tipoCambio DECIMAL(18,6) NOT NULL,
    checksum VARCHAR(100),
    horaCambio TIMESTAMP,
    FOREIGN KEY (moneda1ID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (moneda2ID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS TiposPermisos (
    tipoPermisoID SERIAL PRIMARY KEY,
    nombreTipoPermiso VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS PermisosImportacion (
    permisoID SERIAL PRIMARY KEY,
    paisID INT NOT NULL,
    tipoPermisoID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    nombrePermiso VARCHAR(50) NOT NULL,
    descripcion VARCHAR(200) NOT NULL,
    urlDocumentacion TEXT NOT NULL,
    costo DECIMAL(18,6) NOT NULL CHECK (costo >= 0),
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoPermisoID) REFERENCES TiposPermisos(tipoPermisoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_permisos_pais_tipo ON PermisosImportacion(paisID, tipoPermisoID);

CREATE TABLE IF NOT EXISTS Lotes (
    loteID SERIAL PRIMARY KEY,
    productoID INT NOT NULL,
    cantidadProductoLoteInicial INT NOT NULL CHECK (cantidadProductoLoteInicial > 0),
    cantidadProductoLoteDisponible INT NOT NULL CHECK (cantidadProductoLoteDisponible >= 0 AND cantidadProductoLoteDisponible <= cantidadProductoLoteInicial),
    fechaFabricacion TIMESTAMP NOT NULL,
    fechaVencimiento TIMESTAMP,
    FOREIGN KEY (productoID) REFERENCES Productos(productoID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS TipoMovimientosInventario (
    tipoMovimientoInventarioID SERIAL PRIMARY KEY,
    nombreTipoMovimientoInventario VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS MovimientosInventario (
    movimientoID SERIAL PRIMARY KEY,
    loteID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    tipoMovimientoInventarioID INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loteID) REFERENCES Lotes(loteID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoMovimientoInventarioID) REFERENCES TipoMovimientosInventario(tipoMovimientoInventarioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS Inventarios (
    inventarioID SERIAL PRIMARY KEY,
    loteID INT UNIQUE NOT NULL,
    usuarioModificacion INT,
    cantidadDisponible INT NOT NULL CHECK (cantidadDisponible >= 0),
    ultimaActualizacion TIMESTAMP,
    FOREIGN KEY (loteID) REFERENCES Lotes(loteID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS HistorialPreciosProducto (
    historialPrecioID SERIAL PRIMARY KEY,
    productoID INT NOT NULL,
    precio DECIMAL(18,6) NOT NULL,
    monedaID INT NOT NULL,
    fechaInicio TIMESTAMP NOT NULL,
    fechaFin TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (productoID) REFERENCES Productos(productoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS ImpuestosPais (
    impuestoID SERIAL PRIMARY KEY,
    paisID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    valor DECIMAL(18,6) NOT NULL,
    tipo tipo_impuesto NOT NULL,
    CHECK (
        (tipo = 'porcentaje' AND valor > 0 AND valor <= 100)
        OR
        (tipo = 'monto_fijo' AND valor > 0)
    ),
    fechaInicio TIMESTAMP NOT NULL,
    fechaFin TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_impuestos_pais_nombre ON ImpuestosPais(paisID, nombre);

CREATE TABLE IF NOT EXISTS EstadosOrdenes (
    estadoID SERIAL PRIMARY KEY,
    nombreEstadoOrden VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS TiposOrden (
    tipoOrdenID SERIAL PRIMARY KEY,
    nombre VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Ordenes (
    ordenID SERIAL PRIMARY KEY,
    estadoID INT NOT NULL,
    tipoOrdenID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    direccionEnvioID INT NOT NULL,
    direccionEntregaID INT NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    numeroOrden VARCHAR(30) UNIQUE NOT NULL,
    precioFinal DECIMAL(18,6) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (estadoID) REFERENCES EstadosOrdenes(estadoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoOrdenID) REFERENCES TiposOrden(tipoOrdenID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (direccionEnvioID) REFERENCES Direcciones(direccionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (direccionEntregaID) REFERENCES Direcciones(direccionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS OrdenDetalles (
    ordenDetalleID SERIAL PRIMARY KEY,
    ordenID INT NOT NULL,
    productoID INT NOT NULL,
    loteID INT NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    descuentoFinal DECIMAL(18,6) DEFAULT 0,
    costoEnvio DECIMAL(18,6) DEFAULT 0,
    precioLoteFinal DECIMAL(18,6) DEFAULT 0,
    checksum TEXT,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (productoID) REFERENCES Productos(productoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (loteID) REFERENCES Lotes(loteID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS OrdenDetalleImpuestos (
    ordenDetalleID INT NOT NULL,
    impuestoID INT NOT NULL,
    PRIMARY KEY (ordenDetalleID, impuestoID),
    FOREIGN KEY (ordenDetalleID) REFERENCES OrdenDetalles(ordenDetalleID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (impuestoID) REFERENCES ImpuestosPais(impuestoID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS OrdenDetallePermisos (
    ordenDetalleID INT NOT NULL,
    permisoID INT NOT NULL,
    PRIMARY KEY (ordenDetalleID, permisoID),
    FOREIGN KEY (ordenDetalleID) REFERENCES OrdenDetalles(ordenDetalleID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (permisoID) REFERENCES PermisosImportacion(permisoID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS OrdenDetalleDescuentos (
    ordenDetalleDescuentoID SERIAL PRIMARY KEY,
    ordenDetalleID INT NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    monto DECIMAL(18,6) NOT NULL,
    FOREIGN KEY (ordenDetalleID) REFERENCES OrdenDetalles(ordenDetalleID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS TrazabilidadOrden (
    trazabilidadID SERIAL PRIMARY KEY,
    ordenID INT NOT NULL,
    centroLogisticoID INT NOT NULL,
    direccionID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    estadoID INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (centroLogisticoID) REFERENCES CentrosLogisticos(centroLogisticoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (estadoID) REFERENCES EstadosOrdenes(estadoID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS EstadoTransacciones (
    estadoTransaccionID SERIAL PRIMARY KEY,
    nombreEstadoTransac VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS TipoTransacciones (
    tipoID SERIAL PRIMARY KEY,
    nombreTipoTransac VARCHAR(30) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS Transacciones (
    transaccionID SERIAL PRIMARY KEY,
    monedaID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    tipoID INT NOT NULL,
    estadoTransaccionID INT NOT NULL,
    ordenID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    monto DECIMAL(18,6) NOT NULL CHECK (monto >= 0),
    descripcion TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checksum TEXT,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoID) REFERENCES TipoTransacciones(tipoID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (estadoTransaccionID) REFERENCES EstadoTransacciones(estadoTransaccionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS EstadosCuenta (
    estadoCuentaID SERIAL PRIMARY KEY,
    ordenID INT NOT NULL,
    usuarioModificacion INT NOT NULL,
    tipoMovimiento tipo_movimiento_cuenta NOT NULL,
    estado estado_cuenta_enum NOT NULL,
    monedaID INT NOT NULL,
    tipoCambioID INT NOT NULL,
    tipoCambio DECIMAL(18,6) NOT NULL,
    monto DECIMAL(18,6) NOT NULL,
    fechaRegistro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    checksum TEXT,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE IF NOT EXISTS BalanceNeto (
    balanceID SERIAL PRIMARY KEY,
    saldo DECIMAL(18,6) NOT NULL,
    ultimaActualizacion TIMESTAMP
);
