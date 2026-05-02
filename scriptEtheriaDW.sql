DROP DATABASE IF EXISTS etheriaDW;
CREATE DATABASE etheriaDW;

CREATE TABLE centroAnalisis (
    registroID BIGSERIAL PRIMARY KEY,

    sistemaOrigen VARCHAR(30) NOT NULL,
    idOrdenOrigen VARCHAR(50),
    idProductoOrigen INT,
    idOrdenDetalleOrigen INT,

    fechaOrden DATE NOT NULL,
    anioOrden INT NOT NULL,
    mesOrden INT NOT NULL,
    diaOrden INT NOT NULL,
    trimestreOrden INT NOT NULL,

    nombreProducto VARCHAR(120) NOT NULL,
    descripcionProducto VARCHAR(500),
    nombreCategoria VARCHAR(80) NOT NULL,
    nombreProveedor VARCHAR(80),
    precioBaseUSD DECIMAL(18,6),

    nombreMarca VARCHAR(80),
    nombreSitio VARCHAR(100),
    dominioSitio VARCHAR(150),
    enfoqueMarketing VARCHAR(100),
    estadoSitio VARCHAR(30),
    fechaLanzamientoSitio DATE,

    paisOrigen VARCHAR(50),
    codigoIsoPaisOrigen VARCHAR(10),
    paisDestino VARCHAR(50),
    codigoIsoPaisDestino VARCHAR(10),

    idClienteOrigen INT,
    paisCliente VARCHAR(50),

    codigoMonedaLocal VARCHAR(10),
    nombreMonedaLocal VARCHAR(50),
    simboloMonedaLocal VARCHAR(10),
    tipoCambioUSD DECIMAL(18,6),

    cantidad INT NOT NULL DEFAULT 0,
    precioUnitarioLocal DECIMAL(18,6) NOT NULL DEFAULT 0,
    subtotalLocal DECIMAL(18,6) NOT NULL DEFAULT 0,
    descuentoLocal DECIMAL(18,6) NOT NULL DEFAULT 0,
    impuestoLocal DECIMAL(18,6) NOT NULL DEFAULT 0,
    costoEnvioLocal DECIMAL(18,6) NOT NULL DEFAULT 0,
    totalLineaLocal DECIMAL(18,6) NOT NULL DEFAULT 0,

    precioUnitarioUSD DECIMAL(18,6) NOT NULL DEFAULT 0,
    subtotalUSD DECIMAL(18,6) NOT NULL DEFAULT 0,
    descuentoUSD DECIMAL(18,6) NOT NULL DEFAULT 0,
    impuestoUSD DECIMAL(18,6) NOT NULL DEFAULT 0,
    costoEnvioUSD DECIMAL(18,6) NOT NULL DEFAULT 0,
    totalLineaUSD DECIMAL(18,6) NOT NULL DEFAULT 0,

    costoPermisoImportacion DECIMAL(18,6) NOT NULL DEFAULT 0,
    costoPermisoExportacion DECIMAL(18,6) NOT NULL DEFAULT 0,
    costoLogistico DECIMAL(18,6) NOT NULL DEFAULT 0,
    costoProductoBase DECIMAL(18,6) NOT NULL DEFAULT 0,
    costoTotalOperativo DECIMAL(18,6) NOT NULL DEFAULT 0,

    margenBrutoUSD DECIMAL(18,6) NOT NULL DEFAULT 0,
    porcentajeMargen DECIMAL(10,4) NOT NULL DEFAULT 0,

    estadoOrden VARCHAR(30),
    estadoPago VARCHAR(30),
    estadoEnvio VARCHAR(30),
    metodoPago VARCHAR(30),

    transportista VARCHAR(60),
    direccionEnvio VARCHAR(250),
    tiempoEntregaDias INT,

    visitasSitio DECIMAL(18,6) DEFAULT 0,
    comprasSitio DECIMAL(18,6) DEFAULT 0,
    tasaConversion DECIMAL(10,6) DEFAULT 0,
    ingresosSitio DECIMAL(18,6) DEFAULT 0,

    cantidadDisponible INT DEFAULT 0,
    cantidadReservada INT DEFAULT 0,
    nivelReorden INT DEFAULT 0,

    fechaCargaDW TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fechaActualizacionDW TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_centro_sistemaOrigen ON centroAnalisis (sistemaOrigen);
CREATE INDEX idx_centro_fechaOrden ON centroAnalisis (fechaOrden);
CREATE INDEX idx_centro_anioOrden ON centroAnalisis (anioOrden);
CREATE INDEX idx_centro_trimestreOrden ON centroAnalisis (trimestreOrden);
CREATE INDEX idx_centro_nombreCategoria ON centroAnalisis (nombreCategoria);
CREATE INDEX idx_centro_nombreProducto ON centroAnalisis (nombreProducto);
CREATE INDEX idx_centro_paisDestino ON centroAnalisis (paisDestino);
CREATE INDEX idx_centro_paisOrigen ON centroAnalisis (paisOrigen);
CREATE INDEX idx_centro_nombreMarca ON centroAnalisis (nombreMarca);
CREATE INDEX idx_centro_estadoOrden ON centroAnalisis (estadoOrden);
CREATE INDEX idx_centro_nombreSitio ON centroAnalisis (nombreSitio);
CREATE INDEX idx_centro_codigoMoneda ON centroAnalisis (codigoMonedaLocal);
