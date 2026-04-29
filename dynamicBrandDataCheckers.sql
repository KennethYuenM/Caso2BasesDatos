USE dynamicBrandsDB;

SELECT 'currencyWithoutCode' AS checkerName, COUNT(*) AS issueCount
FROM currency
WHERE currencyCode IS NULL OR TRIM(currencyCode) = '';

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

SELECT 'exchangeRateSameCurrency' AS checkerName, COUNT(*) AS issueCount
FROM currentExchangeRate
WHERE baseCurrencyID = quoteCurrencyID;

SELECT 'exchangeRateInvalidRates' AS checkerName, COUNT(*) AS issueCount
FROM currentExchangeRate
WHERE buyRate <= 0
   OR sellRate <= 0;

SELECT 'historicalExchangeRateInvalidDates' AS checkerName, COUNT(*) AS issueCount
FROM historicalExchangeRate
WHERE validTo IS NOT NULL
  AND validTo < validFrom;

SELECT 'peopleWithoutCountry' AS checkerName, COUNT(*) AS issueCount
FROM people p
LEFT JOIN country c ON p.countryID = c.countryID
WHERE c.countryID IS NULL;

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

SELECT 'systemUserWithoutRole' AS checkerName, COUNT(*) AS issueCount
FROM systemUser su
LEFT JOIN userRole ur ON su.roleCode = ur.roleCode
WHERE ur.roleCode IS NULL;

SELECT 'dynamicSiteWithoutBrand' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo dsi
LEFT JOIN brandTemplate bt ON dsi.brandCode = bt.brandCode
WHERE bt.brandCode IS NULL;

SELECT 'dynamicSiteWithoutCountry' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo dsi
LEFT JOIN country c ON dsi.countryID = c.countryID
WHERE c.countryID IS NULL;

SELECT 'dynamicSiteWithoutCurrency' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo dsi
LEFT JOIN currency cur ON dsi.currencyID = cur.currencyID
WHERE cur.currencyID IS NULL;

SELECT 'dynamicSiteWithoutStatus' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo dsi
LEFT JOIN dynamicSiteStatus dss ON dsi.siteStatusCode = dss.statusCode
WHERE dss.statusCode IS NULL;

SELECT 'dynamicSiteClosedWithoutCloseDate' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo
WHERE siteStatusCode = 'CLOSED'
  AND closeDate IS NULL;

SELECT 'dynamicSiteActiveWithCloseDate' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo
WHERE siteStatusCode = 'ACTIVE'
  AND closeDate IS NOT NULL;

SELECT 'dynamicSiteWithoutPrimaryDomain' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo
WHERE primaryDomainName IS NULL
   OR TRIM(primaryDomainName) = '';

SELECT 'dynamicSiteDomainWithoutSite' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteDomain dsd
LEFT JOIN dynamicSiteInfo dsi ON dsd.dynamicSiteID = dsi.dynamicSiteID
WHERE dsi.dynamicSiteID IS NULL;

SELECT 'dynamicSiteWithoutMetrics' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo dsi
LEFT JOIN dynamicSiteMetric dsm ON dsi.dynamicSiteID = dsm.dynamicSiteID
WHERE dsm.dynamicSiteMetricID IS NULL;

SELECT 'metricWithoutMetricType' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteMetric dsm
LEFT JOIN metricType mt ON dsm.metricTypeCode = mt.metricTypeCode
WHERE mt.metricTypeCode IS NULL;

SELECT 'negativeMetricValues' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteMetric
WHERE metricValue < 0;

SELECT 'conversionRateOutOfRange' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteMetric
WHERE metricTypeCode = 'CONVERSION_RATE'
  AND (metricValue < 0 OR metricValue > 1);

SELECT 'duplicateSiteMetricByDate' AS checkerName, COUNT(*) AS issueCount
FROM (
    SELECT dynamicSiteID, metricTypeCode, metricDate
    FROM dynamicSiteMetric
    GROUP BY dynamicSiteID, metricTypeCode, metricDate
    HAVING COUNT(*) > 1
) duplicatedMetrics;

SELECT 'ordersWithoutPerson' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN people p ON co.personID = p.personID
WHERE p.personID IS NULL;

SELECT 'ordersWithoutSite' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN dynamicSiteInfo dsi ON co.dynamicSiteID = dsi.dynamicSiteID
WHERE dsi.dynamicSiteID IS NULL;

SELECT 'ordersWithoutCountry' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN country c ON co.customerCountryID = c.countryID
WHERE c.countryID IS NULL;

SELECT 'ordersWithoutCurrency' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN currency cur ON co.currencyID = cur.currencyID
WHERE cur.currencyID IS NULL;

SELECT 'ordersWithoutStatus' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN orderStatus os ON co.orderStatusCode = os.statusCode
WHERE os.statusCode IS NULL;

SELECT 'ordersWithoutDetails' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN customerOrderDetail cod ON co.customerOrderID = cod.customerOrderID
WHERE cod.customerOrderDetailID IS NULL;

SELECT 'orderDetailsWithoutProduct' AS checkerName, COUNT(*) AS issueCount
FROM customerOrderDetail cod
LEFT JOIN product p ON cod.productID = p.productID
WHERE p.productID IS NULL;

SELECT 'orderDetailsInvalidQuantity' AS checkerName, COUNT(*) AS issueCount
FROM customerOrderDetail
WHERE quantity <= 0;

SELECT 'orderDetailsInvalidUnitPrice' AS checkerName, COUNT(*) AS issueCount
FROM customerOrderDetail
WHERE unitPrice < 0;

SELECT 'orderDetailsNegativeTax' AS checkerName, COUNT(*) AS issueCount
FROM customerOrderDetail
WHERE taxAmount < 0;

SELECT 'orderDetailsNegativeDiscount' AS checkerName, COUNT(*) AS issueCount
FROM customerOrderDetail
WHERE discountAmount < 0;

SELECT 'orderDetailLineTotalMismatch' AS checkerName, COUNT(*) AS issueCount
FROM customerOrderDetail
WHERE ROUND(lineTotal, 6) <> ROUND((quantity * unitPrice) + taxAmount - discountAmount, 6);

SELECT 'orderTotalsMismatch' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
JOIN (
    SELECT
        customerOrderID,
        SUM(quantity * unitPrice) AS calculatedSubTotal,
        SUM(taxAmount) AS calculatedTaxTotal,
        SUM(lineTotal) AS calculatedLineTotal
    FROM customerOrderDetail
    GROUP BY customerOrderID
) orderDetailTotals ON co.customerOrderID = orderDetailTotals.customerOrderID
WHERE ROUND(co.subTotal, 6) <> ROUND(orderDetailTotals.calculatedSubTotal, 6)
   OR ROUND(co.taxTotal, 6) <> ROUND(orderDetailTotals.calculatedTaxTotal, 6)
   OR ROUND(co.totalAmount, 6) <> ROUND(orderDetailTotals.calculatedLineTotal + co.shippingAmount, 6);

SELECT 'ordersWithNegativeAmounts' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder
WHERE subTotal < 0
   OR taxTotal < 0
   OR shippingAmount < 0
   OR totalAmount < 0;

SELECT 'ordersWithInvalidExchangeRate' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder
WHERE exchangeRate <= 0;

SELECT 'productWithoutSite' AS checkerName, COUNT(*) AS issueCount
FROM product p
LEFT JOIN dynamicSiteInfo dsi ON p.dynamicSiteID = dsi.dynamicSiteID
WHERE dsi.dynamicSiteID IS NULL;

SELECT 'productWithoutCategory' AS checkerName, COUNT(*) AS issueCount
FROM product p
LEFT JOIN productCategory pc ON p.productCategoryCode = pc.categoryCode
WHERE pc.categoryCode IS NULL;

SELECT 'productWithoutBaseCurrency' AS checkerName, COUNT(*) AS issueCount
FROM product p
LEFT JOIN currency cur ON p.baseCurrencyID = cur.currencyID
WHERE cur.currencyID IS NULL;

SELECT 'productWithoutUpdaterPerson' AS checkerName, COUNT(*) AS issueCount
FROM product p
LEFT JOIN people pe ON p.updatedByPersonID = pe.personID
WHERE p.updatedByPersonID IS NOT NULL
  AND pe.personID IS NULL;

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

SELECT 'productPriceWithoutSite' AS checkerName, COUNT(*) AS issueCount
FROM productPrice pp
LEFT JOIN dynamicSiteInfo dsi ON pp.dynamicSiteID = dsi.dynamicSiteID
WHERE dsi.dynamicSiteID IS NULL;

SELECT 'productPriceWithoutCurrency' AS checkerName, COUNT(*) AS issueCount
FROM productPrice pp
LEFT JOIN currency cur ON pp.currencyID = cur.currencyID
WHERE cur.currencyID IS NULL;

SELECT 'productPriceInvalidDates' AS checkerName, COUNT(*) AS issueCount
FROM productPrice
WHERE validTo IS NOT NULL
  AND validTo < validFrom;

SELECT 'productPriceInvalidAmount' AS checkerName, COUNT(*) AS issueCount
FROM productPrice
WHERE priceAmount < 0;

SELECT 'duplicateCurrentProductPrice' AS checkerName, COUNT(*) AS issueCount
FROM (
    SELECT productID, dynamicSiteID, currencyID
    FROM productPrice
    WHERE isCurrent = TRUE
    GROUP BY productID, dynamicSiteID, currencyID
    HAVING COUNT(*) > 1
) duplicatedCurrentPrices;

SELECT 'productImagesWithoutProduct' AS checkerName, COUNT(*) AS issueCount
FROM productImage pi
LEFT JOIN product p ON pi.productID = p.productID
WHERE p.productID IS NULL;

SELECT 'productImagesWithoutType' AS checkerName, COUNT(*) AS issueCount
FROM productImage pi
LEFT JOIN productImageType pit ON pi.typeCode = pit.typeCode
WHERE pit.typeCode IS NULL;

SELECT 'productsWithoutPrimaryImage' AS checkerName, COUNT(*) AS issueCount
FROM product p
LEFT JOIN productImage pi ON p.productID = pi.productID AND pi.isPrimary = TRUE
WHERE pi.productImageID IS NULL;

SELECT 'productPackagingWithoutProduct' AS checkerName, COUNT(*) AS issueCount
FROM productPackaging pp
LEFT JOIN product p ON pp.productID = p.productID
WHERE p.productID IS NULL;

SELECT 'productPackagingWithoutCountry' AS checkerName, COUNT(*) AS issueCount
FROM productPackaging pp
LEFT JOIN country c ON pp.countryID = c.countryID
WHERE c.countryID IS NULL;

SELECT 'productPackagingWithoutType' AS checkerName, COUNT(*) AS issueCount
FROM productPackaging pp
LEFT JOIN packagingType pt ON pp.packagingTypeCode = pt.packagingTypeCode
WHERE pt.packagingTypeCode IS NULL;

SELECT 'productLabelsWithoutProduct' AS checkerName, COUNT(*) AS issueCount
FROM productLabel pl
LEFT JOIN product p ON pl.productID = p.productID
WHERE p.productID IS NULL;

SELECT 'productLabelsWithoutSite' AS checkerName, COUNT(*) AS issueCount
FROM productLabel pl
LEFT JOIN dynamicSiteInfo dsi ON pl.dynamicSiteID = dsi.dynamicSiteID
WHERE dsi.dynamicSiteID IS NULL;

SELECT 'productLabelsWithoutCountry' AS checkerName, COUNT(*) AS issueCount
FROM productLabel pl
LEFT JOIN country c ON pl.countryID = c.countryID
WHERE c.countryID IS NULL;

SELECT 'productLabelsWithoutType' AS checkerName, COUNT(*) AS issueCount
FROM productLabel pl
LEFT JOIN labelType lt ON pl.labelTypeCode = lt.labelTypeCode
WHERE lt.labelTypeCode IS NULL;

SELECT 'requirementsWithoutProduct' AS checkerName, COUNT(*) AS issueCount
FROM countryProductRequirement cpr
LEFT JOIN product p ON cpr.productID = p.productID
WHERE p.productID IS NULL;

SELECT 'requirementsWithoutCountry' AS checkerName, COUNT(*) AS issueCount
FROM countryProductRequirement cpr
LEFT JOIN country c ON cpr.countryID = c.countryID
WHERE c.countryID IS NULL;

SELECT 'requirementsWithoutType' AS checkerName, COUNT(*) AS issueCount
FROM countryProductRequirement cpr
LEFT JOIN regulatoryRequirementType rrt ON cpr.requirementTypeCode = rrt.requirementTypeCode
WHERE rrt.requirementTypeCode IS NULL;

SELECT 'requirementsInvalidDates' AS checkerName, COUNT(*) AS issueCount
FROM countryProductRequirement
WHERE validTo IS NOT NULL
  AND validTo < validFrom;

SELECT 'permissionsWithoutProduct' AS checkerName, COUNT(*) AS issueCount
FROM countryProductPermission cpp
LEFT JOIN product p ON cpp.productID = p.productID
WHERE p.productID IS NULL;

SELECT 'permissionsWithoutCountry' AS checkerName, COUNT(*) AS issueCount
FROM countryProductPermission cpp
LEFT JOIN country c ON cpp.countryID = c.countryID
WHERE c.countryID IS NULL;

SELECT 'permissionsWithoutStatus' AS checkerName, COUNT(*) AS issueCount
FROM countryProductPermission cpp
LEFT JOIN permissionStatus ps ON cpp.permissionStatusCode = ps.statusCode
WHERE ps.statusCode IS NULL;

SELECT 'permissionsInvalidDates' AS checkerName, COUNT(*) AS issueCount
FROM countryProductPermission
WHERE expiresAt IS NOT NULL
  AND issuedAt IS NOT NULL
  AND expiresAt < issuedAt;

SELECT 'expiredApprovedPermissions' AS checkerName, COUNT(*) AS issueCount
FROM countryProductPermission
WHERE permissionStatusCode = 'APPROVED'
  AND expiresAt IS NOT NULL
  AND expiresAt < CURRENT_TIMESTAMP;

SELECT 'permissionsExpiringNext30Days' AS checkerName, COUNT(*) AS issueCount
FROM countryProductPermission
WHERE expiresAt IS NOT NULL
  AND expiresAt BETWEEN CURRENT_TIMESTAMP AND DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 30 DAY);

SELECT 'negativePermissionCost' AS checkerName, COUNT(*) AS issueCount
FROM countryProductPermission
WHERE permissionCost < 0;

SELECT 'inventoryWithoutSite' AS checkerName, COUNT(*) AS issueCount
FROM inventory i
LEFT JOIN dynamicSiteInfo dsi ON i.dynamicSiteID = dsi.dynamicSiteID
WHERE dsi.dynamicSiteID IS NULL;

SELECT 'inventoryWithoutProduct' AS checkerName, COUNT(*) AS issueCount
FROM inventory i
LEFT JOIN product p ON i.productID = p.productID
WHERE p.productID IS NULL;

SELECT 'inventoryWithoutSource' AS checkerName, COUNT(*) AS issueCount
FROM inventory i
LEFT JOIN inventorySource ins ON i.sourceCode = ins.sourceCode
WHERE ins.sourceCode IS NULL;

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

SELECT 'stockBelowReorderLevel' AS checkerName, COUNT(*) AS issueCount
FROM inventory
WHERE sellableQuantity <= reorderLevel;

SELECT 'inactiveSitesWithActiveInventory' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteInfo dsi
JOIN inventory i ON dsi.dynamicSiteID = i.dynamicSiteID
WHERE dsi.isActive = FALSE
  AND i.sellableQuantity > 0;

SELECT 'paymentsWithoutOrder' AS checkerName, COUNT(*) AS issueCount
FROM paymentTransaction pt
LEFT JOIN customerOrder co ON pt.customerOrderID = co.customerOrderID
WHERE co.customerOrderID IS NULL;

SELECT 'paymentsWithoutMethod' AS checkerName, COUNT(*) AS issueCount
FROM paymentTransaction pt
LEFT JOIN paymentMethod pm ON pt.methodCode = pm.methodCode
WHERE pm.methodCode IS NULL;

SELECT 'paymentsWithoutStatus' AS checkerName, COUNT(*) AS issueCount
FROM paymentTransaction pt
LEFT JOIN paymentTransactionStatus pts ON pt.paymentStatusCode = pts.statusCode
WHERE pts.statusCode IS NULL;

SELECT 'paymentsWithoutCurrency' AS checkerName, COUNT(*) AS issueCount
FROM paymentTransaction pt
LEFT JOIN currency cur ON pt.currencyID = cur.currencyID
WHERE cur.currencyID IS NULL;

SELECT 'paymentsInvalidAmount' AS checkerName, COUNT(*) AS issueCount
FROM paymentTransaction
WHERE transactionAmount < 0;

SELECT 'paymentsInvalidExchangeRate' AS checkerName, COUNT(*) AS issueCount
FROM paymentTransaction
WHERE exchangeRate <= 0;

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

SELECT 'approvedPaymentAmountDifferentFromOrder' AS checkerName, COUNT(*) AS issueCount
FROM paymentTransaction pt
JOIN customerOrder co ON pt.customerOrderID = co.customerOrderID
WHERE pt.paymentStatusCode = 'APPROVED'
  AND ROUND(pt.transactionAmount, 6) <> ROUND(co.totalAmount, 6);

SELECT 'ordersWithoutApprovedPayment' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN paymentTransaction pt 
    ON co.customerOrderID = pt.customerOrderID 
   AND pt.paymentStatusCode = 'APPROVED'
WHERE co.orderStatusCode IN ('PAID', 'SHIPPED', 'DELIVERED')
  AND pt.paymentTransactionID IS NULL;

SELECT 'shipmentsWithoutOrder' AS checkerName, COUNT(*) AS issueCount
FROM shipment s
LEFT JOIN customerOrder co ON s.customerOrderID = co.customerOrderID
WHERE co.customerOrderID IS NULL;

SELECT 'shipmentsWithoutStatus' AS checkerName, COUNT(*) AS issueCount
FROM shipment s
LEFT JOIN shipmentStatus ss ON s.shipmentStatusCode = ss.statusCode
WHERE ss.statusCode IS NULL;

SELECT 'shipmentsWithoutViewType' AS checkerName, COUNT(*) AS issueCount
FROM shipment s
LEFT JOIN shipmentViewType svt ON s.viewTypeCode = svt.viewTypeCode
WHERE svt.viewTypeCode IS NULL;

SELECT 'ordersWithoutShipment' AS checkerName, COUNT(*) AS issueCount
FROM customerOrder co
LEFT JOIN shipment s ON co.customerOrderID = s.customerOrderID
WHERE s.shipmentID IS NULL;

SELECT 'shipmentDeliveredWithoutDeliveredAt' AS checkerName, COUNT(*) AS issueCount
FROM shipment
WHERE shipmentStatusCode = 'DELIVERED'
  AND deliveredAt IS NULL;

SELECT 'shipmentInTransitWithoutShippedAt' AS checkerName, COUNT(*) AS issueCount
FROM shipment
WHERE shipmentStatusCode = 'IN_TRANSIT'
  AND shippedAt IS NULL;

SELECT 'shipmentInvalidDates' AS checkerName, COUNT(*) AS issueCount
FROM shipment
WHERE deliveredAt IS NOT NULL
  AND shippedAt IS NOT NULL
  AND deliveredAt < shippedAt;

SELECT 'dynamicSiteStatusLogsWithoutSite' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteStatusLog dssl
LEFT JOIN dynamicSiteInfo dsi ON dssl.dynamicSiteID = dsi.dynamicSiteID
WHERE dsi.dynamicSiteID IS NULL;

SELECT 'dynamicSiteAuditLogsWithoutSite' AS checkerName, COUNT(*) AS issueCount
FROM dynamicSiteAuditLog dsal
LEFT JOIN dynamicSiteInfo dsi ON dsal.dynamicSiteID = dsi.dynamicSiteID
WHERE dsi.dynamicSiteID IS NULL;

SELECT 'customerOrderStatusLogsWithoutOrder' AS checkerName, COUNT(*) AS issueCount
FROM customerOrderStatusLog cosl
LEFT JOIN customerOrder co ON cosl.customerOrderID = co.customerOrderID
WHERE co.customerOrderID IS NULL;