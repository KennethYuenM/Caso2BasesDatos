Crea el script para la creacion de la base de datos en MySQL con la siguien informacion, recuerda siempre agregar ON DELETE NO ACTION
El contexto es: Esta es una empresa de base tecnológica. Han desarrollado una IA capaz de generar sitios de e-commerce dinámicos.  
A partir de parámetros (logo, enfoque, país), la IA despliega tiendas virtuales con marcas blancas.  
Pueden abrir y cerrar "N" sitios en diferentes países de Latam con un solo clic, cada uno con un enfoque de marketing y mensajes distintos para el mismo producto base.

## currency
- currencyID PK
- currencyCode varchar 20
- currencyName varchar 45
- currencySymbol varchar 30
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## country
- countryID PK
- countryName varchar 50
- iso2Code char 2
- iso3Code char 3
- localCurrencyID bigint
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## currentExchangeRate
- currentExchangeRateID PK
- exchangePairID bigint
- baseCurrencyID bigint
- quoteCurrencyID bigint
- buyRate numeric 18,6
- sellRate numeric 18,6
- sourceName varchar 50
- updatedAt timestamp

## historicalExchangeRate
- historicalExchangeRateID PK
- exchangePairID bigint
- buyRate numeric 18,6
- sellRate numeric 18,6
- validFrom timestamp
- validTo timestamp
- recordedAt timestamp

## userRole
- roleCode PK
- roleName varchar 50
- roleDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## people
- personID PK
- personCode varchar 50
- countryID bigint
- email varchar 150
- firstName varchar 100
- lastName varchar 100
- passwordHash varchar 255
- isEmailVerified boolean
- isActive boolean
- lastLoginAt timestamp
- createdAt timestamp
- updatedAt timestamp

## personType
- personTypeCode PK varchar 30
- personTypeName varchar 50
- personTypeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## peoplePersonType
- peoplePersonTypeID PK
- personID bigint
- personTypeCode varchar 30
- createdAt timestamp
- updatedAt timestamp

## systemUser
- systemUserID PK
- personID bigint
- userCode varchar 30
- roleCode varchar 30
- createdAt timestamp
- updatedAt timestamp

## brandTemplate
- brandCode PK varchar 30
- brandName varchar 40
- logoURL varchar 255
- corePromise varchar 250
- targetAudience varchar 200
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## dynamicSiteStatus
- statusCode PK varchar 30
- statusName varchar 50
- statusDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## dynamicSiteGenerationStatus
- statusCode PK varchar 30
- statusName varchar 50
- statusDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## dynamicSiteEventType
- eventTypeCode PK varchar 30
- eventName varchar 50
- eventDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## dynamicSiteInfo
- dynamicSiteID PK
- siteCode varchar 30
- siteName varchar 80
- brandCode varchar 30
- countryID bigint
- currencyID bigint
- siteStatusCode varchar 30
- primaryDomainName varchar 150
- marketingFocus varchar 80
- brandVoice TEXT
- siteVisualsConfig JSON NULL
- launchDate datetime
- closeDate datetime
- clientName varchar 80
- logoURL varchar 255
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## dynamicSiteDomain
- dynamicSiteDomainID PK
- dynamicSiteID bigint
- domainName varchar 150
- isPrimary boolean
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## metricType
- metricTypeCode PK varchar 30
- metricName varchar 50
- metricDescription varchar 150
- valueType varchar 20
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## dynamicSiteMetric
- dynamicSiteMetricID PK
- dynamicSiteID bigint
- metricTypeCode varchar 30
- metricDate date
- metricValue decimal 18,6
- createdAt timestamp
- updatedAt timestamp

## changeSource
- sourceCode PK varchar 30
- sourceName varchar 50
- sourceDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## dynamicSiteStatusLog
- dynamicSiteStatusLogID PK
- dynamicSiteID bigint
- previousSiteStatusCode varchar 30
- currentSiteStatusCode varchar 30
- changeDetails varchar 250
- changeSourceCode varchar 30
- changedByPersonID bigint
- changedAt timestamp
- createdAt timestamp

## dynamicSiteAuditLog
- dynamicSiteAuditLogID PK
- dynamicSiteID bigint
- eventTypeCode varchar 30
- eventDetails varchar 250
- performedByPersonID bigint
- performedAt timestamp
- createdAt timestamp

## orderStatus
- statusCode PK varchar 30
- statusName varchar 50
- statusDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## customerOrder
- customerOrderID PK
- orderCode varchar 50
- personID bigint
- dynamicSiteID bigint
- customerCountryID bigint
- currencyID bigint
- orderStatusCode varchar 30
- orderDate timestamp
- subTotal decimal 18,6
- taxTotal decimal 18,6
- shippingAmount decimal 18,6
- totalAmount decimal 18,6
- exchangeRate decimal 18,6
- notes varchar 200
- createdAt timestamp
- updatedAt timestamp

## customerOrderDetail
- customerOrderDetailID PK
- customerOrderID bigint
- productID bigint
- quantity int
- unitPrice decimal 18,6
- taxAmount decimal 18,6
- discountAmount decimal 18,6
- lineTotal decimal 18,6
- createdAt timestamp
- updatedAt timestamp

## customerOrderStatusLog
- customerOrderStatusLogID PK
- customerOrderID bigint
- previousOrderStatusCode varchar 30
- currentOrderStatusCode varchar 30
- changeDetails varchar 250
- changeSourceCode varchar 30
- changedByPersonID bigint
- changedAt timestamp
- createdAt timestamp

## productCategory
- categoryCode PK varchar 30
- categoryName varchar 80
- categoryDescription varchar 200
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## product
- productID PK
- productCode varchar 50
- dynamicSiteID bigint
- productCategoryCode varchar 30
- productName varchar 120
- productDescription varchar 500
- sku varchar 50
- baseCurrencyID bigint
- basePrice decimal 18,6
- updatedByPersonID bigint
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## productPrice
- productPriceID PK
- productID bigint
- dynamicSiteID bigint
- currencyID bigint
- priceAmount decimal 18,6
- validFrom timestamp
- validTo timestamp
- isCurrent boolean
- createdAt timestamp
- updatedAt timestamp

## productImageType
- typeCode PK varchar 30
- typeName varchar 50
- typeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## productImage
- productImageID PK
- productID bigint
- typeCode varchar 30
- imageURL varchar 255
- displayOrder int
- isPrimary boolean
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## packagingType
- packagingTypeCode PK varchar 30
- packagingTypeName varchar 50
- packagingTypeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## productPackaging
- productPackagingID PK
- productID bigint
- countryID bigint
- packagingTypeCode varchar 30
- packagingName varchar 80
- packagingDescription varchar 250
- unitContent varchar 50
- unitMeasure varchar 30  -- normaliza esto
- packageMaterial varchar 50
- isFragile boolean
- isPrimary boolean
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## labelType
- labelTypeCode PK varchar 30
- labelTypeName varchar 50
- labelTypeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## productLabel
- productLabelID PK
- productID bigint
- dynamicSiteID bigint
- countryID bigint
- labelTypeCode varchar 30
- labelName varchar 80
- labelDescription varchar 250
- labelLanguage varchar 30
- labelContent text
- isPrimary boolean
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## regulatoryRequirementType
- requirementTypeCode PK varchar 30
- requirementTypeName varchar 60
- requirementTypeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## permissionStatus
- statusCode PK varchar 30
- statusName varchar 50
- statusDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## countryProductRequirement
- countryProductRequirementID PK
- productID bigint
- countryID bigint
- requirementTypeCode varchar 30
- requirementName varchar 100
- requirementDescription varchar 250
- isMandatory boolean
- issuedBy varchar 80
- validFrom timestamp
- validTo timestamp
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## countryProductPermission
- countryProductPermissionID PK
- productID bigint
- countryID bigint
- permissionCost bigint
- permissionCode varchar 50
- permissionName varchar 100
- permissionStatusCode varchar 30
- certificateNumber varchar 80
- issuedBy varchar 80
- issuedAt timestamp
- expiresAt timestamp
- notes varchar 250
- createdAt timestamp
- updatedAt timestamp

## inventorySource
- sourceCode PK varchar 30
- sourceName varchar 50
- sourceDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## inventory
- inventoryID PK
- dynamicSiteID bigint
- productID bigint
- availableQuantity int
- reservedQuantity int
- sellableQuantity int
- reorderLevel int
- sourceCode varchar 30
- lastStockUpdateAt timestamp
- createdAt timestamp
- updatedAt timestamp

## paymentMethod
- methodCode PK
- methodName varchar 50
- providerName varchar 50
- providerDescription varchar 150
- methodDescription varchar 150
- config JSON NULL
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## paymentTransactionStatus
- statusCode PK
- statusName varchar 50
- statusDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## paymentTransaction
- paymentTransactionID PK
- customerOrderID bigint
- transactionCode varchar 50
- methodCode varchar 30
- paymentStatusCode varchar 30
- transactionAmount decimal 18,6
- currencyID bigint
- exchangeRate decimal 18,6
- exchangeRateID bigint
- providerReference varchar 80
- transactionDate timestamp
- checksum varchar 80
- createdAt timestamp
- updatedAt timestamp

## shipmentViewType
- viewTypeCode PK varchar 30
- viewTypeName varchar 50
- viewTypeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## shipmentStatus
- statusCode PK varchar 30
- statusName varchar 50
- statusDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## shipment
- shipmentID PK
- customerOrderID bigint
- shipmentCode varchar 50
- shipmentStatusCode varchar 30
- shippingAddress varchar 250
- trackingNumber varchar 80
- carrierName varchar 60
- viewTypeCode varchar 30
- shippedAt timestamp
- deliveredAt timestamp
- createdAt timestamp
- updatedAt timestamp

## etlExecutionLog
- etlExecutionLogID PK
- processName varchar 60
- sourceSystem varchar 30
- targetSystem varchar 30
- executionStatus varchar 30
- recordsExtracted int
- recordsLoaded int
- errorDetails varchar 500
- startedAt timestamp
- finishedAt timestamp
- createdAt timestamp