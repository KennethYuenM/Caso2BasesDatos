USE dynamicBrandsDB;
DELIMITER $$
DROP TRIGGER IF EXISTS trgBeforeInsertCustomerOrder $$
CREATE TRIGGER trgBeforeInsertCustomerOrder
BEFORE INSERT ON customerOrder
FOR EACH ROW
BEGIN
    IF NEW.subTotal < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'subTotal cannot be negative';
    END IF;
    IF NEW.taxTotal < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'taxTotal cannot be negative';
    END IF;
    IF NEW.shippingAmount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'shippingAmount cannot be negative';
    END IF;
    IF NEW.exchangeRate <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'exchangeRate must be greater than zero';
    END IF;
    SET NEW.totalAmount = ROUND(NEW.subTotal + NEW.taxTotal + NEW.shippingAmount, 6);
END $$
DROP TRIGGER IF EXISTS trgBeforeUpdateCustomerOrder $$
CREATE TRIGGER trgBeforeUpdateCustomerOrder
BEFORE UPDATE ON customerOrder
FOR EACH ROW
BEGIN
    IF NEW.subTotal < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'subTotal cannot be negative';
    END IF;
    IF NEW.taxTotal < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'taxTotal cannot be negative';
    END IF;
    IF NEW.shippingAmount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'shippingAmount cannot be negative';
    END IF;
    IF NEW.exchangeRate <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'exchangeRate must be greater than zero';
    END IF;
    SET NEW.totalAmount = ROUND(NEW.subTotal + NEW.taxTotal + NEW.shippingAmount, 6);
END $$
DROP TRIGGER IF EXISTS trgBeforeInsertCustomerOrderDetail $$
CREATE TRIGGER trgBeforeInsertCustomerOrderDetail
BEFORE INSERT ON customerOrderDetail
FOR EACH ROW
BEGIN
    IF NEW.quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'quantity must be greater than zero';
    END IF;
    IF NEW.unitPrice < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'unitPrice cannot be negative';
    END IF;
    IF NEW.taxAmount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'taxAmount cannot be negative';
    END IF;
    IF NEW.discountAmount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'discountAmount cannot be negative';
    END IF;
    SET NEW.lineTotal = ROUND((NEW.quantity * NEW.unitPrice) + NEW.taxAmount - NEW.discountAmount, 6);
    IF NEW.lineTotal < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'lineTotal cannot be negative';
    END IF;
END $$
DROP TRIGGER IF EXISTS trgAfterInsertCustomerOrderDetail $$
CREATE TRIGGER trgAfterInsertCustomerOrderDetail
AFTER INSERT ON customerOrderDetail
FOR EACH ROW
BEGIN
    UPDATE customerOrder
    SET subTotal = (
            SELECT IFNULL(SUM(quantity * unitPrice), 0)
            FROM customerOrderDetail
            WHERE customerOrderID = NEW.customerOrderID
        ),
        taxTotal = (
            SELECT IFNULL(SUM(taxAmount), 0)
            FROM customerOrderDetail
            WHERE customerOrderID = NEW.customerOrderID
        ),
        updatedAt = CURRENT_TIMESTAMP
    WHERE customerOrderID = NEW.customerOrderID;
END $$
DROP TRIGGER IF EXISTS trgAfterDeleteCustomerOrderDetail $$
CREATE TRIGGER trgAfterDeleteCustomerOrderDetail
AFTER DELETE ON customerOrderDetail
FOR EACH ROW
BEGIN
    UPDATE customerOrder
    SET subTotal = (
            SELECT IFNULL(SUM(quantity * unitPrice), 0)
            FROM customerOrderDetail
            WHERE customerOrderID = OLD.customerOrderID
        ),
        taxTotal = (
            SELECT IFNULL(SUM(taxAmount), 0)
            FROM customerOrderDetail
            WHERE customerOrderID = OLD.customerOrderID
        ),
        updatedAt = CURRENT_TIMESTAMP
    WHERE customerOrderID = OLD.customerOrderID;
END $$
DROP TRIGGER IF EXISTS trgBeforeInsertInventory $$
CREATE TRIGGER trgBeforeInsertInventory
BEFORE INSERT ON inventory
FOR EACH ROW
BEGIN
    IF NEW.availableQuantity < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'availableQuantity cannot be negative';
    END IF;
    IF NEW.reservedQuantity < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'reservedQuantity cannot be negative';
    END IF;
    IF NEW.reorderLevel < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'reorderLevel cannot be negative';
    END IF;
    SET NEW.sellableQuantity = NEW.availableQuantity - NEW.reservedQuantity;
    IF NEW.sellableQuantity < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'reservedQuantity cannot be greater than availableQuantity';
    END IF;
    SET NEW.lastStockUpdateAt = CURRENT_TIMESTAMP;
END $$
DROP TRIGGER IF EXISTS trgBeforeUpdateInventory $$
CREATE TRIGGER trgBeforeUpdateInventory
BEFORE UPDATE ON inventory
FOR EACH ROW
BEGIN
    IF NEW.availableQuantity < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'availableQuantity cannot be negative';
    END IF;
    IF NEW.reservedQuantity < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'reservedQuantity cannot be negative';
    END IF;
    IF NEW.reorderLevel < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'reorderLevel cannot be negative';
    END IF;
    SET NEW.sellableQuantity = NEW.availableQuantity - NEW.reservedQuantity;
    IF NEW.sellableQuantity < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'reservedQuantity cannot be greater than availableQuantity';
    END IF;
    SET NEW.lastStockUpdateAt = CURRENT_TIMESTAMP;
END $$
DROP TRIGGER IF EXISTS trgBeforeInsertPaymentTransaction $$
CREATE TRIGGER trgBeforeInsertPaymentTransaction
BEFORE INSERT ON paymentTransaction
FOR EACH ROW
BEGIN
    IF NEW.transactionAmount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'transactionAmount cannot be negative';
    END IF;
    IF NEW.exchangeRate <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'exchangeRate must be greater than zero';
    END IF;
    SET NEW.checksum = SHA2(CONCAT(
        NEW.transactionCode,
        '|',
        NEW.customerOrderID,
        '|',
        NEW.methodCode,
        '|',
        NEW.paymentStatusCode,
        '|',
        NEW.transactionAmount,
        '|',
        NEW.currencyID,
        '|',
        NEW.exchangeRate
    ), 256);
END $$
DROP TRIGGER IF EXISTS trgAfterInsertDynamicSiteInfo $$
CREATE TRIGGER trgAfterInsertDynamicSiteInfo
AFTER INSERT ON dynamicSiteInfo
FOR EACH ROW
BEGIN
    INSERT INTO dynamicSiteAuditLog (
        dynamicSiteID,
        eventTypeCode,
        eventDetails,
        performedByPersonID,
        performedAt,
        createdAt
    )
    VALUES (
        NEW.dynamicSiteID,
        'SITE_CREATED',
        CONCAT('Dynamic site created with siteCode ', NEW.siteCode),
        NULL,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
END $$
DROP TRIGGER IF EXISTS trgAfterUpdateDynamicSiteInfo $$
CREATE TRIGGER trgAfterUpdateDynamicSiteInfo
AFTER UPDATE ON dynamicSiteInfo
FOR EACH ROW
BEGIN
    IF OLD.siteStatusCode <> NEW.siteStatusCode THEN
        INSERT INTO dynamicSiteStatusLog (
            dynamicSiteID,
            previousSiteStatusCode,
            currentSiteStatusCode,
            changeDetails,
            changeSourceCode,
            changedByPersonID,
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
        INSERT INTO dynamicSiteAuditLog (
            dynamicSiteID,
            eventTypeCode,
            eventDetails,
            performedByPersonID,
            performedAt,
            createdAt
        )
        VALUES (
            NEW.dynamicSiteID,
            'SITE_STATUS_CHANGED',
            CONCAT('Site status changed from ', OLD.siteStatusCode, ' to ', NEW.siteStatusCode),
            NULL,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );
    END IF;
END $$
DROP TRIGGER IF EXISTS trgBeforeInsertProduct $$
CREATE TRIGGER trgBeforeInsertProduct
BEFORE INSERT ON product
FOR EACH ROW
BEGIN
    IF NEW.basePrice < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'basePrice cannot be negative';
    END IF;
END $$
DROP TRIGGER IF EXISTS trgBeforeInsertProductPrice $$
CREATE TRIGGER trgBeforeInsertProductPrice
BEFORE INSERT ON productPrice
FOR EACH ROW
BEGIN
    IF NEW.priceAmount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'priceAmount cannot be negative';
    END IF;
    IF NEW.validTo IS NOT NULL AND NEW.validTo < NEW.validFrom THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'validTo cannot be earlier than validFrom';
    END IF;
END $$
DROP TRIGGER IF EXISTS trgBeforeInsertCurrentExchangeRate $$
CREATE TRIGGER trgBeforeInsertCurrentExchangeRate
BEFORE INSERT ON currentExchangeRate
FOR EACH ROW
BEGIN
    IF NEW.baseCurrencyID = NEW.quoteCurrencyID THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'baseCurrencyID and quoteCurrencyID cannot be equal';
    END IF;
    IF NEW.buyRate <= 0 OR NEW.sellRate <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'exchange rates must be greater than zero';
    END IF;
END $$
DROP TRIGGER IF EXISTS trgBeforeInsertDynamicSiteMetric $$
CREATE TRIGGER trgBeforeInsertDynamicSiteMetric
BEFORE INSERT ON dynamicSiteMetric
FOR EACH ROW
BEGIN
    IF NEW.metricValue < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'metricValue cannot be negative';
    END IF;
    IF NEW.metricTypeCode IN ('CONVERSION_RATE', 'BOUNCE_RATE') AND NEW.metricValue > 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'rate metrics must be between 0 and 1';
    END IF;
END $$
DROP TRIGGER IF EXISTS trgBeforeInsertShipment $$
CREATE TRIGGER trgBeforeInsertShipment
BEFORE INSERT ON shipment
FOR EACH ROW
BEGIN
    IF NEW.deliveredAt IS NOT NULL AND NEW.shippedAt IS NOT NULL AND NEW.deliveredAt < NEW.shippedAt THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'deliveredAt cannot be earlier than shippedAt';
    END IF;
END $$
DROP TRIGGER IF EXISTS trgBeforeInsertCountryProductPermission $$
CREATE TRIGGER trgBeforeInsertCountryProductPermission
BEFORE INSERT ON countryProductPermission
FOR EACH ROW
BEGIN
    IF NEW.permissionCost < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'permissionCost cannot be negative';
    END IF;
    IF NEW.exportCost < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'exportCost cannot be negative';
    END IF;
    IF NEW.expiresAt IS NOT NULL AND NEW.issuedAt IS NOT NULL AND NEW.expiresAt < NEW.issuedAt THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'expiresAt cannot be earlier than issuedAt';
    END IF;
END $$
DELIMITER ;
