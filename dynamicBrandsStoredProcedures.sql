USE dynamicBrandsDB;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_log_etl_step $$
CREATE PROCEDURE sp_log_etl_step(
    IN p_processName VARCHAR(60),
    IN p_sourceSystem VARCHAR(30),
    IN p_targetSystem VARCHAR(30),
    IN p_executionStatus VARCHAR(30),
    IN p_recordsExtracted INT,
    IN p_recordsLoaded INT,
    IN p_errorDetails VARCHAR(500)
)
BEGIN
    INSERT INTO etlExecutionLog (
        processName,
        sourceSystem,
        targetSystem,
        executionStatus,
        recordsExtracted,
        recordsLoaded,
        errorDetails,
        startedAt,
        finishedAt,
        createdAt
    )
    VALUES (
        p_processName,
        p_sourceSystem,
        p_targetSystem,
        p_executionStatus,
        p_recordsExtracted,
        p_recordsLoaded,
        p_errorDetails,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP PROCEDURE IF EXISTS sp_seed_base_catalogs $$
CREATE PROCEDURE sp_seed_base_catalogs()
BEGIN
    DECLARE v_error_message TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_seed_base_catalogs', 'MANUAL', 'dynamicBrandsDB', 'ERROR', 0, 0, v_error_message);
    END;

    START TRANSACTION;

    INSERT INTO changeSource (sourceCode, sourceName, sourceDescription, isActive, createdAt, updatedAt) VALUES
    ('SYSTEM', 'System', 'System generated change', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('MANUAL', 'Manual', 'Manual change', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ETL', 'ETL', 'ETL process change', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO userRole (roleCode, roleName, roleDescription, isActive, createdAt, updatedAt) VALUES
    ('ADMIN', 'Administrator', 'Full access user', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('OPERATOR', 'Operator', 'Operational user', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO dynamicSiteStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('DRAFT', 'Draft', 'Draft status', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ACTIVE', 'Active', 'Active status', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('CLOSED', 'Closed', 'Closed status', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO dynamicSiteGenerationStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Pending generation', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SUCCESS', 'Success', 'Successful generation', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('FAILED', 'Failed', 'Failed generation', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO dynamicSiteEventType (eventTypeCode, eventName, eventDescription, isActive, createdAt, updatedAt) VALUES
    ('SITE_CREATED', 'Site Created', 'Site creation event', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SITE_UPDATED', 'Site Updated', 'Site update event', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO orderStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('CREATED', 'Created', 'Order created', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('PAID', 'Paid', 'Order paid', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SHIPPED', 'Shipped', 'Order shipped', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('DELIVERED', 'Delivered', 'Order delivered', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO productCategory (categoryCode, categoryName, categoryDescription, isActive, createdAt, updatedAt) VALUES
    ('OIL', 'Oil', 'Oil products', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SOAP', 'Soap', 'Soap products', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('BEAUTY', 'Beauty', 'Beauty products', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO productImageType (typeCode, typeName, typeDescription, isActive, createdAt, updatedAt) VALUES
    ('MAIN', 'Main', 'Main image', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('GALLERY', 'Gallery', 'Gallery image', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO packagingType (packagingTypeCode, packagingTypeName, packagingTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('BOTTLE', 'Bottle', 'Bottle packaging', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('BOX', 'Box', 'Box packaging', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO labelType (labelTypeCode, labelTypeName, labelTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('PRIMARY', 'Primary', 'Primary label', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('WARNING', 'Warning', 'Warning label', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO regulatoryRequirementType (requirementTypeCode, requirementTypeName, requirementTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('HEALTH', 'Health', 'Health requirement', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('IMPORT', 'Import', 'Import requirement', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO permissionStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Pending permission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('APPROVED', 'Approved', 'Approved permission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('EXPIRED', 'Expired', 'Expired permission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO inventorySource (sourceCode, sourceName, sourceDescription, isActive, createdAt, updatedAt) VALUES
    ('HUB', 'Hub', 'Hub inventory source', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('MANUAL', 'Manual', 'Manual inventory source', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO paymentMethod (methodCode, methodName, methodDescription, isActive, createdAt, updatedAt) VALUES
    ('CARD', 'Card', 'Card payment', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('TRANSFER', 'Transfer', 'Bank transfer', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO paymentTransactionStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Payment pending', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('APPROVED', 'Approved', 'Payment approved', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('REJECTED', 'Rejected', 'Payment rejected', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO paymentProvider (providerCode, providerName, providerDescription, isActive, createdAt, updatedAt) VALUES
    ('VISA', 'Visa', 'Visa network', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('MASTERCARD', 'Mastercard', 'Mastercard network', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO shipmentViewType (viewTypeCode, viewTypeName, viewTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('CUSTOMER', 'Customer', 'Customer view', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('INTERNAL', 'Internal', 'Internal view', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO shipmentStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Pending shipment', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('IN_TRANSIT', 'In Transit', 'Shipment in transit', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('DELIVERED', 'Delivered', 'Shipment delivered', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    COMMIT;
    CALL sp_log_etl_step('sp_seed_base_catalogs', 'MANUAL', 'dynamicBrandsDB', 'SUCCESS', 0, 0, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_currency $$
CREATE PROCEDURE sp_insert_currency(
    IN p_currencyCode VARCHAR(20),
    IN p_currencyName VARCHAR(45),
    IN p_currencySymbol VARCHAR(30)
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_currency', 'MANUAL', 'currency', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO currency (currencyCode, currencyName, currencySymbol, isActive, createdAt, updatedAt)
    VALUES (p_currencyCode, p_currencyName, p_currencySymbol, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    COMMIT;
    CALL sp_log_etl_step('sp_insert_currency', 'MANUAL', 'currency', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_country $$
CREATE PROCEDURE sp_insert_country(
    IN p_countryName VARCHAR(50),
    IN p_iso2Code CHAR(2),
    IN p_iso3Code CHAR(3),
    IN p_localCurrencyID BIGINT
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_country', 'MANUAL', 'country', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO country (countryName, iso2Code, iso3Code, localCurrencyID, isActive, createdAt, updatedAt)
    VALUES (p_countryName, p_iso2Code, p_iso3Code, p_localCurrencyID, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    COMMIT;
    CALL sp_log_etl_step('sp_insert_country', 'MANUAL', 'country', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_userInfo $$
CREATE PROCEDURE sp_insert_userInfo(
    IN p_userCode VARCHAR(30),
    IN p_firstName VARCHAR(100),
    IN p_lastName VARCHAR(100),
    IN p_email VARCHAR(150),
    IN p_passwordHash VARCHAR(255),
    IN p_roleCode VARCHAR(30)
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_userInfo', 'MANUAL', 'userInfo', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO userInfo (
        userCode, firstName, lastName, email, passwordHash, roleCode, isActive, lastLoginAt, createdAt, updatedAt
    )
    VALUES (
        p_userCode, p_firstName, p_lastName, p_email, p_passwordHash, p_roleCode, TRUE, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_userInfo', 'MANUAL', 'userInfo', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_brandTemplate $$
CREATE PROCEDURE sp_insert_brandTemplate(
    IN p_brandCode VARCHAR(30),
    IN p_brandName VARCHAR(40),
    IN p_logoURL VARCHAR(255),
    IN p_corePromise VARCHAR(250),
    IN p_targetAudience VARCHAR(200)
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_brandTemplate', 'MANUAL', 'brandTemplate', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO brandTemplate (
        brandCode, brandName, logoURL, corePromise, targetAudience, isActive, createdAt, updatedAt
    )
    VALUES (
        p_brandCode, p_brandName, p_logoURL, p_corePromise, p_targetAudience, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_brandTemplate', 'MANUAL', 'brandTemplate', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_dynamicSiteInfo $$
CREATE PROCEDURE sp_insert_dynamicSiteInfo(
    IN p_siteCode VARCHAR(30),
    IN p_siteName VARCHAR(80),
    IN p_brandCode VARCHAR(30),
    IN p_countryID BIGINT,
    IN p_currencyID BIGINT,
    IN p_siteStatusCode VARCHAR(30),
    IN p_primaryDomainName VARCHAR(150),
    IN p_marketingFocus VARCHAR(80),
    IN p_brandVoice VARCHAR(80),
    IN p_targetSegment VARCHAR(80),
    IN p_launchDate DATETIME,
    IN p_closeDate DATETIME,
    IN p_clientName VARCHAR(80),
    IN p_logoURL VARCHAR(255)
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_dynamicSiteInfo', 'MANUAL', 'dynamicSiteInfo', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO dynamicSiteInfo (
        siteCode, siteName, brandCode, countryID, currencyID, siteStatusCode,
        primaryDomainName, marketingFocus, brandVoice, targetSegment,
        launchDate, closeDate, clientName, logoURL, isActive, createdAt, updatedAt
    )
    VALUES (
        p_siteCode, p_siteName, p_brandCode, p_countryID, p_currencyID, p_siteStatusCode,
        p_primaryDomainName, p_marketingFocus, p_brandVoice, p_targetSegment,
        p_launchDate, p_closeDate, p_clientName, p_logoURL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_dynamicSiteInfo', 'MANUAL', 'dynamicSiteInfo', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_dynamicSiteDomain $$
CREATE PROCEDURE sp_insert_dynamicSiteDomain(
    IN p_dynamicSiteID BIGINT,
    IN p_domainName VARCHAR(150),
    IN p_isPrimary BOOLEAN
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_dynamicSiteDomain', 'MANUAL', 'dynamicSiteDomain', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO dynamicSiteDomain (
        dynamicSiteID, domainName, isPrimary, isActive, createdAt, updatedAt
    )
    VALUES (
        p_dynamicSiteID, p_domainName, p_isPrimary, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_dynamicSiteDomain', 'MANUAL', 'dynamicSiteDomain', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_dynamicSiteAIGeneration $$
CREATE PROCEDURE sp_insert_dynamicSiteAIGeneration(
    IN p_dynamicSiteID BIGINT,
    IN p_promptContent TEXT,
    IN p_generatedConfiguration JSON,
    IN p_generationStatusCode VARCHAR(30),
    IN p_generationDetails VARCHAR(250)
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_dynamicSiteAIGeneration', 'MANUAL', 'dynamicSiteAIGeneration', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO dynamicSiteAIGeneration (
        dynamicSiteID, promptContent, generatedConfiguration, generationStatusCode,
        generationDetails, generatedAt, createdAt, updatedAt
    )
    VALUES (
        p_dynamicSiteID, p_promptContent, p_generatedConfiguration, p_generationStatusCode,
        p_generationDetails, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_dynamicSiteAIGeneration', 'MANUAL', 'dynamicSiteAIGeneration', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_customer $$
CREATE PROCEDURE sp_insert_customer(
    IN p_customerCode VARCHAR(50),
    IN p_countryID BIGINT,
    IN p_email VARCHAR(150),
    IN p_firstName VARCHAR(100),
    IN p_lastName VARCHAR(100),
    IN p_passwordHash VARCHAR(255)
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_customer', 'MANUAL', 'customer', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO customer (
        customerCode, countryID, email, firstName, lastName, passwordHash,
        isEmailVerified, isActive, lastLoginAt, createdAt, updatedAt
    )
    VALUES (
        p_customerCode, p_countryID, p_email, p_firstName, p_lastName, p_passwordHash,
        FALSE, TRUE, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_customer', 'MANUAL', 'customer', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_product $$
CREATE PROCEDURE sp_insert_product(
    IN p_productCode VARCHAR(50),
    IN p_dynamicSiteID BIGINT,
    IN p_categoryCode VARCHAR(30),
    IN p_productName VARCHAR(120),
    IN p_productDescription VARCHAR(500),
    IN p_sku VARCHAR(50),
    IN p_baseCurrencyID BIGINT,
    IN p_basePrice DECIMAL(18,6),
    IN p_updatedByUserID BIGINT
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_product', 'MANUAL', 'product', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO product (
        productCode, dynamicSiteID, categoryCode, productName, productDescription,
        sku, baseCurrencyID, basePrice, updatedByUserID, isActive, createdAt, updatedAt
    )
    VALUES (
        p_productCode, p_dynamicSiteID, p_categoryCode, p_productName, p_productDescription,
        p_sku, p_baseCurrencyID, p_basePrice, p_updatedByUserID, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_product', 'MANUAL', 'product', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_productPrice $$
CREATE PROCEDURE sp_insert_productPrice(
    IN p_productID BIGINT,
    IN p_currencyID BIGINT,
    IN p_priceAmount DECIMAL(18,6),
    IN p_validFrom TIMESTAMP,
    IN p_validTo TIMESTAMP,
    IN p_isCurrent BOOLEAN
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_productPrice', 'MANUAL', 'productPrice', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO productPrice (
        productID, currencyID, priceAmount, validFrom, validTo, isCurrent, createdAt, updatedAt
    )
    VALUES (
        p_productID, p_currencyID, p_priceAmount, p_validFrom, p_validTo, p_isCurrent, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_productPrice', 'MANUAL', 'productPrice', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_inventory $$
CREATE PROCEDURE sp_insert_inventory(
    IN p_dynamicSiteID BIGINT,
    IN p_productID BIGINT,
    IN p_availableQuantity INT,
    IN p_reservedQuantity INT,
    IN p_reorderLevel INT,
    IN p_sourceCode VARCHAR(30)
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE v_sellableQuantity INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_inventory', 'MANUAL', 'inventory', 'ERROR', 0, 0, v_error_message);
    END;
    SET v_sellableQuantity = p_availableQuantity - p_reservedQuantity;
    START TRANSACTION;
    INSERT INTO inventory (
        dynamicSiteID, productID, availableQuantity, reservedQuantity, sellableQuantity,
        reorderLevel, sourceCode, lastStockUpdateAt, createdAt, updatedAt
    )
    VALUES (
        p_dynamicSiteID, p_productID, p_availableQuantity, p_reservedQuantity, v_sellableQuantity,
        p_reorderLevel, p_sourceCode, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_inventory', 'MANUAL', 'inventory', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_customerOrder $$
CREATE PROCEDURE sp_insert_customerOrder(
    IN p_orderCode VARCHAR(50),
    IN p_customerID BIGINT,
    IN p_dynamicSiteID BIGINT,
    IN p_customerCountryID BIGINT,
    IN p_currencyID BIGINT,
    IN p_orderStatusCode VARCHAR(30),
    IN p_subTotal DECIMAL(18,6),
    IN p_taxTotal DECIMAL(18,6),
    IN p_shippingAmount DECIMAL(18,6),
    IN p_exchangeRate DECIMAL(18,6),
    IN p_notes VARCHAR(200)
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE v_totalAmount DECIMAL(18,6);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_customerOrder', 'MANUAL', 'customerOrder', 'ERROR', 0, 0, v_error_message);
    END;
    SET v_totalAmount = ROUND(p_subTotal + p_taxTotal + p_shippingAmount, 6);
    START TRANSACTION;
    INSERT INTO customerOrder (
        orderCode, customerID, dynamicSiteID, customerCountryID, currencyID,
        orderStatusCode, orderDate, subTotal, taxTotal, shippingAmount,
        totalAmount, exchangeRate, notes, createdAt, updatedAt
    )
    VALUES (
        p_orderCode, p_customerID, p_dynamicSiteID, p_customerCountryID, p_currencyID,
        p_orderStatusCode, CURRENT_TIMESTAMP, p_subTotal, p_taxTotal, p_shippingAmount,
        v_totalAmount, p_exchangeRate, p_notes, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_customerOrder', 'MANUAL', 'customerOrder', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_paymentTransaction $$
CREATE PROCEDURE sp_insert_paymentTransaction(
    IN p_customerOrderID BIGINT,
    IN p_transactionCode VARCHAR(50),
    IN p_methodCode VARCHAR(30),
    IN p_paymentStatusCode VARCHAR(30),
    IN p_providerCode VARCHAR(30),
    IN p_transactionAmount DECIMAL(18,6),
    IN p_currencyID BIGINT,
    IN p_providerReference VARCHAR(80)
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_paymentTransaction', 'MANUAL', 'paymentTransaction', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO paymentTransaction (
        customerOrderID, transactionCode, methodCode, paymentStatusCode, providerCode,
        transactionAmount, currencyID, providerReference, transactionDate, createdAt, updatedAt
    )
    VALUES (
        p_customerOrderID, p_transactionCode, p_methodCode, p_paymentStatusCode, p_providerCode,
        p_transactionAmount, p_currencyID, p_providerReference, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_paymentTransaction', 'MANUAL', 'paymentTransaction', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_shipment $$
CREATE PROCEDURE sp_insert_shipment(
    IN p_customerOrderID BIGINT,
    IN p_shipmentCode VARCHAR(50),
    IN p_shipmentStatusCode VARCHAR(30),
    IN p_shippingAddress VARCHAR(250),
    IN p_trackingNumber VARCHAR(80),
    IN p_carrierName VARCHAR(60),
    IN p_viewTypeCode VARCHAR(30),
    IN p_shippedAt TIMESTAMP,
    IN p_deliveredAt TIMESTAMP
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_shipment', 'MANUAL', 'shipment', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO shipment (
        customerOrderID, shipmentCode, shipmentStatusCode, shippingAddress,
        trackingNumber, carrierName, viewTypeCode, shippedAt, deliveredAt, createdAt, updatedAt
    )
    VALUES (
        p_customerOrderID, p_shipmentCode, p_shipmentStatusCode, p_shippingAddress,
        p_trackingNumber, p_carrierName, p_viewTypeCode, p_shippedAt, p_deliveredAt, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_shipment', 'MANUAL', 'shipment', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_countryProductRequirement $$
CREATE PROCEDURE sp_insert_countryProductRequirement(
    IN p_productID BIGINT,
    IN p_countryID BIGINT,
    IN p_requirementTypeCode VARCHAR(30),
    IN p_requirementName VARCHAR(100),
    IN p_requirementDescription VARCHAR(250),
    IN p_isMandatory BOOLEAN,
    IN p_issuedBy VARCHAR(80),
    IN p_validFrom TIMESTAMP,
    IN p_validTo TIMESTAMP
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_countryProductRequirement', 'MANUAL', 'countryProductRequirement', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO countryProductRequirement (
        productID, countryID, requirementTypeCode, requirementName, requirementDescription,
        isMandatory, issuedBy, validFrom, validTo, isActive, createdAt, updatedAt
    )
    VALUES (
        p_productID, p_countryID, p_requirementTypeCode, p_requirementName, p_requirementDescription,
        p_isMandatory, p_issuedBy, p_validFrom, p_validTo, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_countryProductRequirement', 'MANUAL', 'countryProductRequirement', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_countryProductPermission $$
CREATE PROCEDURE sp_insert_countryProductPermission(
    IN p_productID BIGINT,
    IN p_countryID BIGINT,
    IN p_permissionCode VARCHAR(50),
    IN p_permissionName VARCHAR(100),
    IN p_permissionStatusCode VARCHAR(30),
    IN p_certificateNumber VARCHAR(80),
    IN p_issuedBy VARCHAR(80),
    IN p_issuedAt TIMESTAMP,
    IN p_expiresAt TIMESTAMP,
    IN p_notes VARCHAR(250)
)
BEGIN
    DECLARE v_error_message TEXT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_message = MESSAGE_TEXT;
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_countryProductPermission', 'MANUAL', 'countryProductPermission', 'ERROR', 0, 0, v_error_message);
    END;
    START TRANSACTION;
    INSERT INTO countryProductPermission (
        productID, countryID, permissionCode, permissionName, permissionStatusCode,
        certificateNumber, issuedBy, issuedAt, expiresAt, notes, createdAt, updatedAt
    )
    VALUES (
        p_productID, p_countryID, p_permissionCode, p_permissionName, p_permissionStatusCode,
        p_certificateNumber, p_issuedBy, p_issuedAt, p_expiresAt, p_notes, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
    );
    COMMIT;
    CALL sp_log_etl_step('sp_insert_countryProductPermission', 'MANUAL', 'countryProductPermission', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_seed_sample_dynamicBrands $$
CREATE PROCEDURE sp_seed_sample_dynamicBrands()
BEGIN
    DECLARE v_crc BIGINT;
    DECLARE v_usd BIGINT;
    DECLARE v_cr_country BIGINT;
    DECLARE v_userID BIGINT;
    DECLARE v_siteID BIGINT;
    DECLARE v_customerID BIGINT;
    DECLARE v_productID BIGINT;
    DECLARE v_orderID BIGINT;

    CALL sp_insert_currency('USD', 'US Dollar', '$');
    CALL sp_insert_currency('CRC', 'Costa Rican Colon', '₡');

    SELECT currencyID INTO v_usd FROM currency WHERE currencyCode = 'USD' LIMIT 1;
    SELECT currencyID INTO v_crc FROM currency WHERE currencyCode = 'CRC' LIMIT 1;

    CALL sp_insert_country('Costa Rica', 'CR', 'CRI', v_crc);
    SELECT countryID INTO v_cr_country FROM country WHERE iso2Code = 'CR' LIMIT 1;

    CALL sp_insert_userInfo('USR001', 'Admin', 'Dynamic', 'admin@dynamicbrands.com', 'hash_demo', 'ADMIN');
    SELECT userID INTO v_userID FROM userInfo WHERE userCode = 'USR001' LIMIT 1;

    CALL sp_insert_brandTemplate('BRAND001', 'PureAura', 'https://logo.test/pureaura.png', 'Natural wellness', 'Premium wellness audience');

    CALL sp_insert_dynamicSiteInfo(
        'SITE001',
        'PureAura Costa Rica',
        'BRAND001',
        v_cr_country,
        v_crc,
        'ACTIVE',
        'pureaura-cr.com',
        'Natural health',
        'Warm',
        'Adults',
        NOW(),
        NULL,
        'Dynamic Brands',
        'https://logo.test/pureaura-cr.png'
    );

    SELECT dynamicSiteID INTO v_siteID FROM dynamicSiteInfo WHERE siteCode = 'SITE001' LIMIT 1;

    CALL sp_insert_dynamicSiteDomain(v_siteID, 'www.pureaura-cr.com', TRUE);

    CALL sp_insert_dynamicSiteAIGeneration(
        v_siteID,
        'Generate premium wellness site for Costa Rica',
        JSON_OBJECT('theme', 'wellness', 'country', 'CR'),
        'SUCCESS',
        'Initial generation completed'
    );

    CALL sp_insert_customer('CUS001', v_cr_country, 'cliente1@test.com', 'Laura', 'Ramirez', 'hash_cliente');
    SELECT customerID INTO v_customerID FROM customer WHERE customerCode = 'CUS001' LIMIT 1;

    CALL sp_insert_product(
        'PROD001',
        v_siteID,
        'OIL',
        'Aceite Esencial Premium',
        'Aceite natural para aromaterapia',
        'SKU-001',
        v_usd,
        25.500000,
        v_userID
    );

    SELECT productID INTO v_productID FROM product WHERE productCode = 'PROD001' LIMIT 1;

    CALL sp_insert_productPrice(v_productID, v_crc, 14500.000000, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL sp_insert_inventory(v_siteID, v_productID, 120, 10, 20, 'HUB');

    CALL sp_insert_countryProductRequirement(
        v_productID,
        v_cr_country,
        'HEALTH',
        'Registro sanitario',
        'Requiere registro sanitario vigente',
        TRUE,
        'Ministerio de Salud',
        CURRENT_TIMESTAMP,
        NULL
    );

    CALL sp_insert_countryProductPermission(
        v_productID,
        v_cr_country,
        'PERM-001',
        'Registro sanitario aceite premium',
        'APPROVED',
        'CERT-001',
        'Ministerio de Salud',
        CURRENT_TIMESTAMP,
        DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 YEAR),
        'Permiso inicial aprobado'
    );

    CALL sp_insert_customerOrder(
        'ORD001',
        v_customerID,
        v_siteID,
        v_cr_country,
        v_crc,
        'CREATED',
        14500.000000,
        1885.000000,
        2500.000000,
        1.000000,
        'Primera orden de prueba'
    );

    SELECT customerOrderID INTO v_orderID FROM customerOrder WHERE orderCode = 'ORD001' LIMIT 1;

    CALL sp_insert_paymentTransaction(
        v_orderID,
        'PAY001',
        'CARD',
        'APPROVED',
        'VISA',
        18885.000000,
        v_crc,
        'VISA-REF-001'
    );

    CALL sp_insert_shipment(
        v_orderID,
        'SHIP001',
        'PENDING',
        'San José, Costa Rica',
        NULL,
        'Correos CR',
        'CUSTOMER',
        NULL,
        NULL
    );

    CALL sp_log_etl_step('sp_seed_sample_dynamicBrands', 'MANUAL', 'dynamicBrandsDB', 'SUCCESS', 0, 0, NULL);
END $$

DELIMITER ;