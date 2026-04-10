USE dynamicBrandsDB;

DELIMITER $$

-- =========================================================
-- CONSISTENCY TRIGGERS
-- =========================================================

DROP TRIGGER IF EXISTS trg_bi_customerOrder_calc_total $$
CREATE TRIGGER trg_bi_customerOrder_calc_total
BEFORE INSERT ON customerOrder
FOR EACH ROW
BEGIN
    SET NEW.totalAmount = ROUND(NEW.subTotal + NEW.taxTotal + NEW.shippingAmount, 6);
END $$

DROP TRIGGER IF EXISTS trg_bu_customerOrder_calc_total $$
CREATE TRIGGER trg_bu_customerOrder_calc_total
BEFORE UPDATE ON customerOrder
FOR EACH ROW
BEGIN
    SET NEW.totalAmount = ROUND(NEW.subTotal + NEW.taxTotal + NEW.shippingAmount, 6);
END $$

DROP TRIGGER IF EXISTS trg_bi_inventory_calc_sellable $$
CREATE TRIGGER trg_bi_inventory_calc_sellable
BEFORE INSERT ON inventory
FOR EACH ROW
BEGIN
    SET NEW.sellableQuantity = NEW.availableQuantity - NEW.reservedQuantity;
    SET NEW.lastStockUpdateAt = CURRENT_TIMESTAMP;
END $$

DROP TRIGGER IF EXISTS trg_bu_inventory_calc_sellable $$
CREATE TRIGGER trg_bu_inventory_calc_sellable
BEFORE UPDATE ON inventory
FOR EACH ROW
BEGIN
    SET NEW.sellableQuantity = NEW.availableQuantity - NEW.reservedQuantity;
    SET NEW.lastStockUpdateAt = CURRENT_TIMESTAMP;
END $$

-- =========================================================
-- DYNAMIC SITE INFO
-- =========================================================

DROP TRIGGER IF EXISTS trg_ai_dynamicSiteInfo $$
CREATE TRIGGER trg_ai_dynamicSiteInfo
AFTER INSERT ON dynamicSiteInfo
FOR EACH ROW
BEGIN
    INSERT INTO dynamicSiteAuditLog (
        dynamicSiteID,
        eventTypeCode,
        eventDetails,
        performedByUserID,
        performedAt,
        createdAt
    )
    VALUES (
        NEW.dynamicSiteID,
        'SITE_CREATED',
        CONCAT('Dynamic site created. siteCode=', NEW.siteCode, ', siteName=', NEW.siteName),
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    INSERT INTO generalLog (
        tableName,
        recordID,
        recordCode,
        actionType,
        fieldName,
        oldValue,
        newValue,
        changeDetails,
        changeSourceCode,
        performedByUserID,
        performedAt,
        createdAt
    )
    VALUES (
        'dynamicSiteInfo',
        NEW.dynamicSiteID,
        NEW.siteCode,
        'INSERT',
        NULL,
        NULL,
        CONCAT(
            'brandCode=', NEW.brandCode,
            '; countryID=', NEW.countryID,
            '; currencyID=', NEW.currencyID,
            '; siteStatusCode=', NEW.siteStatusCode,
            '; primaryDomainName=', NEW.primaryDomainName
        ),
        'New dynamic site created',
        'SYSTEM',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP TRIGGER IF EXISTS trg_au_dynamicSiteInfo $$
CREATE TRIGGER trg_au_dynamicSiteInfo
AFTER UPDATE ON dynamicSiteInfo
FOR EACH ROW
BEGIN
    DECLARE v_has_changes BOOLEAN DEFAULT FALSE;

    IF OLD.siteStatusCode <> NEW.siteStatusCode THEN
        INSERT INTO dynamicSiteStatusLog (
            dynamicSiteID,
            previousSiteStatusCode,
            currentSiteStatusCode,
            changeDetails,
            changeSourceCode,
            changedByUserID,
            changedAt,
            createdAt
        )
        VALUES (
            NEW.dynamicSiteID,
            OLD.siteStatusCode,
            NEW.siteStatusCode,
            CONCAT('Site status changed from ', OLD.siteStatusCode, ' to ', NEW.siteStatusCode),
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );

        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'STATUS_CHANGE',
            'siteStatusCode',
            OLD.siteStatusCode,
            NEW.siteStatusCode,
            'Dynamic site status updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );

        SET v_has_changes = TRUE;
    END IF;

    IF OLD.siteName <> NEW.siteName THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'siteName',
            OLD.siteName,
            NEW.siteName,
            'Dynamic site name updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF OLD.brandCode <> NEW.brandCode THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'brandCode',
            OLD.brandCode,
            NEW.brandCode,
            'Dynamic site brand updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF OLD.countryID <> NEW.countryID THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'countryID',
            CAST(OLD.countryID AS CHAR),
            CAST(NEW.countryID AS CHAR),
            'Dynamic site country updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF OLD.currencyID <> NEW.currencyID THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'currencyID',
            CAST(OLD.currencyID AS CHAR),
            CAST(NEW.currencyID AS CHAR),
            'Dynamic site currency updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF OLD.primaryDomainName <> NEW.primaryDomainName THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'primaryDomainName',
            OLD.primaryDomainName,
            NEW.primaryDomainName,
            'Dynamic site primary domain updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF IFNULL(OLD.marketingFocus, '') <> IFNULL(NEW.marketingFocus, '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'marketingFocus',
            OLD.marketingFocus,
            NEW.marketingFocus,
            'Dynamic site marketing focus updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF IFNULL(OLD.brandVoice, '') <> IFNULL(NEW.brandVoice, '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'brandVoice',
            OLD.brandVoice,
            NEW.brandVoice,
            'Dynamic site brand voice updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF IFNULL(OLD.targetSegment, '') <> IFNULL(NEW.targetSegment, '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'targetSegment',
            OLD.targetSegment,
            NEW.targetSegment,
            'Dynamic site target segment updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF IFNULL(CAST(OLD.launchDate AS CHAR), '') <> IFNULL(CAST(NEW.launchDate AS CHAR), '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'launchDate',
            CAST(OLD.launchDate AS CHAR),
            CAST(NEW.launchDate AS CHAR),
            'Dynamic site launch date updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF IFNULL(CAST(OLD.closeDate AS CHAR), '') <> IFNULL(CAST(NEW.closeDate AS CHAR), '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'closeDate',
            CAST(OLD.closeDate AS CHAR),
            CAST(NEW.closeDate AS CHAR),
            'Dynamic site close date updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF IFNULL(OLD.clientName, '') <> IFNULL(NEW.clientName, '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'clientName',
            OLD.clientName,
            NEW.clientName,
            'Dynamic site client name updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF IFNULL(OLD.logoURL, '') <> IFNULL(NEW.logoURL, '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'logoURL',
            OLD.logoURL,
            NEW.logoURL,
            'Dynamic site logo updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF OLD.isActive <> NEW.isActive THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteInfo',
            NEW.dynamicSiteID,
            NEW.siteCode,
            'UPDATE',
            'isActive',
            CAST(OLD.isActive AS CHAR),
            CAST(NEW.isActive AS CHAR),
            'Dynamic site active flag updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
        SET v_has_changes = TRUE;
    END IF;

    IF v_has_changes THEN
        INSERT INTO dynamicSiteAuditLog (
            dynamicSiteID,
            eventTypeCode,
            eventDetails,
            performedByUserID,
            performedAt,
            createdAt
        )
        VALUES (
            NEW.dynamicSiteID,
            'SITE_UPDATED',
            CONCAT('Dynamic site updated. siteCode=', NEW.siteCode),
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

-- =========================================================
-- DYNAMIC SITE AI GENERATION
-- =========================================================

DROP TRIGGER IF EXISTS trg_ai_dynamicSiteAIGeneration $$
CREATE TRIGGER trg_ai_dynamicSiteAIGeneration
AFTER INSERT ON dynamicSiteAIGeneration
FOR EACH ROW
BEGIN
    INSERT INTO generalLog (
        tableName, recordID, recordCode, actionType, fieldName,
        oldValue, newValue, changeDetails, changeSourceCode,
        performedByUserID, performedAt, createdAt
    )
    VALUES (
        'dynamicSiteAIGeneration',
        NEW.dynamicSiteAIGenerationID,
        NULL,
        'INSERT',
        'generationStatusCode',
        NULL,
        NEW.generationStatusCode,
        CONCAT('AI generation created for dynamicSiteID=', NEW.dynamicSiteID),
        'SYSTEM',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP TRIGGER IF EXISTS trg_au_dynamicSiteAIGeneration $$
CREATE TRIGGER trg_au_dynamicSiteAIGeneration
AFTER UPDATE ON dynamicSiteAIGeneration
FOR EACH ROW
BEGIN
    IF OLD.generationStatusCode <> NEW.generationStatusCode THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteAIGeneration',
            NEW.dynamicSiteAIGenerationID,
            NULL,
            'STATUS_CHANGE',
            'generationStatusCode',
            OLD.generationStatusCode,
            NEW.generationStatusCode,
            'AI generation status updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF IFNULL(OLD.generationDetails, '') <> IFNULL(NEW.generationDetails, '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'dynamicSiteAIGeneration',
            NEW.dynamicSiteAIGenerationID,
            NULL,
            'UPDATE',
            'generationDetails',
            OLD.generationDetails,
            NEW.generationDetails,
            'AI generation details updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

-- =========================================================
-- CUSTOMER ORDER
-- =========================================================

DROP TRIGGER IF EXISTS trg_ai_customerOrder $$
CREATE TRIGGER trg_ai_customerOrder
AFTER INSERT ON customerOrder
FOR EACH ROW
BEGIN
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
        NEW.customerOrderID,
        NULL,
        NEW.orderStatusCode,
        CONCAT('Initial order status set to ', NEW.orderStatusCode),
        'SYSTEM',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    INSERT INTO generalLog (
        tableName, recordID, recordCode, actionType, fieldName,
        oldValue, newValue, changeDetails, changeSourceCode,
        performedByUserID, performedAt, createdAt
    )
    VALUES (
        'customerOrder',
        NEW.customerOrderID,
        NEW.orderCode,
        'INSERT',
        NULL,
        NULL,
        NEW.orderStatusCode,
        CONCAT('Customer order created. totalAmount=', NEW.totalAmount),
        'SYSTEM',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP TRIGGER IF EXISTS trg_au_customerOrder $$
CREATE TRIGGER trg_au_customerOrder
AFTER UPDATE ON customerOrder
FOR EACH ROW
BEGIN
    IF OLD.orderStatusCode <> NEW.orderStatusCode THEN
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
            NEW.customerOrderID,
            OLD.orderStatusCode,
            NEW.orderStatusCode,
            CONCAT('Order status changed from ', OLD.orderStatusCode, ' to ', NEW.orderStatusCode),
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );

        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'customerOrder',
            NEW.customerOrderID,
            NEW.orderCode,
            'STATUS_CHANGE',
            'orderStatusCode',
            OLD.orderStatusCode,
            NEW.orderStatusCode,
            'Customer order status updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.subTotal <> NEW.subTotal THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'customerOrder',
            NEW.customerOrderID,
            NEW.orderCode,
            'UPDATE',
            'subTotal',
            CAST(OLD.subTotal AS CHAR),
            CAST(NEW.subTotal AS CHAR),
            'Customer order subtotal updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.taxTotal <> NEW.taxTotal THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'customerOrder',
            NEW.customerOrderID,
            NEW.orderCode,
            'UPDATE',
            'taxTotal',
            CAST(OLD.taxTotal AS CHAR),
            CAST(NEW.taxTotal AS CHAR),
            'Customer order tax total updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.shippingAmount <> NEW.shippingAmount THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'customerOrder',
            NEW.customerOrderID,
            NEW.orderCode,
            'UPDATE',
            'shippingAmount',
            CAST(OLD.shippingAmount AS CHAR),
            CAST(NEW.shippingAmount AS CHAR),
            'Customer order shipping amount updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.totalAmount <> NEW.totalAmount THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'customerOrder',
            NEW.customerOrderID,
            NEW.orderCode,
            'UPDATE',
            'totalAmount',
            CAST(OLD.totalAmount AS CHAR),
            CAST(NEW.totalAmount AS CHAR),
            'Customer order total amount updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.currencyID <> NEW.currencyID THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'customerOrder',
            NEW.customerOrderID,
            NEW.orderCode,
            'UPDATE',
            'currencyID',
            CAST(OLD.currencyID AS CHAR),
            CAST(NEW.currencyID AS CHAR),
            'Customer order currency updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.exchangeRate <> NEW.exchangeRate THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'customerOrder',
            NEW.customerOrderID,
            NEW.orderCode,
            'UPDATE',
            'exchangeRate',
            CAST(OLD.exchangeRate AS CHAR),
            CAST(NEW.exchangeRate AS CHAR),
            'Customer order exchange rate updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

-- =========================================================
-- PRODUCT
-- =========================================================

DROP TRIGGER IF EXISTS trg_ai_product $$
CREATE TRIGGER trg_ai_product
AFTER INSERT ON product
FOR EACH ROW
BEGIN
    INSERT INTO generalLog (
        tableName, recordID, recordCode, actionType, fieldName,
        oldValue, newValue, changeDetails, changeSourceCode,
        performedByUserID, performedAt, createdAt
    )
    VALUES (
        'product',
        NEW.productID,
        NEW.productCode,
        'INSERT',
        NULL,
        NULL,
        NEW.categoryCode,
        CONCAT('Product created. sku=', NEW.sku),
        'SYSTEM',
        NEW.updatedByUserID,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP TRIGGER IF EXISTS trg_au_product $$
CREATE TRIGGER trg_au_product
AFTER UPDATE ON product
FOR EACH ROW
BEGIN
    IF OLD.categoryCode <> NEW.categoryCode THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'product',
            NEW.productID,
            NEW.productCode,
            'UPDATE',
            'categoryCode',
            OLD.categoryCode,
            NEW.categoryCode,
            'Product category updated',
            'SYSTEM',
            NEW.updatedByUserID,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.basePrice <> NEW.basePrice THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'product',
            NEW.productID,
            NEW.productCode,
            'UPDATE',
            'basePrice',
            CAST(OLD.basePrice AS CHAR),
            CAST(NEW.basePrice AS CHAR),
            'Product base price updated',
            'SYSTEM',
            NEW.updatedByUserID,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.isActive <> NEW.isActive THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'product',
            NEW.productID,
            NEW.productCode,
            'UPDATE',
            'isActive',
            CAST(OLD.isActive AS CHAR),
            CAST(NEW.isActive AS CHAR),
            'Product active flag updated',
            'SYSTEM',
            NEW.updatedByUserID,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

-- =========================================================
-- PRODUCT PRICE
-- =========================================================

DROP TRIGGER IF EXISTS trg_ai_productPrice $$
CREATE TRIGGER trg_ai_productPrice
AFTER INSERT ON productPrice
FOR EACH ROW
BEGIN
    INSERT INTO generalLog (
        tableName, recordID, recordCode, actionType, fieldName,
        oldValue, newValue, changeDetails, changeSourceCode,
        performedByUserID, performedAt, createdAt
    )
    VALUES (
        'productPrice',
        NEW.productPriceID,
        NULL,
        'INSERT',
        'priceAmount',
        NULL,
        CAST(NEW.priceAmount AS CHAR),
        CONCAT('Product price created for productID=', NEW.productID, ', currencyID=', NEW.currencyID),
        'SYSTEM',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP TRIGGER IF EXISTS trg_au_productPrice $$
CREATE TRIGGER trg_au_productPrice
AFTER UPDATE ON productPrice
FOR EACH ROW
BEGIN
    IF OLD.priceAmount <> NEW.priceAmount THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'productPrice',
            NEW.productPriceID,
            NULL,
            'UPDATE',
            'priceAmount',
            CAST(OLD.priceAmount AS CHAR),
            CAST(NEW.priceAmount AS CHAR),
            'Product price amount updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.isCurrent <> NEW.isCurrent THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'productPrice',
            NEW.productPriceID,
            NULL,
            'UPDATE',
            'isCurrent',
            CAST(OLD.isCurrent AS CHAR),
            CAST(NEW.isCurrent AS CHAR),
            'Product price current flag updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

-- =========================================================
-- INVENTORY
-- =========================================================

DROP TRIGGER IF EXISTS trg_ai_inventory $$
CREATE TRIGGER trg_ai_inventory
AFTER INSERT ON inventory
FOR EACH ROW
BEGIN
    INSERT INTO generalLog (
        tableName, recordID, recordCode, actionType, fieldName,
        oldValue, newValue, changeDetails, changeSourceCode,
        performedByUserID, performedAt, createdAt
    )
    VALUES (
        'inventory',
        NEW.inventoryID,
        NULL,
        'INSERT',
        NULL,
        NULL,
        CONCAT(
            'available=', NEW.availableQuantity,
            '; reserved=', NEW.reservedQuantity,
            '; sellable=', NEW.sellableQuantity
        ),
        CONCAT('Inventory created for dynamicSiteID=', NEW.dynamicSiteID, ', productID=', NEW.productID),
        'SYSTEM',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP TRIGGER IF EXISTS trg_au_inventory $$
CREATE TRIGGER trg_au_inventory
AFTER UPDATE ON inventory
FOR EACH ROW
BEGIN
    IF OLD.availableQuantity <> NEW.availableQuantity THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'inventory',
            NEW.inventoryID,
            NULL,
            'UPDATE',
            'availableQuantity',
            CAST(OLD.availableQuantity AS CHAR),
            CAST(NEW.availableQuantity AS CHAR),
            'Inventory available quantity updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.reservedQuantity <> NEW.reservedQuantity THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'inventory',
            NEW.inventoryID,
            NULL,
            'UPDATE',
            'reservedQuantity',
            CAST(OLD.reservedQuantity AS CHAR),
            CAST(NEW.reservedQuantity AS CHAR),
            'Inventory reserved quantity updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.sellableQuantity <> NEW.sellableQuantity THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'inventory',
            NEW.inventoryID,
            NULL,
            'UPDATE',
            'sellableQuantity',
            CAST(OLD.sellableQuantity AS CHAR),
            CAST(NEW.sellableQuantity AS CHAR),
            'Inventory sellable quantity updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.reorderLevel <> NEW.reorderLevel THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'inventory',
            NEW.inventoryID,
            NULL,
            'UPDATE',
            'reorderLevel',
            CAST(OLD.reorderLevel AS CHAR),
            CAST(NEW.reorderLevel AS CHAR),
            'Inventory reorder level updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

-- =========================================================
-- PAYMENT TRANSACTION
-- =========================================================

DROP TRIGGER IF EXISTS trg_ai_paymentTransaction $$
CREATE TRIGGER trg_ai_paymentTransaction
AFTER INSERT ON paymentTransaction
FOR EACH ROW
BEGIN
    INSERT INTO generalLog (
        tableName, recordID, recordCode, actionType, fieldName,
        oldValue, newValue, changeDetails, changeSourceCode,
        performedByUserID, performedAt, createdAt
    )
    VALUES (
        'paymentTransaction',
        NEW.paymentTransactionID,
        NEW.transactionCode,
        'INSERT',
        'paymentStatusCode',
        NULL,
        NEW.paymentStatusCode,
        CONCAT('Payment transaction created. providerCode=', NEW.providerCode),
        'SYSTEM',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP TRIGGER IF EXISTS trg_au_paymentTransaction $$
CREATE TRIGGER trg_au_paymentTransaction
AFTER UPDATE ON paymentTransaction
FOR EACH ROW
BEGIN
    IF OLD.paymentStatusCode <> NEW.paymentStatusCode THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'paymentTransaction',
            NEW.paymentTransactionID,
            NEW.transactionCode,
            'STATUS_CHANGE',
            'paymentStatusCode',
            OLD.paymentStatusCode,
            NEW.paymentStatusCode,
            'Payment status updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.transactionAmount <> NEW.transactionAmount THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'paymentTransaction',
            NEW.paymentTransactionID,
            NEW.transactionCode,
            'UPDATE',
            'transactionAmount',
            CAST(OLD.transactionAmount AS CHAR),
            CAST(NEW.transactionAmount AS CHAR),
            'Payment amount updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF OLD.providerCode <> NEW.providerCode THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'paymentTransaction',
            NEW.paymentTransactionID,
            NEW.transactionCode,
            'UPDATE',
            'providerCode',
            OLD.providerCode,
            NEW.providerCode,
            'Payment provider updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF IFNULL(OLD.providerReference, '') <> IFNULL(NEW.providerReference, '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'paymentTransaction',
            NEW.paymentTransactionID,
            NEW.transactionCode,
            'UPDATE',
            'providerReference',
            OLD.providerReference,
            NEW.providerReference,
            'Payment provider reference updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

-- =========================================================
-- SHIPMENT
-- =========================================================

DROP TRIGGER IF EXISTS trg_ai_shipment $$
CREATE TRIGGER trg_ai_shipment
AFTER INSERT ON shipment
FOR EACH ROW
BEGIN
    INSERT INTO generalLog (
        tableName, recordID, recordCode, actionType, fieldName,
        oldValue, newValue, changeDetails, changeSourceCode,
        performedByUserID, performedAt, createdAt
    )
    VALUES (
        'shipment',
        NEW.shipmentID,
        NEW.shipmentCode,
        'INSERT',
        'shipmentStatusCode',
        NULL,
        NEW.shipmentStatusCode,
        CONCAT('Shipment created for customerOrderID=', NEW.customerOrderID),
        'SYSTEM',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP TRIGGER IF EXISTS trg_au_shipment $$
CREATE TRIGGER trg_au_shipment
AFTER UPDATE ON shipment
FOR EACH ROW
BEGIN
    IF OLD.shipmentStatusCode <> NEW.shipmentStatusCode THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'shipment',
            NEW.shipmentID,
            NEW.shipmentCode,
            'STATUS_CHANGE',
            'shipmentStatusCode',
            OLD.shipmentStatusCode,
            NEW.shipmentStatusCode,
            'Shipment status updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF IFNULL(OLD.trackingNumber, '') <> IFNULL(NEW.trackingNumber, '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'shipment',
            NEW.shipmentID,
            NEW.shipmentCode,
            'UPDATE',
            'trackingNumber',
            OLD.trackingNumber,
            NEW.trackingNumber,
            'Shipment tracking number updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF IFNULL(OLD.carrierName, '') <> IFNULL(NEW.carrierName, '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'shipment',
            NEW.shipmentID,
            NEW.shipmentCode,
            'UPDATE',
            'carrierName',
            OLD.carrierName,
            NEW.carrierName,
            'Shipment carrier updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF IFNULL(CAST(OLD.shippedAt AS CHAR), '') <> IFNULL(CAST(NEW.shippedAt AS CHAR), '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'shipment',
            NEW.shipmentID,
            NEW.shipmentCode,
            'UPDATE',
            'shippedAt',
            CAST(OLD.shippedAt AS CHAR),
            CAST(NEW.shippedAt AS CHAR),
            'Shipment shippedAt updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF IFNULL(CAST(OLD.deliveredAt AS CHAR), '') <> IFNULL(CAST(NEW.deliveredAt AS CHAR), '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'shipment',
            NEW.shipmentID,
            NEW.shipmentCode,
            'UPDATE',
            'deliveredAt',
            CAST(OLD.deliveredAt AS CHAR),
            CAST(NEW.deliveredAt AS CHAR),
            'Shipment deliveredAt updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

-- =========================================================
-- COUNTRY PRODUCT PERMISSION
-- =========================================================

DROP TRIGGER IF EXISTS trg_ai_countryProductPermission $$
CREATE TRIGGER trg_ai_countryProductPermission
AFTER INSERT ON countryProductPermission
FOR EACH ROW
BEGIN
    INSERT INTO generalLog (
        tableName, recordID, recordCode, actionType, fieldName,
        oldValue, newValue, changeDetails, changeSourceCode,
        performedByUserID, performedAt, createdAt
    )
    VALUES (
        'countryProductPermission',
        NEW.countryProductPermissionID,
        NEW.permissionCode,
        'INSERT',
        'permissionStatusCode',
        NULL,
        NEW.permissionStatusCode,
        CONCAT('Permission created for productID=', NEW.productID, ', countryID=', NEW.countryID),
        'SYSTEM',
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$

DROP TRIGGER IF EXISTS trg_au_countryProductPermission $$
CREATE TRIGGER trg_au_countryProductPermission
AFTER UPDATE ON countryProductPermission
FOR EACH ROW
BEGIN
    IF OLD.permissionStatusCode <> NEW.permissionStatusCode THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'countryProductPermission',
            NEW.countryProductPermissionID,
            NEW.permissionCode,
            'STATUS_CHANGE',
            'permissionStatusCode',
            OLD.permissionStatusCode,
            NEW.permissionStatusCode,
            'Permission status updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF IFNULL(OLD.certificateNumber, '') <> IFNULL(NEW.certificateNumber, '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'countryProductPermission',
            NEW.countryProductPermissionID,
            NEW.permissionCode,
            'UPDATE',
            'certificateNumber',
            OLD.certificateNumber,
            NEW.certificateNumber,
            'Permission certificate number updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF IFNULL(CAST(OLD.issuedAt AS CHAR), '') <> IFNULL(CAST(NEW.issuedAt AS CHAR), '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'countryProductPermission',
            NEW.countryProductPermissionID,
            NEW.permissionCode,
            'UPDATE',
            'issuedAt',
            CAST(OLD.issuedAt AS CHAR),
            CAST(NEW.issuedAt AS CHAR),
            'Permission issuedAt updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;

    IF IFNULL(CAST(OLD.expiresAt AS CHAR), '') <> IFNULL(CAST(NEW.expiresAt AS CHAR), '') THEN
        INSERT INTO generalLog (
            tableName, recordID, recordCode, actionType, fieldName,
            oldValue, newValue, changeDetails, changeSourceCode,
            performedByUserID, performedAt, createdAt
        )
        VALUES (
            'countryProductPermission',
            NEW.countryProductPermissionID,
            NEW.permissionCode,
            'UPDATE',
            'expiresAt',
            CAST(OLD.expiresAt AS CHAR),
            CAST(NEW.expiresAt AS CHAR),
            'Permission expiration updated',
            'SYSTEM',
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
END $$

DELIMITER ;