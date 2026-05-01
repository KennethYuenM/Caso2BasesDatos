USE dynamicBrandsDB;

-- =========================================================
-- CHECKERS DE MONEDAS Y PAISES
-- =========================================================
SELECT 'duplicateCurrencyCode' AS checkerName, COUNT(*) AS issueCount
FROM (
    SELECT currencyCode
    FROM currency
    GROUP BY currencyCode
    HAVING COUNT(*) > 1
) duplicatedCurrencies;

SELECT 'countryWithoutLocalCurrency' AS checkerName, COUNT(*) AS issueCount
FROM country c
LEFT JOIN currency cur ON c.localCurrencyID = cur.currencyID
WHERE cur.currencyID IS NULL;

SELECT 'invalidCountryIsoCodes' AS checkerName, COUNT(*) AS issueCount
FROM country
WHERE CHAR_LENGTH(iso2Code) <> 2
   OR CHAR_LENGTH(iso3Code) <> 3;

-- =========================================================
-- CHECKERS DE TIPOS DE CAMBIO
-- =========================================================
SELECT 'exchangeRateSameCurrency' AS checkerName, COUNT(*) AS issueCount
FROM currentExchangeRate
WHERE baseCurrencyID = quoteCurrencyID;

SELECT 'exchangeRateInvalidRates' AS checkerName, COUNT(*) AS issueCount
FROM currentExchangeRate
WHERE buyRate <= 0
   OR sellRate <= 0;

-- =========================================================
-- CHECKERS DE PERSONAS Y USUARIOS
-- =========================================================
SELECT 'peopleWithoutEmail' AS checkerName, COUNT(*) AS issueCount
FROM people
WHERE email IS NULL OR TRIM(email) = '';

SELECT 'duplicatePeopleEmail' AS checkerName, COUNT(*) AS issueCount
FROM (
    SELECT email
    FROM people
    GROUP BY email
    HAVING COUNT(*) > 1
) duplicatedEmails;

SELECT 'peopleWithoutPersonType' AS checkerName, COUNT(*) AS issueCount
FROM people p
LEFT JOIN peoplePersonType ppt ON p.personID = ppt.personID
WHERE ppt.peoplePersonTypeID IS NULL;

SELECT 'systemUserWithoutPerson' AS checkerName, COUNT(*) AS issueCount
FROM systemUser su
LEFT JOIN people p ON su.personID = p.personID
WHERE p.personID IS NULL;

-- =========================================================
-- CHECKERS DE SITIOS DINAMICOS
-- =========================================================
SELECT 'dynamicSiteWithoutBrand' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo dsi
LEFT JOIN brandTemplate bt ON dsi.brandCode = bt.brandCode
WHERE bt.brandCode IS NULL;

SELECT 'dynamicSiteWithoutCountry' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo dsi
LEFT JOIN country c ON dsi.countryID = c.countryID
WHERE c.countryID IS NULL;

SELECT 'dynamicSiteWithoutPrimaryDomain' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo
WHERE primaryDomainName IS NULL
   OR TRIM(primaryDomainName) = '';

-- =========================================================
-- CHECKERS DE PRODUCTOS
-- =========================================================
SELECT 'productWithoutSite' AS checkerName, COUNT(*) AS issueCount
FROM product p
LEFT JOIN dynamicSiteInfo dsi ON p.dynamicSiteID = dsi.dynamicSiteID
WHERE dsi.dynamicSiteID IS NULL;

SELECT 'productWithoutCategory' AS checkerName, COUNT(*) AS issueCount
FROM product p
LEFT JOIN productCategory pc ON p.productCategoryCode = pc.categoryCode
WHERE pc.categoryCode IS NULL;

SELECT 'duplicateProductCode' AS checkerName, COUNT(*) AS issueCount
FROM (
    SELECT productCode
    FROM product
    GROUP BY productCode
    HAVING COUNT(*) > 1
) duplicatedProducts;

SELECT 'duplicateProductSku' AS checkerName, COUNT(*) AS issueCount
FROM (
    SELECT sku
    FROM product
    GROUP BY sku
    HAVING COUNT(*) > 1
) duplicatedSkus;

SELECT 'productsWithoutCurrentPrice' AS checkerName, COUNT(*) AS issueCount
FROM product p
LEFT JOIN productPrice pp ON p.productID = pp.productID AND pp.isCurrent = TRUE
WHERE pp.productPriceID IS NULL;

SELECT 'productPriceInvalidAmount' AS checkerName, COUNT(*) AS issueCount
FROM productPrice
WHERE priceAmount < 0;

-- =========================================================
-- CHECKERS DE ORDENES
-- =========================================================
SELECT 'ordersWithoutPerson' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN people p ON co.personID = p.personID
WHERE p.personID IS NULL;

SELECT 'ordersWithoutSite' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN dynamicSiteInfo dsi ON co.dynamicSiteID = dsi.dynamicSiteID
WHERE dsi.dynamicSiteID IS NULL;

SELECT 'ordersWithoutDetails' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN customerOrderDetail cod ON co.customerOrderID = cod.customerOrderID
WHERE cod.customerOrderDetailID IS NULL;

SELECT 'orderDetailsInvalidQuantity' AS checkerName, COUNT(*) AS issueCount
FROM customerOrderDetail
WHERE quantity <= 0;

SELECT 'orderDetailLineTotalMismatch' AS checkerName, COUNT(*) AS issueCount
FROM customerOrderDetail
WHERE ROUND(lineTotal, 6) <> ROUND((quantity * unitPrice) + taxAmount - discountAmount, 6);

SELECT 'ordersWithNegativeAmounts' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder
WHERE subTotal < 0
   OR taxTotal < 0
   OR shippingAmount < 0
   OR totalAmount < 0;

-- =========================================================
-- CHECKERS DE INVENTARIO
-- =========================================================
SELECT 'negativeInventory' AS checkerName, COUNT(*) AS issueCount
FROM inventory
WHERE availableQuantity < 0
   OR reservedQuantity < 0
   OR sellableQuantity < 0
   OR reorderLevel < 0;

SELECT 'inventoryCalculationMismatch' AS checkerName, COUNT(*) AS issueCount
FROM inventory
WHERE sellableQuantity <> availableQuantity - reservedQuantity;

SELECT 'productsWithoutInventory' AS checkerName, COUNT(*) AS issueCount
FROM product p
LEFT JOIN inventory i ON p.productID = i.productID AND p.dynamicSiteID = i.dynamicSiteID
WHERE i.inventoryID IS NULL;

-- =========================================================
-- CHECKERS DE PAGOS (incluye verificacion de checksum SHA2)
-- =========================================================
SELECT 'paymentsWithoutOrder' AS checkerName, COUNT(*) AS issueCount
FROM paymentTransaction pt
LEFT JOIN customerOrder co ON pt.customerOrderID = co.customerOrderID
WHERE co.customerOrderID IS NULL;

SELECT 'paymentsInvalidAmount' AS checkerName, COUNT(*) AS issueCount
FROM paymentTransaction
WHERE transactionAmount < 0;

SELECT 'paymentsChecksumMismatch' AS checkerName, COUNT(*) AS issueCount
FROM paymentTransaction
WHERE checksum <> SHA2(CONCAT(
    transactionCode,
    '|',
    customerOrderID,
    '|',
    methodCode,
    '|',
    paymentStatusCode,
    '|',
    transactionAmount,
    '|',
    currencyID,
    '|',
    exchangeRate
), 256);

-- =========================================================
-- CHECKERS DE ENVIOS
-- =========================================================
SELECT 'shipmentsWithoutOrder' AS checkerName, COUNT(*) AS issueCount
FROM shipment s
LEFT JOIN customerOrder co ON s.customerOrderID = co.customerOrderID
WHERE co.customerOrderID IS NULL;

SELECT 'shipmentInvalidDates' AS checkerName, COUNT(*) AS issueCount
FROM shipment
WHERE deliveredAt IS NOT NULL
  AND shippedAt IS NOT NULL
  AND deliveredAt < shippedAt;

SELECT 'ordersWithoutShipment' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN shipment s ON co.customerOrderID = s.customerOrderID
WHERE s.shipmentID IS NULL;

-- =========================================================
-- CHECKERS DE PERMISOS Y REQUERIMIENTOS
-- =========================================================
SELECT 'permissionsWithoutProduct' AS checkerName, COUNT(*) AS issueCount
FROM countryProductPermission cpp
LEFT JOIN product p ON cpp.productID = p.productID
WHERE p.productID IS NULL;

SELECT 'negativePermissionCost' AS checkerName, COUNT(*) AS issueCount
FROM countryProductPermission
WHERE permissionCost < 0;

SELECT 'permissionsInvalidDates' AS checkerName, COUNT(*) AS issueCount
FROM countryProductPermission
WHERE expiresAt IS NOT NULL
  AND issuedAt IS NOT NULL
  AND expiresAt < issuedAt;

-- =========================================================
-- CHECKERS DE METRICAS
-- =========================================================
SELECT 'negativeMetricValues' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteMetric
WHERE metricValue < 0;

SELECT 'conversionRateOutOfRange' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteMetric
WHERE metricTypeCode = 'CONVERSION_RATE'
  AND (metricValue < 0 OR metricValue > 1);
