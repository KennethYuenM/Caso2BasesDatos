USE dynamicBrandsDB;

DELIMITER $$

DROP PROCEDURE IF EXISTS spSeedFullData $$
CREATE PROCEDURE spSeedFullData()
BEGIN
    -- IDs de monedas
    DECLARE usdCurrencyID BIGINT;
    DECLARE crcCurrencyID BIGINT;
    DECLARE mxnCurrencyID BIGINT;
    DECLARE copCurrencyID BIGINT;
    DECLARE penCurrencyID BIGINT;
    DECLARE gtqCurrencyID BIGINT;

    -- IDs de paises
    DECLARE costaRicaCountryID BIGINT;
    DECLARE mexicoCountryID BIGINT;
    DECLARE colombiaCountryID BIGINT;
    DECLARE peruCountryID BIGINT;
    DECLARE guatemalaCountryID BIGINT;

    -- IDs de personas
    DECLARE adminPersonID BIGINT;
    DECLARE managerPersonID BIGINT;
    DECLARE cust1PersonID BIGINT;
    DECLARE cust2PersonID BIGINT;
    DECLARE cust3PersonID BIGINT;
    DECLARE cust4PersonID BIGINT;
    DECLARE cust5PersonID BIGINT;

    -- IDs de sitios dinamicos (9 sitios)
    DECLARE site1ID BIGINT;
    DECLARE site2ID BIGINT;
    DECLARE site3ID BIGINT;
    DECLARE site4ID BIGINT;
    DECLARE site5ID BIGINT;
    DECLARE site6ID BIGINT;
    DECLARE site7ID BIGINT;
    DECLARE site8ID BIGINT;
    DECLARE site9ID BIGINT;

    -- IDs de productos (reutilizable)
    DECLARE prodID BIGINT;

    -- IDs de ordenes
    DECLARE order1ID BIGINT;
    DECLARE order2ID BIGINT;
    DECLARE order3ID BIGINT;
    DECLARE order4ID BIGINT;
    DECLARE order5ID BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL spLogEtlStep('spSeedFullData', 'MANUAL', 'dynamicBrandsDB', 'ERROR', 0, 0, 'Error durante el seed de datos');
    END;

    START TRANSACTION;

    -- =============================================================
    -- FASE 1: CATALOGOS BASE
    -- =============================================================
    CALL spSeedBaseCatalogs();

    -- =============================================================
    -- FASE 2: MONEDAS (6 monedas)
    -- =============================================================
    CALL spInsertCurrency('USD', 'US Dollar', '$');
    CALL spInsertCurrency('CRC', 'Costa Rican Colon', '₡');
    CALL spInsertCurrency('MXN', 'Mexican Peso', '$');
    CALL spInsertCurrency('COP', 'Colombian Peso', '$');
    CALL spInsertCurrency('PEN', 'Peruvian Sol', 'S/');
    CALL spInsertCurrency('GTQ', 'Guatemalan Quetzal', 'Q');

    SELECT currencyID INTO usdCurrencyID FROM currency WHERE currencyCode = 'USD' LIMIT 1;
    SELECT currencyID INTO crcCurrencyID FROM currency WHERE currencyCode = 'CRC' LIMIT 1;
    SELECT currencyID INTO mxnCurrencyID FROM currency WHERE currencyCode = 'MXN' LIMIT 1;
    SELECT currencyID INTO copCurrencyID FROM currency WHERE currencyCode = 'COP' LIMIT 1;
    SELECT currencyID INTO penCurrencyID FROM currency WHERE currencyCode = 'PEN' LIMIT 1;
    SELECT currencyID INTO gtqCurrencyID FROM currency WHERE currencyCode = 'GTQ' LIMIT 1;

    -- =============================================================
    -- FASE 3: PAISES (5)
    -- =============================================================
    CALL spInsertCountry('Costa Rica', 'CR', 'CRI', crcCurrencyID);
    CALL spInsertCountry('Mexico', 'MX', 'MEX', mxnCurrencyID);
    CALL spInsertCountry('Colombia', 'CO', 'COL', copCurrencyID);
    CALL spInsertCountry('Peru', 'PE', 'PER', penCurrencyID);
    CALL spInsertCountry('Guatemala', 'GT', 'GTM', gtqCurrencyID);

    SELECT countryID INTO costaRicaCountryID FROM country WHERE iso2Code = 'CR' LIMIT 1;
    SELECT countryID INTO mexicoCountryID FROM country WHERE iso2Code = 'MX' LIMIT 1;
    SELECT countryID INTO colombiaCountryID FROM country WHERE iso2Code = 'CO' LIMIT 1;
    SELECT countryID INTO peruCountryID FROM country WHERE iso2Code = 'PE' LIMIT 1;
    SELECT countryID INTO guatemalaCountryID FROM country WHERE iso2Code = 'GT' LIMIT 1;

    -- =============================================================
    -- FASE 4: TIPOS DE CAMBIO (USD vs cada moneda local)
    -- =============================================================
    CALL spInsertCurrentExchangeRate(1, usdCurrencyID, crcCurrencyID, 510.500000, 515.750000, 'Central Bank CR');
    CALL spInsertCurrentExchangeRate(2, usdCurrencyID, mxnCurrencyID, 17.150000, 17.350000, 'Banxico');
    CALL spInsertCurrentExchangeRate(3, usdCurrencyID, copCurrencyID, 3950.000000, 3985.000000, 'Banco Republica');
    CALL spInsertCurrentExchangeRate(4, usdCurrencyID, penCurrencyID, 3.720000, 3.760000, 'BCRP');
    CALL spInsertCurrentExchangeRate(5, usdCurrencyID, gtqCurrencyID, 7.800000, 7.850000, 'Banguat');

    -- =============================================================
    -- FASE 5: BRAND TEMPLATES (3 marcas)
    -- =============================================================
    CALL spInsertBrandTemplate('PUREAURA', 'PureAura', 'https://example.com/pureaura-logo.png', 'Natural wellness for daily life', 'Health-conscious consumers 25-45');
    CALL spInsertBrandTemplate('TERRAVERDE', 'TerraVerde', 'https://example.com/terraverde-logo.png', 'Organic food from earth to table', 'Organic food enthusiasts 30-55');
    CALL spInsertBrandTemplate('AQUAVITA', 'AquaVita', 'https://example.com/aquavita-logo.png', 'Refreshing natural beverages', 'Active lifestyle consumers 20-40');

    -- =============================================================
    -- FASE 6: PERSONAS (admin, manager, 5 clientes)
    -- =============================================================
    CALL spInsertPeople('PERS-ADMIN-001', costaRicaCountryID, 'admin@dynamicbrands.com', 'Carlos', 'Mendez', 'hash_admin_001', 'SYSTEM_USER', adminPersonID);
    CALL spInsertSystemUser(adminPersonID, 'USR-ADMIN-001', 'ADMIN');

    CALL spInsertPeople('PERS-MGR-001', mexicoCountryID, 'manager@dynamicbrands.com', 'Ana', 'Lopez', 'hash_mgr_001', 'SYSTEM_USER', managerPersonID);
    CALL spInsertSystemUser(managerPersonID, 'USR-MGR-001', 'MANAGER');

    CALL spInsertPeople('PERS-CUST-001', costaRicaCountryID, 'laura.ramirez@email.com', 'Laura', 'Ramirez', 'hash_cust_001', 'CUSTOMER', cust1PersonID);
    CALL spInsertPeople('PERS-CUST-002', mexicoCountryID, 'diego.hernandez@email.com', 'Diego', 'Hernandez', 'hash_cust_002', 'CUSTOMER', cust2PersonID);
    CALL spInsertPeople('PERS-CUST-003', colombiaCountryID, 'valentina.castro@email.com', 'Valentina', 'Castro', 'hash_cust_003', 'CUSTOMER', cust3PersonID);
    CALL spInsertPeople('PERS-CUST-004', peruCountryID, 'miguel.flores@email.com', 'Miguel', 'Flores', 'hash_cust_004', 'CUSTOMER', cust4PersonID);
    CALL spInsertPeople('PERS-CUST-005', guatemalaCountryID, 'sofia.morales@email.com', 'Sofia', 'Morales', 'hash_cust_005', 'CUSTOMER', cust5PersonID);

    -- =============================================================
    -- FASE 7: SITIOS DINAMICOS (9 sitios, distribuidos entre paises y marcas)
    -- =============================================================
    -- PureAura: Costa Rica, Mexico, Colombia
    CALL spInsertDynamicSite('SITE-PA-CR', 'PureAura Costa Rica', 'PUREAURA', costaRicaCountryID, crcCurrencyID, 'ACTIVE', 'pureaura.cr', 'Natural health oils', 'Warm and trustworthy', JSON_OBJECT('primaryColor', '#2E7D32', 'style', 'natural'), 'Dynamic Brands CR', 'https://example.com/pa-cr-logo.png', site1ID);
    CALL spInsertDynamicSite('SITE-PA-MX', 'PureAura Mexico', 'PUREAURA', mexicoCountryID, mxnCurrencyID, 'ACTIVE', 'pureaura.mx', 'Wellness and beauty', 'Fresh and modern', JSON_OBJECT('primaryColor', '#1B5E20', 'style', 'modern'), 'Dynamic Brands MX', 'https://example.com/pa-mx-logo.png', site2ID);
    CALL spInsertDynamicSite('SITE-PA-CO', 'PureAura Colombia', 'PUREAURA', colombiaCountryID, copCurrencyID, 'ACTIVE', 'pureaura.co', 'Essential oils and soaps', 'Elegant and natural', JSON_OBJECT('primaryColor', '#388E3C', 'style', 'elegant'), 'Dynamic Brands CO', 'https://example.com/pa-co-logo.png', site3ID);

    -- TerraVerde: Peru, Guatemala, Costa Rica
    CALL spInsertDynamicSite('SITE-TV-PE', 'TerraVerde Peru', 'TERRAVERDE', peruCountryID, penCurrencyID, 'ACTIVE', 'terraverde.pe', 'Organic superfoods', 'Earthy and authentic', JSON_OBJECT('primaryColor', '#795548', 'style', 'earthy'), 'Dynamic Brands PE', 'https://example.com/tv-pe-logo.png', site4ID);
    CALL spInsertDynamicSite('SITE-TV-GT', 'TerraVerde Guatemala', 'TERRAVERDE', guatemalaCountryID, gtqCurrencyID, 'ACTIVE', 'terraverde.gt', 'Traditional organic food', 'Rustic and warm', JSON_OBJECT('primaryColor', '#6D4C41', 'style', 'rustic'), 'Dynamic Brands GT', 'https://example.com/tv-gt-logo.png', site5ID);
    CALL spInsertDynamicSite('SITE-TV-CR', 'TerraVerde Costa Rica', 'TERRAVERDE', costaRicaCountryID, crcCurrencyID, 'ACTIVE', 'terraverde.cr', 'Farm to table organics', 'Pure and simple', JSON_OBJECT('primaryColor', '#8D6E63', 'style', 'simple'), 'Dynamic Brands CR', 'https://example.com/tv-cr-logo.png', site6ID);

    -- AquaVita: Mexico, Colombia, Peru
    CALL spInsertDynamicSite('SITE-AV-MX', 'AquaVita Mexico', 'AQUAVITA', mexicoCountryID, mxnCurrencyID, 'ACTIVE', 'aquavita.mx', 'Natural refreshing drinks', 'Vibrant and energetic', JSON_OBJECT('primaryColor', '#0288D1', 'style', 'vibrant'), 'Dynamic Brands MX', 'https://example.com/av-mx-logo.png', site7ID);
    CALL spInsertDynamicSite('SITE-AV-CO', 'AquaVita Colombia', 'AQUAVITA', colombiaCountryID, copCurrencyID, 'ACTIVE', 'aquavita.co', 'Tropical beverages', 'Tropical and fun', JSON_OBJECT('primaryColor', '#0277BD', 'style', 'tropical'), 'Dynamic Brands CO', 'https://example.com/av-co-logo.png', site8ID);
    CALL spInsertDynamicSite('SITE-AV-PE', 'AquaVita Peru', 'AQUAVITA', peruCountryID, penCurrencyID, 'ACTIVE', 'aquavita.pe', 'Andean natural drinks', 'Bold and authentic', JSON_OBJECT('primaryColor', '#01579B', 'style', 'bold'), 'Dynamic Brands PE', 'https://example.com/av-pe-logo.png', site9ID);

    -- =============================================================
    -- FASE 7.1: METRICAS DE SITIOS (algunas metricas por sitio)
    -- =============================================================
    -- Site 1: PureAura CR
    CALL spInsertDynamicSiteMetric(site1ID, 'VISITS', CURRENT_DATE, 1200);
    CALL spInsertDynamicSiteMetric(site1ID, 'SESSIONS', CURRENT_DATE, 950);
    CALL spInsertDynamicSiteMetric(site1ID, 'PURCHASES', CURRENT_DATE, 48);
    CALL spInsertDynamicSiteMetric(site1ID, 'CONVERSION_RATE', CURRENT_DATE, 0.05);
    CALL spInsertDynamicSiteMetric(site1ID, 'REVENUE', CURRENT_DATE, 685000.00);
    -- Site 2: PureAura MX
    CALL spInsertDynamicSiteMetric(site2ID, 'VISITS', CURRENT_DATE, 2500);
    CALL spInsertDynamicSiteMetric(site2ID, 'SESSIONS', CURRENT_DATE, 1800);
    CALL spInsertDynamicSiteMetric(site2ID, 'PURCHASES', CURRENT_DATE, 95);
    CALL spInsertDynamicSiteMetric(site2ID, 'CONVERSION_RATE', CURRENT_DATE, 0.053);
    -- Site 3: PureAura CO
    CALL spInsertDynamicSiteMetric(site3ID, 'VISITS', CURRENT_DATE, 1800);
    CALL spInsertDynamicSiteMetric(site3ID, 'SESSIONS', CURRENT_DATE, 1400);
    CALL spInsertDynamicSiteMetric(site3ID, 'PURCHASES', CURRENT_DATE, 60);
    -- Site 4: TerraVerde PE
    CALL spInsertDynamicSiteMetric(site4ID, 'VISITS', CURRENT_DATE, 900);
    CALL spInsertDynamicSiteMetric(site4ID, 'PURCHASES', CURRENT_DATE, 35);
    -- Site 5: TerraVerde GT
    CALL spInsertDynamicSiteMetric(site5ID, 'VISITS', CURRENT_DATE, 700);
    CALL spInsertDynamicSiteMetric(site5ID, 'PURCHASES', CURRENT_DATE, 22);
    -- Site 6: TerraVerde CR
    CALL spInsertDynamicSiteMetric(site6ID, 'VISITS', CURRENT_DATE, 1100);
    CALL spInsertDynamicSiteMetric(site6ID, 'PURCHASES', CURRENT_DATE, 42);
    -- Site 7: AquaVita MX
    CALL spInsertDynamicSiteMetric(site7ID, 'VISITS', CURRENT_DATE, 3200);
    CALL spInsertDynamicSiteMetric(site7ID, 'PURCHASES', CURRENT_DATE, 150);
    -- Site 8: AquaVita CO
    CALL spInsertDynamicSiteMetric(site8ID, 'VISITS', CURRENT_DATE, 2100);
    CALL spInsertDynamicSiteMetric(site8ID, 'PURCHASES', CURRENT_DATE, 85);
    -- Site 9: AquaVita PE
    CALL spInsertDynamicSiteMetric(site9ID, 'VISITS', CURRENT_DATE, 1500);
    CALL spInsertDynamicSiteMetric(site9ID, 'PURCHASES', CURRENT_DATE, 55);

    -- =============================================================
    -- FASE 8: PRODUCTOS (100 productos distribuidos entre 9 sitios)
    -- Cada producto: spInsertProduct + spInsertProductPrice + spInsertProductImage
    -- =============================================================

    -- ---- SITE 1: PureAura Costa Rica (12 productos: OIL, SOAP, BEAUTY) ----
    CALL spInsertProduct('PROD-001', site1ID, 'OIL', 'Aceite Esencial de Lavanda', 'Aceite esencial puro de lavanda para aromaterapia', 'SKU-001', usdCurrencyID, 12.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 6375.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-001.png', 1, TRUE);

    CALL spInsertProduct('PROD-002', site1ID, 'OIL', 'Aceite de Argan Premium', 'Aceite de argan puro para cabello y piel', 'SKU-002', usdCurrencyID, 18.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 9180.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-002.png', 1, TRUE);

    CALL spInsertProduct('PROD-003', site1ID, 'OIL', 'Aceite de Coco Organico', 'Aceite de coco virgen extra organico', 'SKU-003', usdCurrencyID, 9.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 5095.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-003.png', 1, TRUE);

    CALL spInsertProduct('PROD-004', site1ID, 'SOAP', 'Jabon de Avena y Miel', 'Jabon artesanal de avena y miel natural', 'SKU-004', usdCurrencyID, 6.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 3315.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-004.png', 1, TRUE);

    CALL spInsertProduct('PROD-005', site1ID, 'SOAP', 'Jabon de Carbon Activado', 'Jabon facial de carbon activado purificante', 'SKU-005', usdCurrencyID, 7.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 4075.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-005.png', 1, TRUE);

    CALL spInsertProduct('PROD-006', site1ID, 'SOAP', 'Jabon de Aloe Vera', 'Jabon hidratante de aloe vera natural', 'SKU-006', usdCurrencyID, 5.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 3055.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-006.png', 1, TRUE);

    CALL spInsertProduct('PROD-007', site1ID, 'BEAUTY', 'Crema Facial Antioxidante', 'Crema facial con vitamina C y E', 'SKU-007', usdCurrencyID, 22.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 11220.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-007.png', 1, TRUE);

    CALL spInsertProduct('PROD-008', site1ID, 'BEAUTY', 'Serum de Acido Hialuronico', 'Serum hidratante de acido hialuronico', 'SKU-008', usdCurrencyID, 28.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 14535.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-008.png', 1, TRUE);

    CALL spInsertProduct('PROD-009', site1ID, 'BEAUTY', 'Mascarilla de Arcilla Verde', 'Mascarilla purificante de arcilla verde', 'SKU-009', usdCurrencyID, 15.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 7650.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-009.png', 1, TRUE);

    CALL spInsertProduct('PROD-010', site1ID, 'OIL', 'Aceite de Rosa Mosqueta', 'Aceite regenerador de rosa mosqueta', 'SKU-010', usdCurrencyID, 16.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 8160.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-010.png', 1, TRUE);

    CALL spInsertProduct('PROD-011', site1ID, 'BEAUTY', 'Balsamo Labial de Menta', 'Balsamo labial natural de menta', 'SKU-011', usdCurrencyID, 4.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 2295.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-011.png', 1, TRUE);

    CALL spInsertProduct('PROD-012', site1ID, 'SOAP', 'Jabon Exfoliante de Cafe', 'Jabon exfoliante artesanal con cafe', 'SKU-012', usdCurrencyID, 7.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site1ID, crcCurrencyID, 3825.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-012.png', 1, TRUE);

    -- ---- SITE 2: PureAura Mexico (11 productos) ----
    CALL spInsertProduct('PROD-013', site2ID, 'OIL', 'Aceite de Jojoba Puro', 'Aceite de jojoba para piel y cabello', 'SKU-013', usdCurrencyID, 14.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 240.10, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-013.png', 1, TRUE);

    CALL spInsertProduct('PROD-014', site2ID, 'OIL', 'Aceite Esencial de Eucalipto', 'Aceite esencial de eucalipto para respiracion', 'SKU-014', usdCurrencyID, 10.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 180.07, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-014.png', 1, TRUE);

    CALL spInsertProduct('PROD-015', site2ID, 'SOAP', 'Jabon de Calendula', 'Jabon suave de calendula para piel sensible', 'SKU-015', usdCurrencyID, 6.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 119.88, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-015.png', 1, TRUE);

    CALL spInsertProduct('PROD-016', site2ID, 'SOAP', 'Jabon de Romero', 'Jabon artesanal de romero estimulante', 'SKU-016', usdCurrencyID, 6.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 111.47, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-016.png', 1, TRUE);

    CALL spInsertProduct('PROD-017', site2ID, 'BEAUTY', 'Crema Corporal de Karite', 'Crema hidratante corporal de manteca de karite', 'SKU-017', usdCurrencyID, 19.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 342.82, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-017.png', 1, TRUE);

    CALL spInsertProduct('PROD-018', site2ID, 'BEAUTY', 'Tonico Facial de Hamamelis', 'Tonico astringente natural de hamamelis', 'SKU-018', usdCurrencyID, 13.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 231.52, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-018.png', 1, TRUE);

    CALL spInsertProduct('PROD-019', site2ID, 'OIL', 'Aceite de Almendras Dulces', 'Aceite hidratante de almendras dulces', 'SKU-019', usdCurrencyID, 11.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 188.65, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-019.png', 1, TRUE);

    CALL spInsertProduct('PROD-020', site2ID, 'BEAUTY', 'Gel de Sabila Puro', 'Gel de aloe vera 100% natural', 'SKU-020', usdCurrencyID, 8.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 154.19, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-020.png', 1, TRUE);

    CALL spInsertProduct('PROD-021', site2ID, 'SOAP', 'Jabon de Manzanilla', 'Jabon calmante de manzanilla para bebe', 'SKU-021', usdCurrencyID, 5.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 94.32, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-021.png', 1, TRUE);

    CALL spInsertProduct('PROD-022', site2ID, 'OIL', 'Aceite Esencial de Menta', 'Aceite esencial de menta refrescante', 'SKU-022', usdCurrencyID, 9.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 162.92, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-022.png', 1, TRUE);

    CALL spInsertProduct('PROD-023', site2ID, 'BEAUTY', 'Exfoliante Corporal de Sal Marina', 'Exfoliante natural de sal marina y aceites', 'SKU-023', usdCurrencyID, 16.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site2ID, mxnCurrencyID, 282.97, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-023.png', 1, TRUE);

    -- ---- SITE 3: PureAura Colombia (11 productos) ----
    CALL spInsertProduct('PROD-024', site3ID, 'OIL', 'Aceite de Aguacate Prensado en Frio', 'Aceite nutritivo de aguacate para piel', 'SKU-024', usdCurrencyID, 13.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 51350.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-024.png', 1, TRUE);

    CALL spInsertProduct('PROD-025', site3ID, 'OIL', 'Aceite Esencial de Naranja', 'Aceite esencial de naranja dulce energizante', 'SKU-025', usdCurrencyID, 8.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 33575.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-025.png', 1, TRUE);

    CALL spInsertProduct('PROD-026', site3ID, 'SOAP', 'Jabon de Cacao y Vainilla', 'Jabon artesanal de cacao y vainilla', 'SKU-026', usdCurrencyID, 7.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 31560.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-026.png', 1, TRUE);

    CALL spInsertProduct('PROD-027', site3ID, 'SOAP', 'Jabon de Arcilla Blanca', 'Jabon purificante de arcilla blanca', 'SKU-027', usdCurrencyID, 6.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 25675.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-027.png', 1, TRUE);

    CALL spInsertProduct('PROD-028', site3ID, 'BEAUTY', 'Aceite Corporal de Coco y Vainilla', 'Aceite corporal hidratante tropical', 'SKU-028', usdCurrencyID, 17.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 69125.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-028.png', 1, TRUE);

    CALL spInsertProduct('PROD-029', site3ID, 'BEAUTY', 'Crema de Manos de Rosa', 'Crema reparadora de manos con rosa', 'SKU-029', usdCurrencyID, 9.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 39460.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-029.png', 1, TRUE);

    CALL spInsertProduct('PROD-030', site3ID, 'OIL', 'Aceite Esencial de Canela', 'Aceite esencial de canela reconfortante', 'SKU-030', usdCurrencyID, 10.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 39500.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-030.png', 1, TRUE);

    CALL spInsertProduct('PROD-031', site3ID, 'SOAP', 'Jabon de Leche de Cabra', 'Jabon hidratante de leche de cabra', 'SKU-031', usdCurrencyID, 8.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 33575.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-031.png', 1, TRUE);

    CALL spInsertProduct('PROD-032', site3ID, 'BEAUTY', 'Protector Solar Natural SPF30', 'Protector solar con ingredientes naturales', 'SKU-032', usdCurrencyID, 24.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 94800.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-032.png', 1, TRUE);

    CALL spInsertProduct('PROD-033', site3ID, 'BEAUTY', 'Desodorante Natural de Coco', 'Desodorante sin aluminio de coco', 'SKU-033', usdCurrencyID, 8.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 31600.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-033.png', 1, TRUE);

    CALL spInsertProduct('PROD-034', site3ID, 'OIL', 'Aceite de Semilla de Uva', 'Aceite ligero de semilla de uva para piel', 'SKU-034', usdCurrencyID, 11.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site3ID, copCurrencyID, 45425.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-034.png', 1, TRUE);

    -- ---- SITE 4: TerraVerde Peru (11 productos: FOOD, BEVERAGE) ----
    CALL spInsertProduct('PROD-035', site4ID, 'FOOD', 'Quinoa Organica Premium', 'Quinoa blanca organica de los Andes', 'SKU-035', usdCurrencyID, 8.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 31.62, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-035.png', 1, TRUE);

    CALL spInsertProduct('PROD-036', site4ID, 'FOOD', 'Maca en Polvo Gelatinizada', 'Maca peruana gelatinizada en polvo', 'SKU-036', usdCurrencyID, 14.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 52.08, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-036.png', 1, TRUE);

    CALL spInsertProduct('PROD-037', site4ID, 'FOOD', 'Cacao en Polvo Crudo', 'Cacao crudo organico en polvo', 'SKU-037', usdCurrencyID, 12.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 44.64, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-037.png', 1, TRUE);

    CALL spInsertProduct('PROD-038', site4ID, 'FOOD', 'Semillas de Chia Organicas', 'Semillas de chia premium organicas', 'SKU-038', usdCurrencyID, 7.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 27.90, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-038.png', 1, TRUE);

    CALL spInsertProduct('PROD-039', site4ID, 'FOOD', 'Granola Artesanal con Frutas', 'Granola hecha a mano con frutas secas', 'SKU-039', usdCurrencyID, 9.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 37.16, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-039.png', 1, TRUE);

    CALL spInsertProduct('PROD-040', site4ID, 'FOOD', 'Miel Organica de Abeja', 'Miel pura organica de abejas silvestres', 'SKU-040', usdCurrencyID, 11.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 42.78, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-040.png', 1, TRUE);

    CALL spInsertProduct('PROD-041', site4ID, 'BEVERAGE', 'Te de Munia Andino', 'Infusion de hierbas andinas relajante', 'SKU-041', usdCurrencyID, 5.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 22.28, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-041.png', 1, TRUE);

    CALL spInsertProduct('PROD-042', site4ID, 'BEVERAGE', 'Chicha Morada Concentrada', 'Concentrado natural de chicha morada', 'SKU-042', usdCurrencyID, 6.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 24.18, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-042.png', 1, TRUE);

    CALL spInsertProduct('PROD-043', site4ID, 'FOOD', 'Lucuma en Polvo', 'Polvo de lucuma peruana para smoothies', 'SKU-043', usdCurrencyID, 13.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 50.22, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-043.png', 1, TRUE);

    CALL spInsertProduct('PROD-044', site4ID, 'FOOD', 'Aceite de Sacha Inchi', 'Aceite omega-3 de sacha inchi peruano', 'SKU-044', usdCurrencyID, 18.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 66.96, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-044.png', 1, TRUE);

    CALL spInsertProduct('PROD-045', site4ID, 'BEVERAGE', 'Emoliente en Sobre', 'Mezcla de emoliente peruano tradicional', 'SKU-045', usdCurrencyID, 3.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site4ID, penCurrencyID, 14.84, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-045.png', 1, TRUE);

    -- ---- SITE 5: TerraVerde Guatemala (11 productos) ----
    CALL spInsertProduct('PROD-046', site5ID, 'FOOD', 'Cafe Organico de Antigua', 'Cafe de altura organico de Antigua Guatemala', 'SKU-046', usdCurrencyID, 15.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 117.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-046.png', 1, TRUE);

    CALL spInsertProduct('PROD-047', site5ID, 'FOOD', 'Chocolate Artesanal 70%', 'Chocolate oscuro artesanal 70% cacao', 'SKU-047', usdCurrencyID, 8.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 70.12, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-047.png', 1, TRUE);

    CALL spInsertProduct('PROD-048', site5ID, 'FOOD', 'Cardamomo Premium', 'Cardamomo entero de Alta Verapaz', 'SKU-048', usdCurrencyID, 12.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 97.50, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-048.png', 1, TRUE);

    CALL spInsertProduct('PROD-049', site5ID, 'FOOD', 'Pepitoria Tostada', 'Semilla de ayote tostada tradicional', 'SKU-049', usdCurrencyID, 6.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 46.80, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-049.png', 1, TRUE);

    CALL spInsertProduct('PROD-050', site5ID, 'FOOD', 'Miel de Abeja Melipona', 'Miel de abeja nativa melipona', 'SKU-050', usdCurrencyID, 20.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 156.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-050.png', 1, TRUE);

    CALL spInsertProduct('PROD-051', site5ID, 'BEVERAGE', 'Atol de Elote Instantaneo', 'Mezcla para atol de elote tradicional', 'SKU-051', usdCurrencyID, 4.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 35.10, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-051.png', 1, TRUE);

    CALL spInsertProduct('PROD-052', site5ID, 'BEVERAGE', 'Rosa de Jamaica Seca', 'Flor de jamaica seca para infusiones', 'SKU-052', usdCurrencyID, 5.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 46.72, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-052.png', 1, TRUE);

    CALL spInsertProduct('PROD-053', site5ID, 'FOOD', 'Achiote en Pasta', 'Pasta de achiote para cocina tradicional', 'SKU-053', usdCurrencyID, 3.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 27.30, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-053.png', 1, TRUE);

    CALL spInsertProduct('PROD-054', site5ID, 'FOOD', 'Macadamia Tostada con Sal', 'Nuez de macadamia guatemalteca tostada', 'SKU-054', usdCurrencyID, 14.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 109.20, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-054.png', 1, TRUE);

    CALL spInsertProduct('PROD-055', site5ID, 'FOOD', 'Panela Granulada Organica', 'Panela organica granulada artesanal', 'SKU-055', usdCurrencyID, 5.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 42.90, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-055.png', 1, TRUE);

    CALL spInsertProduct('PROD-056', site5ID, 'BEVERAGE', 'Horchata de Morro', 'Bebida tradicional de semilla de morro', 'SKU-056', usdCurrencyID, 4.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site5ID, gtqCurrencyID, 38.92, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-056.png', 1, TRUE);

    -- ---- SITE 6: TerraVerde Costa Rica (11 productos) ----
    CALL spInsertProduct('PROD-057', site6ID, 'FOOD', 'Cafe de Tarrazu Organico', 'Cafe gourmet organico de Tarrazu', 'SKU-057', usdCurrencyID, 16.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 8160.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-057.png', 1, TRUE);

    CALL spInsertProduct('PROD-058', site6ID, 'FOOD', 'Salsa Lizano Artesanal', 'Salsa tipo Lizano hecha a mano', 'SKU-058', usdCurrencyID, 5.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 2805.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-058.png', 1, TRUE);

    CALL spInsertProduct('PROD-059', site6ID, 'FOOD', 'Mermelada de Guayaba', 'Mermelada artesanal de guayaba', 'SKU-059', usdCurrencyID, 6.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 3565.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-059.png', 1, TRUE);

    CALL spInsertProduct('PROD-060', site6ID, 'FOOD', 'Cacao en Barra Puro', 'Barra de cacao puro costarricense', 'SKU-060', usdCurrencyID, 9.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 4845.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-060.png', 1, TRUE);

    CALL spInsertProduct('PROD-061', site6ID, 'FOOD', 'Coconut Chips Deshidratado', 'Chips de coco deshidratado natural', 'SKU-061', usdCurrencyID, 4.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 2545.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-061.png', 1, TRUE);

    CALL spInsertProduct('PROD-062', site6ID, 'BEVERAGE', 'Agua de Pipa Embotellada', 'Agua de pipa natural embotellada', 'SKU-062', usdCurrencyID, 3.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 1785.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-062.png', 1, TRUE);

    CALL spInsertProduct('PROD-063', site6ID, 'BEVERAGE', 'Jugo de Cas Natural', 'Jugo de cas natural concentrado', 'SKU-063', usdCurrencyID, 4.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 2295.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-063.png', 1, TRUE);

    CALL spInsertProduct('PROD-064', site6ID, 'FOOD', 'Tapa de Dulce Organica', 'Tapa de dulce de cana organica', 'SKU-064', usdCurrencyID, 3.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 2035.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-064.png', 1, TRUE);

    CALL spInsertProduct('PROD-065', site6ID, 'FOOD', 'Pimienta de Jamaica Molida', 'Pimienta gorda molida de la zona sur', 'SKU-065', usdCurrencyID, 5.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 2550.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-065.png', 1, TRUE);

    CALL spInsertProduct('PROD-066', site6ID, 'BEVERAGE', 'Te de Hierba Buena', 'Infusion de hierba buena natural', 'SKU-066', usdCurrencyID, 4.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 2040.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-066.png', 1, TRUE);

    CALL spInsertProduct('PROD-067', site6ID, 'FOOD', 'Mantequilla de Mani Artesanal', 'Mantequilla de mani sin azucar anadida', 'SKU-067', usdCurrencyID, 7.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site6ID, crcCurrencyID, 3825.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-067.png', 1, TRUE);

    -- ---- SITE 7: AquaVita Mexico (11 productos: BEVERAGE) ----
    CALL spInsertProduct('PROD-068', site7ID, 'BEVERAGE', 'Agua de Horchata Natural', 'Agua de horchata de arroz tradicional', 'SKU-068', usdCurrencyID, 4.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 77.17, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-068.png', 1, TRUE);

    CALL spInsertProduct('PROD-069', site7ID, 'BEVERAGE', 'Jugo Verde Detox', 'Jugo verde prensado en frio detox', 'SKU-069', usdCurrencyID, 6.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 119.88, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-069.png', 1, TRUE);

    CALL spInsertProduct('PROD-070', site7ID, 'BEVERAGE', 'Agua de Tamarindo', 'Agua fresca de tamarindo natural', 'SKU-070', usdCurrencyID, 3.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 68.43, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-070.png', 1, TRUE);

    CALL spInsertProduct('PROD-071', site7ID, 'BEVERAGE', 'Kombucha de Jengibre', 'Kombucha artesanal de jengibre', 'SKU-071', usdCurrencyID, 5.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 94.32, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-071.png', 1, TRUE);

    CALL spInsertProduct('PROD-072', site7ID, 'BEVERAGE', 'Tepache Artesanal', 'Tepache fermentado de pina artesanal', 'SKU-072', usdCurrencyID, 4.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 85.58, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-072.png', 1, TRUE);

    CALL spInsertProduct('PROD-073', site7ID, 'BEVERAGE', 'Agua de Jamaica Premium', 'Agua de jamaica con flor seleccionada', 'SKU-073', usdCurrencyID, 4.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 68.60, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-073.png', 1, TRUE);

    CALL spInsertProduct('PROD-074', site7ID, 'BEVERAGE', 'Smoothie de Mango y Chia', 'Smoothie natural de mango con chia', 'SKU-074', usdCurrencyID, 5.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 102.73, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-074.png', 1, TRUE);

    CALL spInsertProduct('PROD-075', site7ID, 'BEVERAGE', 'Limonada con Chia', 'Limonada natural con semillas de chia', 'SKU-075', usdCurrencyID, 3.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 60.02, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-075.png', 1, TRUE);

    CALL spInsertProduct('PROD-076', site7ID, 'BEVERAGE', 'Te Matcha Organico', 'Te matcha japones grado ceremonial', 'SKU-076', usdCurrencyID, 18.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 308.70, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-076.png', 1, TRUE);

    CALL spInsertProduct('PROD-077', site7ID, 'BEVERAGE', 'Agua de Coco Natural', 'Agua de coco embotellada sin azucar', 'SKU-077', usdCurrencyID, 3.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 68.43, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-077.png', 1, TRUE);

    CALL spInsertProduct('PROD-078', site7ID, 'BEVERAGE', 'Jugo de Nopal y Toronja', 'Jugo natural de nopal con toronja', 'SKU-078', usdCurrencyID, 4.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site7ID, mxnCurrencyID, 77.17, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-078.png', 1, TRUE);

    -- ---- SITE 8: AquaVita Colombia (11 productos) ----
    CALL spInsertProduct('PROD-079', site8ID, 'BEVERAGE', 'Jugo de Lulo Natural', 'Jugo de lulo colombiano natural', 'SKU-079', usdCurrencyID, 4.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 17775.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-079.png', 1, TRUE);

    CALL spInsertProduct('PROD-080', site8ID, 'BEVERAGE', 'Jugo de Maracuya Concentrado', 'Concentrado de maracuya colombiana', 'SKU-080', usdCurrencyID, 5.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 21725.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-080.png', 1, TRUE);

    CALL spInsertProduct('PROD-081', site8ID, 'BEVERAGE', 'Agua de Panela con Limon', 'Agua de panela tradicional con limon', 'SKU-081', usdCurrencyID, 3.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 13825.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-081.png', 1, TRUE);

    CALL spInsertProduct('PROD-082', site8ID, 'BEVERAGE', 'Jugo de Guanabana', 'Jugo natural de guanabana', 'SKU-082', usdCurrencyID, 4.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 19710.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-082.png', 1, TRUE);

    CALL spInsertProduct('PROD-083', site8ID, 'BEVERAGE', 'Jugo de Borojó Energizante', 'Jugo de borojo del Pacifico colombiano', 'SKU-083', usdCurrencyID, 6.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 25675.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-083.png', 1, TRUE);

    CALL spInsertProduct('PROD-084', site8ID, 'BEVERAGE', 'Avena Colombiana', 'Bebida de avena estilo colombiano', 'SKU-084', usdCurrencyID, 3.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 15760.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-084.png', 1, TRUE);

    CALL spInsertProduct('PROD-085', site8ID, 'BEVERAGE', 'Jugo de Mora Andina', 'Jugo de mora de castilla andina', 'SKU-085', usdCurrencyID, 4.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 17775.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-085.png', 1, TRUE);

    CALL spInsertProduct('PROD-086', site8ID, 'BEVERAGE', 'Jugo de Mango Premium', 'Jugo de mango maduro seleccionado', 'SKU-086', usdCurrencyID, 4.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 15800.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-086.png', 1, TRUE);

    CALL spInsertProduct('PROD-087', site8ID, 'BEVERAGE', 'Limonada de Coco', 'Limonada cremosa con leche de coco', 'SKU-087', usdCurrencyID, 5.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 19750.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-087.png', 1, TRUE);

    CALL spInsertProduct('PROD-088', site8ID, 'BEVERAGE', 'Te de Coca Andino', 'Infusion de hoja de coca tradicional', 'SKU-088', usdCurrencyID, 6.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 23700.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-088.png', 1, TRUE);

    CALL spInsertProduct('PROD-089', site8ID, 'BEVERAGE', 'Jugo de Tomate de Arbol', 'Jugo natural de tomate de arbol', 'SKU-089', usdCurrencyID, 4.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site8ID, copCurrencyID, 17775.00, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-089.png', 1, TRUE);

    -- ---- SITE 9: AquaVita Peru (11 productos) ----
    CALL spInsertProduct('PROD-090', site9ID, 'BEVERAGE', 'Jugo de Camu Camu', 'Jugo de camu camu alto en vitamina C', 'SKU-090', usdCurrencyID, 7.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 27.90, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-090.png', 1, TRUE);

    CALL spInsertProduct('PROD-091', site9ID, 'BEVERAGE', 'Chicha de Jora Artesanal', 'Chicha de jora fermentada artesanal', 'SKU-091', usdCurrencyID, 5.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 20.46, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-091.png', 1, TRUE);

    CALL spInsertProduct('PROD-092', site9ID, 'BEVERAGE', 'Jugo de Aguaymanto', 'Jugo natural de aguaymanto peruano', 'SKU-092', usdCurrencyID, 6.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 22.32, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-092.png', 1, TRUE);

    CALL spInsertProduct('PROD-093', site9ID, 'BEVERAGE', 'Mate de Coca en Sobre', 'Infusion de coca en sobres individuales', 'SKU-093', usdCurrencyID, 4.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 14.88, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-093.png', 1, TRUE);

    CALL spInsertProduct('PROD-094', site9ID, 'BEVERAGE', 'Refresco de Maracuya', 'Refresco natural de maracuya peruana', 'SKU-094', usdCurrencyID, 3.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 13.02, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-094.png', 1, TRUE);

    CALL spInsertProduct('PROD-095', site9ID, 'BEVERAGE', 'Jugo de Lucuma', 'Jugo cremoso de lucuma peruana', 'SKU-095', usdCurrencyID, 5.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 22.28, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-095.png', 1, TRUE);

    CALL spInsertProduct('PROD-096', site9ID, 'BEVERAGE', 'Agua de Kiwicha', 'Bebida nutritiva de kiwicha andina', 'SKU-096', usdCurrencyID, 4.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 16.74, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-096.png', 1, TRUE);

    CALL spInsertProduct('PROD-097', site9ID, 'BEVERAGE', 'Jugo de Papaya Arequipena', 'Jugo de papaya de Arequipa', 'SKU-097', usdCurrencyID, 3.99, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 14.84, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-097.png', 1, TRUE);

    CALL spInsertProduct('PROD-098', site9ID, 'BEVERAGE', 'Infusion de Una de Gato', 'Infusion medicinal de una de gato', 'SKU-098', usdCurrencyID, 6.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 24.18, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-098.png', 1, TRUE);

    CALL spInsertProduct('PROD-099', site9ID, 'BEVERAGE', 'Leche de Quinua', 'Bebida vegetal de quinua organica', 'SKU-099', usdCurrencyID, 5.00, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 18.60, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-099.png', 1, TRUE);

    CALL spInsertProduct('PROD-100', site9ID, 'BEVERAGE', 'Chicha Morada Lista para Beber', 'Chicha morada embotellada lista para beber', 'SKU-100', usdCurrencyID, 3.50, adminPersonID, prodID);
    CALL spInsertProductPrice(prodID, site9ID, penCurrencyID, 13.02, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(prodID, 'MAIN', 'https://example.com/img/prod-100.png', 1, TRUE);

    -- =============================================================
    -- FASE 9: INVENTARIO (un registro por producto en su sitio)
    -- Se hace para una seleccion representativa de productos
    -- =============================================================
    -- Site 1 productos
    CALL spUpsertInventory(site1ID, (SELECT productID FROM product WHERE productCode = 'PROD-001'), 200, 15, 30, 'HUB');
    CALL spUpsertInventory(site1ID, (SELECT productID FROM product WHERE productCode = 'PROD-002'), 150, 10, 25, 'HUB');
    CALL spUpsertInventory(site1ID, (SELECT productID FROM product WHERE productCode = 'PROD-003'), 300, 20, 40, 'HUB');
    CALL spUpsertInventory(site1ID, (SELECT productID FROM product WHERE productCode = 'PROD-004'), 250, 12, 35, 'HUB');
    CALL spUpsertInventory(site1ID, (SELECT productID FROM product WHERE productCode = 'PROD-005'), 180, 8, 20, 'HUB');
    CALL spUpsertInventory(site1ID, (SELECT productID FROM product WHERE productCode = 'PROD-007'), 100, 5, 15, 'HUB');
    CALL spUpsertInventory(site1ID, (SELECT productID FROM product WHERE productCode = 'PROD-008'), 80, 3, 10, 'HUB');

    -- Site 2 productos
    CALL spUpsertInventory(site2ID, (SELECT productID FROM product WHERE productCode = 'PROD-013'), 220, 18, 30, 'HUB');
    CALL spUpsertInventory(site2ID, (SELECT productID FROM product WHERE productCode = 'PROD-014'), 170, 12, 25, 'HUB');
    CALL spUpsertInventory(site2ID, (SELECT productID FROM product WHERE productCode = 'PROD-017'), 90, 5, 15, 'HUB');

    -- Site 4 productos
    CALL spUpsertInventory(site4ID, (SELECT productID FROM product WHERE productCode = 'PROD-035'), 400, 30, 50, 'HUB');
    CALL spUpsertInventory(site4ID, (SELECT productID FROM product WHERE productCode = 'PROD-036'), 150, 10, 20, 'HUB');
    CALL spUpsertInventory(site4ID, (SELECT productID FROM product WHERE productCode = 'PROD-040'), 200, 15, 25, 'HUB');

    -- Site 7 productos
    CALL spUpsertInventory(site7ID, (SELECT productID FROM product WHERE productCode = 'PROD-068'), 500, 40, 60, 'HUB');
    CALL spUpsertInventory(site7ID, (SELECT productID FROM product WHERE productCode = 'PROD-069'), 300, 25, 40, 'HUB');
    CALL spUpsertInventory(site7ID, (SELECT productID FROM product WHERE productCode = 'PROD-071'), 250, 20, 30, 'HUB');

    -- =============================================================
    -- FASE 10: ORDENES, PAGOS Y ENVIOS
    -- =============================================================
    -- Orden 1: Laura compra en PureAura CR
    CALL spInsertCustomerOrder('ORD-001', cust1PersonID, site1ID, costaRicaCountryID, crcCurrencyID, 'CREATED', 2500.00, 1.00, 'Primera orden de Laura', order1ID);
    CALL spInsertCustomerOrderDetail(order1ID, (SELECT productID FROM product WHERE productCode = 'PROD-001'), 2, 6375.00, 1657.50, 0.00);
    CALL spInsertCustomerOrderDetail(order1ID, (SELECT productID FROM product WHERE productCode = 'PROD-004'), 1, 3315.00, 431.95, 0.00);
    CALL spInsertPaymentTransaction(order1ID, 'PAY-001', 'VISA', 'APPROVED', 20654.45, crcCurrencyID, 1.00, NULL, 'VISA-REF-001');
    CALL spUpdateCustomerOrderStatus(order1ID, 'PAID', adminPersonID, 'Pago aprobado con Visa');
    CALL spInsertShipment(order1ID, 'SHIP-001', 'PENDING', 'San Jose, Costa Rica', NULL, 'Correos CR', 'CUSTOMER', NULL, NULL);

    -- Orden 2: Diego compra en PureAura MX
    CALL spInsertCustomerOrder('ORD-002', cust2PersonID, site2ID, mexicoCountryID, mxnCurrencyID, 'CREATED', 150.00, 1.00, 'Orden de Diego en Mexico', order2ID);
    CALL spInsertCustomerOrderDetail(order2ID, (SELECT productID FROM product WHERE productCode = 'PROD-013'), 1, 240.10, 38.42, 0.00);
    CALL spInsertCustomerOrderDetail(order2ID, (SELECT productID FROM product WHERE productCode = 'PROD-017'), 1, 342.82, 54.85, 0.00);
    CALL spInsertPaymentTransaction(order2ID, 'PAY-002', 'MASTERCARD', 'APPROVED', 826.19, mxnCurrencyID, 1.00, NULL, 'MC-REF-002');
    CALL spUpdateCustomerOrderStatus(order2ID, 'PAID', adminPersonID, 'Pago aprobado con Mastercard');
    CALL spUpdateCustomerOrderStatus(order2ID, 'SHIPPED', adminPersonID, 'Orden enviada');
    CALL spInsertShipment(order2ID, 'SHIP-002', 'IN_TRANSIT', 'Ciudad de Mexico, Mexico', 'TRACK-MX-001', 'FedEx MX', 'CUSTOMER', CURRENT_TIMESTAMP, NULL);

    -- Orden 3: Valentina compra en AquaVita CO
    CALL spInsertCustomerOrder('ORD-003', cust3PersonID, site8ID, colombiaCountryID, copCurrencyID, 'CREATED', 8500.00, 1.00, 'Orden de Valentina', order3ID);
    CALL spInsertCustomerOrderDetail(order3ID, (SELECT productID FROM product WHERE productCode = 'PROD-079'), 3, 17775.00, 6937.25, 0.00);
    CALL spInsertCustomerOrderDetail(order3ID, (SELECT productID FROM product WHERE productCode = 'PROD-082'), 2, 19710.00, 6448.00, 0.00);
    CALL spInsertPaymentTransaction(order3ID, 'PAY-003', 'VISA', 'APPROVED', 117195.25, copCurrencyID, 1.00, NULL, 'VISA-REF-003');
    CALL spUpdateCustomerOrderStatus(order3ID, 'PAID', adminPersonID, 'Pago aprobado');
    CALL spUpdateCustomerOrderStatus(order3ID, 'SHIPPED', adminPersonID, 'Enviado');
    CALL spUpdateCustomerOrderStatus(order3ID, 'DELIVERED', adminPersonID, 'Entregado al cliente');
    CALL spInsertShipment(order3ID, 'SHIP-003', 'DELIVERED', 'Bogota, Colombia', 'TRACK-CO-001', 'Servientrega', 'CUSTOMER', DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 3 DAY), CURRENT_TIMESTAMP);

    -- Orden 4: Miguel compra en TerraVerde PE
    CALL spInsertCustomerOrder('ORD-004', cust4PersonID, site4ID, peruCountryID, penCurrencyID, 'CREATED', 10.00, 1.00, 'Orden de Miguel en Peru', order4ID);
    CALL spInsertCustomerOrderDetail(order4ID, (SELECT productID FROM product WHERE productCode = 'PROD-035'), 2, 31.62, 11.38, 0.00);
    CALL spInsertCustomerOrderDetail(order4ID, (SELECT productID FROM product WHERE productCode = 'PROD-040'), 1, 42.78, 7.70, 0.00);
    CALL spInsertPaymentTransaction(order4ID, 'PAY-004', 'VISA', 'APPROVED', 135.10, penCurrencyID, 1.00, NULL, 'VISA-REF-004');
    CALL spUpdateCustomerOrderStatus(order4ID, 'PAID', adminPersonID, 'Pago aprobado');
    CALL spInsertShipment(order4ID, 'SHIP-004', 'PENDING', 'Lima, Peru', NULL, 'Olva Courier', 'CUSTOMER', NULL, NULL);

    -- Orden 5: Sofia compra en TerraVerde GT
    CALL spInsertCustomerOrder('ORD-005', cust5PersonID, site5ID, guatemalaCountryID, gtqCurrencyID, 'CREATED', 25.00, 1.00, 'Orden de Sofia en Guatemala', order5ID);
    CALL spInsertCustomerOrderDetail(order5ID, (SELECT productID FROM product WHERE productCode = 'PROD-046'), 1, 117.00, 14.04, 0.00);
    CALL spInsertCustomerOrderDetail(order5ID, (SELECT productID FROM product WHERE productCode = 'PROD-047'), 2, 70.12, 16.83, 0.00);
    CALL spInsertPaymentTransaction(order5ID, 'PAY-005', 'VISA', 'APPROVED', 313.11, gtqCurrencyID, 1.00, NULL, 'VISA-REF-005');
    CALL spUpdateCustomerOrderStatus(order5ID, 'PAID', adminPersonID, 'Pago aprobado');
    CALL spInsertShipment(order5ID, 'SHIP-005', 'PENDING', 'Ciudad de Guatemala, Guatemala', NULL, 'Cargo Expreso', 'CUSTOMER', NULL, NULL);

    -- =============================================================
    -- FASE 11: PERMISOS REGULATORIOS (algunos productos)
    -- =============================================================
    CALL spInsertCountryProductPermission(
        (SELECT productID FROM product WHERE productCode = 'PROD-001'), costaRicaCountryID, 50000,
        'PERM-CR-001', 'Registro sanitario aceite esencial', 'APPROVED', 'CERT-CR-001',
        'Ministerio de Salud CR', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 YEAR), 'Permiso aprobado');

    CALL spInsertCountryProductPermission(
        (SELECT productID FROM product WHERE productCode = 'PROD-035'), peruCountryID, 30000,
        'PERM-PE-001', 'Registro sanitario alimentos organicos', 'APPROVED', 'CERT-PE-001',
        'DIGESA Peru', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 2 YEAR), 'Alimento organico aprobado');

    CALL spInsertCountryProductPermission(
        (SELECT productID FROM product WHERE productCode = 'PROD-046'), guatemalaCountryID, 25000,
        'PERM-GT-001', 'Licencia de exportacion cafe', 'APPROVED', 'CERT-GT-001',
        'MAGA Guatemala', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 YEAR), 'Exportacion aprobada');

    CALL spInsertCountryProductPermission(
        (SELECT productID FROM product WHERE productCode = 'PROD-068'), mexicoCountryID, 40000,
        'PERM-MX-001', 'Registro sanitario bebida', 'PENDING', NULL,
        'COFEPRIS Mexico', CURRENT_TIMESTAMP, NULL, 'En proceso de aprobacion');

    CALL spInsertCountryProductPermission(
        (SELECT productID FROM product WHERE productCode = 'PROD-079'), colombiaCountryID, 35000,
        'PERM-CO-001', 'Registro INVIMA bebida natural', 'APPROVED', 'CERT-CO-001',
        'INVIMA Colombia', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 2 YEAR), 'Bebida aprobada por INVIMA');

    -- =============================================================
    -- FASE 11.1: REQUERIMIENTOS REGULATORIOS (algunos productos)
    -- =============================================================
    CALL spInsertCountryProductRequirement(
        (SELECT productID FROM product WHERE productCode = 'PROD-001'), costaRicaCountryID,
        'HEALTH', 'Registro sanitario obligatorio', 'Todo producto de uso topico requiere registro sanitario',
        TRUE, 'Ministerio de Salud CR', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 2 YEAR));

    CALL spInsertCountryProductRequirement(
        (SELECT productID FROM product WHERE productCode = 'PROD-035'), peruCountryID,
        'LABELING', 'Etiquetado nutricional', 'Debe incluir tabla nutricional en espanol',
        TRUE, 'DIGESA Peru', CURRENT_TIMESTAMP, NULL);

    CALL spInsertCountryProductRequirement(
        (SELECT productID FROM product WHERE productCode = 'PROD-046'), guatemalaCountryID,
        'IMPORT', 'Certificado de origen', 'Certificado de origen para exportacion de cafe',
        TRUE, 'MAGA Guatemala', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 YEAR));

    COMMIT;
    CALL spLogEtlStep('spSeedFullData', 'MANUAL', 'dynamicBrandsDB', 'SUCCESS', 0, 0, NULL);
END $$

DELIMITER ;

-- =============================================================
-- EJECUCION DE LA ORQUESTACION
-- =============================================================
CALL spSeedFullData();
