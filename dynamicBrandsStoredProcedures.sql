USE dynamicBrandsDB;

DELIMITER $$

DROP PROCEDURE IF EXISTS spLogEtlStep $$
CREATE PROCEDURE spLogEtlStep(
    IN processNameParam VARCHAR(60),
    IN sourceSystemParam VARCHAR(30),
    IN targetSystemParam VARCHAR(30),
    IN executionStatusParam VARCHAR(30),
    IN recordsExtractedParam INT,
    IN recordsLoadedParam INT,
    IN errorDetailsParam VARCHAR(500)
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
        processNameParam,
        sourceSystemParam,
        targetSystemParam,
        executionStatusParam,
        recordsExtractedParam,
        recordsLoadedParam,
        errorDetailsParam,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP PROCEDURE IF EXISTS spSeedBaseCatalogs $$
CREATE PROCEDURE spSeedBaseCatalogs()
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spSeedBaseCatalogs', 'MANUAL', 'dynamicBrandsDB', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    INSERT IGNORE INTO userRole (roleCode, roleName, roleDescription, isActive, createdAt, updatedAt) VALUES
    ('ADMIN', 'Administrator', 'Full access user', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('MANAGER', 'Manager', 'Management user', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ANALYST', 'Analyst', 'Analytics user', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('OPERATOR', 'Operator', 'Operational user', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO personType (personTypeCode, personTypeName, personTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('CUSTOMER', 'Customer', 'External customer', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SYSTEM_USER', 'System User', 'Internal system user', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('BOTH', 'Customer and System User', 'Person with customer and internal user capabilities', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO dynamicSiteStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('DRAFT', 'Draft', 'Draft site', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ACTIVE', 'Active', 'Active site', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('PAUSED', 'Paused', 'Temporarily paused site', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('CLOSED', 'Closed', 'Closed site', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO dynamicSiteGenerationStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Pending generation', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('RUNNING', 'Running', 'Generation process is running', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SUCCESS', 'Success', 'Successful generation', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('FAILED', 'Failed', 'Failed generation', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO dynamicSiteEventType (eventTypeCode, eventName, eventDescription, isActive, createdAt, updatedAt) VALUES
    ('SITE_CREATED', 'Site Created', 'Site was created', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SITE_UPDATED', 'Site Updated', 'Site was updated', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SITE_STATUS_CHANGED', 'Site Status Changed', 'Site status was changed', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('AI_CONFIGURATION_CHANGED', 'AI Configuration Changed', 'AI generated configuration was changed', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO changeSource (sourceCode, sourceName, sourceDescription, isActive, createdAt, updatedAt) VALUES
    ('SYSTEM', 'System', 'System generated change', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('MANUAL', 'Manual', 'Manual change', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ETL', 'ETL', 'ETL process change', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('API', 'API', 'External API process change', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO orderStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('CREATED', 'Created', 'Order created', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('PAID', 'Paid', 'Order paid', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SHIPPED', 'Shipped', 'Order shipped', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('DELIVERED', 'Delivered', 'Order delivered', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('CANCELLED', 'Cancelled', 'Order cancelled', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO metricType (metricTypeCode, metricName, metricDescription, valueType, isActive, createdAt, updatedAt) VALUES
    ('VISITS', 'Visits', 'Visit count', 'COUNT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SESSIONS', 'Sessions', 'Session count', 'COUNT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('PURCHASES', 'Purchases', 'Purchase count', 'COUNT', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('CONVERSION_RATE', 'Conversion Rate', 'Purchase conversion rate', 'RATE', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('REVENUE', 'Revenue', 'Revenue amount', 'MONEY', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('BOUNCE_RATE', 'Bounce Rate', 'Bounce rate', 'RATE', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO productCategory (categoryCode, categoryName, categoryDescription, isActive, createdAt, updatedAt) VALUES
    ('OIL', 'Oil', 'Oil products', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SOAP', 'Soap', 'Soap products', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('BEAUTY', 'Beauty', 'Beauty products', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('FOOD', 'Food', 'Food products', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('BEVERAGE', 'Beverage', 'Beverage products', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO productImageType (typeCode, typeName, typeDescription, isActive, createdAt, updatedAt) VALUES
    ('MAIN', 'Main', 'Main product image', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('GALLERY', 'Gallery', 'Gallery image', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('DETAIL', 'Detail', 'Detailed product image', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO packagingType (packagingTypeCode, packagingTypeName, packagingTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('BOTTLE', 'Bottle', 'Bottle packaging', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('BOX', 'Box', 'Box packaging', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('BAG', 'Bag', 'Bag packaging', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('JAR', 'Jar', 'Jar packaging', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO labelType (labelTypeCode, labelTypeName, labelTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('PRIMARY', 'Primary', 'Primary label', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('WARNING', 'Warning', 'Warning label', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('LEGAL', 'Legal', 'Legal label', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('NUTRITIONAL', 'Nutritional', 'Nutritional label', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO regulatoryRequirementType (requirementTypeCode, requirementTypeName, requirementTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('HEALTH', 'Health', 'Health requirement', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('IMPORT', 'Import', 'Import requirement', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('LABELING', 'Labeling', 'Labeling requirement', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('PACKAGING', 'Packaging', 'Packaging requirement', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO paymentTransactionStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Pending payment', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('APPROVED', 'Approved', 'Approved payment', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('REJECTED', 'Rejected', 'Rejected payment', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('REFUNDED', 'Refunded', 'Refunded payment', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO paymentMethod (methodCode, methodName, providerName, providerDescription, methodDescription, config, isActive, createdAt, updatedAt) VALUES
    ('VISA', 'Visa', 'Visa', 'Visa card network', 'Card payment', JSON_OBJECT('type', 'card', 'requires3DS', true), TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('MASTERCARD', 'Mastercard', 'Mastercard', 'Mastercard card network', 'Card payment', JSON_OBJECT('type', 'card', 'requires3DS', true), TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('SINPE', 'SINPE', 'SINPE', 'Costa Rica bank transfer network', 'Bank transfer', JSON_OBJECT('type', 'transfer', 'manualConfirmation', true), TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO permissionStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Pending permission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('APPROVED', 'Approved', 'Approved permission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('REJECTED', 'Rejected', 'Rejected permission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('EXPIRED', 'Expired', 'Expired permission', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO shipmentStatus (statusCode, statusName, statusDescription, isActive, createdAt, updatedAt) VALUES
    ('PENDING', 'Pending', 'Pending shipment', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('IN_TRANSIT', 'In Transit', 'Shipment in transit', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('DELIVERED', 'Delivered', 'Delivered shipment', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('RETURNED', 'Returned', 'Returned shipment', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO shipmentViewType (viewTypeCode, viewTypeName, viewTypeDescription, isActive, createdAt, updatedAt) VALUES
    ('CUSTOMER', 'Customer', 'Customer view', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('INTERNAL', 'Internal', 'Internal view', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    INSERT IGNORE INTO inventorySource (sourceCode, sourceName, sourceDescription, isActive, createdAt, updatedAt) VALUES
    ('HUB', 'Hub', 'Hub inventory', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('MANUAL', 'Manual', 'Manual update', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('ORDER', 'Order', 'Inventory movement from order', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('RETURN', 'Return', 'Inventory movement from return', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

    COMMIT;
    CALL spLogEtlStep('spSeedBaseCatalogs', 'MANUAL', 'dynamicBrandsDB', 'SUCCESS', 0, 0, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertCurrency $$
CREATE PROCEDURE spInsertCurrency(
    IN currencyCodeParam VARCHAR(20),
    IN currencyNameParam VARCHAR(45),
    IN currencySymbolParam VARCHAR(30)
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertCurrency', 'MANUAL', 'currency', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF currencyCodeParam IS NULL OR TRIM(currencyCodeParam) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'currencyCodeParam is required';
    END IF;

    INSERT INTO currency (currencyCode, currencyName, currencySymbol)
    VALUES (currencyCodeParam, currencyNameParam, currencySymbolParam);

    COMMIT;
    CALL spLogEtlStep('spInsertCurrency', 'MANUAL', 'currency', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertCountry $$
CREATE PROCEDURE spInsertCountry(
    IN countryNameParam VARCHAR(50),
    IN iso2CodeParam CHAR(2),
    IN iso3CodeParam CHAR(3),
    IN localCurrencyIDParam BIGINT
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertCountry', 'MANUAL', 'country', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF CHAR_LENGTH(iso2CodeParam) <> 2 OR CHAR_LENGTH(iso3CodeParam) <> 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid ISO code length';
    END IF;

    INSERT INTO country (countryName, iso2Code, iso3Code, localCurrencyID)
    VALUES (countryNameParam, UPPER(iso2CodeParam), UPPER(iso3CodeParam), localCurrencyIDParam);

    COMMIT;
    CALL spLogEtlStep('spInsertCountry', 'MANUAL', 'country', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertCurrentExchangeRate $$
CREATE PROCEDURE spInsertCurrentExchangeRate(
    IN exchangePairIDParam BIGINT,
    IN baseCurrencyIDParam BIGINT,
    IN quoteCurrencyIDParam BIGINT,
    IN buyRateParam NUMERIC(18,6),
    IN sellRateParam NUMERIC(18,6),
    IN sourceNameParam VARCHAR(50)
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertCurrentExchangeRate', 'MANUAL', 'currentExchangeRate', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF baseCurrencyIDParam = quoteCurrencyIDParam THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'baseCurrencyIDParam and quoteCurrencyIDParam cannot be equal';
    END IF;

    IF buyRateParam <= 0 OR sellRateParam <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Exchange rates must be greater than zero';
    END IF;

    INSERT INTO currentExchangeRate (
        exchangePairID,
        baseCurrencyID,
        quoteCurrencyID,
        buyRate,
        sellRate,
        sourceName
    )
    VALUES (
        exchangePairIDParam,
        baseCurrencyIDParam,
        quoteCurrencyIDParam,
        buyRateParam,
        sellRateParam,
        sourceNameParam
    )
    ON DUPLICATE KEY UPDATE
        exchangePairID = exchangePairIDParam,
        buyRate = buyRateParam,
        sellRate = sellRateParam,
        sourceName = sourceNameParam,
        updatedAt = CURRENT_TIMESTAMP;

    INSERT INTO historicalExchangeRate (
        exchangePairID,
        buyRate,
        sellRate,
        validFrom,
        validTo,
        recordedAt
    )
    VALUES (
        exchangePairIDParam,
        buyRateParam,
        sellRateParam,
        CURRENT_TIMESTAMP,
        NULL,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL spLogEtlStep('spInsertCurrentExchangeRate', 'MANUAL', 'currentExchangeRate', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertPeople $$
CREATE PROCEDURE spInsertPeople(
    IN personCodeParam VARCHAR(50),
    IN countryIDParam BIGINT,
    IN emailParam VARCHAR(150),
    IN firstNameParam VARCHAR(100),
    IN lastNameParam VARCHAR(100),
    IN passwordHashParam VARCHAR(255),
    IN personTypeCodeParam VARCHAR(30),
    OUT newPersonIDParam BIGINT
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        SET newPersonIDParam = NULL;
        CALL spLogEtlStep('spInsertPeople', 'MANUAL', 'people', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF emailParam IS NULL OR TRIM(emailParam) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'emailParam is required';
    END IF;

    IF personTypeCodeParam IS NULL OR TRIM(personTypeCodeParam) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'personTypeCodeParam is required';
    END IF;

    INSERT INTO people (
        personCode,
        countryID,
        email,
        firstName,
        lastName,
        passwordHash,
        isEmailVerified,
        isActive
    )
    VALUES (
        personCodeParam,
        countryIDParam,
        LOWER(emailParam),
        firstNameParam,
        lastNameParam,
        passwordHashParam,
        FALSE,
        TRUE
    );

    SET newPersonIDParam = LAST_INSERT_ID();

    INSERT INTO peoplePersonType (personID, personTypeCode)
    VALUES (newPersonIDParam, personTypeCodeParam);

    COMMIT;
    CALL spLogEtlStep('spInsertPeople', 'MANUAL', 'people', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertSystemUser $$
CREATE PROCEDURE spInsertSystemUser(
    IN personIDParam BIGINT,
    IN userCodeParam VARCHAR(30),
    IN roleCodeParam VARCHAR(30)
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertSystemUser', 'MANUAL', 'systemUser', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF userCodeParam IS NULL OR TRIM(userCodeParam) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'userCodeParam is required';
    END IF;

    INSERT INTO systemUser (personID, userCode, roleCode)
    VALUES (personIDParam, userCodeParam, roleCodeParam);

    INSERT IGNORE INTO peoplePersonType (personID, personTypeCode)
    VALUES (personIDParam, 'SYSTEM_USER');

    COMMIT;
    CALL spLogEtlStep('spInsertSystemUser', 'MANUAL', 'systemUser', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertBrandTemplate $$
CREATE PROCEDURE spInsertBrandTemplate(
    IN brandCodeParam VARCHAR(30),
    IN brandNameParam VARCHAR(40),
    IN logoURLParam VARCHAR(255),
    IN corePromiseParam VARCHAR(250),
    IN targetAudienceParam VARCHAR(200)
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertBrandTemplate', 'MANUAL', 'brandTemplate', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    INSERT INTO brandTemplate (
        brandCode,
        brandName,
        logoURL,
        corePromise,
        targetAudience
    )
    VALUES (
        brandCodeParam,
        brandNameParam,
        logoURLParam,
        corePromiseParam,
        targetAudienceParam
    );

    COMMIT;
    CALL spLogEtlStep('spInsertBrandTemplate', 'MANUAL', 'brandTemplate', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertDynamicSite $$
CREATE PROCEDURE spInsertDynamicSite(
    IN siteCodeParam VARCHAR(30),
    IN siteNameParam VARCHAR(80),
    IN brandCodeParam VARCHAR(30),
    IN countryIDParam BIGINT,
    IN currencyIDParam BIGINT,
    IN siteStatusCodeParam VARCHAR(30),
    IN primaryDomainNameParam VARCHAR(150),
    IN marketingFocusParam VARCHAR(80),
    IN brandVoiceParam TEXT,
    IN siteVisualsConfigParam JSON,
    IN clientNameParam VARCHAR(80),
    IN logoURLParam VARCHAR(255),
    OUT newDynamicSiteIDParam BIGINT
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        SET newDynamicSiteIDParam = NULL;
        CALL spLogEtlStep('spInsertDynamicSite', 'MANUAL', 'dynamicSiteInfo', 'ERROR', 0, 0, errorMessage);
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
        siteVisualsConfig,
        launchDate,
        clientName,
        logoURL
    )
    VALUES (
        siteCodeParam,
        siteNameParam,
        brandCodeParam,
        countryIDParam,
        currencyIDParam,
        siteStatusCodeParam,
        primaryDomainNameParam,
        marketingFocusParam,
        brandVoiceParam,
        siteVisualsConfigParam,
        CURRENT_TIMESTAMP,
        clientNameParam,
        logoURLParam
    );

    SET newDynamicSiteIDParam = LAST_INSERT_ID();

    INSERT INTO dynamicSiteDomain (
        dynamicSiteID,
        domainName,
        isPrimary,
        isActive
    )
    VALUES (
        newDynamicSiteIDParam,
        primaryDomainNameParam,
        TRUE,
        TRUE
    );

    COMMIT;
    CALL spLogEtlStep('spInsertDynamicSite', 'MANUAL', 'dynamicSiteInfo', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertDynamicSiteMetric $$
CREATE PROCEDURE spInsertDynamicSiteMetric(
    IN dynamicSiteIDParam BIGINT,
    IN metricTypeCodeParam VARCHAR(30),
    IN metricDateParam DATE,
    IN metricValueParam DECIMAL(18,6)
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertDynamicSiteMetric', 'MANUAL', 'dynamicSiteMetric', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF metricValueParam < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'metricValueParam cannot be negative';
    END IF;

    IF metricTypeCodeParam IN ('CONVERSION_RATE', 'BOUNCE_RATE') AND metricValueParam > 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rate metrics must be between 0 and 1';
    END IF;

    INSERT INTO dynamicSiteMetric (
        dynamicSiteID,
        metricTypeCode,
        metricDate,
        metricValue
    )
    VALUES (
        dynamicSiteIDParam,
        metricTypeCodeParam,
        metricDateParam,
        metricValueParam
    )
    ON DUPLICATE KEY UPDATE
        metricValue = metricValueParam,
        updatedAt = CURRENT_TIMESTAMP;

    COMMIT;
    CALL spLogEtlStep('spInsertDynamicSiteMetric', 'MANUAL', 'dynamicSiteMetric', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertProduct $$
CREATE PROCEDURE spInsertProduct(
    IN productCodeParam VARCHAR(50),
    IN dynamicSiteIDParam BIGINT,
    IN productCategoryCodeParam VARCHAR(30),
    IN productNameParam VARCHAR(120),
    IN productDescriptionParam VARCHAR(500),
    IN skuParam VARCHAR(50),
    IN baseCurrencyIDParam BIGINT,
    IN basePriceParam DECIMAL(18,6),
    IN updatedByPersonIDParam BIGINT,
    OUT newProductIDParam BIGINT
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        SET newProductIDParam = NULL;
        CALL spLogEtlStep('spInsertProduct', 'MANUAL', 'product', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF basePriceParam < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'basePriceParam cannot be negative';
    END IF;

    INSERT INTO product (
        productCode,
        dynamicSiteID,
        productCategoryCode,
        productName,
        productDescription,
        sku,
        baseCurrencyID,
        basePrice,
        updatedByPersonID
    )
    VALUES (
        productCodeParam,
        dynamicSiteIDParam,
        productCategoryCodeParam,
        productNameParam,
        productDescriptionParam,
        skuParam,
        baseCurrencyIDParam,
        basePriceParam,
        updatedByPersonIDParam
    );

    SET newProductIDParam = LAST_INSERT_ID();

    COMMIT;
    CALL spLogEtlStep('spInsertProduct', 'MANUAL', 'product', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertProductPrice $$
CREATE PROCEDURE spInsertProductPrice(
    IN productIDParam BIGINT,
    IN dynamicSiteIDParam BIGINT,
    IN currencyIDParam BIGINT,
    IN priceAmountParam DECIMAL(18,6),
    IN validFromParam TIMESTAMP,
    IN validToParam TIMESTAMP,
    IN isCurrentParam BOOLEAN
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertProductPrice', 'MANUAL', 'productPrice', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF priceAmountParam < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'priceAmountParam cannot be negative';
    END IF;

    IF validToParam IS NOT NULL AND validToParam < validFromParam THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'validToParam cannot be earlier than validFromParam';
    END IF;

    IF isCurrentParam = TRUE THEN
        UPDATE productPrice
        SET isCurrent = FALSE,
            updatedAt = CURRENT_TIMESTAMP
        WHERE productID = productIDParam
          AND dynamicSiteID = dynamicSiteIDParam
          AND currencyID = currencyIDParam
          AND isCurrent = TRUE;
    END IF;

    INSERT INTO productPrice (
        productID,
        dynamicSiteID,
        currencyID,
        priceAmount,
        validFrom,
        validTo,
        isCurrent
    )
    VALUES (
        productIDParam,
        dynamicSiteIDParam,
        currencyIDParam,
        priceAmountParam,
        validFromParam,
        validToParam,
        isCurrentParam
    );

    COMMIT;
    CALL spLogEtlStep('spInsertProductPrice', 'MANUAL', 'productPrice', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertProductImage $$
CREATE PROCEDURE spInsertProductImage(
    IN productIDParam BIGINT,
    IN typeCodeParam VARCHAR(30),
    IN imageURLParam VARCHAR(255),
    IN displayOrderParam INT,
    IN isPrimaryParam BOOLEAN
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertProductImage', 'MANUAL', 'productImage', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF isPrimaryParam = TRUE THEN
        UPDATE productImage
        SET isPrimary = FALSE,
            updatedAt = CURRENT_TIMESTAMP
        WHERE productID = productIDParam
          AND isPrimary = TRUE;
    END IF;

    INSERT INTO productImage (
        productID,
        typeCode,
        imageURL,
        displayOrder,
        isPrimary
    )
    VALUES (
        productIDParam,
        typeCodeParam,
        imageURLParam,
        displayOrderParam,
        isPrimaryParam
    );

    COMMIT;
    CALL spLogEtlStep('spInsertProductImage', 'MANUAL', 'productImage', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertProductPackaging $$
CREATE PROCEDURE spInsertProductPackaging(
    IN productIDParam BIGINT,
    IN countryIDParam BIGINT,
    IN packagingTypeCodeParam VARCHAR(30),
    IN packagingNameParam VARCHAR(80),
    IN packagingDescriptionParam VARCHAR(250),
    IN unitContentParam VARCHAR(50),
    IN unitMeasureParam VARCHAR(30),
    IN packageMaterialParam VARCHAR(50),
    IN isFragileParam BOOLEAN,
    IN isPrimaryParam BOOLEAN
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertProductPackaging', 'MANUAL', 'productPackaging', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF isPrimaryParam = TRUE THEN
        UPDATE productPackaging
        SET isPrimary = FALSE,
            updatedAt = CURRENT_TIMESTAMP
        WHERE productID = productIDParam
          AND countryID = countryIDParam
          AND isPrimary = TRUE;
    END IF;

    INSERT INTO productPackaging (
        productID,
        countryID,
        packagingTypeCode,
        packagingName,
        packagingDescription,
        unitContent,
        unitMeasure,
        packageMaterial,
        isFragile,
        isPrimary
    )
    VALUES (
        productIDParam,
        countryIDParam,
        packagingTypeCodeParam,
        packagingNameParam,
        packagingDescriptionParam,
        unitContentParam,
        unitMeasureParam,
        packageMaterialParam,
        isFragileParam,
        isPrimaryParam
    );

    COMMIT;
    CALL spLogEtlStep('spInsertProductPackaging', 'MANUAL', 'productPackaging', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertProductLabel $$
CREATE PROCEDURE spInsertProductLabel(
    IN productIDParam BIGINT,
    IN dynamicSiteIDParam BIGINT,
    IN countryIDParam BIGINT,
    IN labelTypeCodeParam VARCHAR(30),
    IN labelNameParam VARCHAR(80),
    IN labelDescriptionParam VARCHAR(250),
    IN labelLanguageParam VARCHAR(30),
    IN labelContentParam TEXT,
    IN isPrimaryParam BOOLEAN
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertProductLabel', 'MANUAL', 'productLabel', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF isPrimaryParam = TRUE THEN
        UPDATE productLabel
        SET isPrimary = FALSE,
            updatedAt = CURRENT_TIMESTAMP
        WHERE productID = productIDParam
          AND dynamicSiteID = dynamicSiteIDParam
          AND countryID = countryIDParam
          AND labelTypeCode = labelTypeCodeParam
          AND isPrimary = TRUE;
    END IF;

    INSERT INTO productLabel (
        productID,
        dynamicSiteID,
        countryID,
        labelTypeCode,
        labelName,
        labelDescription,
        labelLanguage,
        labelContent,
        isPrimary
    )
    VALUES (
        productIDParam,
        dynamicSiteIDParam,
        countryIDParam,
        labelTypeCodeParam,
        labelNameParam,
        labelDescriptionParam,
        labelLanguageParam,
        labelContentParam,
        isPrimaryParam
    );

    COMMIT;
    CALL spLogEtlStep('spInsertProductLabel', 'MANUAL', 'productLabel', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertCountryProductRequirement $$
CREATE PROCEDURE spInsertCountryProductRequirement(
    IN productIDParam BIGINT,
    IN countryIDParam BIGINT,
    IN requirementTypeCodeParam VARCHAR(30),
    IN requirementNameParam VARCHAR(100),
    IN requirementDescriptionParam VARCHAR(250),
    IN isMandatoryParam BOOLEAN,
    IN issuedByParam VARCHAR(80),
    IN validFromParam TIMESTAMP,
    IN validToParam TIMESTAMP
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertCountryProductRequirement', 'MANUAL', 'countryProductRequirement', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF validToParam IS NOT NULL AND validFromParam IS NOT NULL AND validToParam < validFromParam THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'validToParam cannot be earlier than validFromParam';
    END IF;

    INSERT INTO countryProductRequirement (
        productID,
        countryID,
        requirementTypeCode,
        requirementName,
        requirementDescription,
        isMandatory,
        issuedBy,
        validFrom,
        validTo
    )
    VALUES (
        productIDParam,
        countryIDParam,
        requirementTypeCodeParam,
        requirementNameParam,
        requirementDescriptionParam,
        isMandatoryParam,
        issuedByParam,
        validFromParam,
        validToParam
    );

    COMMIT;
    CALL spLogEtlStep('spInsertCountryProductRequirement', 'MANUAL', 'countryProductRequirement', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertCountryProductPermission $$
CREATE PROCEDURE spInsertCountryProductPermission(
    IN productIDParam BIGINT,
    IN countryIDParam BIGINT,
    IN permissionCostParam BIGINT,
    IN permissionCodeParam VARCHAR(50),
    IN permissionNameParam VARCHAR(100),
    IN permissionStatusCodeParam VARCHAR(30),
    IN certificateNumberParam VARCHAR(80),
    IN issuedByParam VARCHAR(80),
    IN issuedAtParam TIMESTAMP,
    IN expiresAtParam TIMESTAMP,
    IN notesParam VARCHAR(250)
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertCountryProductPermission', 'MANUAL', 'countryProductPermission', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF permissionCostParam < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'permissionCostParam cannot be negative';
    END IF;

    IF expiresAtParam IS NOT NULL AND issuedAtParam IS NOT NULL AND expiresAtParam < issuedAtParam THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'expiresAtParam cannot be earlier than issuedAtParam';
    END IF;

    INSERT INTO countryProductPermission (
        productID,
        countryID,
        permissionCost,
        permissionCode,
        permissionName,
        permissionStatusCode,
        certificateNumber,
        issuedBy,
        issuedAt,
        expiresAt,
        notes
    )
    VALUES (
        productIDParam,
        countryIDParam,
        permissionCostParam,
        permissionCodeParam,
        permissionNameParam,
        permissionStatusCodeParam,
        certificateNumberParam,
        issuedByParam,
        issuedAtParam,
        expiresAtParam,
        notesParam
    );

    COMMIT;
    CALL spLogEtlStep('spInsertCountryProductPermission', 'MANUAL', 'countryProductPermission', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spUpsertInventory $$
CREATE PROCEDURE spUpsertInventory(
    IN dynamicSiteIDParam BIGINT,
    IN productIDParam BIGINT,
    IN availableQuantityParam INT,
    IN reservedQuantityParam INT,
    IN reorderLevelParam INT,
    IN sourceCodeParam VARCHAR(30)
)
BEGIN
    DECLARE errorMessage TEXT;
    DECLARE sellableQuantityValue INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spUpsertInventory', 'MANUAL', 'inventory', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF availableQuantityParam < 0 OR reservedQuantityParam < 0 OR reorderLevelParam < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inventory quantities cannot be negative';
    END IF;

    SET sellableQuantityValue = availableQuantityParam - reservedQuantityParam;

    IF sellableQuantityValue < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'reservedQuantityParam cannot be greater than availableQuantityParam';
    END IF;

    INSERT INTO inventory (
        dynamicSiteID,
        productID,
        availableQuantity,
        reservedQuantity,
        sellableQuantity,
        reorderLevel,
        sourceCode,
        lastStockUpdateAt
    )
    VALUES (
        dynamicSiteIDParam,
        productIDParam,
        availableQuantityParam,
        reservedQuantityParam,
        sellableQuantityValue,
        reorderLevelParam,
        sourceCodeParam,
        CURRENT_TIMESTAMP
    )
    ON DUPLICATE KEY UPDATE
        availableQuantity = availableQuantityParam,
        reservedQuantity = reservedQuantityParam,
        sellableQuantity = sellableQuantityValue,
        reorderLevel = reorderLevelParam,
        sourceCode = sourceCodeParam,
        lastStockUpdateAt = CURRENT_TIMESTAMP,
        updatedAt = CURRENT_TIMESTAMP;

    COMMIT;
    CALL spLogEtlStep('spUpsertInventory', 'MANUAL', 'inventory', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertCustomerOrder $$
CREATE PROCEDURE spInsertCustomerOrder(
    IN orderCodeParam VARCHAR(50),
    IN personIDParam BIGINT,
    IN dynamicSiteIDParam BIGINT,
    IN customerCountryIDParam BIGINT,
    IN currencyIDParam BIGINT,
    IN orderStatusCodeParam VARCHAR(30),
    IN shippingAmountParam DECIMAL(18,6),
    IN exchangeRateParam DECIMAL(18,6),
    IN notesParam VARCHAR(200),
    OUT newCustomerOrderIDParam BIGINT
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        SET newCustomerOrderIDParam = NULL;
        CALL spLogEtlStep('spInsertCustomerOrder', 'MANUAL', 'customerOrder', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF shippingAmountParam < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'shippingAmountParam cannot be negative';
    END IF;

    IF exchangeRateParam <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'exchangeRateParam must be greater than zero';
    END IF;

    INSERT INTO customerOrder (
        orderCode,
        personID,
        dynamicSiteID,
        customerCountryID,
        currencyID,
        orderStatusCode,
        shippingAmount,
        exchangeRate,
        notes
    )
    VALUES (
        orderCodeParam,
        personIDParam,
        dynamicSiteIDParam,
        customerCountryIDParam,
        currencyIDParam,
        orderStatusCodeParam,
        shippingAmountParam,
        exchangeRateParam,
        notesParam
    );

    SET newCustomerOrderIDParam = LAST_INSERT_ID();

    COMMIT;
    CALL spLogEtlStep('spInsertCustomerOrder', 'MANUAL', 'customerOrder', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertCustomerOrderDetail $$
CREATE PROCEDURE spInsertCustomerOrderDetail(
    IN customerOrderIDParam BIGINT,
    IN productIDParam BIGINT,
    IN quantityParam INT,
    IN unitPriceParam DECIMAL(18,6),
    IN taxAmountParam DECIMAL(18,6),
    IN discountAmountParam DECIMAL(18,6)
)
BEGIN
    DECLARE errorMessage TEXT;
    DECLARE lineTotalValue DECIMAL(18,6);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertCustomerOrderDetail', 'MANUAL', 'customerOrderDetail', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF quantityParam <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'quantityParam must be greater than zero';
    END IF;

    IF unitPriceParam < 0 OR taxAmountParam < 0 OR discountAmountParam < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Amounts cannot be negative';
    END IF;

    SET lineTotalValue = ROUND((quantityParam * unitPriceParam) + taxAmountParam - discountAmountParam, 6);

    IF lineTotalValue < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lineTotal cannot be negative';
    END IF;

    INSERT INTO customerOrderDetail (
        customerOrderID,
        productID,
        quantity,
        unitPrice,
        taxAmount,
        discountAmount,
        lineTotal
    )
    VALUES (
        customerOrderIDParam,
        productIDParam,
        quantityParam,
        unitPriceParam,
        taxAmountParam,
        discountAmountParam,
        lineTotalValue
    );

    COMMIT;
    CALL spLogEtlStep('spInsertCustomerOrderDetail', 'MANUAL', 'customerOrderDetail', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spUpdateCustomerOrderStatus $$
CREATE PROCEDURE spUpdateCustomerOrderStatus(
    IN customerOrderIDParam BIGINT,
    IN orderStatusCodeParam VARCHAR(30),
    IN changedByPersonIDParam BIGINT,
    IN changeDetailsParam VARCHAR(250)
)
BEGIN
    DECLARE errorMessage TEXT;
    DECLARE previousOrderStatusCodeValue VARCHAR(30);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spUpdateCustomerOrderStatus', 'MANUAL', 'customerOrder', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    SELECT orderStatusCode
    INTO previousOrderStatusCodeValue
    FROM customerOrder
    WHERE customerOrderID = customerOrderIDParam
    FOR UPDATE;

    UPDATE customerOrder
    SET orderStatusCode = orderStatusCodeParam,
        updatedAt = CURRENT_TIMESTAMP
    WHERE customerOrderID = customerOrderIDParam;

    INSERT INTO customerOrderStatusLog (
        customerOrderID,
        previousOrderStatusCode,
        currentOrderStatusCode,
        changeDetails,
        changeSourceCode,
        changedByPersonID,
        changedAt,
        createdAt
    )
    VALUES (
        customerOrderIDParam,
        previousOrderStatusCodeValue,
        orderStatusCodeParam,
        changeDetailsParam,
        'MANUAL',
        changedByPersonIDParam,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    CALL spLogEtlStep('spUpdateCustomerOrderStatus', 'MANUAL', 'customerOrder', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertPaymentTransaction $$
CREATE PROCEDURE spInsertPaymentTransaction(
    IN customerOrderIDParam BIGINT,
    IN transactionCodeParam VARCHAR(50),
    IN methodCodeParam VARCHAR(30),
    IN paymentStatusCodeParam VARCHAR(30),
    IN transactionAmountParam DECIMAL(18,6),
    IN currencyIDParam BIGINT,
    IN exchangeRateParam DECIMAL(18,6),
    IN exchangeRateIDParam BIGINT,
    IN providerReferenceParam VARCHAR(80)
)
BEGIN
    DECLARE errorMessage TEXT;
    DECLARE checksumValue VARCHAR(80);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertPaymentTransaction', 'MANUAL', 'paymentTransaction', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF transactionAmountParam < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transactionAmountParam cannot be negative';
    END IF;

    IF exchangeRateParam <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'exchangeRateParam must be greater than zero';
    END IF;

    SET checksumValue = SHA2(CONCAT(
        transactionCodeParam,
        '|',
        customerOrderIDParam,
        '|',
        methodCodeParam,
        '|',
        paymentStatusCodeParam,
        '|',
        transactionAmountParam,
        '|',
        currencyIDParam,
        '|',
        exchangeRateParam
    ), 256);

    INSERT INTO paymentTransaction (
        customerOrderID,
        transactionCode,
        methodCode,
        paymentStatusCode,
        transactionAmount,
        currencyID,
        exchangeRate,
        exchangeRateID,
        providerReference,
        checksum
    )
    VALUES (
        customerOrderIDParam,
        transactionCodeParam,
        methodCodeParam,
        paymentStatusCodeParam,
        transactionAmountParam,
        currencyIDParam,
        exchangeRateParam,
        exchangeRateIDParam,
        providerReferenceParam,
        checksumValue
    );

    COMMIT;
    CALL spLogEtlStep('spInsertPaymentTransaction', 'MANUAL', 'paymentTransaction', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spInsertShipment $$
CREATE PROCEDURE spInsertShipment(
    IN customerOrderIDParam BIGINT,
    IN shipmentCodeParam VARCHAR(50),
    IN shipmentStatusCodeParam VARCHAR(30),
    IN shippingAddressParam VARCHAR(250),
    IN trackingNumberParam VARCHAR(80),
    IN carrierNameParam VARCHAR(60),
    IN viewTypeCodeParam VARCHAR(30),
    IN shippedAtParam TIMESTAMP,
    IN deliveredAtParam TIMESTAMP
)
BEGIN
    DECLARE errorMessage TEXT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 errorMessage = MESSAGE_TEXT;
        ROLLBACK;
        CALL spLogEtlStep('spInsertShipment', 'MANUAL', 'shipment', 'ERROR', 0, 0, errorMessage);
    END;

    START TRANSACTION;

    IF deliveredAtParam IS NOT NULL AND shippedAtParam IS NOT NULL AND deliveredAtParam < shippedAtParam THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'deliveredAtParam cannot be earlier than shippedAtParam';
    END IF;

    INSERT INTO shipment (
        customerOrderID,
        shipmentCode,
        shipmentStatusCode,
        shippingAddress,
        trackingNumber,
        carrierName,
        viewTypeCode,
        shippedAt,
        deliveredAt
    )
    VALUES (
        customerOrderIDParam,
        shipmentCodeParam,
        shipmentStatusCodeParam,
        shippingAddressParam,
        trackingNumberParam,
        carrierNameParam,
        viewTypeCodeParam,
        shippedAtParam,
        deliveredAtParam
    );

    COMMIT;
    CALL spLogEtlStep('spInsertShipment', 'MANUAL', 'shipment', 'SUCCESS', 1, 1, NULL);
END $$

DROP PROCEDURE IF EXISTS spSeedSampleData $$
CREATE PROCEDURE spSeedSampleData()
BEGIN
    DECLARE crcCurrencyID BIGINT;
    DECLARE usdCurrencyID BIGINT;
    DECLARE costaRicaCountryID BIGINT;
    DECLARE adminPersonID BIGINT;
    DECLARE customerPersonID BIGINT;
    DECLARE dynamicSiteIDValue BIGINT;
    DECLARE productIDValue BIGINT;
    DECLARE customerOrderIDValue BIGINT;

    CALL spInsertCurrency('USD', 'US Dollar', '$');
    CALL spInsertCurrency('CRC', 'Costa Rican Colon', '₡');

    SELECT currencyID INTO usdCurrencyID FROM currency WHERE currencyCode = 'USD' LIMIT 1;
    SELECT currencyID INTO crcCurrencyID FROM currency WHERE currencyCode = 'CRC' LIMIT 1;

    CALL spInsertCountry('Costa Rica', 'CR', 'CRI', crcCurrencyID);
    SELECT countryID INTO costaRicaCountryID FROM country WHERE iso2Code = 'CR' LIMIT 1;

    CALL spInsertBrandTemplate('PUREAURA', 'PureAura', 'https://example.com/logo.png', 'Natural wellness for daily life', 'Premium wellness customers');

    CALL spInsertPeople('PERS-ADMIN-001', costaRicaCountryID, 'admin@dynamicbrands.com', 'Admin', 'User', 'hash_admin', 'SYSTEM_USER', adminPersonID);
    CALL spInsertSystemUser(adminPersonID, 'USR-ADMIN-001', 'ADMIN');

    CALL spInsertPeople('PERS-CUST-001', costaRicaCountryID, 'customer@example.com', 'Laura', 'Ramirez', 'hash_customer', 'CUSTOMER', customerPersonID);

    CALL spInsertDynamicSite(
        'SITE-CR-001',
        'PureAura Costa Rica',
        'PUREAURA',
        costaRicaCountryID,
        crcCurrencyID,
        'ACTIVE',
        'pureaura.cr',
        'Natural health',
        'Warm, premium, trustworthy',
        JSON_OBJECT('primaryColor', '#2E7D32', 'style', 'natural'),
        'Dynamic Brands',
        'https://example.com/site-logo.png',
        dynamicSiteIDValue
    );

    CALL spInsertDynamicSiteMetric(dynamicSiteIDValue, 'VISITS', CURRENT_DATE, 1000);
    CALL spInsertDynamicSiteMetric(dynamicSiteIDValue, 'SESSIONS', CURRENT_DATE, 800);
    CALL spInsertDynamicSiteMetric(dynamicSiteIDValue, 'PURCHASES', CURRENT_DATE, 40);
    CALL spInsertDynamicSiteMetric(dynamicSiteIDValue, 'CONVERSION_RATE', CURRENT_DATE, 0.05);

    CALL spInsertProduct(
        'PROD-OIL-001',
        dynamicSiteIDValue,
        'OIL',
        'Aceite Esencial Premium',
        'Aceite esencial premium para aromaterapia',
        'SKU-OIL-001',
        usdCurrencyID,
        15.000000,
        adminPersonID,
        productIDValue
    );

    CALL spInsertProductPrice(productIDValue, dynamicSiteIDValue, crcCurrencyID, 14500.000000, CURRENT_TIMESTAMP, NULL, TRUE);
    CALL spInsertProductImage(productIDValue, 'MAIN', 'https://example.com/product-main.png', 1, TRUE);
    CALL spUpsertInventory(dynamicSiteIDValue, productIDValue, 120, 10, 20, 'HUB');

    CALL spInsertCountryProductPermission(
        productIDValue,
        costaRicaCountryID,
        50000,
        'PERM-CR-001',
        'Registro sanitario producto natural',
        'APPROVED',
        'CERT-001',
        'Ministerio de Salud',
        CURRENT_TIMESTAMP,
        DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 YEAR),
        'Permiso inicial aprobado'
    );

    CALL spInsertCustomerOrder(
        'ORD-001',
        customerPersonID,
        dynamicSiteIDValue,
        costaRicaCountryID,
        crcCurrencyID,
        'CREATED',
        2500.000000,
        1.000000,
        'Orden de prueba',
        customerOrderIDValue
    );

    CALL spInsertCustomerOrderDetail(customerOrderIDValue, productIDValue, 2, 14500.000000, 3770.000000, 0.000000);

    CALL spInsertPaymentTransaction(
        customerOrderIDValue,
        'PAY-001',
        'VISA',
        'APPROVED',
        35270.000000,
        crcCurrencyID,
        1.000000,
        NULL,
        'VISA-REF-001'
    );

    CALL spUpdateCustomerOrderStatus(customerOrderIDValue, 'PAID', adminPersonID, 'Payment approved');

    CALL spInsertShipment(
        customerOrderIDValue,
        'SHIP-001',
        'PENDING',
        'San José, Costa Rica',
        NULL,
        'Correos CR',
        'CUSTOMER',
        NULL,
        NULL
    );
END $$

DELIMITER ;