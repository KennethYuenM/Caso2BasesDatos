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

DROP PROCEDURE IF EXISTS sp_insert_currency $$
CREATE PROCEDURE sp_insert_currency(
    IN p_currencyCode VARCHAR(20),
    IN p_currencyName VARCHAR(45),
    IN p_currencySymbol VARCHAR(30)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_currency', 'manual', 'currency', 'ERROR', 0, 0, CONCAT('Error inserting currency ', p_currencyCode));
    END;

    START TRANSACTION;

    INSERT INTO currency (
        currencyCode,
        currencyName,
        currencySymbol,
        isActive,
        createdAt,
        updatedAt
    )
    VALUES (
        p_currencyCode,
        p_currencyName,
        p_currencySymbol,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL sp_log_etl_step('sp_insert_currency', 'manual', 'currency', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_country $$
CREATE PROCEDURE sp_insert_country(
    IN p_countryName VARCHAR(50),
    IN p_iso2Code CHAR(2),
    IN p_iso3Code CHAR(3),
    IN p_localCurrencyID BIGINT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_country', 'manual', 'country', 'ERROR', 0, 0, CONCAT('Error inserting country ', p_countryName));
    END;

    START TRANSACTION;

    INSERT INTO country (
        countryName,
        iso2Code,
        iso3Code,
        localCurrencyID,
        isActive,
        createdAt,
        updatedAt
    )
    VALUES (
        p_countryName,
        p_iso2Code,
        p_iso3Code,
        p_localCurrencyID,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL sp_log_etl_step('sp_insert_country', 'manual', 'country', 'SUCCESS', 1, 1, NULL);
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
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_brandTemplate', 'manual', 'brandTemplate', 'ERROR', 0, 0, CONCAT('Error inserting brand ', p_brandCode));
    END;

    START TRANSACTION;

    INSERT INTO brandTemplate (
        brandCode,
        brandName,
        logoURL,
        corePromise,
        targetAudience,
        isActive,
        createdAt,
        updatedAt
    )
    VALUES (
        p_brandCode,
        p_brandName,
        p_logoURL,
        p_corePromise,
        p_targetAudience,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL sp_log_etl_step('sp_insert_brandTemplate', 'manual', 'brandTemplate', 'SUCCESS', 1, 1, NULL);
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
    DECLARE v_dynamicSiteID BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_dynamicSiteInfo', 'manual', 'dynamicSiteInfo', 'ERROR', 0, 0, CONCAT('Error inserting site ', p_siteCode));
    END;

    START TRANSACTION;

    INSERT INTO dynamicSiteInfo (
        siteCode,
        siteName,
        brandCode,
        countryID,
        currencyID,
        siteStatusCode,
        primaryDomainName,
        marketingFocus,
        brandVoice,
        targetSegment,
        launchDate,
        closeDate,
        clientName,
        logoURL,
        isActive,
        createdAt,
        updatedAt
    )
    VALUES (
        p_siteCode,
        p_siteName,
        p_brandCode,
        p_countryID,
        p_currencyID,
        p_siteStatusCode,
        p_primaryDomainName,
        p_marketingFocus,
        p_brandVoice,
        p_targetSegment,
        p_launchDate,
        p_closeDate,
        p_clientName,
        p_logoURL,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    SET v_dynamicSiteID = LAST_INSERT_ID();

    INSERT INTO dynamicSiteAuditLog (
        dynamicSiteID,
        eventTypeCode,
        eventDetails,
        performedByUserID,
        performedAt,
        createdAt
    )
    VALUES (
        v_dynamicSiteID,
        'SITE_CREATED',
        CONCAT('Site created from procedure: ', p_siteCode),
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL sp_log_etl_step('sp_insert_dynamicSiteInfo', 'manual', 'dynamicSiteInfo', 'SUCCESS', 1, 1, NULL);
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
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_customer', 'manual', 'customer', 'ERROR', 0, 0, CONCAT('Error inserting customer ', p_customerCode));
    END;

    START TRANSACTION;

    INSERT INTO customer (
        customerCode,
        countryID,
        email,
        firstName,
        lastName,
        passwordHash,
        isEmailVerified,
        isActive,
        lastLoginAt,
        createdAt,
        updatedAt
    )
    VALUES (
        p_customerCode,
        p_countryID,
        p_email,
        p_firstName,
        p_lastName,
        p_passwordHash,
        FALSE,
        TRUE,
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL sp_log_etl_step('sp_insert_customer', 'manual', 'customer', 'SUCCESS', 1, 1, NULL);
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
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_product', 'manual', 'product', 'ERROR', 0, 0, CONCAT('Error inserting product ', p_productCode));
    END;

    START TRANSACTION;

    INSERT INTO product (
        productCode,
        dynamicSiteID,
        categoryCode,
        productName,
        productDescription,
        sku,
        baseCurrencyID,
        basePrice,
        updatedByUserID,
        isActive,
        createdAt,
        updatedAt
    )
    VALUES (
        p_productCode,
        p_dynamicSiteID,
        p_categoryCode,
        p_productName,
        p_productDescription,
        p_sku,
        p_baseCurrencyID,
        p_basePrice,
        p_updatedByUserID,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL sp_log_etl_step('sp_insert_product', 'manual', 'product', 'SUCCESS', 1, 1, NULL);
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
    DECLARE v_customerOrderID BIGINT;
    DECLARE v_totalAmount DECIMAL(18,6);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_customerOrder', 'manual', 'customerOrder', 'ERROR', 0, 0, CONCAT('Error inserting order ', p_orderCode));
    END;

    SET v_totalAmount = ROUND(p_subTotal + p_taxTotal + p_shippingAmount, 6);

    START TRANSACTION;

    INSERT INTO customerOrder (
        orderCode,
        customerID,
        dynamicSiteID,
        customerCountryID,
        currencyID,
        orderStatusCode,
        orderDate,
        subTotal,
        taxTotal,
        shippingAmount,
        totalAmount,
        exchangeRate,
        notes,
        createdAt,
        updatedAt
    )
    VALUES (
        p_orderCode,
        p_customerID,
        p_dynamicSiteID,
        p_customerCountryID,
        p_currencyID,
        p_orderStatusCode,
        CURRENT_TIMESTAMP,
        p_subTotal,
        p_taxTotal,
        p_shippingAmount,
        v_totalAmount,
        p_exchangeRate,
        p_notes,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    SET v_customerOrderID = LAST_INSERT_ID();

    INSERT INTO customerOrderStatusLog (
        customerOrderID,
        previousOrderStatusCode,
        currentOrderStatusCode,
        changeDetails,
        changeSourceCode,
        changedByUserID,
        changedAt,
        createdAt
    )
    VALUES (
        v_customerOrderID,
        NULL,
        p_orderStatusCode,
        CONCAT('Initial order status: ', p_orderStatusCode),
        'SYSTEM',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL sp_log_etl_step('sp_insert_customerOrder', 'manual', 'customerOrder', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_insert_customerOrderLine $$
CREATE PROCEDURE sp_insert_customerOrderLine(
    IN p_customerOrderID BIGINT,
    IN p_productID BIGINT,
    IN p_quantity INT,
    IN p_unitPrice DECIMAL(18,6),
    IN p_taxAmount DECIMAL(18,6),
    IN p_discountAmount DECIMAL(18,6)
)
BEGIN
    DECLARE v_lineTotal DECIMAL(18,6);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_customerOrderLine', 'manual', 'customerOrderLine', 'ERROR', 0, 0, CONCAT('Error inserting order line for order ', p_customerOrderID));
    END;

    SET v_lineTotal = ROUND((p_quantity * p_unitPrice) + p_taxAmount - p_discountAmount, 6);

    START TRANSACTION;

    INSERT INTO customerOrderLine (
        customerOrderID,
        productID,
        quantity,
        unitPrice,
        taxAmount,
        discountAmount,
        lineTotal,
        createdAt,
        updatedAt
    )
    VALUES (
        p_customerOrderID,
        p_productID,
        p_quantity,
        p_unitPrice,
        p_taxAmount,
        p_discountAmount,
        v_lineTotal,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL sp_log_etl_step('sp_insert_customerOrderLine', 'manual', 'customerOrderLine', 'SUCCESS', 1, 1, NULL);
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
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_paymentTransaction', 'manual', 'paymentTransaction', 'ERROR', 0, 0, CONCAT('Error inserting payment ', p_transactionCode));
    END;

    START TRANSACTION;

    INSERT INTO paymentTransaction (
        customerOrderID,
        transactionCode,
        methodCode,
        paymentStatusCode,
        providerCode,
        transactionAmount,
        currencyID,
        providerReference,
        transactionDate,
        createdAt,
        updatedAt
    )
    VALUES (
        p_customerOrderID,
        p_transactionCode,
        p_methodCode,
        p_paymentStatusCode,
        p_providerCode,
        p_transactionAmount,
        p_currencyID,
        p_providerReference,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL sp_log_etl_step('sp_insert_paymentTransaction', 'manual', 'paymentTransaction', 'SUCCESS', 1, 1, NULL);
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
    DECLARE v_sellableQuantity INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_insert_inventory', 'manual', 'inventory', 'ERROR', 0, 0, CONCAT('Error inserting inventory for product ', p_productID));
    END;

    SET v_sellableQuantity = p_availableQuantity - p_reservedQuantity;

    START TRANSACTION;

    INSERT INTO inventory (
        dynamicSiteID,
        productID,
        availableQuantity,
        reservedQuantity,
        sellableQuantity,
        reorderLevel,
        sourceCode,
        lastStockUpdateAt,
        createdAt,
        updatedAt
    )
    VALUES (
        p_dynamicSiteID,
        p_productID,
        p_availableQuantity,
        p_reservedQuantity,
        v_sellableQuantity,
        p_reorderLevel,
        p_sourceCode,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL sp_log_etl_step('sp_insert_inventory', 'manual', 'inventory', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS sp_seed_dynamicBrands_base $$
CREATE PROCEDURE sp_seed_dynamicBrands_base()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        CALL sp_log_etl_step('sp_seed_dynamicBrands_base', 'manual', 'dynamicBrandsDB', 'ERROR', 0, 0, 'Error seeding base catalog data');
    END;

    START TRANSACTION;

    INSERT INTO userRole (roleCode, roleName, roleDescription, isActive, createdAt, updatedAt) VALUES
    ('ADMIN', 'Administrator', 'Full access user', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('OPERATOR', 'Operator', 'Operational user', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO changeSource (sourceCode, sourceName, sourceDescription, isActive, createdAt, updatedAt) VALUES
    ('SYSTEM', 'System', 'System generated change', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('MANUAL', 'Manual', 'Manual change by user', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ETL', 'ETL', 'ETL process change', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO dynamicSiteStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('DRAFT', 'Draft', 'Site in draft status', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ACTIVE', 'Active', 'Site active', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('CLOSED', 'Closed', 'Site closed', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO dynamicSiteGenerationStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Generation pending', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SUCCESS', 'Success', 'Generation successful', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('FAILED', 'Failed', 'Generation failed', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO dynamicSiteEventType (eventTypeCode, eventName, eventDescription, isActive, createdAt, updatedAt) VALUES
    ('SITE_CREATED', 'Site Created', 'Dynamic site created', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SITE_UPDATED', 'Site Updated', 'Dynamic site updated', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SITE_CLOSED', 'Site Closed', 'Dynamic site closed', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO orderStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('CREATED', 'Created', 'Order created', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('PAID', 'Paid', 'Order paid', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SHIPPED', 'Shipped', 'Order shipped', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('DELIVERED', 'Delivered', 'Order delivered', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO paymentMethod (methodCode, methodName, methodDescription, isActive, createdAt, updatedAt) VALUES
    ('CARD', 'Card', 'Credit or debit card', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('TRANSFER', 'Transfer', 'Bank transfer', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO paymentTransactionStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Payment pending', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('APPROVED', 'Approved', 'Payment approved', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('REJECTED', 'Rejected', 'Payment rejected', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO paymentProvider (providerCode, providerName, providerDescription, isActive, createdAt, updatedAt) VALUES
    ('VISA', 'Visa', 'Visa network', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('MASTERCARD', 'Mastercard', 'Mastercard network', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO shipmentViewType (viewTypeCode, viewTypeName, viewTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('CUSTOMER', 'Customer', 'Customer visible shipment view', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('INTERNAL', 'Internal', 'Internal shipment view', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO shipmentStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Shipment pending', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('IN_TRANSIT', 'In Transit', 'Shipment in transit', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('DELIVERED', 'Delivered', 'Shipment delivered', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO productCategory (categoryCode, categoryName, categoryDescription, isActive, createdAt, updatedAt) VALUES
    ('OIL', 'Oil', 'Essential oils', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SOAP', 'Soap', 'Natural soaps', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('BEAUTY', 'Beauty', 'Beauty products', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO productImageType (typeCode, typeName, typeDescription, isActive, createdAt, updatedAt) VALUES
    ('MAIN', 'Main', 'Main product image', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('GALLERY', 'Gallery', 'Gallery image', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO packagingType (packagingTypeCode, packagingTypeName, packagingTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('BOTTLE', 'Bottle', 'Bottle packaging', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('BOX', 'Box', 'Box packaging', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO labelType (labelTypeCode, labelTypeName, labelTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('PRIMARY', 'Primary', 'Primary label', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('WARNING', 'Warning', 'Warning label', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO regulatoryRequirementType (requirementTypeCode, requirementTypeName, requirementTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('HEALTH', 'Health Requirement', 'Health regulatory requirement', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('IMPORT', 'Import Requirement', 'Import requirement', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO permissionStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Permission pending', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('APPROVED', 'Approved', 'Permission approved', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('EXPIRED', 'Expired', 'Permission expired', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT INTO inventorySource (sourceCode, sourceName, sourceDescription, isActive, createdAt, updatedAt) VALUES
    ('HUB', 'Hub', 'Central hub source', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('MANUAL', 'Manual', 'Manual inventory source', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    COMMIT;
    CALL sp_log_etl_step('sp_seed_dynamicBrands_base', 'manual', 'dynamicBrandsDB', 'SUCCESS', 0, 0, NULL);
END $$

DELIMITER ;