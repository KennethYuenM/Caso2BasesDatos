DROP DATABASE IF EXISTS dynamicBrandsDB;
CREATE DATABASE dynamicBrandsDB;
USE dynamicBrandsDB;

CREATE TABLE dynamicSiteStatus (
    siteStatusID BIGINT AUTO_INCREMENT PRIMARY KEY,
    statusCode VARCHAR(30) NOT NULL,
    statusName VARCHAR(50) NOT NULL,
    statusDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dynamicSiteStatus_statusCode (statusCode)
) ENGINE=InnoDB;

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
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_country_countryName (countryName),
    UNIQUE KEY uq_country_iso2Code (iso2Code),
    UNIQUE KEY uq_country_iso3Code (iso3Code)
) ENGINE=InnoDB;

CREATE TABLE brandTemplate (
    brandTemplateID BIGINT AUTO_INCREMENT PRIMARY KEY,
    brandCode VARCHAR(30) NOT NULL,
    brandName VARCHAR(40) NOT NULL,
    logoURL VARCHAR(255),
    corePromise VARCHAR(250),
    targetAudience VARCHAR(200),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_brandTemplate_brandCode (brandCode)
) ENGINE=InnoDB;

CREATE TABLE userRole (
    userRoleID BIGINT AUTO_INCREMENT PRIMARY KEY,
    roleCode VARCHAR(30) NOT NULL,
    roleName VARCHAR(50) NOT NULL,
    roleDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_userRole_roleCode (roleCode)
) ENGINE=InnoDB;

CREATE TABLE orderStatus (
    orderStatusID BIGINT AUTO_INCREMENT PRIMARY KEY,
    statusCode VARCHAR(30) NOT NULL,
    statusName VARCHAR(50) NOT NULL,
    statusDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_orderStatus_statusCode (statusCode)
) ENGINE=InnoDB;

CREATE TABLE productCategory (
    productCategoryID BIGINT AUTO_INCREMENT PRIMARY KEY,
    categoryCode VARCHAR(30) NOT NULL,
    categoryName VARCHAR(80) NOT NULL,
    categoryDescription VARCHAR(200),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_productCategory_categoryCode (categoryCode)
) ENGINE=InnoDB;

CREATE TABLE paymentMethod (
    paymentMethodID BIGINT AUTO_INCREMENT PRIMARY KEY,
    methodCode VARCHAR(30) NOT NULL,
    methodName VARCHAR(50) NOT NULL,
    methodDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_paymentMethod_methodCode (methodCode)
) ENGINE=InnoDB;

CREATE TABLE paymentTransactionStatus (
    paymentTransactionStatusID BIGINT AUTO_INCREMENT PRIMARY KEY,
    statusCode VARCHAR(30) NOT NULL,
    statusName VARCHAR(50) NOT NULL,
    statusDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_paymentTransactionStatus_statusCode (statusCode)
) ENGINE=InnoDB;

CREATE TABLE shipmentStatus (
    shipmentStatusID BIGINT AUTO_INCREMENT PRIMARY KEY,
    statusCode VARCHAR(30) NOT NULL,
    statusName VARCHAR(50) NOT NULL,
    statusDescription VARCHAR(150),
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_shipmentStatus_statusCode (statusCode)
) ENGINE=InnoDB;

CREATE TABLE userInfo (
    userID BIGINT AUTO_INCREMENT PRIMARY KEY,
    userCode VARCHAR(30) NOT NULL,
    firstName VARCHAR(100) NOT NULL,
    lastName VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    passwordHash VARCHAR(255) NOT NULL,
    userRoleID BIGINT NOT NULL,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    lastLoginAt TIMESTAMP NULL,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_userInfo_userCode (userCode),
    UNIQUE KEY uq_userInfo_email (email),
    KEY idx_userInfo_userRoleID (userRoleID),
    CONSTRAINT fk_userInfo_userRole
        FOREIGN KEY (userRoleID) REFERENCES userRole(userRoleID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteInfo (
    dynamicSiteID BIGINT AUTO_INCREMENT PRIMARY KEY,
    siteCode VARCHAR(30) NOT NULL,
    siteName VARCHAR(80) NOT NULL,
    brandTemplateID BIGINT NOT NULL,
    countryID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    siteStatusID BIGINT NOT NULL,
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
    KEY idx_dynamicSiteInfo_brandTemplateID (brandTemplateID),
    KEY idx_dynamicSiteInfo_countryID (countryID),
    KEY idx_dynamicSiteInfo_currencyID (currencyID),
    KEY idx_dynamicSiteInfo_siteStatusID (siteStatusID),
    CONSTRAINT fk_dynamicSiteInfo_brandTemplate
        FOREIGN KEY (brandTemplateID) REFERENCES brandTemplate(brandTemplateID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteInfo_country
        FOREIGN KEY (countryID) REFERENCES country(countryID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteInfo_currency
        FOREIGN KEY (currencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteInfo_siteStatus
        FOREIGN KEY (siteStatusID) REFERENCES dynamicSiteStatus(siteStatusID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteStatusLog (
    dynamicSiteStatusLogID BIGINT AUTO_INCREMENT PRIMARY KEY,
    dynamicSiteID BIGINT NOT NULL,
    previousSiteStatusID BIGINT,
    currentSiteStatusID BIGINT NOT NULL,
    changeDetails VARCHAR(250),
    changeSource VARCHAR(30),
    changedByUserID BIGINT,
    changedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_dynamicSiteStatusLog_dynamicSiteID (dynamicSiteID),
    KEY idx_dynamicSiteStatusLog_previousSiteStatusID (previousSiteStatusID),
    KEY idx_dynamicSiteStatusLog_currentSiteStatusID (currentSiteStatusID),
    KEY idx_dynamicSiteStatusLog_changedByUserID (changedByUserID),
    CONSTRAINT fk_dynamicSiteStatusLog_dynamicSite
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteStatusLog_previousStatus
        FOREIGN KEY (previousSiteStatusID) REFERENCES dynamicSiteStatus(siteStatusID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteStatusLog_currentStatus
        FOREIGN KEY (currentSiteStatusID) REFERENCES dynamicSiteStatus(siteStatusID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteStatusLog_changedByUser
        FOREIGN KEY (changedByUserID) REFERENCES userInfo(userID)
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
    CONSTRAINT fk_dynamicSiteDomain_dynamicSite
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteAIGeneration (
    dynamicSiteAIGenerationID BIGINT AUTO_INCREMENT PRIMARY KEY,
    dynamicSiteID BIGINT NOT NULL,
    promptVersion VARCHAR(50) NOT NULL,
    promptContent TEXT,
    generatedConfiguration JSON,
    generationStatus VARCHAR(30),
    generationDetails VARCHAR(250),
    generatedAt TIMESTAMP NULL,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_dynamicSiteAIGeneration_dynamicSiteID (dynamicSiteID),
    CONSTRAINT fk_dynamicSiteAIGeneration_dynamicSite
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
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
    CONSTRAINT fk_exchangePair_baseCurrency
        FOREIGN KEY (baseCurrencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_exchangePair_quoteCurrency
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
    KEY idx_currentExchangeRate_exchangePairID (exchangePairID),
    CONSTRAINT fk_currentExchangeRate_exchangePair
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
    CONSTRAINT fk_historicalExchangeRate_exchangePair
        FOREIGN KEY (exchangePairID) REFERENCES exchangePair(exchangePairID)
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
    CONSTRAINT fk_customer_country
        FOREIGN KEY (countryID) REFERENCES country(countryID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE product (
    productID BIGINT AUTO_INCREMENT PRIMARY KEY,
    productCode VARCHAR(50) NOT NULL,
    dynamicSiteID BIGINT NOT NULL,
    productCategoryID BIGINT NOT NULL,
    productName VARCHAR(120) NOT NULL,
    productDescription VARCHAR(500),
    sku VARCHAR(50) NOT NULL,
    baseCurrencyID BIGINT NOT NULL,
    basePrice DECIMAL(18,6) NOT NULL DEFAULT 0,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_product_productCode (productCode),
    UNIQUE KEY uq_product_sku (sku),
    KEY idx_product_dynamicSiteID (dynamicSiteID),
    KEY idx_product_productCategoryID (productCategoryID),
    KEY idx_product_baseCurrencyID (baseCurrencyID),
    CONSTRAINT fk_product_dynamicSite
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_product_productCategory
        FOREIGN KEY (productCategoryID) REFERENCES productCategory(productCategoryID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_product_baseCurrency
        FOREIGN KEY (baseCurrencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE customerOrder (
    customerOrderID BIGINT AUTO_INCREMENT PRIMARY KEY,
    orderCode VARCHAR(50) NOT NULL,
    customerID BIGINT NOT NULL,
    dynamicSiteID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    orderStatusID BIGINT NOT NULL,
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
    KEY idx_customerOrder_currencyID (currencyID),
    KEY idx_customerOrder_orderStatusID (orderStatusID),
    CONSTRAINT fk_customerOrder_customer
        FOREIGN KEY (customerID) REFERENCES customer(customerID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrder_dynamicSite
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrder_currency
        FOREIGN KEY (currencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrder_orderStatus
        FOREIGN KEY (orderStatusID) REFERENCES orderStatus(orderStatusID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE customerOrderStatusLog (
    customerOrderStatusLogID BIGINT AUTO_INCREMENT PRIMARY KEY,
    customerOrderID BIGINT NOT NULL,
    previousOrderStatusID BIGINT,
    currentOrderStatusID BIGINT NOT NULL,
    changeDetails VARCHAR(250),
    changeSource VARCHAR(30),
    changedByUserID BIGINT,
    changedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_customerOrderStatusLog_customerOrderID (customerOrderID),
    KEY idx_customerOrderStatusLog_previousOrderStatusID (previousOrderStatusID),
    KEY idx_customerOrderStatusLog_currentOrderStatusID (currentOrderStatusID),
    KEY idx_customerOrderStatusLog_changedByUserID (changedByUserID),
    CONSTRAINT fk_customerOrderStatusLog_order
        FOREIGN KEY (customerOrderID) REFERENCES customerOrder(customerOrderID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrderStatusLog_previousStatus
        FOREIGN KEY (previousOrderStatusID) REFERENCES orderStatus(orderStatusID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrderStatusLog_currentStatus
        FOREIGN KEY (currentOrderStatusID) REFERENCES orderStatus(orderStatusID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrderStatusLog_changedByUser
        FOREIGN KEY (changedByUserID) REFERENCES userInfo(userID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE customerOrderLine (
    customerOrderLineID BIGINT AUTO_INCREMENT PRIMARY KEY,
    customerOrderID BIGINT NOT NULL,
    productID BIGINT NOT NULL,
    quantity INT NOT NULL,
    unitPrice DECIMAL(18,6) NOT NULL DEFAULT 0,
    taxAmount DECIMAL(18,6) NOT NULL DEFAULT 0,
    discountAmount DECIMAL(18,6) NOT NULL DEFAULT 0,
    lineTotal DECIMAL(18,6) NOT NULL DEFAULT 0,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_customerOrderLine_customerOrderID (customerOrderID),
    KEY idx_customerOrderLine_productID (productID),
    CONSTRAINT fk_customerOrderLine_order
        FOREIGN KEY (customerOrderID) REFERENCES customerOrder(customerOrderID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_customerOrderLine_product
        FOREIGN KEY (productID) REFERENCES product(productID)
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
    CONSTRAINT fk_productPrice_product
        FOREIGN KEY (productID) REFERENCES product(productID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_productPrice_currency
        FOREIGN KEY (currencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE productImage (
    productImageID BIGINT AUTO_INCREMENT PRIMARY KEY,
    productID BIGINT NOT NULL,
    imageURL VARCHAR(255) NOT NULL,
    imageType VARCHAR(30),
    displayOrder INT NOT NULL DEFAULT 1,
    isPrimary BOOLEAN NOT NULL DEFAULT FALSE,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_productImage_productID (productID),
    CONSTRAINT fk_productImage_product
        FOREIGN KEY (productID) REFERENCES product(productID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE inventory (
    inventoryID BIGINT AUTO_INCREMENT PRIMARY KEY,
    productID BIGINT NOT NULL,
    availableQuantity INT NOT NULL DEFAULT 0,
    reservedQuantity INT NOT NULL DEFAULT 0,
    sellableQuantity INT NOT NULL DEFAULT 0,
    reorderLevel INT NOT NULL DEFAULT 0,
    inventorySource VARCHAR(30),
    lastStockUpdateAt TIMESTAMP NULL,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_inventory_productID (productID),
    CONSTRAINT fk_inventory_product
        FOREIGN KEY (productID) REFERENCES product(productID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE paymentTransaction (
    paymentTransactionID BIGINT AUTO_INCREMENT PRIMARY KEY,
    customerOrderID BIGINT NOT NULL,
    transactionCode VARCHAR(50) NOT NULL,
    paymentMethodID BIGINT NOT NULL,
    paymentTransactionStatusID BIGINT NOT NULL,
    transactionAmount DECIMAL(18,6) NOT NULL DEFAULT 0,
    currencyID BIGINT NOT NULL,
    providerName VARCHAR(50),
    providerReference VARCHAR(80),
    transactionDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_paymentTransaction_transactionCode (transactionCode),
    KEY idx_paymentTransaction_customerOrderID (customerOrderID),
    KEY idx_paymentTransaction_paymentMethodID (paymentMethodID),
    KEY idx_paymentTransaction_paymentTransactionStatusID (paymentTransactionStatusID),
    KEY idx_paymentTransaction_currencyID (currencyID),
    CONSTRAINT fk_paymentTransaction_order
        FOREIGN KEY (customerOrderID) REFERENCES customerOrder(customerOrderID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_paymentTransaction_method
        FOREIGN KEY (paymentMethodID) REFERENCES paymentMethod(paymentMethodID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_paymentTransaction_status
        FOREIGN KEY (paymentTransactionStatusID) REFERENCES paymentTransactionStatus(paymentTransactionStatusID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_paymentTransaction_currency
        FOREIGN KEY (currencyID) REFERENCES currency(currencyID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE shipment (
    shipmentID BIGINT AUTO_INCREMENT PRIMARY KEY,
    customerOrderID BIGINT NOT NULL,
    shipmentCode VARCHAR(50) NOT NULL,
    shipmentStatusID BIGINT NOT NULL,
    shippingAddress VARCHAR(250) NOT NULL,
    trackingNumber VARCHAR(80),
    carrierName VARCHAR(60),
    shipmentViewType VARCHAR(30),
    shippedAt TIMESTAMP NULL,
    deliveredAt TIMESTAMP NULL,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_shipment_shipmentCode (shipmentCode),
    KEY idx_shipment_customerOrderID (customerOrderID),
    KEY idx_shipment_shipmentStatusID (shipmentStatusID),
    CONSTRAINT fk_shipment_order
        FOREIGN KEY (customerOrderID) REFERENCES customerOrder(customerOrderID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_shipment_status
        FOREIGN KEY (shipmentStatusID) REFERENCES shipmentStatus(shipmentStatusID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE dynamicSiteAuditLog (
    dynamicSiteAuditLogID BIGINT AUTO_INCREMENT PRIMARY KEY,
    dynamicSiteID BIGINT NOT NULL,
    eventType VARCHAR(50) NOT NULL,
    eventDetails VARCHAR(250),
    performedByUserID BIGINT,
    performedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_dynamicSiteAuditLog_dynamicSiteID (dynamicSiteID),
    KEY idx_dynamicSiteAuditLog_performedByUserID (performedByUserID),
    CONSTRAINT fk_dynamicSiteAuditLog_dynamicSite
        FOREIGN KEY (dynamicSiteID) REFERENCES dynamicSiteInfo(dynamicSiteID)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT fk_dynamicSiteAuditLog_user
        FOREIGN KEY (performedByUserID) REFERENCES userInfo(userID)
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