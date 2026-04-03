-- =========================
-- ESQUEMA BASE
-- =========================
CREATE DATABASE "EtheriaGlobal";
-- Conectarse manualmente luego

-- =========================
-- USUARIOS Y SEGURIDAD
-- =========================

CREATE TABLE Usuarios (
    usuarioID SERIAL PRIMARY KEY,
    nombre VARCHAR(50),
    apellido VARCHAR(50),
    segundoApellido VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    contraseñaHASH TEXT,
    creado TIMESTAMP,
    actualizado TIMESTAMP,
    activo BOOLEAN
);

CREATE TABLE Roles (
    roleID SERIAL PRIMARY KEY,
    rolNombre VARCHAR(40),
    descripcion VARCHAR(500),
    activo BOOLEAN
);

CREATE TABLE RolesXUsuario (
    usuarioID INT,
    roleID INT,
    asignado TIMESTAMP,
    PRIMARY KEY (usuarioID, roleID),
    FOREIGN KEY (usuarioID) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION,
    FOREIGN KEY (roleID) REFERENCES Roles(roleID) ON DELETE NO ACTION
);

-- =========================
-- PERMISOS
-- =========================

CREATE TABLE Tablas (
    tablaID SERIAL PRIMARY KEY,
    nombreTabla VARCHAR(50),
    creado TIMESTAMP
);

CREATE TABLE Acciones (
    accionID SERIAL PRIMARY KEY,
    nombreAccion VARCHAR(10)
);

CREATE TABLE Permisos (
    permisoID SERIAL PRIMARY KEY,
    tablaID INT,
    accionID INT,
    FOREIGN KEY (tablaID) REFERENCES Tablas(tablaID) ON DELETE NO ACTION,
    FOREIGN KEY (accionID) REFERENCES Acciones(accionID) ON DELETE NO ACTION
);

CREATE TABLE PermisosXRole (
    roleID INT,
    permisoID INT,
    PRIMARY KEY (roleID, permisoID),
    FOREIGN KEY (roleID) REFERENCES Roles(roleID) ON DELETE NO ACTION,
    FOREIGN KEY (permisoID) REFERENCES Permisos(permisoID) ON DELETE NO ACTION
);

-- =========================
-- GEOGRAFÍA
-- =========================

CREATE TABLE Paises (
    paisID SERIAL PRIMARY KEY,
    nombre VARCHAR(30),
    codigoISO VARCHAR(3),
    activo BOOLEAN
);

CREATE TABLE NivelesGeograficos (
    nivelID SERIAL PRIMARY KEY,
    nombre VARCHAR(50),
    orden INT,
    activo BOOLEAN
);

CREATE TABLE DivisionesGeograficas (
    divisionID SERIAL PRIMARY KEY,
    paisID INT,
    nivelID INT,
    padreID INT,
    nombre VARCHAR(100),
    FOREIGN KEY (paisID) REFERENCES Paises(paisID) ON DELETE NO ACTION,
    FOREIGN KEY (nivelID) REFERENCES NivelesGeograficos(nivelID) ON DELETE NO ACTION,
    FOREIGN KEY (padreID) REFERENCES DivisionesGeograficas(divisionID) ON DELETE NO ACTION
);

CREATE TABLE Direcciones (
    direccionID SERIAL PRIMARY KEY,
    divisionID INT,
    usuarioModificacion INT,
    calle VARCHAR(150),
    numero VARCHAR(20),
    referencia TEXT,
    codigoPostal VARCHAR(20),
    direccionCompleta TEXT,
    fechaCreacion TIMESTAMP,
    activo BOOLEAN,
    FOREIGN KEY (divisionID) REFERENCES DivisionesGeograficas(divisionID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION
);

-- =========================
-- CENTROS LOGÍSTICOS
-- =========================

CREATE TABLE TiposCentroLogistico (
    tipoID SERIAL PRIMARY KEY,
    nombre VARCHAR(20)
);

CREATE TABLE CentrosLogisticos (
    centroLogisticoID SERIAL PRIMARY KEY,
    tipoID INT,
    direccionID INT,
    usuarioModificacion INT,
    nombre VARCHAR(50),
    telefono VARCHAR(20),
    activo BOOLEAN,
    FOREIGN KEY (tipoID) REFERENCES TiposCentroLogistico(tipoID) ON DELETE NO ACTION,
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION
);

-- =========================
-- MONEDAS
-- =========================

CREATE TABLE Monedas (
    monedaID SERIAL PRIMARY KEY,
    usuarioModificacion INT,
    paisID INT,
    simboloMoneda VARCHAR(10),
    nombreMoneda VARCHAR(50),
    tiempoCreacion TIMESTAMP,
    activo BOOLEAN,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID) ON DELETE NO ACTION
);

CREATE TABLE TiposCambio (
    tipoCambioID SERIAL PRIMARY KEY,
    usuarioModificacion INT,
    moneda1ID INT,
    moneda2ID INT,
    tipoCambio DECIMAL(18,6),
    tiempoCreacion TIMESTAMP,
    ultimaActualizacion TIMESTAMP,
    checksum VARCHAR(100),
    activo BOOLEAN,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION,
    FOREIGN KEY (moneda1ID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION,
    FOREIGN KEY (moneda2ID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION
);

CREATE TABLE HistorialCambiosMonedas (
    histotalCambioID SERIAL PRIMARY KEY,
    moneda1ID INT,
    moneda2ID INT,
    tipoCambioID INT,
    usuarioModificacion INT,
    fechaInicio TIMESTAMP,
    fechaFin TIMESTAMP,
    tipoCambio DECIMAL(18,6),
    checksum VARCHAR(100),
    horaCambio TIMESTAMP,
    FOREIGN KEY (moneda1ID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION,
    FOREIGN KEY (moneda2ID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION,
    FOREIGN KEY (tipoCambioID) REFERENCES TiposCambio(tipoCambioID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION
);

-- =========================
-- LOGS
-- =========================

CREATE TABLE Logs (
    logID SERIAL PRIMARY KEY,
    usuarioModificacion INT,
    tablaID INT,
    accionID INT,
    objetoAfectadoID INT,
    datosViejos JSON,
    datosNuevos JSON,
    hora TIMESTAMP,
    error TEXT,
    checksum TEXT,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION,
    FOREIGN KEY (tablaID) REFERENCES Tablas(tablaID) ON DELETE NO ACTION,
    FOREIGN KEY (accionID) REFERENCES Acciones(accionID) ON DELETE NO ACTION
);

-- =========================
-- PRODUCTOS
-- =========================

CREATE TABLE Categorias (
    categoriaID SERIAL PRIMARY KEY,
    nombre VARCHAR(20),
    activo BOOLEAN
);

CREATE TABLE Marcas (
    marcaID SERIAL PRIMARY KEY,
    nombre VARCHAR(20),
    paisID INT,
    activo BOOLEAN,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID) ON DELETE NO ACTION
);

CREATE TABLE Productos (
    productoID SERIAL PRIMARY KEY,
    categoriaID INT,
    marcaID INT,
    usuarioModificacion INT,
    nombre VARCHAR(20),
    descripcion TEXT,
    descripcionManejo TEXT,
    activo BOOLEAN,
    FOREIGN KEY (categoriaID) REFERENCES Categorias(categoriaID) ON DELETE NO ACTION,
    FOREIGN KEY (marcaID) REFERENCES Marcas(marcaID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION
);

CREATE TABLE Caracteristicas (
    caracteristicaID SERIAL PRIMARY KEY,
    nombre VARCHAR(50)
);

CREATE TABLE ValorCaracteristicas (
    productoID INT,
    caracteristicaID INT,
    valor VARCHAR(50),
    deleted BOOLEAN,
    PRIMARY KEY (productoID, caracteristicaID),
    FOREIGN KEY (productoID) REFERENCES Productos(productoID) ON DELETE NO ACTION,
    FOREIGN KEY (caracteristicaID) REFERENCES Caracteristicas(caracteristicaID) ON DELETE NO ACTION
);

-- =========================
-- PROVEEDORES
-- =========================

CREATE TABLE Proveedores (
    proveedorID SERIAL PRIMARY KEY,
    nombre VARCHAR(30),
    direccionID INT,
    activo BOOLEAN,
    FOREIGN KEY (direccionID) REFERENCES Direcciones(direccionID) ON DELETE NO ACTION
);

CREATE TABLE ProductoProveedor (
    productoProveedorID SERIAL PRIMARY KEY,
    productoID INT,
    proveedorID INT,
    activo BOOLEAN,
    FOREIGN KEY (productoID) REFERENCES Productos(productoID) ON DELETE NO ACTION,
    FOREIGN KEY (proveedorID) REFERENCES Proveedores(proveedorID) ON DELETE NO ACTION
);

CREATE TABLE ContactosProveedor (
    contactoID SERIAL PRIMARY KEY,
    proveedorID INT,
    usuarioModificacion INT,
    nombre VARCHAR(30),
    telefono VARCHAR(20),
    email VARCHAR(40),
    activo BOOLEAN,
    FOREIGN KEY (proveedorID) REFERENCES Proveedores(proveedorID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION
);

-- =========================
-- LOTES
-- =========================

CREATE TABLE Lotes (
    loteID SERIAL PRIMARY KEY,
    productoProveedorID INT,
    monedaID INT,
    precio DECIMAL(18,6),
    ingredientes TEXT,
    fechaFabricacion TIMESTAMP,
    fechaVencimiento TIMESTAMP,
    FOREIGN KEY (productoProveedorID) REFERENCES ProductoProveedor(productoProveedorID) ON DELETE NO ACTION,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION
);

-- =========================
-- ORDENES
-- =========================

CREATE TABLE EstadosOrdenes (
    estadoID SERIAL PRIMARY KEY,
    nombre VARCHAR(10)
);

CREATE TABLE Ordenes (
    ordenID SERIAL PRIMARY KEY,
    estadoID INT,
    usuarioModificacion INT,
    direccionEntregaID INT,
    numeroOrden VARCHAR(30),
    fecha TIMESTAMP,
    FOREIGN KEY (estadoID) REFERENCES EstadosOrdenes(estadoID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION,
    FOREIGN KEY (direccionEntregaID) REFERENCES Direcciones(direccionID) ON DELETE NO ACTION
);

CREATE TABLE ImpuestosPais (
    impuestoID SERIAL PRIMARY KEY,
    paisID INT,
    usuarioModificacion INT,
    porcentaje DECIMAL(5,2),
    activo BOOLEAN,
    FOREIGN KEY (paisID) REFERENCES Paises(paisID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION
);

CREATE TABLE OrdenDetalle (
    ordenDetalleID SERIAL PRIMARY KEY,
    loteID INT,
    impuestoID INT,
    cantidad INT,
    precioFinal DECIMAL(18,6),
    descuento DECIMAL(18,6),
    checksum TEXT,
    FOREIGN KEY (loteID) REFERENCES Lotes(loteID) ON DELETE NO ACTION,
    FOREIGN KEY (impuestoID) REFERENCES ImpuestosPais(impuestoID) ON DELETE NO ACTION
);

CREATE TABLE TrazabilidadOrden (
    trazabilidadID SERIAL PRIMARY KEY,
    ordenID INT,
    centroLogisticoID INT,
    usuarioModificacion INT,
    estadoID INT,
    fecha TIMESTAMP,
    FOREIGN KEY (ordenID) REFERENCES Ordenes(ordenID) ON DELETE NO ACTION,
    FOREIGN KEY (centroLogisticoID) REFERENCES CentrosLogisticos(centroLogisticoID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION,
    FOREIGN KEY (estadoID) REFERENCES EstadosOrdenes(estadoID) ON DELETE NO ACTION
);

-- =========================
-- TRANSACCIONES
-- =========================

CREATE TABLE EstadoTransacciones (
    estadoTransaccionID SERIAL PRIMARY KEY,
    nombre VARCHAR(20)
);

CREATE TABLE TipoTransacciones (
    tipoID SERIAL PRIMARY KEY,
    nombre VARCHAR(20)
);

CREATE TABLE ReferenciasTipos (
    referenciaTipoID SERIAL PRIMARY KEY,
    nombre VARCHAR(20)
);

CREATE TABLE Transacciones (
    transaccionID SERIAL PRIMARY KEY,
    monedaID INT,
    usuarioModificacion INT,
    tipoID INT,
    referenciaTipoID INT,
    estadoTransaccionID INT,
    monto DECIMAL(18,6),
    referenciaID INT,
    descripcion TEXT,
    fecha TIMESTAMP,
    FOREIGN KEY (monedaID) REFERENCES Monedas(monedaID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION,
    FOREIGN KEY (tipoID) REFERENCES TipoTransacciones(tipoID) ON DELETE NO ACTION,
    FOREIGN KEY (referenciaTipoID) REFERENCES ReferenciasTipos(referenciaTipoID) ON DELETE NO ACTION,
    FOREIGN KEY (estadoTransaccionID) REFERENCES EstadoTransacciones(estadoTransaccionID) ON DELETE NO ACTION
);

-- =========================
-- INVENTARIO
-- =========================

CREATE TABLE Inventario (
    inventarioID SERIAL PRIMARY KEY,
    loteID INT,
    usuarioModificacion INT,
    cantidadDisponible INT,
    ultimaActualizacion TIMESTAMP,
    FOREIGN KEY (loteID) REFERENCES Lotes(loteID) ON DELETE NO ACTION,
    FOREIGN KEY (usuarioModificacion) REFERENCES Usuarios(usuarioID) ON DELETE NO ACTION
);