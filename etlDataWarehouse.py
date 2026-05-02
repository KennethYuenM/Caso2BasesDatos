import os
from datetime import datetime, timezone
import numpy as np
import pandas as pd
from sqlalchemy import create_engine

mysqlHost = "localhost"
mysqlPort = 3306
mysqlUser = "root"
mysqlPassword = "root123"
mysqlDatabase = "dynamicBrandsDB"

etheriaPostgresHost = "localhost"
etheriaPostgresPort = 5432
etheriaPostgresUser = "postgres"
etheriaPostgresPassword = "postgres"
etheriaPostgresDatabase = "etheriaGlobal"

dwPostgresHost = "localhost"
dwPostgresPort = 5432
dwPostgresUser = "postgres"
dwPostgresPassword = "postgres"
dwPostgresDatabase = "etheriaDW"

mysqlEngine = create_engine(
    f"mysql+mysqlconnector://{mysqlUser}:{mysqlPassword}@{mysqlHost}:{mysqlPort}/{mysqlDatabase}"
)

etheriaEngine = create_engine(
    f"postgresql+pg8000://{etheriaPostgresUser}:{etheriaPostgresPassword}@{etheriaPostgresHost}:{etheriaPostgresPort}/{etheriaPostgresDatabase}"
)

dwEngine = create_engine(
    f"postgresql+pg8000://{dwPostgresUser}:{dwPostgresPassword}@{dwPostgresHost}:{dwPostgresPort}/{dwPostgresDatabase}"
)

dynamicQuery = """
SELECT
    co.orderCode AS idOrdenOrigen,
    p.productID AS idProductoOrigen,
    cod.customerOrderDetailID AS idOrdenDetalleOrigen,
    DATE(co.orderDate) AS fechaOrden,
    YEAR(co.orderDate) AS anioOrden,
    MONTH(co.orderDate) AS mesOrden,
    DAY(co.orderDate) AS diaOrden,
    QUARTER(co.orderDate) AS trimestreOrden,

    p.productName AS nombreProducto,
    p.productDescription AS descripcionProducto,
    pc.categoryName AS nombreCategoria,
    p.basePrice AS precioBaseUSD,

    bt.brandName AS nombreMarca,
    ds.siteName AS nombreSitio,
    ds.primaryDomainName AS dominioSitio,
    ds.marketingFocus AS enfoqueMarketing,
    ds.siteStatusCode AS estadoSitio,
    DATE(ds.launchDate) AS fechaLanzamientoSitio,

    siteCountry.countryName AS paisDestino,
    siteCountry.iso3Code AS codigoIsoPaisDestino,

    co.personID AS idClienteOrigen,
    customerCountry.countryName AS paisCliente,

    curr.currencyCode AS codigoMonedaLocal,
    curr.currencyName AS nombreMonedaLocal,
    curr.currencySymbol AS simboloMonedaLocal,

    CASE
        WHEN curr.currencyCode = 'USD' THEN 1
        WHEN cer.sellRate IS NOT NULL AND cer.sellRate > 0 THEN cer.sellRate
        WHEN co.exchangeRate IS NOT NULL AND co.exchangeRate > 0 THEN co.exchangeRate
        ELSE 1
    END AS tipoCambioUSD,

    cod.quantity AS cantidad,
    cod.unitPrice AS precioUnitarioLocal,
    (cod.quantity * cod.unitPrice) AS subtotalLocal,
    cod.discountAmount AS descuentoLocal,
    cod.taxAmount AS impuestoLocal,
    co.shippingAmount AS costoEnvioLocal,
    cod.lineTotal AS totalLineaLocal,

    co.orderStatusCode AS estadoOrden,
    pay.paymentStatusCode AS estadoPago,
    ship.shipmentStatusCode AS estadoEnvio,
    pay.methodCode AS metodoPago,
    ship.carrierName AS transportista,
    ship.shippingAddress AS direccionEnvio,
    DATEDIFF(ship.deliveredAt, ship.shippedAt) AS tiempoEntregaDias,

    metrics.visitasSitio AS visitasSitio,
    metrics.comprasSitio AS comprasSitio,
    metrics.tasaConversion AS tasaConversion,
    metrics.ingresosSitio AS ingresosSitio,

    inv.availableQuantity AS cantidadDisponible,
    inv.reservedQuantity AS cantidadReservada,
    inv.reorderLevel AS nivelReorden,

    perm.permissionCost AS costoPermisoImportacion

FROM customerOrderDetail cod
JOIN customerOrder co
    ON cod.customerOrderID = co.customerOrderID
JOIN product p
    ON cod.productID = p.productID
JOIN productCategory pc
    ON p.productCategoryCode = pc.categoryCode
JOIN dynamicSiteInfo ds
    ON co.dynamicSiteID = ds.dynamicSiteID
JOIN brandTemplate bt
    ON ds.brandCode = bt.brandCode
JOIN country siteCountry
    ON ds.countryID = siteCountry.countryID
JOIN country customerCountry
    ON co.customerCountryID = customerCountry.countryID
JOIN currency curr
    ON co.currencyID = curr.currencyID
LEFT JOIN currency usdCurrency
    ON usdCurrency.currencyCode = 'USD'
LEFT JOIN currentExchangeRate cer
    ON cer.baseCurrencyID = usdCurrency.currencyID
    AND cer.quoteCurrencyID = curr.currencyID
LEFT JOIN paymentTransaction pay
    ON co.customerOrderID = pay.customerOrderID
LEFT JOIN shipment ship
    ON co.customerOrderID = ship.customerOrderID
LEFT JOIN inventory inv
    ON p.productID = inv.productID
    AND ds.dynamicSiteID = inv.dynamicSiteID
LEFT JOIN countryProductPermission perm
    ON p.productID = perm.productID
    AND siteCountry.countryID = perm.countryID
LEFT JOIN (
    SELECT
        dynamicSiteID,
        MAX(CASE WHEN metricTypeCode = 'VISITS' THEN metricValue ELSE NULL END) AS visitasSitio,
        MAX(CASE WHEN metricTypeCode = 'PURCHASES' THEN metricValue ELSE NULL END) AS comprasSitio,
        MAX(CASE WHEN metricTypeCode = 'CONVERSION_RATE' THEN metricValue ELSE NULL END) AS tasaConversion,
        MAX(CASE WHEN metricTypeCode = 'REVENUE' THEN metricValue ELSE NULL END) AS ingresosSitio
    FROM dynamicSiteMetric
    GROUP BY dynamicSiteID
) metrics
    ON ds.dynamicSiteID = metrics.dynamicSiteID
"""

etheriaQuery = """
SELECT
    p.productoid AS "etheriaProductoID",
    p.nombreproducto AS "etheriaNombreProducto",
    p.precio AS "costoProductoBase",
    p.descripcion AS "etheriaDescripcionProducto",
    c.nombrecategoriap AS "etheriaNombreCategoria",
    pr.nombreproveedor AS "nombreProveedor",
    pa.nombrepais AS "paisOrigen",
    pa.codigoiso AS "codigoIsoPaisOrigen"
FROM productos p
JOIN categorias c
    ON p.categoriaid = c.categoriaid
JOIN proveedores pr
    ON p.proveedorid = pr.proveedorid
JOIN direcciones d
    ON pr.direccionid = d.direccionid
JOIN divisionesgeograficas dg
    ON d.divisionid = dg.divisionid
JOIN paises pa
    ON dg.paisid = pa.paisid
"""

def normalizarTexto(valor):
    if pd.isna(valor):
        return ""

    texto = str(valor).strip().lower()

    reemplazos = {
        "á": "a",
        "é": "e",
        "í": "i",
        "ó": "o",
        "ú": "u",
        "ñ": "n",
        "ü": "u"
    }

    for caracterOriginal in reemplazos:
        texto = texto.replace(caracterOriginal, reemplazos[caracterOriginal])

    texto = " ".join(texto.split())
    return texto

def asegurarColumnaNumerica(dataFrame, nombreColumna):
    dataFrame[nombreColumna] = pd.to_numeric(dataFrame[nombreColumna], errors="coerce")

def completarColumnaDesdeFallback(dataFrame, columnaPrincipal, columnaFallback):
    condicionFaltante = dataFrame[columnaPrincipal].isna()
    dataFrame.loc[condicionFaltante, columnaPrincipal] = dataFrame.loc[condicionFaltante, columnaFallback]

try:
    dynamicDataFrame = pd.read_sql(dynamicQuery, mysqlEngine)
    etheriaDataFrame = pd.read_sql(etheriaQuery, etheriaEngine)

    dynamicDataFrame["nombreNormalizado"] = dynamicDataFrame["nombreProducto"].apply(normalizarTexto)
    etheriaDataFrame["nombreNormalizado"] = etheriaDataFrame["etheriaNombreProducto"].apply(normalizarTexto)

    mergedDataFrame = pd.merge(
        dynamicDataFrame,
        etheriaDataFrame,
        on="nombreNormalizado",
        how="left"
    )

    etheriaFallbackDataFrame = etheriaDataFrame.copy()
    etheriaFallbackDataFrame = etheriaFallbackDataFrame.rename(columns={
        "etheriaProductoID": "idProductoOrigen",
        "costoProductoBase": "costoProductoBaseFallback",
        "nombreProveedor": "nombreProveedorFallback",
        "paisOrigen": "paisOrigenFallback",
        "codigoIsoPaisOrigen": "codigoIsoPaisOrigenFallback",
        "etheriaNombreCategoria": "etheriaNombreCategoriaFallback"
    })

    mergedDataFrame = pd.merge(
        mergedDataFrame,
        etheriaFallbackDataFrame[
            [
                "idProductoOrigen",
                "costoProductoBaseFallback",
                "nombreProveedorFallback",
                "paisOrigenFallback",
                "codigoIsoPaisOrigenFallback",
                "etheriaNombreCategoriaFallback"
            ]
        ],
        on="idProductoOrigen",
        how="left"
    )

    completarColumnaDesdeFallback(mergedDataFrame, "costoProductoBase", "costoProductoBaseFallback")
    completarColumnaDesdeFallback(mergedDataFrame, "nombreProveedor", "nombreProveedorFallback")
    completarColumnaDesdeFallback(mergedDataFrame, "paisOrigen", "paisOrigenFallback")
    completarColumnaDesdeFallback(mergedDataFrame, "codigoIsoPaisOrigen", "codigoIsoPaisOrigenFallback")

    columnasNumericas = [
        "tipoCambioUSD",
        "cantidad",
        "precioUnitarioLocal",
        "subtotalLocal",
        "descuentoLocal",
        "impuestoLocal",
        "costoEnvioLocal",
        "totalLineaLocal",
        "costoPermisoImportacion",
        "costoProductoBase",
        "cantidadDisponible",
        "cantidadReservada",
        "nivelReorden",
        "visitasSitio",
        "comprasSitio",
        "tasaConversion",
        "ingresosSitio",
        "precioBaseUSD"
    ]

    for nombreColumna in columnasNumericas:
        asegurarColumnaNumerica(mergedDataFrame, nombreColumna)

    mergedDataFrame.loc[mergedDataFrame["tipoCambioUSD"].isna(), "tipoCambioUSD"] = 1.0
    mergedDataFrame.loc[mergedDataFrame["tipoCambioUSD"] <= 0, "tipoCambioUSD"] = 1.0

    columnasCeroValido = [
        "cantidad",
        "precioUnitarioLocal",
        "subtotalLocal",
        "descuentoLocal",
        "impuestoLocal",
        "costoEnvioLocal",
        "totalLineaLocal",
        "costoPermisoImportacion",
        "costoProductoBase",
        "precioBaseUSD"
    ]

    for nombreColumna in columnasCeroValido:
        mergedDataFrame[nombreColumna] = mergedDataFrame[nombreColumna].fillna(0.0)

    mergedDataFrame["precioUnitarioUSD"] = mergedDataFrame["precioUnitarioLocal"] / mergedDataFrame["tipoCambioUSD"]
    mergedDataFrame["subtotalUSD"] = mergedDataFrame["subtotalLocal"] / mergedDataFrame["tipoCambioUSD"]
    mergedDataFrame["descuentoUSD"] = mergedDataFrame["descuentoLocal"] / mergedDataFrame["tipoCambioUSD"]
    mergedDataFrame["impuestoUSD"] = mergedDataFrame["impuestoLocal"] / mergedDataFrame["tipoCambioUSD"]
    mergedDataFrame["costoEnvioUSD"] = mergedDataFrame["costoEnvioLocal"] / mergedDataFrame["tipoCambioUSD"]
    mergedDataFrame["totalLineaUSD"] = mergedDataFrame["totalLineaLocal"] / mergedDataFrame["tipoCambioUSD"]
    mergedDataFrame["costoPermisoImportacionUSD"] = mergedDataFrame["costoPermisoImportacion"] / mergedDataFrame["tipoCambioUSD"]

    mergedDataFrame["costoProductoBaseTotal"] = mergedDataFrame["costoProductoBase"] * mergedDataFrame["cantidad"]

    mergedDataFrame["costoTotalOperativo"] = (
        mergedDataFrame["costoProductoBaseTotal"]
        + mergedDataFrame["costoPermisoImportacionUSD"]
        + mergedDataFrame["costoEnvioUSD"]
    )

    mergedDataFrame["margenBrutoUSD"] = mergedDataFrame["totalLineaUSD"] - mergedDataFrame["costoTotalOperativo"]

    mergedDataFrame["porcentajeMargen"] = 0.0
    condicionMargen = mergedDataFrame["totalLineaUSD"] > 0

    mergedDataFrame.loc[condicionMargen, "porcentajeMargen"] = (
        mergedDataFrame.loc[condicionMargen, "margenBrutoUSD"].astype(float)
        / mergedDataFrame.loc[condicionMargen, "totalLineaUSD"].astype(float)
    ) * 100.0

    condicionTasaConversionFaltante = mergedDataFrame["tasaConversion"].isna()
    condicionVisitasValidas = mergedDataFrame["visitasSitio"] > 0
    condicionComprasValidas = mergedDataFrame["comprasSitio"].notna()

    mergedDataFrame.loc[
        condicionTasaConversionFaltante & condicionVisitasValidas & condicionComprasValidas,
        "tasaConversion"
    ] = (
        mergedDataFrame.loc[
            condicionTasaConversionFaltante & condicionVisitasValidas & condicionComprasValidas,
            "comprasSitio"
        ]
        / mergedDataFrame.loc[
            condicionTasaConversionFaltante & condicionVisitasValidas & condicionComprasValidas,
            "visitasSitio"
        ]
    )

    ingresosPorSitioDataFrame = mergedDataFrame.groupby("nombreSitio", as_index=False)["totalLineaUSD"].sum()
    ingresosPorSitioDataFrame = ingresosPorSitioDataFrame.rename(columns={
        "totalLineaUSD": "ingresosSitioCalculado"
    })

    mergedDataFrame = pd.merge(
        mergedDataFrame,
        ingresosPorSitioDataFrame,
        on="nombreSitio",
        how="left"
    )

    condicionIngresosFaltantes = mergedDataFrame["ingresosSitio"].isna()
    mergedDataFrame.loc[condicionIngresosFaltantes, "ingresosSitio"] = mergedDataFrame.loc[
        condicionIngresosFaltantes,
        "ingresosSitioCalculado"
    ]

    fechaCargaActual = datetime.now(timezone.utc)

    resultadoFinal = pd.DataFrame(index=mergedDataFrame.index)

    resultadoFinal["sistemaorigen"] = "DYNAMIC_BRANDS"
    resultadoFinal["idordenorigen"] = mergedDataFrame["idOrdenOrigen"].astype(str)
    resultadoFinal["idproductoorigen"] = mergedDataFrame["idProductoOrigen"]
    resultadoFinal["idordendetalleorigen"] = mergedDataFrame["idOrdenDetalleOrigen"]
    resultadoFinal["fechaorden"] = mergedDataFrame["fechaOrden"]
    resultadoFinal["anioorden"] = mergedDataFrame["anioOrden"]
    resultadoFinal["mesorden"] = mergedDataFrame["mesOrden"]
    resultadoFinal["diaorden"] = mergedDataFrame["diaOrden"]
    resultadoFinal["trimestreorden"] = mergedDataFrame["trimestreOrden"]

    resultadoFinal["nombreproducto"] = mergedDataFrame["nombreProducto"]
    resultadoFinal["descripcionproducto"] = mergedDataFrame["descripcionProducto"]
    resultadoFinal["nombrecategoria"] = mergedDataFrame["nombreCategoria"]
    resultadoFinal["nombreproveedor"] = mergedDataFrame["nombreProveedor"]
    resultadoFinal["preciobaseusd"] = mergedDataFrame["precioBaseUSD"]

    resultadoFinal["nombremarca"] = mergedDataFrame["nombreMarca"]
    resultadoFinal["nombresitio"] = mergedDataFrame["nombreSitio"]
    resultadoFinal["dominiositio"] = mergedDataFrame["dominioSitio"]
    resultadoFinal["enfoquemarketing"] = mergedDataFrame["enfoqueMarketing"]
    resultadoFinal["estadositio"] = mergedDataFrame["estadoSitio"]
    resultadoFinal["fechalanzamientositio"] = mergedDataFrame["fechaLanzamientoSitio"]

    resultadoFinal["paisorigen"] = mergedDataFrame["paisOrigen"]
    resultadoFinal["codigoisopaisorigen"] = mergedDataFrame["codigoIsoPaisOrigen"]
    resultadoFinal["paisdestino"] = mergedDataFrame["paisDestino"]
    resultadoFinal["codigoisopaisdestino"] = mergedDataFrame["codigoIsoPaisDestino"]

    resultadoFinal["idclienteorigen"] = mergedDataFrame["idClienteOrigen"]
    resultadoFinal["paiscliente"] = mergedDataFrame["paisCliente"]

    resultadoFinal["codigomonedalocal"] = mergedDataFrame["codigoMonedaLocal"]
    resultadoFinal["nombremonedalocal"] = mergedDataFrame["nombreMonedaLocal"]
    resultadoFinal["simbolomonedalocal"] = mergedDataFrame["simboloMonedaLocal"]
    resultadoFinal["tipocambiousd"] = mergedDataFrame["tipoCambioUSD"]

    resultadoFinal["cantidad"] = mergedDataFrame["cantidad"]
    resultadoFinal["preciounitariolocal"] = mergedDataFrame["precioUnitarioLocal"]
    resultadoFinal["subtotallocal"] = mergedDataFrame["subtotalLocal"]
    resultadoFinal["descuentolocal"] = mergedDataFrame["descuentoLocal"]
    resultadoFinal["impuestolocal"] = mergedDataFrame["impuestoLocal"]
    resultadoFinal["costoenviolocal"] = mergedDataFrame["costoEnvioLocal"]
    resultadoFinal["totallinealocal"] = mergedDataFrame["totalLineaLocal"]

    resultadoFinal["preciounitariousd"] = mergedDataFrame["precioUnitarioUSD"]
    resultadoFinal["subtotalusd"] = mergedDataFrame["subtotalUSD"]
    resultadoFinal["descuentousd"] = mergedDataFrame["descuentoUSD"]
    resultadoFinal["impuestousd"] = mergedDataFrame["impuestoUSD"]
    resultadoFinal["costoenviousd"] = mergedDataFrame["costoEnvioUSD"]
    resultadoFinal["totallineausd"] = mergedDataFrame["totalLineaUSD"]

    resultadoFinal["costopermisoimportacion"] = mergedDataFrame["costoPermisoImportacionUSD"]
    resultadoFinal["costopermisoexportacion"] = 0.0
    resultadoFinal["costologistico"] = mergedDataFrame["costoEnvioUSD"]
    resultadoFinal["costoproductobase"] = mergedDataFrame["costoProductoBaseTotal"]
    resultadoFinal["costototaloperativo"] = mergedDataFrame["costoTotalOperativo"]

    resultadoFinal["margenbrutousd"] = mergedDataFrame["margenBrutoUSD"]
    resultadoFinal["porcentajemargen"] = mergedDataFrame["porcentajeMargen"]

    resultadoFinal["estadoorden"] = mergedDataFrame["estadoOrden"]
    resultadoFinal["estadopago"] = mergedDataFrame["estadoPago"]
    resultadoFinal["estadoenvio"] = mergedDataFrame["estadoEnvio"]
    resultadoFinal["metodopago"] = mergedDataFrame["metodoPago"]

    resultadoFinal["transportista"] = mergedDataFrame["transportista"]
    resultadoFinal["direccionenvio"] = mergedDataFrame["direccionEnvio"]
    resultadoFinal["tiempoentregadias"] = mergedDataFrame["tiempoEntregaDias"]

    resultadoFinal["visitassitio"] = mergedDataFrame["visitasSitio"]
    resultadoFinal["comprassitio"] = mergedDataFrame["comprasSitio"]
    resultadoFinal["tasaconversion"] = mergedDataFrame["tasaConversion"]
    resultadoFinal["ingresossitio"] = mergedDataFrame["ingresosSitio"]

    resultadoFinal["cantidaddisponible"] = mergedDataFrame["cantidadDisponible"]
    resultadoFinal["cantidadreservada"] = mergedDataFrame["cantidadReservada"]
    resultadoFinal["nivelreorden"] = mergedDataFrame["nivelReorden"]

    resultadoFinal["fechacargadw"] = fechaCargaActual
    resultadoFinal["fechaactualizaciondw"] = fechaCargaActual

    columnasObligatoriasTexto = [
        "sistemaorigen",
        "nombreproducto",
        "nombrecategoria"
    ]

    for nombreColumna in columnasObligatoriasTexto:
        resultadoFinal[nombreColumna] = resultadoFinal[nombreColumna].fillna("SIN_DATO")

    columnasObligatoriasNumericas = [
        "cantidad",
        "preciounitariolocal",
        "subtotallocal",
        "descuentolocal",
        "impuestolocal",
        "costoenviolocal",
        "totallinealocal",
        "preciounitariousd",
        "subtotalusd",
        "descuentousd",
        "impuestousd",
        "costoenviousd",
        "totallineausd",
        "costopermisoimportacion",
        "costopermisoexportacion",
        "costologistico",
        "costoproductobase",
        "costototaloperativo",
        "margenbrutousd",
        "porcentajemargen"
    ]

    for nombreColumna in columnasObligatoriasNumericas:
        resultadoFinal[nombreColumna] = resultadoFinal[nombreColumna].fillna(0.0)

    resultadoFinal = resultadoFinal.replace({np.nan: None})

    productosSinCruce = resultadoFinal[resultadoFinal["nombreproveedor"].isna()]
    cantidadProductosSinCruce = len(productosSinCruce)

    if cantidadProductosSinCruce > 0:
        print("ADVERTENCIA: hay productos sin cruce completo con Etheria:", cantidadProductosSinCruce)
        print(productosSinCruce[["idproductoorigen", "nombreproducto"]].drop_duplicates().to_string(index=False))

    with dwEngine.begin() as conexionDw:
        conexionDw.exec_driver_sql("DELETE FROM centroanalisis WHERE sistemaorigen = 'DYNAMIC_BRANDS'")
        resultadoFinal.to_sql(
            "centroanalisis",
            conexionDw,
            if_exists="append",
            index=False
        )

    print("ETL completado correctamente")
    print("Registros extraidos de Dynamic Brands:", len(dynamicDataFrame))
    print("Registros extraidos de Etheria:", len(etheriaDataFrame))
    print("Registros cargados en etheriaDW.centroanalisis:", len(resultadoFinal))

except Exception as error:
    print("ERROR REAL DEL ETL:")
    print(error)
