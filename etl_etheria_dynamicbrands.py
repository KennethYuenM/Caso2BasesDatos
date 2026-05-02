import os
import pandas as pd
import numpy as np
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

# ============================================================
# CONFIGURACIÓN
# ============================================================

PG_ETHERIA_URL = os.getenv("ETHERIA_PG_URL", "postgresql+psycopg2://admin:admin123@localhost:5432/ETHERIA GLOBAL")
MYSQL_DYNAMIC_URL = os.getenv("DYNAMIC_MYSQL_URL", "mysql+pymysql://root:admin123@localhost:3306/dynamicBrandsDB")
PG_DW_URL = os.getenv("DW_PG_URL", "postgresql+psycopg2://admin:admin123@localhost:5432/etheriaDW")

DW_TABLE = "centroanalisis"
FULL_REFRESH = True

# Nombres exactos según tu DDL (Postgres normaliza a minúsculas sin guiones si no se usan comillas)
DW_COLUMNS = [
    "sistemaorigen", "idordenorigen", "idproductoorigen", "idordendetalleorigen",
    "fechaorden", "anioorden", "mesorden", "diaorden", "trimestreorden",
    "nombreproducto", "descripcionproducto", "nombrecategoria", "nombreproveedor",
    "preciobaseusd", "nombremarca", "nombresitio", "dominiositio", "enfoquemarketing",
    "estadositio", "fechalanzamientositio", "paisorigen", "codigoisopaisorigen",
    "paisdestino", "codigoisopaisdestino", "idclienteorigen", "paiscliente",
    "codigomonedalocal", "nombremonedalocal", "simbolomonedalocal", "tipocambiousd",
    "cantidad", "preciounitariolocal", "subtotallocal", "descuentolocal",
    "impuestolocal", "costoenviolocal", "totallinealocal", "preciounitariousd",
    "subtotalusd", "descuentousd", "impuestousd", "costoenviousd", "totallineausd",
    "costopermisoimportacion", "costopermisoexportacion", "costologistico",
    "costoproductobase", "costototaloperativo", "margenbrutousd", "porcentajemargen",
    "estadoorden", "estadopago", "estadoenvio", "metodopago", "transportista",
    "direccionenvio", "tiempoentregadias", "visitassitio", "comprassitio",
    "tasaconversion", "ingresossitio", "cantidaddisponible", "cantidadreservada",
    "nivelreorden"
]

# ============================================================
# UTILIDADES
# ============================================================

def make_engine(url: str) -> Engine:
    return create_engine(url, pool_pre_ping=True)

def safe_num(value):
    try:
        return float(value) if value is not None and not pd.isna(value) else 0.0
    except: return 0.0

def truncate_target(dw_engine: Engine) -> None:
    with dw_engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE public.{DW_TABLE} RESTART IDENTITY CASCADE;"))

# ============================================================
# EXTRACCIÓN Y TRANSFORMACIÓN (Mapeo a nuevas columnas)
# ============================================================

def extract_etheria(engine):
    # La query usa los alias ya limpios para facilitar el mapeo
    query = """
    SELECT 
        'ETHERIA' as sistemaorigen, o.numeroorden as idordenorigen, p.productoid as idproductoorigen, 
        od.ordendetalleid as idordendetalleorigen, o.fecha as fechaorden,
        EXTRACT(YEAR FROM o.fecha) as anioorden, EXTRACT(MONTH FROM o.fecha) as mesorden,
        EXTRACT(DAY FROM o.fecha) as diaorden, EXTRACT(QUARTER FROM o.fecha) as trimestreorden,
        p.nombreproducto as nombreproducto, p.descripcion as descripcionproducto, 
        c.nombrecategoriap as nombrecategoria, pr.nombreproveedor as nombreproveedor,
        p.precio / COALESCE(o.tipocambio, 1) as preciobaseusd, po.nombrepais as paisorigen,
        po.codigoiso as codigoisopaisorigen, pd.nombrepais as paisdestino,
        pd.codigoiso as codigoisopaisdestino, m.simbolomoneda as codigomonedalocal,
        m.nombremoneda as nombremonedalocal, m.simbolomoneda as simbolomonedalocal,
        COALESCE(o.tipocambio, 1) as tipocambiousd, od.cantidad as cantidad,
        (od.preciolotefinal / NULLIF(od.cantidad, 0)) as preciounitariolocal,
        od.preciolotefinal as subtotallocal, 0 as descuentolocal, 0 as impuestolocal,
        0 as costoenviolocal, od.preciolotefinal as totallinealocal,
        (od.preciolotefinal / NULLIF(od.cantidad, 0)) / COALESCE(o.tipocambio, 1) as preciounitariousd,
        od.preciolotefinal / COALESCE(o.tipocambio, 1) as subtotalusd,
        0 as descuentousd, 0 as impuestousd, 0 as costoenviousd,
        od.preciolotefinal / COALESCE(o.tipocambio, 1) as totallineausd,
        COALESCE(p.precio, 0) as costoproductobase,
        eo.nombreestadoorden as estadoorden
    FROM ordendetalles od
    JOIN ordenes o ON o.ordenid = od.ordenid
    JOIN productos p ON p.productoid = od.productoid
    JOIN categorias c ON c.categoriaid = p.categoriaid
    LEFT JOIN proveedores pr ON pr.proveedorid = p.proveedorid
    LEFT JOIN monedas m ON m.monedaid = od.monedaid
    LEFT JOIN estadosordenes eo ON eo.estadoid = o.estadoid
    LEFT JOIN direcciones d ON d.direccionid = o.direccionentregaid
    LEFT JOIN divisionesgeograficas dg ON dg.divisionid = d.divisionid
    LEFT JOIN paises pd ON pd.paisid = dg.paisid
    LEFT JOIN direcciones dp ON dp.direccionid = pr.direccionid
    LEFT JOIN divisionesgeograficas dgp ON dgp.divisionid = dp.divisionid
    LEFT JOIN paises po ON po.paisid = dgp.paisid
    """
    return pd.read_sql(query, engine)

def extract_dynamic(engine):
    query = """
    SELECT 
        'DYNAMIC_BRANDS' as sistemaorigen, co.orderCode as idordenorigen, p.productID as idproductoorigen,
        cod.customerOrderDetailID as idordendetalleorigen, co.orderDate as fechaorden,
        YEAR(co.orderDate) as anioorden, MONTH(co.orderDate) as mesorden,
        DAY(co.orderDate) as diaorden, QUARTER(co.orderDate) as trimestreorden,
        p.productName as nombreproducto, p.productDescription as descripcionproducto,
        pc.categoryName as nombrecategoria, bt.brandName as nombremarca,
        dsi.siteName as nombresitio, dsi.primaryDomainName as dominiositio,
        dsi.marketingFocus as enfoquemarketing, dss.statusName as estadositio,
        dsi.launchDate as fechalanzamientositio, c_orig.countryName as paisorigen,
        c_orig.iso3Code as codigoisopaisorigen, c_dest.countryName as paisdestino,
        c_dest.iso3Code as codigoisopaisdestino, co.personID as idclienteorigen,
        c_dest.countryName as paiscliente, cur.currencyCode as codigomonedalocal,
        cur.currencyName as nombremonedalocal, cur.currencySymbol as simbolomonedalocal,
        COALESCE(co.exchangeRate, 1) as tipocambiousd, cod.quantity as cantidad,
        cod.unitPrice as preciounitariolocal, (cod.unitPrice * cod.quantity) as subtotallocal,
        cod.discountAmount as descuentolocal, cod.taxAmount as impuestolocal,
        co.shippingAmount as costoenviolocal, 
        ((cod.unitPrice * cod.quantity) - cod.discountAmount + cod.taxAmount) as totallinealocal,
        cos.statusName as estadoorden, pps.statusName as estadopago,
        ss.statusName as estadoenvio, pm.methodName as metodopago,
        sh.carrierName as transportista, sh.shippingAddress as direccionenvio,
        inv.availableQuantity as cantidaddisponible, inv.reservedQuantity as cantidadreservada,
        inv.reorderLevel as nivelreorden
    FROM customerOrderDetail cod
    JOIN customerOrder co ON co.customerOrderID = cod.customerOrderID
    JOIN product p ON p.productID = cod.productID
    JOIN productCategory pc ON pc.categoryCode = p.productCategoryCode
    JOIN dynamicSiteInfo dsi ON dsi.dynamicSiteID = co.dynamicSiteID
    JOIN brandTemplate bt ON bt.brandCode = dsi.brandCode
    JOIN dynamicSiteStatus dss ON dss.statusCode = dsi.siteStatusCode
    JOIN country c_dest ON c_dest.countryID = co.customerCountryID
    JOIN currency cur ON cur.currencyID = co.currencyID
    LEFT JOIN country c_orig ON c_orig.countryID = dsi.countryID
    LEFT JOIN orderStatus cos ON cos.statusCode = co.orderStatusCode
    LEFT JOIN paymentTransaction pt ON pt.customerOrderID = co.customerOrderID
    LEFT JOIN paymentMethod pm ON pm.methodCode = pt.methodCode
    LEFT JOIN paymentTransactionStatus pps ON pps.statusCode = pt.paymentStatusCode
    LEFT JOIN shipment sh ON sh.customerOrderID = co.customerOrderID
    LEFT JOIN shipmentStatus ss ON ss.statusCode = sh.shipmentStatusCode
    LEFT JOIN inventory inv ON inv.dynamicSiteID = co.dynamicSiteID AND inv.productID = p.productID
    """
    return pd.read_sql(query, engine)

# ============================================================
# CARGA CORREGIDA
# ============================================================

def load_dw(dw_engine, df: pd.DataFrame):
    df_clean = df.copy()
    
    # IMPORTANTE: Forzamos que los nombres del DataFrame sean 100% minúsculas y sin guiones
    df_clean.columns = [c.lower().replace("_", "") for c in df_clean.columns]
    
    # Filtramos solo las columnas que están en el DDL
    df_clean = df_clean[[c for c in DW_COLUMNS if c in df_clean.columns]]

    # Limpieza de nulos y conversión de tipos
    # Reemplazamos NaN de Pandas por None para que SQL lo entienda como NULL
    final_data = df_clean.where(pd.notnull(df_clean), None)

    try:
        with dw_engine.begin() as conn:
            final_data.to_sql(
                "centroanalisis", # Asegúrate de que sea minúsculas aquí también
                conn,
                if_exists="append",
                index=False,
                method="multi",
                chunksize=50
            )
        print("✅ Carga exitosa en el Data Warehouse.")
    except Exception as e:
        print(f"❌ Error en la carga: {e}")

# ============================================================
# MAIN
# ============================================================

def main():
    eng_eth = make_engine(PG_ETHERIA_URL)
    eng_dyn = make_engine(MYSQL_DYNAMIC_URL)
    eng_dw = make_engine(PG_DW_URL)

    print("Extrayendo datos...")
    df_e = extract_etheria(eng_eth)
    df_d = extract_dynamic(eng_dyn)

    print("Combinando y normalizando...")
    df_final = pd.concat([df_e, df_d], ignore_index=True)

    if FULL_REFRESH:
        print("Vaciando tabla destino...")
        truncate_target(eng_dw)

    load_dw(eng_dw, df_final)

if __name__ == "__main__":
    main()
