USE dynamicBrandsDB;
DELIMITER $$

DROP PROCEDURE IF EXISTS spResetDynamicBrandsData $$
CREATE PROCEDURE spResetDynamicBrandsData()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE tbl VARCHAR(255);
    DECLARE cur CURSOR FOR
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
          AND table_type = 'BASE TABLE';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    SET FOREIGN_KEY_CHECKS = 0;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO tbl;
        IF done THEN
            LEAVE read_loop;
        END IF;
        SET @sql = CONCAT('TRUNCATE TABLE `', tbl, '`');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    CLOSE cur;
    SET FOREIGN_KEY_CHECKS = 1;
END $$

DROP PROCEDURE IF EXISTS spSeedFullData $$
CREATE PROCEDURE spSeedFullData()
BEGIN
    DECLARE vUsdCurrencyID BIGINT;
    DECLARE vCrcCurrencyID BIGINT;
    DECLARE vMxnCurrencyID BIGINT;
    DECLARE vCostaRicaID BIGINT;
    DECLARE vMexicoID BIGINT;
    DECLARE vAdminPersonID BIGINT;
    DECLARE vCustomer1ID BIGINT;
    DECLARE vCustomer2ID BIGINT;
    DECLARE vSiteCRID BIGINT;
    DECLARE vSiteMXID BIGINT;
    DECLARE vProductID BIGINT;
    DECLARE vOrderID BIGINT;
    DECLARE vOrderTotal DECIMAL(18,6);
    DECLARE vSeq INT;
    DECLARE vProdStart INT;
    DECLARE vProdEnd INT;
    DECLARE vBasePrice DECIMAL(18,6);
    DECLARE vOrderCurrencyID BIGINT;
    DECLARE vOrderCountryID BIGINT;
    DECLARE vOrderSiteID BIGINT;
    DECLARE vOrderCustomerID BIGINT;
    DECLARE vOrderDate DATETIME;

    CALL spResetDynamicBrandsData();
    CALL spSeedBaseCatalogs();

    CREATE TEMPORARY TABLE tmp_products (
        seq INT PRIMARY KEY,
        productID BIGINT NOT NULL,
        siteID BIGINT NOT NULL,
        countryID BIGINT NOT NULL,
        currencyID BIGINT NOT NULL,
        productName VARCHAR(120) NOT NULL,
        basePrice DECIMAL(18,6) NOT NULL
    );

    CREATE TEMPORARY TABLE tmp_orders (
        seq INT PRIMARY KEY,
        orderID BIGINT NOT NULL,
        siteID BIGINT NOT NULL,
        countryID BIGINT NOT NULL,
        currencyID BIGINT NOT NULL,
        customerID BIGINT NOT NULL,
        orderDate DATETIME NOT NULL
    );

    CALL spInsertCurrency('USD', 'US Dollar', '$');
    CALL spInsertCurrency('CRC', 'Colón Costarricense', '₡');
    CALL spInsertCurrency('MXN', 'Peso Mexicano', '$');

    SELECT currencyID INTO vUsdCurrencyID FROM currency WHERE currencyCode = 'USD' LIMIT 1;
    SELECT currencyID INTO vCrcCurrencyID FROM currency WHERE currencyCode = 'CRC' LIMIT 1;
    SELECT currencyID INTO vMxnCurrencyID FROM currency WHERE currencyCode = 'MXN' LIMIT 1;

    CALL spInsertCountry('Costa Rica', 'CR', 'CRI', vCrcCurrencyID);
    CALL spInsertCountry('Mexico', 'MX', 'MEX', vMxnCurrencyID);

    SELECT countryID INTO vCostaRicaID FROM country WHERE iso3Code = 'CRI' LIMIT 1;
    SELECT countryID INTO vMexicoID FROM country WHERE iso3Code = 'MEX' LIMIT 1;

    CALL spInsertCurrentExchangeRate(1, vUsdCurrencyID, vCrcCurrencyID, 510.500000, 515.750000, 'Central Bank CR');
    CALL spInsertCurrentExchangeRate(2, vUsdCurrencyID, vMxnCurrencyID, 17.150000, 17.350000, 'Banxico');

    CALL spInsertPeople('ADM-001', vCostaRicaID, 'admin@etheria.global', 'Admin', 'Etheria', 'HASH_ADMIN_001', 'SYSTEM_USER', vAdminPersonID);
    CALL spInsertSystemUser(vAdminPersonID, 'ADMIN-001', 'ADMIN');
    CALL spInsertPeople('CUS-001', vCostaRicaID, 'cliente.cr1@etheria.global', 'Laura', 'Ramirez', 'HASH_CUS_001', 'CUSTOMER', vCustomer1ID);
    CALL spInsertPeople('CUS-002', vMexicoID, 'cliente.mx1@etheria.global', 'Carlos', 'Lopez', 'HASH_CUS_002', 'CUSTOMER', vCustomer2ID);

    CALL spInsertBrandTemplate('ETH', 'Etheria Global', 'https://cdn.etheria.global/logo-eth.png', 'Natural products with premium sourcing', 'Wellness customers seeking exotics');
    CALL spInsertBrandTemplate('DYN', 'Dynamic Brands', 'https://cdn.etheria.global/logo-dyn.png', 'Digital commerce for premium brands', 'High-intent online buyers');

    CALL spInsertDynamicSite('SITE-CR-001', 'Etheria Costa Rica', 'ETH', vCostaRicaID, vCrcCurrencyID, 'ACTIVE', 'etheria.cr', 'Wellness and natural care', 'Elegant, premium, clean', JSON_OBJECT('theme', 'forest', 'locale', 'es-CR'), 'Etheria CR', 'https://cdn.etheria.global/site-cr.png', vSiteCRID);
    CALL spInsertDynamicSite('SITE-MX-001', 'Etheria Mexico', 'DYN', vMexicoID, vMxnCurrencyID, 'ACTIVE', 'etheria.mx', 'Premium beauty and wellness', 'Modern, premium, bold', JSON_OBJECT('theme', 'midnight', 'locale', 'es-MX'), 'Etheria MX', 'https://cdn.etheria.global/site-mx.png', vSiteMXID);

    UPDATE dynamicSiteInfo SET launchDate = '2025-01-05 08:00:00' WHERE dynamicSiteID = vSiteCRID;
    UPDATE dynamicSiteInfo SET launchDate = '2025-02-10 09:00:00' WHERE dynamicSiteID = vSiteMXID;
    UPDATE dynamicSiteInfo SET siteStatusCode = 'ACTIVE' WHERE dynamicSiteID IN (vSiteCRID, vSiteMXID);

    -- =======================
    -- PRODUCTOS (100)
    -- =======================
    CALL spInsertProduct('PROD-001', vSiteCRID, 'BEVERAGE', 'Té Matcha Premium 001', 'Producto premium de la línea 001', 'SKU-001', vUsdCurrencyID, 18.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (1, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Té Matcha Premium 001', 18.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 21.240000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 101, 11, 16, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 375, 195, 'PERM-001', 'Permiso regulatorio producto 001', 'APPROVED', 'CERT-001', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 001', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-002', vSiteCRID, 'FOOD', 'Serum Vitamina C 002', 'Producto premium de la línea 002', 'SKU-002', vUsdCurrencyID, 24.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (2, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Serum Vitamina C 002', 24.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 28.320000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 102, 12, 17, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 400, 210, 'PERM-002', 'Permiso regulatorio producto 002', 'APPROVED', 'CERT-002', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 002', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-003', vSiteCRID, 'DERM', 'Jabón Artesanal Lavanda 003', 'Producto premium de la línea 003', 'SKU-003', vUsdCurrencyID, 30.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (3, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Jabón Artesanal Lavanda 003', 30.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 35.400000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 103, 13, 18, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 425, 225, 'PERM-003', 'Permiso regulatorio producto 003', 'APPROVED', 'CERT-003', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 003', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-004', vSiteCRID, 'HAIR', 'Aceite Esencial de Lavanda 004', 'Producto premium de la línea 004', 'SKU-004', vUsdCurrencyID, 36.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (4, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Aceite Esencial de Lavanda 004', 36.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 42.480000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 104, 14, 19, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 450, 240, 'PERM-004', 'Permiso regulatorio producto 004', 'APPROVED', 'CERT-004', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 004', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-005', vSiteCRID, 'AROMA', 'Shampoo de Romero 005', 'Producto premium de la línea 005', 'SKU-005', vUsdCurrencyID, 42.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (5, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Shampoo de Romero 005', 42.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 49.560000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 105, 15, 20, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 475, 255, 'PERM-005', 'Permiso regulatorio producto 005', 'APPROVED', 'CERT-005', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 005', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-006', vSiteCRID, 'SOAP', 'Miel Funcional 006', 'Producto premium de la línea 006', 'SKU-006', vUsdCurrencyID, 48.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (6, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Miel Funcional 006', 48.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 56.640000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 106, 16, 21, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 500, 270, 'PERM-006', 'Permiso regulatorio producto 006', 'APPROVED', 'CERT-006', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 006', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-007', vSiteCRID, 'ESSOIL', 'Bálsamo Corporal 007', 'Producto premium de la línea 007', 'SKU-007', vUsdCurrencyID, 22.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (7, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Bálsamo Corporal 007', 22.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 25.960000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 107, 10, 22, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 525, 285, 'PERM-007', 'Permiso regulatorio producto 007', 'APPROVED', 'CERT-007', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 007', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-008', vSiteCRID, 'BEVERAGE', 'Agua Micelar Botánica 008', 'Producto premium de la línea 008', 'SKU-008', vUsdCurrencyID, 28.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (8, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Agua Micelar Botánica 008', 28.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 33.040000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 108, 11, 23, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 550, 180, 'PERM-008', 'Permiso regulatorio producto 008', 'APPROVED', 'CERT-008', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 008', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-009', vSiteCRID, 'FOOD', 'Crema Facial de Rosas 009', 'Producto premium de la línea 009', 'SKU-009', vUsdCurrencyID, 34.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (9, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Crema Facial de Rosas 009', 34.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 40.120000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 109, 12, 24, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 575, 195, 'PERM-009', 'Permiso regulatorio producto 009', 'APPROVED', 'CERT-009', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 009', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-010', vSiteCRID, 'DERM', 'Infusión Detox 010', 'Producto premium de la línea 010', 'SKU-010', vUsdCurrencyID, 40.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (10, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Infusión Detox 010', 40.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 47.200000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 110, 13, 15, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 600, 210, 'PERM-010', 'Permiso regulatorio producto 010', 'APPROVED', 'CERT-010', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 010', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-011', vSiteCRID, 'HAIR', 'Exfoliante de Café 011', 'Producto premium de la línea 011', 'SKU-011', vUsdCurrencyID, 26.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (11, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Exfoliante de Café 011', 26.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 30.680000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 111, 14, 16, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 625, 225, 'PERM-011', 'Permiso regulatorio producto 011', 'APPROVED', 'CERT-011', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 011', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-012', vSiteCRID, 'AROMA', 'Aceite de Coco Orgánico 012', 'Producto premium de la línea 012', 'SKU-012', vUsdCurrencyID, 32.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (12, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Aceite de Coco Orgánico 012', 32.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 37.760000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 112, 15, 17, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 350, 240, 'PERM-012', 'Permiso regulatorio producto 012', 'APPROVED', 'CERT-012', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 012', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-013', vSiteCRID, 'SOAP', 'Spray de Aromaterapia 013', 'Producto premium de la línea 013', 'SKU-013', vUsdCurrencyID, 38.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (13, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Spray de Aromaterapia 013', 38.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 44.840000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 113, 16, 18, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 375, 255, 'PERM-013', 'Permiso regulatorio producto 013', 'APPROVED', 'CERT-013', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 013', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-014', vSiteCRID, 'ESSOIL', 'Mascarilla Capilar Nutritiva 014', 'Producto premium de la línea 014', 'SKU-014', vUsdCurrencyID, 44.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (14, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Mascarilla Capilar Nutritiva 014', 44.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 51.920000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 114, 10, 19, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 400, 270, 'PERM-014', 'Permiso regulatorio producto 014', 'APPROVED', 'CERT-014', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 014', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-015', vSiteCRID, 'BEVERAGE', 'Tónico Facial de Té Verde 015', 'Producto premium de la línea 015', 'SKU-015', vUsdCurrencyID, 20.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (15, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Tónico Facial de Té Verde 015', 20.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 23.600000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 115, 11, 20, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 425, 285, 'PERM-015', 'Permiso regulatorio producto 015', 'APPROVED', 'CERT-015', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 015', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-016', vSiteCRID, 'FOOD', 'Jabón de Avena 016', 'Producto premium de la línea 016', 'SKU-016', vUsdCurrencyID, 27.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (16, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Jabón de Avena 016', 27.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 31.860000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 116, 12, 21, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 450, 180, 'PERM-016', 'Permiso regulatorio producto 016', 'APPROVED', 'CERT-016', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 016', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-017', vSiteCRID, 'DERM', 'Aceite de Árbol de Té 017', 'Producto premium de la línea 017', 'SKU-017', vUsdCurrencyID, 33.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (17, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Aceite de Árbol de Té 017', 33.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 38.940000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 117, 13, 22, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 475, 195, 'PERM-017', 'Permiso regulatorio producto 017', 'APPROVED', 'CERT-017', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 017', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-018', vSiteCRID, 'HAIR', 'Colágeno Bebible 018', 'Producto premium de la línea 018', 'SKU-018', vUsdCurrencyID, 39.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (18, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Colágeno Bebible 018', 39.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 46.020000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 118, 14, 23, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 500, 210, 'PERM-018', 'Permiso regulatorio producto 018', 'APPROVED', 'CERT-018', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 018', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-019', vSiteCRID, 'AROMA', 'Protector Labial Natural 019', 'Producto premium de la línea 019', 'SKU-019', vUsdCurrencyID, 23.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (19, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Protector Labial Natural 019', 23.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 27.140000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 119, 15, 24, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 525, 225, 'PERM-019', 'Permiso regulatorio producto 019', 'APPROVED', 'CERT-019', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 019', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-020', vSiteCRID, 'SOAP', 'Gel Calmante de Aloe 020', 'Producto premium de la línea 020', 'SKU-020', vUsdCurrencyID, 29.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (20, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Gel Calmante de Aloe 020', 29.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 34.220000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 120, 16, 15, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 550, 240, 'PERM-020', 'Permiso regulatorio producto 020', 'APPROVED', 'CERT-020', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 020', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-021', vSiteCRID, 'ESSOIL', 'Té Matcha Premium 021', 'Producto premium de la línea 021', 'SKU-021', vUsdCurrencyID, 20.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (21, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Té Matcha Premium 021', 20.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 23.600000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 121, 10, 16, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 575, 255, 'PERM-021', 'Permiso regulatorio producto 021', 'APPROVED', 'CERT-021', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 021', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-022', vSiteCRID, 'BEVERAGE', 'Serum Vitamina C 022', 'Producto premium de la línea 022', 'SKU-022', vUsdCurrencyID, 26.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (22, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Serum Vitamina C 022', 26.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 30.680000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 122, 11, 17, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 600, 270, 'PERM-022', 'Permiso regulatorio producto 022', 'APPROVED', 'CERT-022', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 022', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-023', vSiteCRID, 'FOOD', 'Jabón Artesanal Lavanda 023', 'Producto premium de la línea 023', 'SKU-023', vUsdCurrencyID, 32.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (23, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Jabón Artesanal Lavanda 023', 32.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 37.760000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 123, 12, 18, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 625, 285, 'PERM-023', 'Permiso regulatorio producto 023', 'APPROVED', 'CERT-023', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 023', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-024', vSiteCRID, 'DERM', 'Aceite Esencial de Lavanda 024', 'Producto premium de la línea 024', 'SKU-024', vUsdCurrencyID, 38.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (24, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Aceite Esencial de Lavanda 024', 38.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 44.840000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 124, 13, 19, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 350, 180, 'PERM-024', 'Permiso regulatorio producto 024', 'APPROVED', 'CERT-024', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 024', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-025', vSiteCRID, 'HAIR', 'Shampoo de Romero 025', 'Producto premium de la línea 025', 'SKU-025', vUsdCurrencyID, 44.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (25, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Shampoo de Romero 025', 44.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 51.920000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 125, 14, 20, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 375, 195, 'PERM-025', 'Permiso regulatorio producto 025', 'APPROVED', 'CERT-025', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 025', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-026', vSiteCRID, 'AROMA', 'Miel Funcional 026', 'Producto premium de la línea 026', 'SKU-026', vUsdCurrencyID, 50.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (26, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Miel Funcional 026', 50.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 59.000000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 126, 15, 21, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 400, 210, 'PERM-026', 'Permiso regulatorio producto 026', 'APPROVED', 'CERT-026', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 026', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-027', vSiteCRID, 'SOAP', 'Bálsamo Corporal 027', 'Producto premium de la línea 027', 'SKU-027', vUsdCurrencyID, 24.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (27, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Bálsamo Corporal 027', 24.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 28.320000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 127, 16, 22, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 425, 225, 'PERM-027', 'Permiso regulatorio producto 027', 'APPROVED', 'CERT-027', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 027', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-028', vSiteCRID, 'ESSOIL', 'Agua Micelar Botánica 028', 'Producto premium de la línea 028', 'SKU-028', vUsdCurrencyID, 30.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (28, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Agua Micelar Botánica 028', 30.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 35.400000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 128, 10, 23, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 450, 240, 'PERM-028', 'Permiso regulatorio producto 028', 'APPROVED', 'CERT-028', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 028', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-029', vSiteCRID, 'BEVERAGE', 'Crema Facial de Rosas 029', 'Producto premium de la línea 029', 'SKU-029', vUsdCurrencyID, 36.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (29, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Crema Facial de Rosas 029', 36.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 42.480000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 129, 11, 24, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 475, 255, 'PERM-029', 'Permiso regulatorio producto 029', 'APPROVED', 'CERT-029', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 029', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-030', vSiteCRID, 'FOOD', 'Infusión Detox 030', 'Producto premium de la línea 030', 'SKU-030', vUsdCurrencyID, 42.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (30, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Infusión Detox 030', 42.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 49.560000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 130, 12, 15, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 500, 270, 'PERM-030', 'Permiso regulatorio producto 030', 'APPROVED', 'CERT-030', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 030', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-031', vSiteCRID, 'DERM', 'Exfoliante de Café 031', 'Producto premium de la línea 031', 'SKU-031', vUsdCurrencyID, 28.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (31, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Exfoliante de Café 031', 28.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 33.040000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 131, 13, 16, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 525, 285, 'PERM-031', 'Permiso regulatorio producto 031', 'APPROVED', 'CERT-031', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 031', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-032', vSiteCRID, 'HAIR', 'Aceite de Coco Orgánico 032', 'Producto premium de la línea 032', 'SKU-032', vUsdCurrencyID, 34.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (32, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Aceite de Coco Orgánico 032', 34.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 40.120000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 132, 14, 17, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 550, 180, 'PERM-032', 'Permiso regulatorio producto 032', 'APPROVED', 'CERT-032', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 032', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-033', vSiteCRID, 'AROMA', 'Spray de Aromaterapia 033', 'Producto premium de la línea 033', 'SKU-033', vUsdCurrencyID, 40.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (33, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Spray de Aromaterapia 033', 40.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 47.200000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 133, 15, 18, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 575, 195, 'PERM-033', 'Permiso regulatorio producto 033', 'APPROVED', 'CERT-033', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 033', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-034', vSiteCRID, 'SOAP', 'Mascarilla Capilar Nutritiva 034', 'Producto premium de la línea 034', 'SKU-034', vUsdCurrencyID, 46.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (34, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Mascarilla Capilar Nutritiva 034', 46.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 54.280000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 134, 16, 19, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 600, 210, 'PERM-034', 'Permiso regulatorio producto 034', 'APPROVED', 'CERT-034', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 034', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-035', vSiteCRID, 'ESSOIL', 'Tónico Facial de Té Verde 035', 'Producto premium de la línea 035', 'SKU-035', vUsdCurrencyID, 22.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (35, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Tónico Facial de Té Verde 035', 22.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 25.960000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 100, 10, 20, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 625, 225, 'PERM-035', 'Permiso regulatorio producto 035', 'APPROVED', 'CERT-035', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 035', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-036', vSiteCRID, 'BEVERAGE', 'Jabón de Avena 036', 'Producto premium de la línea 036', 'SKU-036', vUsdCurrencyID, 29.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (36, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Jabón de Avena 036', 29.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 34.220000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 101, 11, 21, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 350, 240, 'PERM-036', 'Permiso regulatorio producto 036', 'APPROVED', 'CERT-036', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 036', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-037', vSiteCRID, 'FOOD', 'Aceite de Árbol de Té 037', 'Producto premium de la línea 037', 'SKU-037', vUsdCurrencyID, 35.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (37, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Aceite de Árbol de Té 037', 35.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 41.300000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 102, 12, 22, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 375, 255, 'PERM-037', 'Permiso regulatorio producto 037', 'APPROVED', 'CERT-037', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 037', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-038', vSiteCRID, 'DERM', 'Colágeno Bebible 038', 'Producto premium de la línea 038', 'SKU-038', vUsdCurrencyID, 41.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (38, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Colágeno Bebible 038', 41.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 48.380000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 103, 13, 23, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 400, 270, 'PERM-038', 'Permiso regulatorio producto 038', 'APPROVED', 'CERT-038', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 038', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-039', vSiteCRID, 'HAIR', 'Protector Labial Natural 039', 'Producto premium de la línea 039', 'SKU-039', vUsdCurrencyID, 25.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (39, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Protector Labial Natural 039', 25.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 29.500000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 104, 14, 24, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 425, 285, 'PERM-039', 'Permiso regulatorio producto 039', 'APPROVED', 'CERT-039', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 039', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-040', vSiteCRID, 'AROMA', 'Gel Calmante de Aloe 040', 'Producto premium de la línea 040', 'SKU-040', vUsdCurrencyID, 31.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (40, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Gel Calmante de Aloe 040', 31.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 36.580000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 105, 15, 15, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 450, 180, 'PERM-040', 'Permiso regulatorio producto 040', 'APPROVED', 'CERT-040', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 040', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-041', vSiteCRID, 'SOAP', 'Té Matcha Premium 041', 'Producto premium de la línea 041', 'SKU-041', vUsdCurrencyID, 22.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (41, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Té Matcha Premium 041', 22.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 25.960000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 106, 16, 16, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 475, 195, 'PERM-041', 'Permiso regulatorio producto 041', 'APPROVED', 'CERT-041', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 041', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-042', vSiteCRID, 'ESSOIL', 'Serum Vitamina C 042', 'Producto premium de la línea 042', 'SKU-042', vUsdCurrencyID, 28.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (42, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Serum Vitamina C 042', 28.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 33.040000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 107, 10, 17, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 500, 210, 'PERM-042', 'Permiso regulatorio producto 042', 'APPROVED', 'CERT-042', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 042', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-043', vSiteCRID, 'BEVERAGE', 'Jabón Artesanal Lavanda 043', 'Producto premium de la línea 043', 'SKU-043', vUsdCurrencyID, 34.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (43, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Jabón Artesanal Lavanda 043', 34.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 40.120000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 108, 11, 18, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 525, 225, 'PERM-043', 'Permiso regulatorio producto 043', 'APPROVED', 'CERT-043', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 043', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-044', vSiteCRID, 'FOOD', 'Aceite Esencial de Lavanda 044', 'Producto premium de la línea 044', 'SKU-044', vUsdCurrencyID, 40.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (44, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Aceite Esencial de Lavanda 044', 40.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 47.200000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 109, 12, 19, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 550, 240, 'PERM-044', 'Permiso regulatorio producto 044', 'APPROVED', 'CERT-044', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 044', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-045', vSiteCRID, 'DERM', 'Shampoo de Romero 045', 'Producto premium de la línea 045', 'SKU-045', vUsdCurrencyID, 46.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (45, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Shampoo de Romero 045', 46.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 54.280000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 110, 13, 20, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 575, 255, 'PERM-045', 'Permiso regulatorio producto 045', 'APPROVED', 'CERT-045', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 045', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-046', vSiteCRID, 'HAIR', 'Miel Funcional 046', 'Producto premium de la línea 046', 'SKU-046', vUsdCurrencyID, 52.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (46, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Miel Funcional 046', 52.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 61.360000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 111, 14, 21, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 600, 270, 'PERM-046', 'Permiso regulatorio producto 046', 'APPROVED', 'CERT-046', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 046', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-047', vSiteCRID, 'AROMA', 'Bálsamo Corporal 047', 'Producto premium de la línea 047', 'SKU-047', vUsdCurrencyID, 26.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (47, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Bálsamo Corporal 047', 26.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 30.680000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 112, 15, 22, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 625, 285, 'PERM-047', 'Permiso regulatorio producto 047', 'APPROVED', 'CERT-047', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'LABELING', 'Requisito regulatorio 047', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-048', vSiteCRID, 'SOAP', 'Agua Micelar Botánica 048', 'Producto premium de la línea 048', 'SKU-048', vUsdCurrencyID, 32.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (48, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Agua Micelar Botánica 048', 32.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 37.760000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 113, 16, 23, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 350, 180, 'PERM-048', 'Permiso regulatorio producto 048', 'APPROVED', 'CERT-048', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'PACKAGING', 'Requisito regulatorio 048', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-049', vSiteCRID, 'ESSOIL', 'Crema Facial de Rosas 049', 'Producto premium de la línea 049', 'SKU-049', vUsdCurrencyID, 38.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (49, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Crema Facial de Rosas 049', 38.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 44.840000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 114, 10, 24, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 375, 195, 'PERM-049', 'Permiso regulatorio producto 049', 'APPROVED', 'CERT-049', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'HEALTH', 'Requisito regulatorio 049', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-050', vSiteCRID, 'BEVERAGE', 'Infusión Detox 050', 'Producto premium de la línea 050', 'SKU-050', vUsdCurrencyID, 44.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (50, vProductID, vSiteCRID, vCostaRicaID, vUsdCurrencyID, 'Infusión Detox 050', 44.000000);
    CALL spInsertProductPrice(vProductID, vSiteCRID, vUsdCurrencyID, 51.920000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteCRID, vProductID, 115, 11, 15, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vCostaRicaID, 400, 210, 'PERM-050', 'Permiso regulatorio producto 050', 'APPROVED', 'CERT-050', 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vCostaRicaID, 'IMPORT', 'Requisito regulatorio 050', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-01-15 10:00:00', '2026-01-15 10:00:00');

    CALL spInsertProduct('PROD-051', vSiteMXID, 'FOOD', 'Exfoliante de Café 051', 'Producto premium de la línea 051', 'SKU-051', vUsdCurrencyID, 30.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (51, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Exfoliante de Café 051', 30.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 35.400000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 116, 12, 16, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 465, 245, 'PERM-051', 'Permiso regulatorio producto 051', 'APPROVED', 'CERT-051', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 051', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-052', vSiteMXID, 'DERM', 'Aceite de Coco Orgánico 052', 'Producto premium de la línea 052', 'SKU-052', vUsdCurrencyID, 36.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (52, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Aceite de Coco Orgánico 052', 36.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 42.480000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 117, 13, 17, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 490, 260, 'PERM-052', 'Permiso regulatorio producto 052', 'APPROVED', 'CERT-052', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 052', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-053', vSiteMXID, 'HAIR', 'Spray de Aromaterapia 053', 'Producto premium de la línea 053', 'SKU-053', vUsdCurrencyID, 42.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (53, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Spray de Aromaterapia 053', 42.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 49.560000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 118, 14, 18, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 515, 275, 'PERM-053', 'Permiso regulatorio producto 053', 'APPROVED', 'CERT-053', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 053', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-054', vSiteMXID, 'AROMA', 'Mascarilla Capilar Nutritiva 054', 'Producto premium de la línea 054', 'SKU-054', vUsdCurrencyID, 48.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (54, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Mascarilla Capilar Nutritiva 054', 48.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 56.640000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 119, 15, 19, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 540, 290, 'PERM-054', 'Permiso regulatorio producto 054', 'APPROVED', 'CERT-054', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 054', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-055', vSiteMXID, 'SOAP', 'Tónico Facial de Té Verde 055', 'Producto premium de la línea 055', 'SKU-055', vUsdCurrencyID, 24.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (55, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Tónico Facial de Té Verde 055', 24.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 28.320000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 120, 16, 20, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 565, 305, 'PERM-055', 'Permiso regulatorio producto 055', 'APPROVED', 'CERT-055', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 055', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-056', vSiteMXID, 'ESSOIL', 'Jabón de Avena 056', 'Producto premium de la línea 056', 'SKU-056', vUsdCurrencyID, 31.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (56, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Jabón de Avena 056', 31.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 36.580000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 121, 10, 21, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 590, 200, 'PERM-056', 'Permiso regulatorio producto 056', 'APPROVED', 'CERT-056', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 056', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-057', vSiteMXID, 'BEVERAGE', 'Aceite de Árbol de Té 057', 'Producto premium de la línea 057', 'SKU-057', vUsdCurrencyID, 37.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (57, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Aceite de Árbol de Té 057', 37.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 43.660000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 122, 11, 22, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 615, 215, 'PERM-057', 'Permiso regulatorio producto 057', 'APPROVED', 'CERT-057', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 057', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-058', vSiteMXID, 'FOOD', 'Colágeno Bebible 058', 'Producto premium de la línea 058', 'SKU-058', vUsdCurrencyID, 43.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (58, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Colágeno Bebible 058', 43.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 50.740000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 123, 12, 23, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 640, 230, 'PERM-058', 'Permiso regulatorio producto 058', 'APPROVED', 'CERT-058', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 058', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-059', vSiteMXID, 'DERM', 'Protector Labial Natural 059', 'Producto premium de la línea 059', 'SKU-059', vUsdCurrencyID, 27.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (59, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Protector Labial Natural 059', 27.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 31.860000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 124, 13, 24, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 665, 245, 'PERM-059', 'Permiso regulatorio producto 059', 'APPROVED', 'CERT-059', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 059', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-060', vSiteMXID, 'HAIR', 'Gel Calmante de Aloe 060', 'Producto premium de la línea 060', 'SKU-060', vUsdCurrencyID, 33.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (60, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Gel Calmante de Aloe 060', 33.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 38.940000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 125, 14, 15, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 390, 260, 'PERM-060', 'Permiso regulatorio producto 060', 'APPROVED', 'CERT-060', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 060', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-061', vSiteMXID, 'AROMA', 'Té Matcha Premium 061', 'Producto premium de la línea 061', 'SKU-061', vUsdCurrencyID, 24.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (61, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Té Matcha Premium 061', 24.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 28.320000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 126, 15, 16, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 415, 275, 'PERM-061', 'Permiso regulatorio producto 061', 'APPROVED', 'CERT-061', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 061', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-062', vSiteMXID, 'SOAP', 'Serum Vitamina C 062', 'Producto premium de la línea 062', 'SKU-062', vUsdCurrencyID, 30.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (62, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Serum Vitamina C 062', 30.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 35.400000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 127, 16, 17, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 440, 290, 'PERM-062', 'Permiso regulatorio producto 062', 'APPROVED', 'CERT-062', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 062', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-063', vSiteMXID, 'ESSOIL', 'Jabón Artesanal Lavanda 063', 'Producto premium de la línea 063', 'SKU-063', vUsdCurrencyID, 36.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (63, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Jabón Artesanal Lavanda 063', 36.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 42.480000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 128, 10, 18, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 465, 305, 'PERM-063', 'Permiso regulatorio producto 063', 'APPROVED', 'CERT-063', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 063', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-064', vSiteMXID, 'BEVERAGE', 'Aceite Esencial de Lavanda 064', 'Producto premium de la línea 064', 'SKU-064', vUsdCurrencyID, 42.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (64, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Aceite Esencial de Lavanda 064', 42.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 49.560000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 129, 11, 19, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 490, 200, 'PERM-064', 'Permiso regulatorio producto 064', 'APPROVED', 'CERT-064', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 064', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-065', vSiteMXID, 'FOOD', 'Shampoo de Romero 065', 'Producto premium de la línea 065', 'SKU-065', vUsdCurrencyID, 48.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (65, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Shampoo de Romero 065', 48.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 56.640000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 130, 12, 20, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 515, 215, 'PERM-065', 'Permiso regulatorio producto 065', 'APPROVED', 'CERT-065', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 065', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-066', vSiteMXID, 'DERM', 'Miel Funcional 066', 'Producto premium de la línea 066', 'SKU-066', vUsdCurrencyID, 54.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (66, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Miel Funcional 066', 54.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 63.720000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 131, 13, 21, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 540, 230, 'PERM-066', 'Permiso regulatorio producto 066', 'APPROVED', 'CERT-066', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 066', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-067', vSiteMXID, 'HAIR', 'Bálsamo Corporal 067', 'Producto premium de la línea 067', 'SKU-067', vUsdCurrencyID, 28.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (67, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Bálsamo Corporal 067', 28.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 33.040000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 132, 14, 22, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 565, 245, 'PERM-067', 'Permiso regulatorio producto 067', 'APPROVED', 'CERT-067', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 067', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-068', vSiteMXID, 'AROMA', 'Agua Micelar Botánica 068', 'Producto premium de la línea 068', 'SKU-068', vUsdCurrencyID, 34.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (68, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Agua Micelar Botánica 068', 34.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 40.120000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 133, 15, 23, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 590, 260, 'PERM-068', 'Permiso regulatorio producto 068', 'APPROVED', 'CERT-068', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 068', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-069', vSiteMXID, 'SOAP', 'Crema Facial de Rosas 069', 'Producto premium de la línea 069', 'SKU-069', vUsdCurrencyID, 40.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (69, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Crema Facial de Rosas 069', 40.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 47.200000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 134, 16, 24, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 615, 275, 'PERM-069', 'Permiso regulatorio producto 069', 'APPROVED', 'CERT-069', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 069', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-070', vSiteMXID, 'ESSOIL', 'Infusión Detox 070', 'Producto premium de la línea 070', 'SKU-070', vUsdCurrencyID, 46.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (70, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Infusión Detox 070', 46.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 54.280000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 100, 10, 15, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 640, 290, 'PERM-070', 'Permiso regulatorio producto 070', 'APPROVED', 'CERT-070', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 070', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-071', vSiteMXID, 'BEVERAGE', 'Exfoliante de Café 071', 'Producto premium de la línea 071', 'SKU-071', vUsdCurrencyID, 32.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (71, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Exfoliante de Café 071', 32.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 37.760000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 101, 11, 16, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 665, 305, 'PERM-071', 'Permiso regulatorio producto 071', 'APPROVED', 'CERT-071', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 071', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-072', vSiteMXID, 'FOOD', 'Aceite de Coco Orgánico 072', 'Producto premium de la línea 072', 'SKU-072', vUsdCurrencyID, 38.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (72, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Aceite de Coco Orgánico 072', 38.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 44.840000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 102, 12, 17, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 390, 200, 'PERM-072', 'Permiso regulatorio producto 072', 'APPROVED', 'CERT-072', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 072', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-073', vSiteMXID, 'DERM', 'Spray de Aromaterapia 073', 'Producto premium de la línea 073', 'SKU-073', vUsdCurrencyID, 44.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (73, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Spray de Aromaterapia 073', 44.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 51.920000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 103, 13, 18, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 415, 215, 'PERM-073', 'Permiso regulatorio producto 073', 'APPROVED', 'CERT-073', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 073', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-074', vSiteMXID, 'HAIR', 'Mascarilla Capilar Nutritiva 074', 'Producto premium de la línea 074', 'SKU-074', vUsdCurrencyID, 50.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (74, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Mascarilla Capilar Nutritiva 074', 50.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 59.000000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 104, 14, 19, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 440, 230, 'PERM-074', 'Permiso regulatorio producto 074', 'APPROVED', 'CERT-074', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 074', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-075', vSiteMXID, 'AROMA', 'Tónico Facial de Té Verde 075', 'Producto premium de la línea 075', 'SKU-075', vUsdCurrencyID, 26.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (75, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Tónico Facial de Té Verde 075', 26.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 30.680000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 105, 15, 20, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 465, 245, 'PERM-075', 'Permiso regulatorio producto 075', 'APPROVED', 'CERT-075', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 075', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-076', vSiteMXID, 'SOAP', 'Jabón de Avena 076', 'Producto premium de la línea 076', 'SKU-076', vUsdCurrencyID, 33.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (76, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Jabón de Avena 076', 33.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 38.940000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 106, 16, 21, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 490, 260, 'PERM-076', 'Permiso regulatorio producto 076', 'APPROVED', 'CERT-076', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 076', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-077', vSiteMXID, 'ESSOIL', 'Aceite de Árbol de Té 077', 'Producto premium de la línea 077', 'SKU-077', vUsdCurrencyID, 39.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (77, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Aceite de Árbol de Té 077', 39.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 46.020000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 107, 10, 22, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 515, 275, 'PERM-077', 'Permiso regulatorio producto 077', 'APPROVED', 'CERT-077', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 077', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-078', vSiteMXID, 'BEVERAGE', 'Colágeno Bebible 078', 'Producto premium de la línea 078', 'SKU-078', vUsdCurrencyID, 45.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (78, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Colágeno Bebible 078', 45.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 53.100000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 108, 11, 23, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 540, 290, 'PERM-078', 'Permiso regulatorio producto 078', 'APPROVED', 'CERT-078', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 078', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-079', vSiteMXID, 'FOOD', 'Protector Labial Natural 079', 'Producto premium de la línea 079', 'SKU-079', vUsdCurrencyID, 29.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (79, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Protector Labial Natural 079', 29.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 34.220000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 109, 12, 24, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 565, 305, 'PERM-079', 'Permiso regulatorio producto 079', 'APPROVED', 'CERT-079', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 079', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-080', vSiteMXID, 'DERM', 'Gel Calmante de Aloe 080', 'Producto premium de la línea 080', 'SKU-080', vUsdCurrencyID, 35.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (80, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Gel Calmante de Aloe 080', 35.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 41.300000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 110, 13, 15, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 590, 200, 'PERM-080', 'Permiso regulatorio producto 080', 'APPROVED', 'CERT-080', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 080', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-081', vSiteMXID, 'HAIR', 'Té Matcha Premium 081', 'Producto premium de la línea 081', 'SKU-081', vUsdCurrencyID, 26.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (81, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Té Matcha Premium 081', 26.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 30.680000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 111, 14, 16, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 615, 215, 'PERM-081', 'Permiso regulatorio producto 081', 'APPROVED', 'CERT-081', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 081', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-082', vSiteMXID, 'AROMA', 'Serum Vitamina C 082', 'Producto premium de la línea 082', 'SKU-082', vUsdCurrencyID, 32.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (82, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Serum Vitamina C 082', 32.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 37.760000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 112, 15, 17, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 640, 230, 'PERM-082', 'Permiso regulatorio producto 082', 'APPROVED', 'CERT-082', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 082', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-083', vSiteMXID, 'SOAP', 'Jabón Artesanal Lavanda 083', 'Producto premium de la línea 083', 'SKU-083', vUsdCurrencyID, 38.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (83, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Jabón Artesanal Lavanda 083', 38.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 44.840000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 113, 16, 18, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 665, 245, 'PERM-083', 'Permiso regulatorio producto 083', 'APPROVED', 'CERT-083', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 083', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-084', vSiteMXID, 'ESSOIL', 'Aceite Esencial de Lavanda 084', 'Producto premium de la línea 084', 'SKU-084', vUsdCurrencyID, 44.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (84, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Aceite Esencial de Lavanda 084', 44.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 51.920000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 114, 10, 19, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 390, 260, 'PERM-084', 'Permiso regulatorio producto 084', 'APPROVED', 'CERT-084', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 084', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-085', vSiteMXID, 'BEVERAGE', 'Shampoo de Romero 085', 'Producto premium de la línea 085', 'SKU-085', vUsdCurrencyID, 50.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (85, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Shampoo de Romero 085', 50.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 59.000000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 115, 11, 20, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 415, 275, 'PERM-085', 'Permiso regulatorio producto 085', 'APPROVED', 'CERT-085', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 085', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-086', vSiteMXID, 'FOOD', 'Miel Funcional 086', 'Producto premium de la línea 086', 'SKU-086', vUsdCurrencyID, 56.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (86, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Miel Funcional 086', 56.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 66.080000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 116, 12, 21, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 440, 290, 'PERM-086', 'Permiso regulatorio producto 086', 'APPROVED', 'CERT-086', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 086', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-087', vSiteMXID, 'DERM', 'Bálsamo Corporal 087', 'Producto premium de la línea 087', 'SKU-087', vUsdCurrencyID, 30.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (87, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Bálsamo Corporal 087', 30.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 35.400000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 117, 13, 22, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 465, 305, 'PERM-087', 'Permiso regulatorio producto 087', 'APPROVED', 'CERT-087', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 087', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-088', vSiteMXID, 'HAIR', 'Agua Micelar Botánica 088', 'Producto premium de la línea 088', 'SKU-088', vUsdCurrencyID, 36.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (88, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Agua Micelar Botánica 088', 36.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 42.480000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 118, 14, 23, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 490, 200, 'PERM-088', 'Permiso regulatorio producto 088', 'APPROVED', 'CERT-088', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 088', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-089', vSiteMXID, 'AROMA', 'Crema Facial de Rosas 089', 'Producto premium de la línea 089', 'SKU-089', vUsdCurrencyID, 42.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (89, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Crema Facial de Rosas 089', 42.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 49.560000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 119, 15, 24, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 515, 215, 'PERM-089', 'Permiso regulatorio producto 089', 'APPROVED', 'CERT-089', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 089', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-090', vSiteMXID, 'SOAP', 'Infusión Detox 090', 'Producto premium de la línea 090', 'SKU-090', vUsdCurrencyID, 48.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (90, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Infusión Detox 090', 48.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 56.640000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 120, 16, 15, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 540, 230, 'PERM-090', 'Permiso regulatorio producto 090', 'APPROVED', 'CERT-090', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 090', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-091', vSiteMXID, 'ESSOIL', 'Exfoliante de Café 091', 'Producto premium de la línea 091', 'SKU-091', vUsdCurrencyID, 34.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (91, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Exfoliante de Café 091', 34.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 40.120000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 121, 10, 16, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 565, 245, 'PERM-091', 'Permiso regulatorio producto 091', 'APPROVED', 'CERT-091', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 091', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-092', vSiteMXID, 'BEVERAGE', 'Aceite de Coco Orgánico 092', 'Producto premium de la línea 092', 'SKU-092', vUsdCurrencyID, 40.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (92, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Aceite de Coco Orgánico 092', 40.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 47.200000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 122, 11, 17, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 590, 260, 'PERM-092', 'Permiso regulatorio producto 092', 'APPROVED', 'CERT-092', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 092', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-093', vSiteMXID, 'FOOD', 'Spray de Aromaterapia 093', 'Producto premium de la línea 093', 'SKU-093', vUsdCurrencyID, 46.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (93, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Spray de Aromaterapia 093', 46.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 54.280000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 123, 12, 18, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 615, 275, 'PERM-093', 'Permiso regulatorio producto 093', 'APPROVED', 'CERT-093', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 093', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-094', vSiteMXID, 'DERM', 'Mascarilla Capilar Nutritiva 094', 'Producto premium de la línea 094', 'SKU-094', vUsdCurrencyID, 52.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (94, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Mascarilla Capilar Nutritiva 094', 52.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 61.360000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 124, 13, 19, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 640, 290, 'PERM-094', 'Permiso regulatorio producto 094', 'APPROVED', 'CERT-094', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 094', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-095', vSiteMXID, 'HAIR', 'Tónico Facial de Té Verde 095', 'Producto premium de la línea 095', 'SKU-095', vUsdCurrencyID, 28.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (95, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Tónico Facial de Té Verde 095', 28.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 33.040000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 125, 14, 20, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 665, 305, 'PERM-095', 'Permiso regulatorio producto 095', 'APPROVED', 'CERT-095', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 095', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-096', vSiteMXID, 'AROMA', 'Jabón de Avena 096', 'Producto premium de la línea 096', 'SKU-096', vUsdCurrencyID, 35.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (96, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Jabón de Avena 096', 35.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 41.300000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 126, 15, 21, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 390, 200, 'PERM-096', 'Permiso regulatorio producto 096', 'APPROVED', 'CERT-096', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 096', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-097', vSiteMXID, 'SOAP', 'Aceite de Árbol de Té 097', 'Producto premium de la línea 097', 'SKU-097', vUsdCurrencyID, 41.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (97, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Aceite de Árbol de Té 097', 41.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 48.380000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 127, 16, 22, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 415, 215, 'PERM-097', 'Permiso regulatorio producto 097', 'APPROVED', 'CERT-097', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'HEALTH', 'Requisito regulatorio 097', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-098', vSiteMXID, 'ESSOIL', 'Colágeno Bebible 098', 'Producto premium de la línea 098', 'SKU-098', vUsdCurrencyID, 47.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (98, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Colágeno Bebible 098', 47.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 55.460000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 128, 10, 23, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 440, 230, 'PERM-098', 'Permiso regulatorio producto 098', 'APPROVED', 'CERT-098', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'IMPORT', 'Requisito regulatorio 098', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-099', vSiteMXID, 'BEVERAGE', 'Protector Labial Natural 099', 'Producto premium de la línea 099', 'SKU-099', vUsdCurrencyID, 31.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (99, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Protector Labial Natural 099', 31.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 36.580000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 129, 11, 24, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 465, 245, 'PERM-099', 'Permiso regulatorio producto 099', 'APPROVED', 'CERT-099', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'LABELING', 'Requisito regulatorio 099', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    CALL spInsertProduct('PROD-100', vSiteMXID, 'FOOD', 'Gel Calmante de Aloe 100', 'Producto premium de la línea 100', 'SKU-100', vUsdCurrencyID, 37.000000, vAdminPersonID, vProductID);
    INSERT INTO tmp_products (seq, productID, siteID, countryID, currencyID, productName, basePrice) VALUES (100, vProductID, vSiteMXID, vMexicoID, vUsdCurrencyID, 'Gel Calmante de Aloe 100', 37.000000);
    CALL spInsertProductPrice(vProductID, vSiteMXID, vUsdCurrencyID, 43.660000, '2025-01-01 00:00:00', '2025-12-31 23:59:59', TRUE);
    CALL spUpsertInventory(vSiteMXID, vProductID, 130, 12, 15, 'MANUAL');
    CALL spInsertCountryProductPermission(vProductID, vMexicoID, 490, 260, 'PERM-100', 'Permiso regulatorio producto 100', 'APPROVED', 'CERT-100', 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00', 'Permiso vigente para exportación');
    CALL spInsertCountryProductRequirement(vProductID, vMexicoID, 'PACKAGING', 'Requisito regulatorio 100', 'Cumple con la normativa aplicable', TRUE, 'Ministerio de Salud', '2025-02-15 10:00:00', '2026-02-15 10:00:00');

    -- =======================
    -- METRICAS DE SITIO
    -- =======================
    CALL spInsertDynamicSiteMetric(vSiteCRID, 'VISITS', '2025-12-31', 12840.000000);
    CALL spInsertDynamicSiteMetric(vSiteCRID, 'PURCHASES', '2025-12-31', 920.000000);
    CALL spInsertDynamicSiteMetric(vSiteCRID, 'CONVERSION_RATE', '2025-12-31', 0.071649);
    CALL spInsertDynamicSiteMetric(vSiteCRID, 'REVENUE', '2025-12-31', 184500.000000);
    CALL spInsertDynamicSiteMetric(vSiteCRID, 'SESSIONS', '2025-12-31', 13080.000000);
    CALL spInsertDynamicSiteMetric(vSiteCRID, 'BOUNCE_RATE', '2025-12-31', 0.354321);

    CALL spInsertDynamicSiteMetric(vSiteMXID, 'VISITS', '2025-12-31', 15120.000000);
    CALL spInsertDynamicSiteMetric(vSiteMXID, 'PURCHASES', '2025-12-31', 1165.000000);
    CALL spInsertDynamicSiteMetric(vSiteMXID, 'CONVERSION_RATE', '2025-12-31', 0.077050);
    CALL spInsertDynamicSiteMetric(vSiteMXID, 'REVENUE', '2025-12-31', 246700.000000);
    CALL spInsertDynamicSiteMetric(vSiteMXID, 'SESSIONS', '2025-12-31', 15360.000000);
    CALL spInsertDynamicSiteMetric(vSiteMXID, 'BOUNCE_RATE', '2025-12-31', 0.287654);

    -- =======================
    -- ORDENES (20) + 100 DETALLES
    -- =======================
    CALL spInsertCustomerOrder('ORD-001', vCustomer1ID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, 'DELIVERED', 4500.000000, 515.750000, 'Orden estática 001', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-01-05 09:30:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (1, vOrderID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, vCustomer1ID, '2025-01-05 09:30:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 1 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 18000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 2 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 22000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 3 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 25000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 4 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 30000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 5 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 35000.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-001', 'VISA', 'APPROVED', vOrderTotal, vCrcCurrencyID, 515.750000, 1, 'REF-001');
    CALL spInsertShipment(vOrderID, 'SHP-001', 'DELIVERED', 'San Jose, Costa Rica', 'TRK-001', 'DHL', 'CUSTOMER', '2025-01-07 10:30:00', '2025-01-11 13:30:00');

    CALL spInsertCustomerOrder('ORD-002', vCustomer2ID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, 'DELIVERED', 4500.000000, 515.750000, 'Orden estática 002', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-01-20 14:10:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (2, vOrderID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, vCustomer2ID, '2025-01-20 14:10:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 6 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 3000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 7 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 4000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 8 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 5000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 9 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 6000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 10 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 7000.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-002', 'MASTERCARD', 'APPROVED', vOrderTotal, vCrcCurrencyID, 515.750000, 1, 'REF-002');
    CALL spInsertShipment(vOrderID, 'SHP-002', 'DELIVERED', 'San Jose, Costa Rica', 'TRK-002', 'UPS', 'CUSTOMER', '2025-01-22 15:10:00', '2025-01-26 18:10:00');

    CALL spInsertCustomerOrder('ORD-003', vCustomer1ID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, 'DELIVERED', 4500.000000, 515.750000, 'Orden estática 003', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-02-08 11:25:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (3, vOrderID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, vCustomer1ID, '2025-02-08 11:25:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 11 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 18000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 12 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 22000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 13 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 25000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 14 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 30000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 15 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 35000.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-003', 'SINPE', 'APPROVED', vOrderTotal, vCrcCurrencyID, 515.750000, 1, 'REF-003');
    CALL spInsertShipment(vOrderID, 'SHP-003', 'DELIVERED', 'San Jose, Costa Rica', 'TRK-003', 'FedEx', 'CUSTOMER', '2025-02-10 12:25:00', '2025-02-14 15:25:00');

    CALL spInsertCustomerOrder('ORD-004', vCustomer2ID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, 'DELIVERED', 4500.000000, 515.750000, 'Orden estática 004', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-02-23 16:40:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (4, vOrderID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, vCustomer2ID, '2025-02-23 16:40:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 16 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 3000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 17 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 4000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 18 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 5000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 19 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 6000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 20 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 7000.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-004', 'VISA', 'APPROVED', vOrderTotal, vCrcCurrencyID, 515.750000, 1, 'REF-004');
    CALL spInsertShipment(vOrderID, 'SHP-004', 'DELIVERED', 'San Jose, Costa Rica', 'TRK-004', 'DHL', 'CUSTOMER', '2025-02-25 17:40:00', '2025-03-01 20:40:00');

    CALL spInsertCustomerOrder('ORD-005', vCustomer1ID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, 'DELIVERED', 4500.000000, 515.750000, 'Orden estática 005', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-03-10 10:05:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (5, vOrderID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, vCustomer1ID, '2025-03-10 10:05:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 21 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 18000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 22 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 22000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 23 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 25000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 24 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 30000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 25 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 35000.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-005', 'MASTERCARD', 'APPROVED', vOrderTotal, vCrcCurrencyID, 515.750000, 1, 'REF-005');
    CALL spInsertShipment(vOrderID, 'SHP-005', 'DELIVERED', 'San Jose, Costa Rica', 'TRK-005', 'UPS', 'CUSTOMER', '2025-03-12 11:05:00', '2025-03-16 14:05:00');

    CALL spInsertCustomerOrder('ORD-006', vCustomer2ID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, 'DELIVERED', 4500.000000, 515.750000, 'Orden estática 006', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-04-14 13:15:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (6, vOrderID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, vCustomer2ID, '2025-04-14 13:15:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 26 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 3000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 27 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 4000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 28 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 5000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 29 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 6000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 30 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 7000.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-006', 'SINPE', 'APPROVED', vOrderTotal, vCrcCurrencyID, 515.750000, 1, 'REF-006');
    CALL spInsertShipment(vOrderID, 'SHP-006', 'DELIVERED', 'San Jose, Costa Rica', 'TRK-006', 'FedEx', 'CUSTOMER', '2025-04-16 14:15:00', '2025-04-20 17:15:00');

    CALL spInsertCustomerOrder('ORD-007', vCustomer1ID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, 'DELIVERED', 4500.000000, 515.750000, 'Orden estática 007', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-04-28 09:50:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (7, vOrderID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, vCustomer1ID, '2025-04-28 09:50:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 31 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 18000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 32 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 22000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 33 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 25000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 34 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 30000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 35 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 35000.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-007', 'VISA', 'APPROVED', vOrderTotal, vCrcCurrencyID, 515.750000, 1, 'REF-007');
    CALL spInsertShipment(vOrderID, 'SHP-007', 'DELIVERED', 'San Jose, Costa Rica', 'TRK-007', 'DHL', 'CUSTOMER', '2025-04-30 10:50:00', '2025-05-04 13:50:00');

    CALL spInsertCustomerOrder('ORD-008', vCustomer2ID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, 'DELIVERED', 4500.000000, 515.750000, 'Orden estática 008', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-05-09 15:05:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (8, vOrderID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, vCustomer2ID, '2025-05-09 15:05:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 36 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 3000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 37 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 4000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 38 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 5000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 39 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 6000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 40 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 7000.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-008', 'MASTERCARD', 'APPROVED', vOrderTotal, vCrcCurrencyID, 515.750000, 1, 'REF-008');
    CALL spInsertShipment(vOrderID, 'SHP-008', 'DELIVERED', 'San Jose, Costa Rica', 'TRK-008', 'UPS', 'CUSTOMER', '2025-05-11 16:05:00', '2025-05-15 19:05:00');

    CALL spInsertCustomerOrder('ORD-009', vCustomer1ID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, 'DELIVERED', 4500.000000, 515.750000, 'Orden estática 009', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-06-17 12:30:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (9, vOrderID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, vCustomer1ID, '2025-06-17 12:30:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 41 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 18000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 42 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 22000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 43 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 25000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 44 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 30000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 45 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 35000.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-009', 'SINPE', 'APPROVED', vOrderTotal, vCrcCurrencyID, 515.750000, 1, 'REF-009');
    CALL spInsertShipment(vOrderID, 'SHP-009', 'DELIVERED', 'San Jose, Costa Rica', 'TRK-009', 'FedEx', 'CUSTOMER', '2025-06-19 13:30:00', '2025-06-23 16:30:00');

    CALL spInsertCustomerOrder('ORD-010', vCustomer2ID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, 'DELIVERED', 4500.000000, 515.750000, 'Orden estática 010', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-06-26 17:45:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (10, vOrderID, vSiteCRID, vCostaRicaID, vCrcCurrencyID, vCustomer2ID, '2025-06-26 17:45:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 46 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 3000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 47 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 4000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 48 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 5000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 49 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 6000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 50 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 7000.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-010', 'VISA', 'APPROVED', vOrderTotal, vCrcCurrencyID, 515.750000, 1, 'REF-010');
    CALL spInsertShipment(vOrderID, 'SHP-010', 'DELIVERED', 'San Jose, Costa Rica', 'TRK-010', 'DHL', 'CUSTOMER', '2025-06-28 18:45:00', '2025-07-02 21:45:00');

    CALL spInsertCustomerOrder('ORD-011', vCustomer1ID, vSiteMXID, vMexicoID, vMxnCurrencyID, 'DELIVERED', 65.000000, 17.350000, 'Orden estática 011', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-07-04 08:20:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (11, vOrderID, vSiteMXID, vMexicoID, vMxnCurrencyID, vCustomer1ID, '2025-07-04 08:20:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 51 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 650.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 52 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 850.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 53 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 54 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1200.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 55 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1400.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-011', 'MASTERCARD', 'APPROVED', vOrderTotal, vMxnCurrencyID, 17.350000, 2, 'REF-011');
    CALL spInsertShipment(vOrderID, 'SHP-011', 'DELIVERED', 'Ciudad de Mexico, Mexico', 'TRK-011', 'UPS', 'CUSTOMER', '2025-07-06 09:20:00', '2025-07-10 12:20:00');

    CALL spInsertCustomerOrder('ORD-012', vCustomer2ID, vSiteMXID, vMexicoID, vMxnCurrencyID, 'DELIVERED', 65.000000, 17.350000, 'Orden estática 012', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-08-12 14:55:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (12, vOrderID, vSiteMXID, vMexicoID, vMxnCurrencyID, vCustomer2ID, '2025-08-12 14:55:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 56 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 90.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 57 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 120.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 58 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 150.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 59 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 180.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 60 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 220.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-012', 'SINPE', 'APPROVED', vOrderTotal, vMxnCurrencyID, 17.350000, 2, 'REF-012');
    CALL spInsertShipment(vOrderID, 'SHP-012', 'DELIVERED', 'Ciudad de Mexico, Mexico', 'TRK-012', 'FedEx', 'CUSTOMER', '2025-08-14 15:55:00', '2025-08-18 18:55:00');

    CALL spInsertCustomerOrder('ORD-013', vCustomer1ID, vSiteMXID, vMexicoID, vMxnCurrencyID, 'DELIVERED', 65.000000, 17.350000, 'Orden estática 013', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-09-06 11:15:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (13, vOrderID, vSiteMXID, vMexicoID, vMxnCurrencyID, vCustomer1ID, '2025-09-06 11:15:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 61 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 650.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 62 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 850.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 63 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 64 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1200.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 65 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1400.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-013', 'VISA', 'APPROVED', vOrderTotal, vMxnCurrencyID, 17.350000, 2, 'REF-013');
    CALL spInsertShipment(vOrderID, 'SHP-013', 'DELIVERED', 'Ciudad de Mexico, Mexico', 'TRK-013', 'DHL', 'CUSTOMER', '2025-09-08 12:15:00', '2025-09-12 15:15:00');

    CALL spInsertCustomerOrder('ORD-014', vCustomer2ID, vSiteMXID, vMexicoID, vMxnCurrencyID, 'DELIVERED', 65.000000, 17.350000, 'Orden estática 014', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-09-23 16:05:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (14, vOrderID, vSiteMXID, vMexicoID, vMxnCurrencyID, vCustomer2ID, '2025-09-23 16:05:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 66 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 90.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 67 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 120.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 68 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 150.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 69 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 180.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 70 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 220.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-014', 'MASTERCARD', 'APPROVED', vOrderTotal, vMxnCurrencyID, 17.350000, 2, 'REF-014');
    CALL spInsertShipment(vOrderID, 'SHP-014', 'DELIVERED', 'Ciudad de Mexico, Mexico', 'TRK-014', 'UPS', 'CUSTOMER', '2025-09-25 17:05:00', '2025-09-29 20:05:00');

    CALL spInsertCustomerOrder('ORD-015', vCustomer1ID, vSiteMXID, vMexicoID, vMxnCurrencyID, 'DELIVERED', 65.000000, 17.350000, 'Orden estática 015', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-10-11 09:40:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (15, vOrderID, vSiteMXID, vMexicoID, vMxnCurrencyID, vCustomer1ID, '2025-10-11 09:40:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 71 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 650.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 72 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 850.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 73 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 74 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1200.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 75 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1400.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-015', 'SINPE', 'APPROVED', vOrderTotal, vMxnCurrencyID, 17.350000, 2, 'REF-015');
    CALL spInsertShipment(vOrderID, 'SHP-015', 'DELIVERED', 'Ciudad de Mexico, Mexico', 'TRK-015', 'FedEx', 'CUSTOMER', '2025-10-13 10:40:00', '2025-10-17 13:40:00');

    CALL spInsertCustomerOrder('ORD-016', vCustomer2ID, vSiteMXID, vMexicoID, vMxnCurrencyID, 'DELIVERED', 65.000000, 17.350000, 'Orden estática 016', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-10-28 18:10:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (16, vOrderID, vSiteMXID, vMexicoID, vMxnCurrencyID, vCustomer2ID, '2025-10-28 18:10:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 76 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 90.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 77 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 120.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 78 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 150.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 79 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 180.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 80 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 220.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-016', 'VISA', 'APPROVED', vOrderTotal, vMxnCurrencyID, 17.350000, 2, 'REF-016');
    CALL spInsertShipment(vOrderID, 'SHP-016', 'DELIVERED', 'Ciudad de Mexico, Mexico', 'TRK-016', 'DHL', 'CUSTOMER', '2025-10-30 19:10:00', '2025-11-03 22:10:00');

    CALL spInsertCustomerOrder('ORD-017', vCustomer1ID, vSiteMXID, vMexicoID, vMxnCurrencyID, 'DELIVERED', 65.000000, 17.350000, 'Orden estática 017', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-11-07 10:00:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (17, vOrderID, vSiteMXID, vMexicoID, vMxnCurrencyID, vCustomer1ID, '2025-11-07 10:00:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 81 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 650.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 82 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 850.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 83 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 84 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1200.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 85 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1400.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-017', 'MASTERCARD', 'APPROVED', vOrderTotal, vMxnCurrencyID, 17.350000, 2, 'REF-017');
    CALL spInsertShipment(vOrderID, 'SHP-017', 'DELIVERED', 'Ciudad de Mexico, Mexico', 'TRK-017', 'UPS', 'CUSTOMER', '2025-11-09 11:00:00', '2025-11-13 14:00:00');

    CALL spInsertCustomerOrder('ORD-018', vCustomer2ID, vSiteMXID, vMexicoID, vMxnCurrencyID, 'DELIVERED', 65.000000, 17.350000, 'Orden estática 018', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-11-24 13:35:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (18, vOrderID, vSiteMXID, vMexicoID, vMxnCurrencyID, vCustomer2ID, '2025-11-24 13:35:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 86 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 90.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 87 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 120.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 88 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 150.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 89 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 180.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 90 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 220.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-018', 'SINPE', 'APPROVED', vOrderTotal, vMxnCurrencyID, 17.350000, 2, 'REF-018');
    CALL spInsertShipment(vOrderID, 'SHP-018', 'DELIVERED', 'Ciudad de Mexico, Mexico', 'TRK-018', 'FedEx', 'CUSTOMER', '2025-11-26 14:35:00', '2025-11-30 17:35:00');

    CALL spInsertCustomerOrder('ORD-019', vCustomer1ID, vSiteMXID, vMexicoID, vMxnCurrencyID, 'DELIVERED', 65.000000, 17.350000, 'Orden estática 019', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-12-05 15:20:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (19, vOrderID, vSiteMXID, vMexicoID, vMxnCurrencyID, vCustomer1ID, '2025-12-05 15:20:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 91 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 650.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 92 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 850.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 93 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1000.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 94 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1200.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 95 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 1400.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-019', 'VISA', 'APPROVED', vOrderTotal, vMxnCurrencyID, 17.350000, 2, 'REF-019');
    CALL spInsertShipment(vOrderID, 'SHP-019', 'DELIVERED', 'Ciudad de Mexico, Mexico', 'TRK-019', 'DHL', 'CUSTOMER', '2025-12-07 16:20:00', '2025-12-11 19:20:00');

    CALL spInsertCustomerOrder('ORD-020', vCustomer2ID, vSiteMXID, vMexicoID, vMxnCurrencyID, 'DELIVERED', 65.000000, 17.350000, 'Orden estática 020', vOrderID);
    UPDATE customerOrder SET orderDate = '2025-12-20 19:05:00' WHERE customerOrderID = vOrderID;
    INSERT INTO tmp_orders (seq, orderID, siteID, countryID, currencyID, customerID, orderDate) VALUES (20, vOrderID, vSiteMXID, vMexicoID, vMxnCurrencyID, vCustomer2ID, '2025-12-20 19:05:00');
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 96 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 90.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 97 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 120.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 98 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 150.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 99 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 180.000000, 0.000000, 0.000000);
    SELECT productID INTO vProductID FROM tmp_products WHERE seq = 100 LIMIT 1;
    CALL spInsertCustomerOrderDetail(vOrderID, vProductID, 1, 220.000000, 0.000000, 0.000000);
    SELECT totalAmount INTO vOrderTotal FROM customerOrder WHERE customerOrderID = vOrderID LIMIT 1;
    CALL spInsertPaymentTransaction(vOrderID, 'PAY-020', 'MASTERCARD', 'APPROVED', vOrderTotal, vMxnCurrencyID, 17.350000, 2, 'REF-020');
    CALL spInsertShipment(vOrderID, 'SHP-020', 'DELIVERED', 'Ciudad de Mexico, Mexico', 'TRK-020', 'UPS', 'CUSTOMER', '2025-12-22 20:05:00', '2025-12-26 23:05:00');

END $$

DELIMITER ;

CALL spSeedFullData();