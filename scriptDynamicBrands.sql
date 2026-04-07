DROP DATABASE IF EXISTS dynamicBrandsDB;
CREATE DATABASE dynamicBrandsDB;
USE dynamicBrandsDB;

CREATE TABLE currency (
    currencyID BIGINT AUTO_INCREMENT PRIMARY KEY,
    currencyCode VARCHAR(20) NOT NULL,
    currencyName VARCHAR(45) NOT NULL,
    currencySymbol VARCHAR(30),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_currency_currencyCode (currencyCode)
) ENGINE=InnoDB;

CREATE TABLE country (
    countryID BIGINT AUTO_INCREMENT PRIMARY KEY,
    countryName VARCHAR(50) NOT NULL,
    iso2Code CHAR(2) NOT NULL,
    iso3Code CHAR(3) NOT NULL,
    localCurrencyID BIGINT NOT NULL,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_country_countryName (countryName),
    UNIQUE KEY uq_country_iso2Code (iso2Code),
    UNIQUE KEY uq_country_iso3Code (iso3Code),
    KEY idx_country_localCurrencyID (localCurrencyID),
    CONSTRAINT fk_country_localCurrencyID
        FOREIGN KEY (localCurrencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE exchangePair (
    exchangePairID BIGINT AUTO_INCREMENT PRIMARY KEY,
    baseCurrencyID BIGINT NOT NULL,
    quoteCurrencyID BIGINT NOT NULL,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_exchangePair_base_quote (baseCurrencyID, quoteCurrencyID),
    KEY idx_exchangePair_baseCurrencyID (baseCurrencyID),
    KEY idx_exchangePair_quoteCurrencyID (quoteCurrencyID),
    CONSTRAINT fk_exchangePair_baseCurrencyID
        FOREIGN KEY (baseCurrencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_exchangePair_quoteCurrencyID
        FOREIGN KEY (quoteCurrencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE currentExchangeRate (
    currentExchangeRateID BIGINT AUTO_INCREMENT PRIMARY KEY,
    exchangePairID BIGINT NOT NULL,
    buyRate NUMERIC(18,6) NOT NULL,
    sellRate NUMERIC(18,6) NOT NULL,
    sourceName VARCHAR(50),
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_currentExchangeRate_exchangePairID (exchangePairID),
    CONSTRAINT fk_currentExchangeRate_exchangePairID
        FOREIGN KEY (exchangePairID) REFERENCES exchangePair(exchangePairID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE historicalExchangeRate (
    historicalExchangeRateID BIGINT AUTO_INCREMENT PRIMARY KEY,
    exchangePairID BIGINT NOT NULL,
    buyRate NUMERIC(18,6) NOT NULL,
    sellRate NUMERIC(18,6) NOT NULL,
    validFrom TIMESTAMP NOT NULL,
    validTo TIMESTAMP NULL,
    recordedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_historicalExchangeRate_exchangePairID (exchangePairID),
    CONSTRAINT fk_historicalExchangeRate_exchangePairID
        FOREIGN KEY (exchangePairID) REFERENCES exchangePair(exchangePairID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE userRole (
    roleCode VARCHAR(30) PRIMARY KEY,
    roleName VARCHAR(50) NOT NULL,
    roleDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE userInfo (
    userID BIGINT AUTO_INCREMENT PRIMARY KEY,
    userCode VARCHAR(30) NOT NULL,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    passwordHash VARCHAR(255) NOT NULL,
    roleCode VARCHAR(30) NOT NULL,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    lastLoginAt TIMESTAMP NULL,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_userInfo_userCode (userCode),
    UNIQUE KEY uq_userInfo_email (email),
    KEY idx_userInfo_roleCode (roleCode),
    CONSTRAINT fk_userInfo_roleCode
        FOREIGN KEY (roleCode) REFERENCES userRole(roleCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE brandTemplate (
    brandCode VARCHAR(30) PRIMARY KEY,
    brandName VARCHAR(40) NOT NULL,
    logoURL VARCHAR(255),
    corePromise VARCHAR(250),
    targetAudience VARCHAR(200),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteStatus (
    statusCode VARCHAR(30) PRIMARY KEY,
    statusName VARCHAR(50) NOT NULL,
    statusDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteGenerationStatus (
    statusCode VARCHAR(30) PRIMARY KEY,
    statusName VARCHAR(50) NOT NULL,
    statusDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteEventType (
    eventTypeCode VARCHAR(30) PRIMARY KEY,
    eventName VARCHAR(50) NOT NULL,
    eventDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteInfo (
    dynamicSiteID BIGINT AUTO_INCREMENT PRIMARY KEY,
    siteCode VARCHAR(30) NOT NULL,
    siteName VARCHAR(80) NOT NULL,
    brandCode VARCHAR(30) NOT NULL,
    countryID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    siteStatusCode VARCHAR(30) NOT NULL,
    primaryDomainName VARCHAR(150) NOT NULL,
    marketingFocus VARCHAR(80),
    brandVoice VARCHAR(80),
    targetSegment VARCHAR(80),
    launchDate DATETIME,
    closeDate DATETIME,
    clientName VARCHAR(80),
    logoURL VARCHAR(255),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dynamicSiteInfo_siteCode (siteCode),
    UNIQUE KEY uq_dynamicSiteInfo_primaryDomainName (primaryDomainName),
    KEY idx_dynamicSiteInfo_brandCode (brandCode),
    KEY idx_dynamicSiteInfo_countryID (countryID),
    KEY idx_dynamicSiteInfo_currencyID (currencyID),
    KEY idx_dynamicSiteInfo_siteStatusCode (siteStatusCode),
    CONSTRAINT fk_dynamicSiteInfo_brandCode
        FOREIGN KEY (brandCode) REFERENCES brandTemplate(brandCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteInfo_countryID
        FOREIGN KEY (countryID) REFERENCES country(countryID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteInfo_currencyID
        FOREIGN KEY (currencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteInfo_siteStatusCode
        FOREIGN KEY (siteStatusCode) REFERENCES dynamicSiteStatus(statusCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteDomain (
    dynamicSiteDomainID BIGINT AUTO_INCREMENT PRIMARY KEY,
    dynamicSiteID BIGINT NOT NULL,
    domainName VARCHAR(150) NOT NULL,
    isPrimary BOOLEAN NOT NULL DEFAULT FALSE,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dynamicSiteDomain_domainName (domainName),
    KEY idx_dynamicSiteDomain_dynamicSiteID (dynamicSiteID),
    CONSTRAINT fk_dynamicSiteDomain_dynamicSiteID
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteAIGeneration (
    dynamicSiteAIGenerationID BIGINT AUTO_INCREMENT PRIMARY KEY,
    dynamicSiteID BIGINT NOT NULL,
    promptContent TEXT,
    generatedConfiguration JSON,
    generationStatusCode VARCHAR(30) NOT NULL,
    generationDetails VARCHAR(250),
    generatedAt TIMESTAMP NULL,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_dynamicSiteAIGeneration_dynamicSiteID (dynamicSiteID),
    KEY idx_dynamicSiteAIGeneration_generationStatusCode (generationStatusCode),
    CONSTRAINT fk_dynamicSiteAIGeneration_dynamicSiteID
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteAIGeneration_generationStatusCode
        FOREIGN KEY (generationStatusCode) REFERENCES dynamicSiteGenerationStatus(statusCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteMetric (
    dynamicSiteMetricID BIGINT AUTO_INCREMENT PRIMARY KEY,
    dynamicSiteID BIGINT NOT NULL,
    metricDate DATE NOT NULL,
    visitCount INT NOT NULL DEFAULT 0,
    sessionCount INT NOT NULL DEFAULT 0,
    purchaseCount INT NOT NULL DEFAULT 0,
    conversionRate DECIMAL(10,4) NOT NULL DEFAULT 0.0000,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dynamicSiteMetric_site_date (dynamicSiteID, metricDate),
    CONSTRAINT fk_dynamicSiteMetric_dynamicSiteID
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE changeSource (
    sourceCode VARCHAR(30) PRIMARY KEY,
    sourceName VARCHAR(50) NOT NULL,
    sourceDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteStatusLog (
    dynamicSiteStatusLogID BIGINT AUTO_INCREMENT PRIMARY KEY,
    dynamicSiteID BIGINT NOT NULL,
    previousSiteStatusCode VARCHAR(30),
    currentSiteStatusCode VARCHAR(30) NOT NULL,
    changeDetails VARCHAR(250),
    changeSourceCode VARCHAR(30) NOT NULL,
    changedByUserID BIGINT,
    changedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_dynamicSiteStatusLog_dynamicSiteID (dynamicSiteID),
    KEY idx_dynamicSiteStatusLog_previousSiteStatusCode (previousSiteStatusCode),
    KEY idx_dynamicSiteStatusLog_currentSiteStatusCode (currentSiteStatusCode),
    KEY idx_dynamicSiteStatusLog_changeSourceCode (changeSourceCode),
    KEY idx_dynamicSiteStatusLog_changedByUserID (changedByUserID),
    CONSTRAINT fk_dynamicSiteStatusLog_dynamicSiteID
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteStatusLog_previousSiteStatusCode
        FOREIGN KEY (previousSiteStatusCode) REFERENCES dynamicSiteStatus(statusCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteStatusLog_currentSiteStatusCode
        FOREIGN KEY (currentSiteStatusCode) REFERENCES dynamicSiteStatus(statusCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteStatusLog_changeSourceCode
        FOREIGN KEY (changeSourceCode) REFERENCES changeSource(sourceCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteStatusLog_changedByUserID
        FOREIGN KEY (changedByUserID) REFERENCES userInfo(userID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteAuditLog (
    dynamicSiteAuditLogID BIGINT AUTO_INCREMENT PRIMARY KEY,
    dynamicSiteID BIGINT NOT NULL,
    eventTypeCode VARCHAR(30) NOT NULL,
    eventDetails VARCHAR(250),
    performedByUserID BIGINT,
    performedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_dynamicSiteAuditLog_dynamicSiteID (dynamicSiteID),
    KEY idx_dynamicSiteAuditLog_eventTypeCode (eventTypeCode),
    KEY idx_dynamicSiteAuditLog_performedByUserID (performedByUserID),
    CONSTRAINT fk_dynamicSiteAuditLog_dynamicSiteID
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteAuditLog_eventTypeCode
        FOREIGN KEY (eventTypeCode) REFERENCES dynamicSiteEventType(eventTypeCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteAuditLog_performedByUserID
        FOREIGN KEY (performedByUserID) REFERENCES userInfo(userID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE customer (
    customerID BIGINT AUTO_INCREMENT PRIMARY KEY,
    customerCode VARCHAR(50) NOT NULL,
    countryID BIGINT NOT NULL,
    email VARCHAR(150) NOT NULL,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    passwordHash VARCHAR(255) NOT NULL,
    isEmailVerified BOOLEAN NOT NULL DEFAULT FALSE,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    lastLoginAt TIMESTAMP NULL,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_customer_customerCode (customerCode),
    UNIQUE KEY uq_customer_email (email),
    KEY idx_customer_countryID (countryID),
    CONSTRAINT fk_customer_countryID
        FOREIGN KEY (countryID) REFERENCES country(countryID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE orderStatus (
    statusCode VARCHAR(30) PRIMARY KEY,
    statusName VARCHAR(50) NOT NULL,
    statusDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE customerOrder (
    customerOrderID BIGINT AUTO_INCREMENT PRIMARY KEY,
    orderCode VARCHAR(50) NOT NULL,
    customerID BIGINT NOT NULL,
    dynamicSiteID BIGINT NOT NULL,
    customerCountryID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    orderStatusCode VARCHAR(30) NOT NULL,
    orderDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subTotal DECIMAL(18,6) NOT NULL DEFAULT 0,
    taxTotal DECIMAL(18,6) NOT NULL DEFAULT 0,
    shippingAmount DECIMAL(18,6) NOT NULL DEFAULT 0,
    totalAmount DECIMAL(18,6) NOT NULL DEFAULT 0,
    exchangeRate DECIMAL(18,6) NOT NULL DEFAULT 1,
    notes VARCHAR(200),
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_customerOrder_orderCode (orderCode),
    KEY idx_customerOrder_customerID (customerID),
    KEY idx_customerOrder_dynamicSiteID (dynamicSiteID),
    KEY idx_customerOrder_customerCountryID (customerCountryID),
    KEY idx_customerOrder_currencyID (currencyID),
    KEY idx_customerOrder_orderStatusCode (orderStatusCode),
    CONSTRAINT fk_customerOrder_customerID
        FOREIGN KEY (customerID) REFERENCES customer(customerID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrder_dynamicSiteID
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrder_customerCountryID
        FOREIGN KEY (customerCountryID) REFERENCES country(countryID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrder_currencyID
        FOREIGN KEY (currencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrder_orderStatusCode
        FOREIGN KEY (orderStatusCode) REFERENCES orderStatus(statusCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE customerOrderStatusLog (
    customerOrderStatusLogID BIGINT AUTO_INCREMENT PRIMARY KEY,
    customerOrderID BIGINT NOT NULL,
    previousOrderStatusCode VARCHAR(30),
    currentOrderStatusCode VARCHAR(30) NOT NULL,
    changeDetails VARCHAR(250),
    changeSourceCode VARCHAR(30) NOT NULL,
    changedByUserID BIGINT,
    changedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_customerOrderStatusLog_customerOrderID (customerOrderID),
    KEY idx_customerOrderStatusLog_previousOrderStatusCode (previousOrderStatusCode),
    KEY idx_customerOrderStatusLog_currentOrderStatusCode (currentOrderStatusCode),
    KEY idx_customerOrderStatusLog_changeSourceCode (changeSourceCode),
    KEY idx_customerOrderStatusLog_changedByUserID (changedByUserID),
    CONSTRAINT fk_customerOrderStatusLog_customerOrderID
        FOREIGN KEY (customerOrderID) REFERENCES customerOrder(customerOrderID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrderStatusLog_previousOrderStatusCode
        FOREIGN KEY (previousOrderStatusCode) REFERENCES orderStatus(statusCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrderStatusLog_currentOrderStatusCode
        FOREIGN KEY (currentOrderStatusCode) REFERENCES orderStatus(statusCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrderStatusLog_changeSourceCode
        FOREIGN KEY (changeSourceCode) REFERENCES changeSource(sourceCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrderStatusLog_changedByUserID
        FOREIGN KEY (changedByUserID) REFERENCES userInfo(userID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE productCategory (
    categoryCode VARCHAR(30) PRIMARY KEY,
    categoryName VARCHAR(80) NOT NULL,
    categoryDescription VARCHAR(200),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE product (
    productID BIGINT AUTO_INCREMENT PRIMARY KEY,
    productCode VARCHAR(50) NOT NULL,
    dynamicSiteID BIGINT NOT NULL,
    categoryCode VARCHAR(30) NOT NULL,
    productName VARCHAR(120) NOT NULL,
    productDescription VARCHAR(500),
    sku VARCHAR(50) NOT NULL,
    baseCurrencyID BIGINT NOT NULL,
    basePrice DECIMAL(18,6) NOT NULL DEFAULT 0,
    updatedByUserID BIGINT,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_product_productCode (productCode),
    UNIQUE KEY uq_product_sku (sku),
    KEY idx_product_dynamicSiteID (dynamicSiteID),
    KEY idx_product_categoryCode (categoryCode),
    KEY idx_product_baseCurrencyID (baseCurrencyID),
    KEY idx_product_updatedByUserID (updatedByUserID),
    CONSTRAINT fk_product_dynamicSiteID
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_product_categoryCode
        FOREIGN KEY (categoryCode) REFERENCES productCategory(categoryCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_product_baseCurrencyID
        FOREIGN KEY (baseCurrencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_product_updatedByUserID
        FOREIGN KEY (updatedByUserID) REFERENCES userInfo(userID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE productPrice (
    productPriceID BIGINT AUTO_INCREMENT PRIMARY KEY,
    productID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    priceAmount DECIMAL(18,6) NOT NULL,
    validFrom TIMESTAMP NOT NULL,
    validTo TIMESTAMP NULL,
    isCurrent BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_productPrice_productID (productID),
    KEY idx_productPrice_currencyID (currencyID),
    CONSTRAINT fk_productPrice_productID
        FOREIGN KEY (productID) REFERENCES product(productID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_productPrice_currencyID
        FOREIGN KEY (currencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE productImageType (
    typeCode VARCHAR(30) PRIMARY KEY,
    typeName VARCHAR(50) NOT NULL,
    typeDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE productImage (
    productImageID BIGINT AUTO_INCREMENT PRIMARY KEY,
    productID BIGINT NOT NULL,
    typeCode VARCHAR(30) NOT NULL,
    imageURL VARCHAR(255) NOT NULL,
    displayOrder INT NOT NULL DEFAULT 1,
    isPrimary BOOLEAN NOT NULL DEFAULT FALSE,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_productImage_productID (productID),
    KEY idx_productImage_typeCode (typeCode),
    CONSTRAINT fk_productImage_productID
        FOREIGN KEY (productID) REFERENCES product(productID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_productImage_typeCode
        FOREIGN KEY (typeCode) REFERENCES productImageType(typeCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE packagingType (
    packagingTypeCode VARCHAR(30) PRIMARY KEY,
    packagingTypeName VARCHAR(50) NOT NULL,
    packagingTypeDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE productPackaging (
    productPackagingID BIGINT AUTO_INCREMENT PRIMARY KEY,
    productID BIGINT NOT NULL,
    countryID BIGINT NOT NULL,
    packagingTypeCode VARCHAR(30) NOT NULL,
    packagingName VARCHAR(80) NOT NULL,
    packagingDescription VARCHAR(250),
    unitContent VARCHAR(50),
    unitMeasure VARCHAR(30),
    packageMaterial VARCHAR(50),
    isFragile BOOLEAN NOT NULL DEFAULT FALSE,
    isPrimary BOOLEAN NOT NULL DEFAULT FALSE,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_productPackaging_productID (productID),
    KEY idx_productPackaging_countryID (countryID),
    KEY idx_productPackaging_packagingTypeCode (packagingTypeCode),
    CONSTRAINT fk_productPackaging_productID
        FOREIGN KEY (productID) REFERENCES product(productID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_productPackaging_countryID
        FOREIGN KEY (countryID) REFERENCES country(countryID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_productPackaging_packagingTypeCode
        FOREIGN KEY (packagingTypeCode) REFERENCES packagingType(packagingTypeCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE labelType (
    labelTypeCode VARCHAR(30) PRIMARY KEY,
    labelTypeName VARCHAR(50) NOT NULL,
    labelTypeDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE productLabel (
    productLabelID BIGINT AUTO_INCREMENT PRIMARY KEY,
    productID BIGINT NOT NULL,
    dynamicSiteID BIGINT NOT NULL,
    countryID BIGINT NOT NULL,
    labelTypeCode VARCHAR(30) NOT NULL,
    labelName VARCHAR(80) NOT NULL,
    labelDescription VARCHAR(250),
    labelLanguage VARCHAR(30),
    labelContent TEXT,
    isPrimary BOOLEAN NOT NULL DEFAULT FALSE,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_productLabel_productID (productID),
    KEY idx_productLabel_dynamicSiteID (dynamicSiteID),
    KEY idx_productLabel_countryID (countryID),
    KEY idx_productLabel_labelTypeCode (labelTypeCode),
    CONSTRAINT fk_productLabel_productID
        FOREIGN KEY (productID) REFERENCES product(productID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_productLabel_dynamicSiteID
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_productLabel_countryID
        FOREIGN KEY (countryID) REFERENCES country(countryID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_productLabel_labelTypeCode
        FOREIGN KEY (labelTypeCode) REFERENCES labelType(labelTypeCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE regulatoryRequirementType (
    requirementTypeCode VARCHAR(30) PRIMARY KEY,
    requirementTypeName VARCHAR(60) NOT NULL,
    requirementTypeDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE permissionStatus (
    statusCode VARCHAR(30) PRIMARY KEY,
    statusName VARCHAR(50) NOT NULL,
    statusDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE countryProductRequirement (
    countryProductRequirementID BIGINT AUTO_INCREMENT PRIMARY KEY,
    productID BIGINT NOT NULL,
    countryID BIGINT NOT NULL,
    requirementTypeCode VARCHAR(30) NOT NULL,
    requirementName VARCHAR(100) NOT NULL,
    requirementDescription VARCHAR(250),
    isMandatory BOOLEAN NOT NULL DEFAULT TRUE,
    issuedBy VARCHAR(80),
    validFrom TIMESTAMP NULL,
    validTo TIMESTAMP NULL,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_countryProductRequirement_productID (productID),
    KEY idx_countryProductRequirement_countryID (countryID),
    KEY idx_countryProductRequirement_requirementTypeCode (requirementTypeCode),
    CONSTRAINT fk_countryProductRequirement_productID
        FOREIGN KEY (productID) REFERENCES product(productID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_countryProductRequirement_countryID
        FOREIGN KEY (countryID) REFERENCES country(countryID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_countryProductRequirement_requirementTypeCode
        FOREIGN KEY (requirementTypeCode) REFERENCES regulatoryRequirementType(requirementTypeCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE countryProductPermission (
    countryProductPermissionID BIGINT AUTO_INCREMENT PRIMARY KEY,
    productID BIGINT NOT NULL,
    countryID BIGINT NOT NULL,
    permissionCode VARCHAR(50) NOT NULL,
    permissionName VARCHAR(100) NOT NULL,
    permissionStatusCode VARCHAR(30) NOT NULL,
    certificateNumber VARCHAR(80),
    issuedBy VARCHAR(80),
    issuedAt TIMESTAMP NULL,
    expiresAt TIMESTAMP NULL,
    notes VARCHAR(250),
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_countryProductPermission_permissionCode (permissionCode),
    KEY idx_countryProductPermission_productID (productID),
    KEY idx_countryProductPermission_countryID (countryID),
    KEY idx_countryProductPermission_permissionStatusCode (permissionStatusCode),
    CONSTRAINT fk_countryProductPermission_productID
        FOREIGN KEY (productID) REFERENCES product(productID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_countryProductPermission_countryID
        FOREIGN KEY (countryID) REFERENCES country(countryID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_countryProductPermission_permissionStatusCode
        FOREIGN KEY (permissionStatusCode) REFERENCES permissionStatus(statusCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE inventorySource (
    sourceCode VARCHAR(30) PRIMARY KEY,
    sourceName VARCHAR(50) NOT NULL,
    sourceDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE inventory (
    inventoryID BIGINT AUTO_INCREMENT PRIMARY KEY,
    dynamicSiteID BIGINT NOT NULL,
    productID BIGINT NOT NULL,
    availableQuantity INT NOT NULL DEFAULT 0,
    reservedQuantity INT NOT NULL DEFAULT 0,
    sellableQuantity INT NOT NULL DEFAULT 0,
    reorderLevel INT NOT NULL DEFAULT 0,
    sourceCode VARCHAR(30) NOT NULL,
    lastStockUpdateAt TIMESTAMP NULL,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_inventory_site_product (dynamicSiteID, productID),
    KEY idx_inventory_dynamicSiteID (dynamicSiteID),
    KEY idx_inventory_productID (productID),
    KEY idx_inventory_sourceCode (sourceCode),
    CONSTRAINT fk_inventory_dynamicSiteID
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_inventory_productID
        FOREIGN KEY (productID) REFERENCES product(productID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_inventory_sourceCode
        FOREIGN KEY (sourceCode) REFERENCES inventorySource(sourceCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE paymentMethod (
    methodCode VARCHAR(30) PRIMARY KEY,
    methodName VARCHAR(50) NOT NULL,
    methodDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE paymentTransactionStatus (
    statusCode VARCHAR(30) PRIMARY KEY,
    statusName VARCHAR(50) NOT NULL,
    statusDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE paymentProvider (
    providerCode VARCHAR(30) PRIMARY KEY,
    providerName VARCHAR(50) NOT NULL,
    providerDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE paymentTransaction (
    paymentTransactionID BIGINT AUTO_INCREMENT PRIMARY KEY,
    customerOrderID BIGINT NOT NULL,
    transactionCode VARCHAR(50) NOT NULL,
    methodCode VARCHAR(30) NOT NULL,
    paymentStatusCode VARCHAR(30) NOT NULL,
    providerCode VARCHAR(30) NOT NULL,
    transactionAmount DECIMAL(18,6) NOT NULL DEFAULT 0,
    currencyID BIGINT NOT NULL,
    providerReference VARCHAR(80),
    transactionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_paymentTransaction_transactionCode (transactionCode),
    KEY idx_paymentTransaction_customerOrderID (customerOrderID),
    KEY idx_paymentTransaction_methodCode (methodCode),
    KEY idx_paymentTransaction_paymentStatusCode (paymentStatusCode),
    KEY idx_paymentTransaction_providerCode (providerCode),
    KEY idx_paymentTransaction_currencyID (currencyID),
    CONSTRAINT fk_paymentTransaction_customerOrderID
        FOREIGN KEY (customerOrderID) REFERENCES customerOrder(customerOrderID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_paymentTransaction_methodCode
        FOREIGN KEY (methodCode) REFERENCES paymentMethod(methodCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_paymentTransaction_paymentStatusCode
        FOREIGN KEY (paymentStatusCode) REFERENCES paymentTransactionStatus(statusCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_paymentTransaction_providerCode
        FOREIGN KEY (providerCode) REFERENCES paymentProvider(providerCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_paymentTransaction_currencyID
        FOREIGN KEY (currencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE shipmentViewType (
    viewTypeCode VARCHAR(30) PRIMARY KEY,
    viewTypeName VARCHAR(50) NOT NULL,
    viewTypeDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE shipmentStatus (
    statusCode VARCHAR(30) PRIMARY KEY,
    statusName VARCHAR(50) NOT NULL,
    statusDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE shipment (
    shipmentID BIGINT AUTO_INCREMENT PRIMARY KEY,
    customerOrderID BIGINT NOT NULL,
    shipmentCode VARCHAR(50) NOT NULL,
    shipmentStatusCode VARCHAR(30) NOT NULL,
    shippingAddress VARCHAR(250) NOT NULL,
    trackingNumber VARCHAR(80),
    carrierName VARCHAR(60),
    viewTypeCode VARCHAR(30) NOT NULL,
    shippedAt TIMESTAMP NULL,
    deliveredAt TIMESTAMP NULL,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_shipment_shipmentCode (shipmentCode),
    KEY idx_shipment_customerOrderID (customerOrderID),
    KEY idx_shipment_shipmentStatusCode (shipmentStatusCode),
    KEY idx_shipment_viewTypeCode (viewTypeCode),
    CONSTRAINT fk_shipment_customerOrderID
        FOREIGN KEY (customerOrderID) REFERENCES customerOrder(customerOrderID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_shipment_shipmentStatusCode
        FOREIGN KEY (shipmentStatusCode) REFERENCES shipmentStatus(statusCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_shipment_viewTypeCode
        FOREIGN KEY (viewTypeCode) REFERENCES shipmentViewType(viewTypeCode)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE etlExecutionLog (
    etlExecutionLogID BIGINT AUTO_INCREMENT PRIMARY KEY,
    processName VARCHAR(60) NOT NULL,
    sourceSystem VARCHAR(30) NOT NULL,
    targetSystem VARCHAR(30) NOT NULL,
    executionStatus VARCHAR(30) NOT NULL,
    recordsExtracted INT NOT NULL DEFAULT 0,
    recordsLoaded INT NOT NULL DEFAULT 0,
    errorDetails VARCHAR(500),
    startedAt TIMESTAMP NULL,
    finishedAt TIMESTAMP NULL,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;