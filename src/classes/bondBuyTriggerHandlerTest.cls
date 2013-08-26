@isTest
private class bondBuyTriggerHandlerTest {

	//Describes to get object labels
	private static final String bondOfferingLabel = Bond_Offering__c.sObjectType.getDescribe().getLabel();
    private static final String investorLabel = Investor__c.sObjectType.getDescribe().getLabel();
    private static final String investorPluralLabel = Investor__c.sObjectType.getDescribe().getLabelPlural();
    private static final String bondBuyLabel = Bond_Buy__c.sObjectType.getDescribe().getLabel();

    //Quantities
    private static final Integer maxToCreate = 200;
    private static final Integer unitsForPending = 10;
    private static final Integer unitsForPurchased = 5;
    private static final Double interestRate = 0.3;

    //Strings
    private static final String pendingStatus = 'Pending';
    private static final String purchasedStatus = 'Purchased';
    private static final String passedStatus = 'Passed';
    private static final String salesRepProfile = 'CJ Sales Rep';
    
    //Ids
    private static final String invalidInvestor = 'a01e0000001ZiSC';
	private static final String invalidOffering = 'a02e0000001VphL';
	
	static testmethod void testBeforeInsertInvalidInvestor() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		Map<String,Object> parameters = prepareBondBuyParameters(true, false, null, null, pendingStatus, unitsForPending);
		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);

		Test.startTest();
			List<Database.SaveResult> results = Database.insert(bondBuysToTest, false);
		Test.stopTest();

		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		for (Database.SaveResult result : results) {
			System.assert(!result.IsSuccess());
			System.assertNotEquals(result.getErrors().size(), 0);

			for (Database.error error : result.getErrors()) {
				System.assertEquals(error.getMessage(), String.format(Label.InvalidIdIntroduced, new List<String>{investorLabel}));
			}
		}
	}

	static testmethod void testBeforeInsertInvalidOffering() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		Map<String,Object> parameters = prepareBondBuyParameters(false, true, null, null, pendingStatus, unitsForPending);
		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		Test.startTest();
			List<Database.SaveResult> results = Database.insert(bondBuysToTest, false);
		Test.stopTest();

		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		for (Database.SaveResult result : results) {
			System.assert(!result.IsSuccess());
			System.assertNotEquals(result.getErrors().size(), 0);

			for (Database.error error : result.getErrors()) {
				System.assertEquals(error.getMessage(), String.format(Label.InvalidIdIntroduced, new List<String>{bondOfferingLabel}));
			}
		}
	}

	static testmethod void testBeforeInsertInvalidInvestorAndOffering() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		Map<String,Object> parameters = prepareBondBuyParameters(true, true, null, null, pendingStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);

		Test.startTest();
			List<Database.SaveResult> results = Database.insert(bondBuysToTest, false);
		Test.stopTest();

		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		for (Database.SaveResult result : results) {
			System.assert(!result.IsSuccess());
			System.assertNotEquals(result.getErrors().size(), 0);

			for (Database.error error : result.getErrors()) {
				System.assertEquals(error.getMessage(), String.format(Label.InvalidIdIntroduced, new List<String>{bondOfferingLabel}) + '. ' + String.format(Label.InvalidIdIntroduced, new List<String>{investorLabel}));
			}
		}
	}

	static testmethod void testInsertPendingCorrect() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, pendingStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		Test.startTest();
			insert bondBuysToTest;
		Test.stopTest();

		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
	}
	
	static testmethod void testInsertPurchasedCorrect() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, purchasedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		Test.startTest();
			insert bondBuysToTest;
		Test.stopTest();

		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);
	}
	
	static testmethod void testUpdatePendingToPurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, pendingStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Status__c = purchasedStatus;
			bondBuy.Units__c = unitsForPurchased;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);
	}
	
	static testmethod void testUpdatePendingToPassed() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, pendingStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Status__c = passedStatus;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
	}
	
	static testmethod void testUpdatePendingToPassedChangeOffering() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Bond_Offering__c bondOffering2 = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering2;
		System.assertNotEquals(bondOffering2.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, pendingStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Status__c = passedStatus;
			bondBuy.Bond_Offering__c = bondOffering2.Id;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		bondOffering2 = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering2.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
		System.assertEquals(0, bondOffering2.Units_Pending__c);
		System.assertEquals(0, bondOffering2.Units_Sold__c);
	}
	
	static testmethod void testUpdatePendingToPurchasedChangeOffering() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Bond_Offering__c bondOffering2 = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering2;
		System.assertNotEquals(bondOffering2.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, pendingStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Status__c = purchasedStatus;
			bondBuy.Units__c = unitsForPurchased;
			bondBuy.Bond_Offering__c = bondOffering2.Id;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		bondOffering2 = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering2.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
		System.assertEquals(0, bondOffering2.Units_Pending__c);
		System.assertEquals(maxToCreate*unitsForPurchased, bondOffering2.Units_Sold__c);
	}
	
	static testmethod void testUpdatePurchasedToPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, purchasedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Status__c = pendingStatus;
			bondBuy.Units__c = unitsForPending;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
	}
	
	static testmethod void testUpdatePurchasedToPassed() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, purchasedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Status__c = passedStatus;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
	}
	
	static testmethod void testUpdatePurchasedToPassedChangeOffering() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Bond_Offering__c bondOffering2 = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering2;
		System.assertNotEquals(bondOffering2.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, purchasedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Status__c = passedStatus;
			bondBuy.Bond_Offering__c = bondOffering2.Id;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		bondOffering2 = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering2.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
		System.assertEquals(0, bondOffering2.Units_Pending__c);
		System.assertEquals(0, bondOffering2.Units_Sold__c);
	}
	
	static testmethod void testUpdatePassedToPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, passedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Status__c = pendingStatus;
			bondBuy.Units__c = unitsForPending;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
	}

	static testmethod void testUpdatePassedToPurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, passedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Status__c = purchasedStatus;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);
	}
	
	static testmethod void testUpdateChangeOfferingPurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Bond_Offering__c bondOffering2 = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering2;
		System.assertNotEquals(bondOffering2.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, purchasedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Bond_Offering__c = bondOffering2.Id;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		bondOffering2 = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering2.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
		System.assertEquals(0, bondOffering2.Units_Pending__c);
		System.assertEquals(maxToCreate*unitsForPurchased, bondOffering2.Units_Sold__c);
	}
	
	static testmethod void testUpdateChangeOfferingPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Bond_Offering__c bondOffering2 = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering2;
		System.assertNotEquals(bondOffering2.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, pendingStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Bond_Offering__c = bondOffering2.Id;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		bondOffering2 = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering2.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
		System.assertEquals(maxToCreate*unitsForPending, bondOffering2.Units_Pending__c);
		System.assertEquals(0, bondOffering2.Units_Sold__c);
	}
	
	static testmethod void testUpdateChangeInvestor() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Investor__c investor2 = generateTestData.getInvestor();
		insert investor2;
		System.assertNotEquals(investor2.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, purchasedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Investor__c = investor2.Id;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		investor2 = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor2.Id];
		System.assertEquals(0, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);
		System.assertEquals(maxToCreate, investor2.Bonds_Pitched__c);
		System.assertEquals(maxToCreate, investor2.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);
	}
	
	static testmethod void testUpdateChangeUnitsPurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, purchasedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Units__c = unitsForPurchased - 1;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(maxToCreate*(unitsForPurchased-1), bondOffering.Units_Sold__c);
	}
	
	static testmethod void testUpdateChangeUnitsPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, pendingStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Units__c = unitsForPending - 1;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(maxToCreate*(unitsForPending-1), bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
	}
	
	static testmethod void testUpdateChangeInvestorOfferingStatusUnits() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Bond_Offering__c bondOffering2 = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering2;
		System.assertNotEquals(bondOffering2.Id, null);
		
		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Investor__c investor2 = generateTestData.getInvestor();
		insert investor2;
		System.assertNotEquals(investor2.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, purchasedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		for (Bond_Buy__c bondBuy : bondBuysToTest) {
			bondBuy.Investor__c = investor2.Id;
			bondBuy.Bond_Offering__c = bondOffering2.Id;
			bondBuy.Status__c = pendingStatus;
			bondBuy.Units__c = unitsForPending;
		}
		
		Test.startTest();
			update bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		investor2 = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor2.Id];
		System.assertEquals(0, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);
		System.assertEquals(maxToCreate, investor2.Bonds_Pitched__c);
		System.assertEquals(0, investor2.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		bondOffering2 = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering2.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
		System.assertEquals(maxToCreate*unitsForPending, bondOffering2.Units_Pending__c);
		System.assertEquals(0, bondOffering2.Units_Sold__c);
	}
	
	static testmethod void testInsertTooManySold() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, purchasedStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		Test.startTest();
			List<Database.SaveResult> results = Database.insert(bondBuysToTest, false);
		Test.stopTest();

		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		for (Database.SaveResult result : results) {
			System.assert(!result.IsSuccess());
			System.assertNotEquals(result.getErrors().size(), 0);

			for (Database.error error : result.getErrors()) {
				System.assertEquals(error.getStatusCode(), StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION);
			}
		}
	}
	
	static testmethod void testInsertTooManyPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, pendingStatus, unitsForPending + unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		Test.startTest();
			List<Database.SaveResult> results = Database.insert(bondBuysToTest, false);
		Test.stopTest();

		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		for (Database.SaveResult result : results) {
			System.assert(!result.IsSuccess());
			System.assertNotEquals(result.getErrors().size(), 0);

			for (Database.error error : result.getErrors()) {
				System.assertEquals(error.getStatusCode(), StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION);
			}
		}
	}
	
	static testmethod void testDeletePurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, purchasedStatus, unitsForPurchased);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);

		Test.startTest();
			delete bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(0, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
		
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
	}
	
	static testmethod void testDeletePending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, pendingStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);

		Test.startTest();
			delete bondBuysToTest;
		Test.stopTest();

		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(0, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
		
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
	}
	
	static testmethod void testUnDelete() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);
		
		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		Map<String,Object> parameters = prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, pendingStatus, unitsForPending);

		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
		
		delete bondBuysToTest;
		
		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(0, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(0, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
		
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		Test.startTest();
			undelete bondBuysToTest;
		Test.stopTest();

		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
		
		investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
		System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
		System.assertEquals(0, investor.Bonds_Purchased__c);

		bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
		System.assertEquals(0, bondOffering.Units_Sold__c);
	}
	
	static Map<String, Object> prepareBondBuyParameters(Boolean investorError, Boolean bondOfferingError, Id bondOfferingId, Id investorId, String status, Integer units) {
		Map<String, Object> parameters = new Map<String, Object>();
		if (bondOfferingError || investorError) {
			if (bondOfferingError)
				parameters.put('bondOfferingId', invalidOffering);
			if (investorError)
				parameters.put('investorId', invalidInvestor);
		}
		else {
			parameters.put('bondOfferingId', bondOfferingId);
			parameters.put('investorId', investorId);
		}
		parameters.put('units', units);
		parameters.put('status', status);
		return parameters;
	}

	static Map<String, Object> prepareBondOfferingParameters(Id clientId, Id salesRep) {
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('clientId', clientId);
		parameters.put('interestRate', interestRate);
		parameters.put('salesRep', salesRep);
		return parameters;
	}
}