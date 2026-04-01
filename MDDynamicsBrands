Crea el script para la crecion de la base de datos en MySQL con la siguien informacion, recuerda siempre agregar ON DELETE NO ACTION

dynamicSiteInfo
	dynamicSiteID PK
	siteCode varchar 30
	siteName varchar 80
	brandTemplateID bigint
	countryID bigint
	currencyID bigint
	siteStatusID bigint
	primaryDomainName varchar 150
	marketingFocus varchar 80
	brandVoice varchar 80
	targetSegment varchar 80
	launchDate datetime
	closeDate datetime
	clientName varchar 80
	logoURL varchar 255
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

dynamicSiteStatus
	siteStatusID PK
	statusCode varchar 30
	statusName varchar 50
	statusDescription varchar 150
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

dynamicSiteStatusLog
	dynamicSiteStatusLogID PK
	dynamicSiteID bigint
	previousSiteStatusID bigint
	currentSiteStatusID bigint
	changeDetails varchar 250
	changeSource varchar 30
	changedByUserID bigint
	changedAt timestamp
	createdAt timestamp

dynamicSiteDomain
	dynamicSiteDomainID PK
	dynamicSiteID bigint
	domainName varchar 150
	isPrimary boolean
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

dynamicSiteAIGeneration
	dynamicSiteAIGenerationID PK
	dynamicSiteID bigint
	promptVersion varchar 50
	promptContent text
	generatedConfiguration json
	generationStatus varchar 30
	generationDetails varchar 250
	generatedAt timestamp
	createdAt timestamp
	updatedAt timestamp

currency
	currencyID PK
	currencyCode varchar 20
	currencyName varchar 45
	currencySymbol varchar 30
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

country
	countryID PK
	countryName varchar 50
	iso2Code char 2
	iso3Code char 3
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

exchangePair
	exchangePairID PK
	baseCurrencyID bigint
	quoteCurrencyID bigint
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

currentExchangeRate
	currentExchangeRateID PK
	exchangePairID bigint
	buyRate numeric 18,6
	sellRate numeric 18,6
	sourceName varchar 50
	updatedAt timestamp

historicalExchangeRate
	historicalExchangeRateID PK
	exchangePairID bigint
	buyRate numeric 18,6
	sellRate numeric 18,6
	validFrom timestamp
	validTo timestamp
	recordedAt timestamp

brandTemplate
	brandTemplateID PK
	brandCode varchar 30
	brandName varchar 40
	logoURL varchar 255
	corePromise varchar 250
	targetAudience varchar 200
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

userRole
	userRoleID PK
	roleCode varchar 30
	roleName varchar 50
	roleDescription varchar 150
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

user
	userID PK
	userCode varchar 30
	firstName varchar 100
	lastName varchar 100
	email varchar 150
	passwordHash varchar 255
	userRoleID bigint
	isActive boolean
	lastLoginAt timestamp
	createdAt timestamp
	updatedAt timestamp

customer
	customerID PK
	customerCode varchar 50
	countryID bigint
	email varchar 150
	firstName varchar 100
	lastName varchar 100
	passwordHash varchar 255
	isEmailVerified boolean
	isActive boolean
	lastLoginAt timestamp
	createdAt timestamp
	updatedAt timestamp

orderStatus
	orderStatusID PK
	statusCode varchar 30
	statusName varchar 50
	statusDescription varchar 150
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

customerOrder
	customerOrderID PK
	orderCode varchar 50
	customerID bigint
	dynamicSiteID bigint
	currencyID bigint
	orderStatusID bigint
	orderDate timestamp
	subTotal decimal 18,6
	taxTotal decimal 18,6
	shippingAmount decimal 18,6
	totalAmount decimal 18,6
	exchangeRate decimal 18,6
	notes varchar 200
	createdAt timestamp
	updatedAt timestamp

customerOrderStatusLog
	customerOrderStatusLogID PK
	customerOrderID bigint
	previousOrderStatusID bigint
	currentOrderStatusID bigint
	changeDetails varchar 250
	changeSource varchar 30
	changedByUserID bigint
	changedAt timestamp
	createdAt timestamp

customerOrderLine
	customerOrderLineID PK
	customerOrderID bigint
	productID bigint
	quantity int
	unitPrice decimal 18,6
	taxAmount decimal 18,6
	discountAmount decimal 18,6
	lineTotal decimal 18,6
	createdAt timestamp
	updatedAt timestamp

productCategory
	productCategoryID PK
	categoryCode varchar 30
	categoryName varchar 80
	categoryDescription varchar 200
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

product
	productID PK
	productCode varchar 50
	dynamicSiteID bigint
	productCategoryID bigint
	productName varchar 120
	productDescription varchar 500
	sku varchar 50
	baseCurrencyID bigint
	basePrice decimal 18,6
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

productPrice
	productPriceID PK
	productID bigint
	currencyID bigint
	priceAmount decimal 18,6
	validFrom timestamp
	validTo timestamp
	isCurrent boolean
	createdAt timestamp
	updatedAt timestamp

productImage
	productImageID PK
	productID bigint
	imageURL varchar 255
	imageType varchar 30
	displayOrder int
	isPrimary boolean
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

inventory
	inventoryID PK
	productID bigint
	availableQuantity int
	reservedQuantity int
	sellableQuantity int
	reorderLevel int
	inventorySource varchar 30
	lastStockUpdateAt timestamp
	createdAt timestamp
	updatedAt timestamp

paymentMethod
	paymentMethodID PK
	methodCode varchar 30
	methodName varchar 50
	methodDescription varchar 150
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

paymentTransactionStatus
	paymentTransactionStatusID PK
	statusCode varchar 30
	statusName varchar 50
	statusDescription varchar 150
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

paymentTransaction
	paymentTransactionID PK
	customerOrderID bigint
	transactionCode varchar 50
	paymentMethodID bigint
	paymentTransactionStatusID bigint
	transactionAmount decimal 18,6
	currencyID bigint
	providerName varchar 50
	providerReference varchar 80
	transactionDate timestamp
	createdAt timestamp
	updatedAt timestamp

shipmentStatus
	shipmentStatusID PK
	statusCode varchar 30
	statusName varchar 50
	statusDescription varchar 150
	isActive boolean
	createdAt timestamp
	updatedAt timestamp

shipment
	shipmentID PK
	customerOrderID bigint
	shipmentCode varchar 50
	shipmentStatusID bigint
	shippingAddress varchar 250
	trackingNumber varchar 80
	carrierName varchar 60
	shipmentViewType varchar 30
	shippedAt timestamp
	deliveredAt timestamp
	createdAt timestamp
	updatedAt timestamp

dynamicSiteAuditLog
	dynamicSiteAuditLogID PK
	dynamicSiteID bigint
	eventType varchar 50
	eventDetails varchar 250
	performedByUserID bigint
	performedAt timestamp
	createdAt timestamp

etlExecutionLog
	etlExecutionLogID PK
	processName varchar 60
	sourceSystem varchar 30
	targetSystem varchar 30
	executionStatus varchar 30
	recordsExtracted int
	recordsLoaded int
	errorDetails varchar 500
	startedAt timestamp
	finishedAt timestamp
	createdAt timestamp
	


