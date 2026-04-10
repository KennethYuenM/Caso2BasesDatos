USE dynamicBrandsDB;

SELECT 'currency' AS tableName, COUNT(*) AS totalRows FROM currency
UNION ALL
SELECT 'country', COUNT(*) FROM country
UNION ALL
SELECT 'exchangePair', COUNT(*) FROM exchangePair
UNION ALL
SELECT 'currentExchangeRate', COUNT(*) FROM currentExchangeRate
UNION ALL
SELECT 'historicalExchangeRate', COUNT(*) FROM historicalExchangeRate
UNION ALL
SELECT 'userRole', COUNT(*) FROM userRole
UNION ALL
SELECT 'userInfo', COUNT(*) FROM userInfo
UNION ALL
SELECT 'brandTemplate', COUNT(*) FROM brandTemplate
UNION ALL
SELECT 'dynamicSiteStatus', COUNT(*) FROM dynamicSiteStatus
UNION ALL
SELECT 'dynamicSiteGenerationStatus', COUNT(*) FROM dynamicSiteGenerationStatus
UNION ALL
SELECT 'dynamicSiteEventType', COUNT(*) FROM dynamicSiteEventType
UNION ALL
SELECT 'dynamicSiteInfo', COUNT(*) FROM dynamicSiteInfo
UNION ALL
SELECT 'dynamicSiteDomain', COUNT(*) FROM dynamicSiteDomain
UNION ALL
SELECT 'dynamicSiteAIGeneration', COUNT(*) FROM dynamicSiteAIGeneration
UNION ALL
SELECT 'dynamicSiteMetric', COUNT(*) FROM dynamicSiteMetric
UNION ALL
SELECT 'changeSource', COUNT(*) FROM changeSource
UNION ALL
SELECT 'dynamicSiteStatusLog', COUNT(*) FROM dynamicSiteStatusLog
UNION ALL
SELECT 'dynamicSiteAuditLog', COUNT(*) FROM dynamicSiteAuditLog
UNION ALL
SELECT 'customer', COUNT(*) FROM customer
UNION ALL
SELECT 'orderStatus', COUNT(*) FROM orderStatus
UNION ALL
SELECT 'customerOrder', COUNT(*) FROM customerOrder
UNION ALL
SELECT 'customerOrderStatusLog', COUNT(*) FROM customerOrderStatusLog
UNION ALL
SELECT 'productCategory', COUNT(*) FROM productCategory
UNION ALL
SELECT 'product', COUNT(*) FROM product
UNION ALL
SELECT 'productPrice', COUNT(*) FROM productPrice
UNION ALL
SELECT 'productImageType', COUNT(*) FROM productImageType
UNION ALL
SELECT 'productImage', COUNT(*) FROM productImage
UNION ALL
SELECT 'packagingType', COUNT(*) FROM packagingType
UNION ALL
SELECT 'productPackaging', COUNT(*) FROM productPackaging
UNION ALL
SELECT 'labelType', COUNT(*) FROM labelType
UNION ALL
SELECT 'productLabel', COUNT(*) FROM productLabel
UNION ALL
SELECT 'regulatoryRequirementType', COUNT(*) FROM regulatoryRequirementType
UNION ALL
SELECT 'permissionStatus', COUNT(*) FROM permissionStatus
UNION ALL
SELECT 'countryProductRequirement', COUNT(*) FROM countryProductRequirement
UNION ALL
SELECT 'countryProductPermission', COUNT(*) FROM countryProductPermission
UNION ALL
SELECT 'inventorySource', COUNT(*) FROM inventorySource
UNION ALL
SELECT 'inventory', COUNT(*) FROM inventory
UNION ALL
SELECT 'paymentMethod', COUNT(*) FROM paymentMethod
UNION ALL
SELECT 'paymentTransactionStatus', COUNT(*) FROM paymentTransactionStatus
UNION ALL
SELECT 'paymentProvider', COUNT(*) FROM paymentProvider
UNION ALL
SELECT 'paymentTransaction', COUNT(*) FROM paymentTransaction
UNION ALL
SELECT 'shipmentViewType', COUNT(*) FROM shipmentViewType
UNION ALL
SELECT 'shipmentStatus', COUNT(*) FROM shipmentStatus
UNION ALL
SELECT 'shipment', COUNT(*) FROM shipment
UNION ALL
SELECT 'etlExecutionLog', COUNT(*) FROM etlExecutionLog
ORDER BY tableName;

SELECT c.countryID, c.countryName
FROM country c
LEFT JOIN currency cur ON c.localCurrencyID = cur.currencyID
WHERE cur.currencyID IS NULL;

SELECT ep.exchangePairID, ep.baseCurrencyID, ep.quoteCurrencyID
FROM exchangePair ep
LEFT JOIN currency c1 ON ep.baseCurrencyID = c1.currencyID
LEFT JOIN currency c2 ON ep.quoteCurrencyID = c2.currencyID
WHERE c1.currencyID IS NULL OR c2.currencyID IS NULL;

SELECT cer.currentExchangeRateID, cer.exchangePairID
FROM currentExchangeRate cer
LEFT JOIN exchangePair ep ON cer.exchangePairID = ep.exchangePairID
WHERE ep.exchangePairID IS NULL;

SELECT her.historicalExchangeRateID, her.exchangePairID
FROM historicalExchangeRate her
LEFT JOIN exchangePair ep ON her.exchangePairID = ep.exchangePairID
WHERE ep.exchangePairID IS NULL;

SELECT u.userID, u.roleCode
FROM userInfo u
LEFT JOIN userRole r ON u.roleCode = r.roleCode
WHERE r.roleCode IS NULL;

SELECT ds.dynamicSiteID, ds.brandCode, ds.countryID, ds.currencyID, ds.siteStatusCode
FROM dynamicSiteInfo ds
LEFT JOIN brandTemplate bt ON ds.brandCode = bt.brandCode
LEFT JOIN country c ON ds.countryID = c.countryID
LEFT JOIN currency cur ON ds.currencyID = cur.currencyID
LEFT JOIN dynamicSiteStatus st ON ds.siteStatusCode = st.statusCode
WHERE bt.brandCode IS NULL
   OR c.countryID IS NULL
   OR cur.currencyID IS NULL
   OR st.statusCode IS NULL;

SELECT dsd.dynamicSiteDomainID, dsd.dynamicSiteID
FROM dynamicSiteDomain dsd
LEFT JOIN dynamicSiteInfo ds ON dsd.dynamicSiteID = ds.dynamicSiteID
WHERE ds.dynamicSiteID IS NULL;

SELECT dsa.dynamicSiteAIGenerationID, dsa.dynamicSiteID, dsa.generationStatusCode
FROM dynamicSiteAIGeneration dsa
LEFT JOIN dynamicSiteInfo ds ON dsa.dynamicSiteID = ds.dynamicSiteID
LEFT JOIN dynamicSiteGenerationStatus gs ON dsa.generationStatusCode = gs.statusCode
WHERE ds.dynamicSiteID IS NULL
   OR gs.statusCode IS NULL;

SELECT dsm.dynamicSiteMetricID, dsm.dynamicSiteID
FROM dynamicSiteMetric dsm
LEFT JOIN dynamicSiteInfo ds ON dsm.dynamicSiteID = ds.dynamicSiteID
WHERE ds.dynamicSiteID IS NULL;

SELECT cu.customerID, cu.countryID
FROM customer cu
LEFT JOIN country c ON cu.countryID = c.countryID
WHERE c.countryID IS NULL;

SELECT co.customerOrderID, co.customerID, co.dynamicSiteID, co.customerCountryID, co.currencyID, co.orderStatusCode
FROM customerOrder co
LEFT JOIN customer cu ON co.customerID = cu.customerID
LEFT JOIN dynamicSiteInfo ds ON co.dynamicSiteID = ds.dynamicSiteID
LEFT JOIN country c ON co.customerCountryID = c.countryID
LEFT JOIN currency cur ON co.currencyID = cur.currencyID
LEFT JOIN orderStatus os ON co.orderStatusCode = os.statusCode
WHERE cu.customerID IS NULL
   OR ds.dynamicSiteID IS NULL
   OR c.countryID IS NULL
   OR cur.currencyID IS NULL
   OR os.statusCode IS NULL;

SELECT col.customerOrderStatusLogID, col.customerOrderID, col.currentOrderStatusCode, col.changeSourceCode
FROM customerOrderStatusLog col
LEFT JOIN customerOrder co ON col.customerOrderID = co.customerOrderID
LEFT JOIN orderStatus os ON col.currentOrderStatusCode = os.statusCode
LEFT JOIN changeSource cs ON col.changeSourceCode = cs.sourceCode
WHERE co.customerOrderID IS NULL
   OR os.statusCode IS NULL
   OR cs.sourceCode IS NULL;

SELECT p.productID, p.dynamicSiteID, p.categoryCode, p.baseCurrencyID, p.updatedByUserID
FROM product p
LEFT JOIN dynamicSiteInfo ds ON p.dynamicSiteID = ds.dynamicSiteID
LEFT JOIN productCategory pc ON p.categoryCode = pc.categoryCode
LEFT JOIN currency cur ON p.baseCurrencyID = cur.currencyID
LEFT JOIN userInfo u ON p.updatedByUserID = u.userID
WHERE ds.dynamicSiteID IS NULL
   OR pc.categoryCode IS NULL
   OR cur.currencyID IS NULL
   OR (p.updatedByUserID IS NOT NULL AND u.userID IS NULL);

SELECT pp.productPriceID, pp.productID, pp.currencyID
FROM productPrice pp
LEFT JOIN product p ON pp.productID = p.productID
LEFT JOIN currency c ON pp.currencyID = c.currencyID
WHERE p.productID IS NULL
   OR c.currencyID IS NULL;

SELECT pi.productImageID, pi.productID, pi.typeCode
FROM productImage pi
LEFT JOIN product p ON pi.productID = p.productID
LEFT JOIN productImageType pit ON pi.typeCode = pit.typeCode
WHERE p.productID IS NULL
   OR pit.typeCode IS NULL;

SELECT pkg.productPackagingID, pkg.productID, pkg.countryID, pkg.packagingTypeCode
FROM productPackaging pkg
LEFT JOIN product p ON pkg.productID = p.productID
LEFT JOIN country c ON pkg.countryID = c.countryID
LEFT JOIN packagingType pt ON pkg.packagingTypeCode = pt.packagingTypeCode
WHERE p.productID IS NULL
   OR c.countryID IS NULL
   OR pt.packagingTypeCode IS NULL;

SELECT pl.productLabelID, pl.productID, pl.dynamicSiteID, pl.countryID, pl.labelTypeCode
FROM productLabel pl
LEFT JOIN product p ON pl.productID = p.productID
LEFT JOIN dynamicSiteInfo ds ON pl.dynamicSiteID = ds.dynamicSiteID
LEFT JOIN country c ON pl.countryID = c.countryID
LEFT JOIN labelType lt ON pl.labelTypeCode = lt.labelTypeCode
WHERE p.productID IS NULL
   OR ds.dynamicSiteID IS NULL
   OR c.countryID IS NULL
   OR lt.labelTypeCode IS NULL;

SELECT cpr.countryProductRequirementID, cpr.productID, cpr.countryID, cpr.requirementTypeCode
FROM countryProductRequirement cpr
LEFT JOIN product p ON cpr.productID = p.productID
LEFT JOIN country c ON cpr.countryID = c.countryID
LEFT JOIN regulatoryRequirementType rrt ON cpr.requirementTypeCode = rrt.requirementTypeCode
WHERE p.productID IS NULL
   OR c.countryID IS NULL
   OR rrt.requirementTypeCode IS NULL;

SELECT cpp.countryProductPermissionID, cpp.productID, cpp.countryID, cpp.permissionStatusCode
FROM countryProductPermission cpp
LEFT JOIN product p ON cpp.productID = p.productID
LEFT JOIN country c ON cpp.countryID = c.countryID
LEFT JOIN permissionStatus ps ON cpp.permissionStatusCode = ps.statusCode
WHERE p.productID IS NULL
   OR c.countryID IS NULL
   OR ps.statusCode IS NULL;

SELECT i.inventoryID, i.dynamicSiteID, i.productID, i.sourceCode
FROM inventory i
LEFT JOIN dynamicSiteInfo ds ON i.dynamicSiteID = ds.dynamicSiteID
LEFT JOIN product p ON i.productID = p.productID
LEFT JOIN inventorySource s ON i.sourceCode = s.sourceCode
WHERE ds.dynamicSiteID IS NULL
   OR p.productID IS NULL
   OR s.sourceCode IS NULL;

SELECT pt.paymentTransactionID, pt.customerOrderID, pt.methodCode, pt.paymentStatusCode, pt.providerCode, pt.currencyID
FROM paymentTransaction pt
LEFT JOIN customerOrder co ON pt.customerOrderID = co.customerOrderID
LEFT JOIN paymentMethod pm ON pt.methodCode = pm.methodCode
LEFT JOIN paymentTransactionStatus ps ON pt.paymentStatusCode = ps.statusCode
LEFT JOIN paymentProvider pp ON pt.providerCode = pp.providerCode
LEFT JOIN currency c ON pt.currencyID = c.currencyID
WHERE co.customerOrderID IS NULL
   OR pm.methodCode IS NULL
   OR ps.statusCode IS NULL
   OR pp.providerCode IS NULL
   OR c.currencyID IS NULL;

SELECT s.shipmentID, s.customerOrderID, s.shipmentStatusCode, s.viewTypeCode
FROM shipment s
LEFT JOIN customerOrder co ON s.customerOrderID = co.customerOrderID
LEFT JOIN shipmentStatus ss ON s.shipmentStatusCode = ss.statusCode
LEFT JOIN shipmentViewType svt ON s.viewTypeCode = svt.viewTypeCode
WHERE co.customerOrderID IS NULL
   OR ss.statusCode IS NULL
   OR svt.viewTypeCode IS NULL;

SELECT 'duplicate currencyCode' AS validationType, currencyCode AS duplicateValue, COUNT(*) AS total
FROM currency
GROUP BY currencyCode
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate userCode', userCode, COUNT(*)
FROM userInfo
GROUP BY userCode
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate user email', email, COUNT(*)
FROM userInfo
GROUP BY email
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate customerCode', customerCode, COUNT(*)
FROM customer
GROUP BY customerCode
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate customer email', email, COUNT(*)
FROM customer
GROUP BY email
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate siteCode', siteCode, COUNT(*)
FROM dynamicSiteInfo
GROUP BY siteCode
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate primaryDomainName', primaryDomainName, COUNT(*)
FROM dynamicSiteInfo
GROUP BY primaryDomainName
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate orderCode', orderCode, COUNT(*)
FROM customerOrder
GROUP BY orderCode
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate productCode', productCode, COUNT(*)
FROM product
GROUP BY productCode
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate sku', sku, COUNT(*)
FROM product
GROUP BY sku
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate transactionCode', transactionCode, COUNT(*)
FROM paymentTransaction
GROUP BY transactionCode
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate shipmentCode', shipmentCode, COUNT(*)
FROM shipment
GROUP BY shipmentCode
HAVING COUNT(*) > 1
UNION ALL
SELECT 'duplicate permissionCode', permissionCode, COUNT(*)
FROM countryProductPermission
GROUP BY permissionCode
HAVING COUNT(*) > 1;

SELECT customerOrderID, subTotal, taxTotal, shippingAmount, totalAmount,
       ROUND(subTotal + taxTotal + shippingAmount, 6) AS expectedTotal
FROM customerOrder
WHERE ROUND(subTotal + taxTotal + shippingAmount, 6) <> ROUND(totalAmount, 6);

SELECT productID, priceAmount, validFrom, validTo
FROM productPrice
WHERE validTo IS NOT NULL
  AND validTo < validFrom;

SELECT countryProductPermissionID, issuedAt, expiresAt
FROM countryProductPermission
WHERE expiresAt IS NOT NULL
  AND issuedAt IS NOT NULL
  AND expiresAt < issuedAt;

SELECT shipmentID, shippedAt, deliveredAt
FROM shipment
WHERE deliveredAt IS NOT NULL
  AND shippedAt IS NOT NULL
  AND deliveredAt < shippedAt;

SELECT inventoryID, availableQuantity, reservedQuantity, sellableQuantity
FROM inventory
WHERE availableQuantity < 0
   OR reservedQuantity < 0
   OR sellableQuantity < 0;

SELECT inventoryID, availableQuantity, reservedQuantity, sellableQuantity
FROM inventory
WHERE sellableQuantity > availableQuantity;

SELECT dynamicSiteMetricID, visitCount, sessionCount, purchaseCount, conversionRate
FROM dynamicSiteMetric
WHERE visitCount < 0
   OR sessionCount < 0
   OR purchaseCount < 0
   OR conversionRate < 0;