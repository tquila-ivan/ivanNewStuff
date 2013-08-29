/**
 * Test class for bondBuyTriggerHandler and bondBuyTrigger
 */
@isTest
private class bondBuyTriggerHandlerTest {

	//Describes to get object labels
	private static final String bondOfferingLabel = Bond_Offering__c.sObjectType.getDescribe().getLabel();
    private static final String investorLabel = Investor__c.sObjectType.getDescribe().getLabel();
    private static final String investorPluralLabel = Investor__c.sObjectType.getDescribe().getLabelPlural();
    private static final String bondBuyLabel = Bond_Buy__c.sObjectType.getDescribe().getLabel();

    //Quantity constants
    private static final Integer maxToCreate = 200;
    private static final Integer unitsForPending = 10;
    private static final Integer unitsForPurchased = 5;
    private static final Double interestRate = 0.3;

    //String constants
    private static final String salesRepProfile = 'CJ Sales Rep';
    private static final String accExProfile = 'CJ Account Executive';
	
	//Method that tests before insert for records with an invalid investor
	static testmethod void testBeforeInsertInvalidInvestor() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			//Get the list of bond buys associated with an invalid investor and try to insert them
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(true, false, null, null, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		
			Test.startTest();
				List<Database.SaveResult> results = Database.insert(bondBuysToTest, false);
			Test.stopTest();
	
			//Check that no bond buy was inserted and that the error was the correct one for every record
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
	}
	
	//Method that tests before insert for records with an invalid offering
	static testmethod void testBeforeInsertInvalidOffering() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
	
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			//Get the list of bond buys associated with an invalid bond offering and try to insert them
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, true, null, null, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);

			Test.startTest();
				List<Database.SaveResult> results = Database.insert(bondBuysToTest, false);
			Test.stopTest();
			
			//Check that no bond buy was inserted and that the error was the correct one for every record
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
	}

	//Method that tests before insert for records with an invalid offering and an invalid investor
	static testmethod void testBeforeInsertInvalidInvestorAndOffering() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
		
			//Get the list of bond buys associated with invalid bond offering and investor and try to insert them
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(true, true, null, null, Label.PendingStatus, unitsForPending);
	
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);

			Test.startTest();
				List<Database.SaveResult> results = Database.insert(bondBuysToTest, false);
			Test.stopTest();
	
			//Check that no bond buy was inserted and that the error was the correct one for every record
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
	}

	//Method that tests the correct insertion of pending bond buys
	static testmethod void testInsertPendingCorrect() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
	
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare and insert pending bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);

			Test.startTest();
				insert bondBuysToTest;
			Test.stopTest();
	
			//Check that all bond buys were inserted and the values for their investor and bond offering were updated properly
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
	
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(0, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
			System.assertEquals(0, bondOffering.Units_Sold__c);
		}
	}
	
	//Method that tests the correct insertion of purchase bond buys
	static testmethod void testInsertPurchasedCorrect() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
	
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
			
			//Prepare and insert purchased bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);

			Test.startTest();
				insert bondBuysToTest;
			Test.stopTest();
	
			//Check that all bond buys were inserted and the values for their investor and bond offering were updated properly
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
	
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);
		}
	}
	
	//Method that tests update of bond buys from pending to purchased
	static testmethod void testUpdatePendingToPurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
	
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert pending bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change units and status to purchased and update
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PurchasedStatus;
				bondBuy.Units__c = unitsForPurchased;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);
		}
	}
	
	//Method that tests update of bond buys from pending to passed
	static testmethod void testUpdatePendingToPassed() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
	
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert pending bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change status to passed and update
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PassedStatus;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(0, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(0, bondOffering.Units_Sold__c);
		}
	}
	
	//Method that tests update from pending to passed changing bond offering
	static testmethod void testUpdatePendingToPassedChangeOffering() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
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
	
			//Prepare, insert and assert pending bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change bond offering and status to passed and update
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PassedStatus;
				bondBuy.Bond_Offering__c = bondOffering2.Id;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
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
	}
	
	//Method that tests update from pending to purchased changing bond offering
	static testmethod void testUpdatePendingToPurchasedChangeOffering() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
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
	
			//Prepare, insert and assert pending bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change units, bond offering and status to purchased and update
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PurchasedStatus;
				bondBuy.Units__c = unitsForPurchased;
				bondBuy.Bond_Offering__c = bondOffering2.Id;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
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
	}
	
	//Method that tests updates from purchased bond buys to pending
	static testmethod void testUpdatePurchasedToPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
	
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert purchased bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change units and status to pending and update
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PendingStatus;
				bondBuy.Units__c = unitsForPending;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(0, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
			System.assertEquals(0, bondOffering.Units_Sold__c);
		}
	}
	
	//Method that tests updates from purchased bond buys to passed
	static testmethod void testUpdatePurchasedToPassed() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
	
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
			
			//Prepare, insert and assert purchased bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change status to passed and update
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PassedStatus;
			}
			
			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(0, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(0, bondOffering.Units_Sold__c);
		}
	}
	
	//Method that tests updates from purchased bond buys to passed, changing the related bond offering
	static testmethod void testUpdatePurchasedToPassedChangeOffering() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
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
	
			//Prepare, insert and assert purchased bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change bond offering and status to passed.
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PassedStatus;
				bondBuy.Bond_Offering__c = bondOffering2.Id;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
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
	}
	
	//Method that tests updates from passed bond buys to pending
	static testmethod void testUpdatePassedToPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
	
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
			
			//Prepare, insert and assert passed bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PassedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change units and status to pending and update
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PendingStatus;
				bondBuy.Units__c = unitsForPending;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(0, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
			System.assertEquals(0, bondOffering.Units_Sold__c);
		}
	}

	//Method that tests updates from passed bond buys to purchased
	static testmethod void testUpdatePassedToPurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
	
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert passed bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PassedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change status to purchased and update
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PurchasedStatus;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);
		}
	}
	
	//Method that tests a change in the related bond offering for purchased bond buys without changing the status
	static testmethod void testUpdateChangeOfferingPurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
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
	
			//Prepare, insert and assert purchased bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change the related bond offering
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Bond_Offering__c = bondOffering2.Id;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
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
	}
	
	//Method that tests a change in the related bond offering for pending bond buys without changing the status
	static testmethod void testUpdateChangeOfferingPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
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
	
			//Prepare, insert and assert pending bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change the related bond offering
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Bond_Offering__c = bondOffering2.Id;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
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
	}
	
	//Method that tests the change of a related investor
	static testmethod void testUpdateChangeInvestor() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
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
	
			//Prepare, insert and assert purchased bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change the related investor
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Investor__c = investor2.Id;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
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
	}
	
	//Method that tests the change of units for purchased bond buys, without changing the status or any related object
	static testmethod void testUpdateChangeUnitsPurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
	
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert purchased bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change the units to a value that doesn't produce an error
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Units__c = unitsForPurchased - 1;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(maxToCreate*(unitsForPurchased-1), bondOffering.Units_Sold__c);
		}
	}
	
	//Method that tests the change of units for pending bond buys, without changing the status or any related object
	static testmethod void testUpdateChangeUnitsPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
	
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert pending bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change the units to a value that doesn't produce an error
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Units__c = unitsForPending - 1;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investor and offering were updated properly
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(0, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(maxToCreate*(unitsForPending-1), bondOffering.Units_Pending__c);
			System.assertEquals(0, bondOffering.Units_Sold__c);
		}
	}

	//Method that tests the change of investor, offering, status and units
	static testmethod void testUpdateChangeInvestorOfferingStatusUnits() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
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
	
			//Prepare, insert and assert purchased bond buys
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Change related investor and offering, units and status to pending and update.
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Investor__c = investor2.Id;
				bondBuy.Bond_Offering__c = bondOffering2.Id;
				bondBuy.Status__c = Label.PendingStatus;
				bondBuy.Units__c = unitsForPending;
			}

			Test.startTest();
				update bondBuysToTest;
			Test.stopTest();
	
			//Assert that all fields for related investors and offerings were updated properly
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
	}
	
	//Method that tests that, when too many units have been inserted as purchased, the proper errors are handled and displayed.
	static testmethod void testInsertTooManySold() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
			
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare and attempt insertion of bond buys having too many units sold for the related offering.
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);

			Test.startTest();
				List<Database.SaveResult> results = Database.insert(bondBuysToTest, false);
			Test.stopTest();
	
			//Assert that no bond buys were created and the proper error messages are displayed.
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
	}
	
	//Method that tests that, when too many units have been inserted as pending, the proper errors are handled and displayed.
	static testmethod void testInsertTooManyPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
			
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare and attempt insertion of bond buys having too many units pending for the related offering.
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending + unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);

			Test.startTest();
				List<Database.SaveResult> results = Database.insert(bondBuysToTest, false);
			Test.stopTest();
	
			//Assert that no bond buys were created and the proper error messages are displayed.
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
	}
	
	//Method that tests that, when the updated bond buys have too many units sold, the proper errors are handled and displayed.
	static testmethod void testUpdateTooManySold() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
			
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert the correct purchased bond buys.
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			System.assertEquals([Select count() from Bond_Buy__c],maxToCreate);
			
			//Change the units for values that will produce errors
			for (Bond_Buy__c bondBuyToTest : bondBuysToTest) {
				bondBuyToTest.Units__c = unitsForPending + unitsForPurchased;
			}

			Test.startTest();
				List<Database.SaveResult> results = Database.update(bondBuysToTest, false);
			Test.stopTest();
			
			//Assert that all the errors were handled and are properly displayed
			for (Database.SaveResult result : results) {
				System.assert(!result.IsSuccess());
				System.assertNotEquals(result.getErrors().size(), 0);
	
				for (Database.error error : result.getErrors()) {
					System.assertEquals(error.getStatusCode(), StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION);
				}
			}
		}
	}
	
	//Method that tests that, when the updated bond buys have too many units pending, the proper errors are handled and displayed.
	static testmethod void testUpdateTooManyPending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
			
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert the correct pending bond buys.
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			System.assertEquals([Select count() from Bond_Buy__c], maxToCreate);
			
			for (Bond_Buy__c bondBuyToTest : bondBuysToTest) {
				bondBuyToTest.Units__c = unitsForPending + unitsForPurchased;
			}

			Test.startTest();
				List<Database.SaveResult> results = Database.update(bondBuysToTest, false);
			Test.stopTest();
			
			//Assert that all the errors were handled and are properly displayed
			for (Database.SaveResult result : results) {
				System.assert(!result.IsSuccess());
				System.assertNotEquals(result.getErrors().size(), 0);
	
				for (Database.error error : result.getErrors()) {
					System.assertEquals(error.getStatusCode(), StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION);
				}
			}
		}
	}
	
	//Method that tests the correct deletion of purchased bond buys
	static testmethod void testDeletePurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
			
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert the correct purchased bond buys.
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Assert that all related values are correct
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);

			//Make the deletion and assert that related values after it are correct
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
	}
	
	//Method that tests the correct deletion of pending bond buys
	static testmethod void testDeletePending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
			
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert the correct pending bond buys.
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Assert that all related values are correct
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(0, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
			System.assertEquals(0, bondOffering.Units_Sold__c);

			//Make the deletion and assert that related values after it are correct
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
	}
	
	//Method that tests the undelete of previously deleted pending bond buys
	static testmethod void testUnDeletePending() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
			
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert the correct pending bond buys.
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Assert that all related values are correct
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(0, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(maxToCreate*unitsForPending, bondOffering.Units_Pending__c);
			System.assertEquals(0, bondOffering.Units_Sold__c);
			
			//Delete and assert that the deletion was correct
			delete bondBuysToTest;
			
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(0, investor.Bonds_Pitched__c);
			System.assertEquals(0, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(0, bondOffering.Units_Sold__c);
			
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,0);

			//Make the undelete and assert that it was correct and all related values are properly populated
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
	}
	
	//Method that tests the undelete of previously deleted purchased bond buys
	static testmethod void testUnDeletePurchased() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		//Create a user to run the tests, an account executive
		User testAccountExec = generateTestData.getTestUser(accExProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);
		
		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);
	
			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
			
			Investor__c investor = generateTestData.getInvestor();
			insert investor;
			System.assertNotEquals(investor.Id, null);
	
			//Prepare, insert and assert the correct pending bond buys.
			Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PurchasedStatus, unitsForPurchased);
			List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
			insert bondBuysToTest;
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,maxToCreate);
			
			//Assert that all related values are correct
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);
			
			//Delete and assert that the deletion was correct
			delete bondBuysToTest;
			
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(0, investor.Bonds_Pitched__c);
			System.assertEquals(0, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(0, bondOffering.Units_Sold__c);
			
			bondBuyCount = [Select count() from Bond_Buy__c];
			System.assertEquals(bondBuyCount,0);

			//Make the undelete and assert that it was correct and all related values are properly populated
			Test.startTest();
				undelete bondBuysToTest;
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
	}
	
	//Method that tests update of bond buys made by a SalesRep with no access to the bond Offering
	//Will only test the update with and without access for the sales rep as he only has Edit access to bond buys
	static testmethod void testUpdateSalesRepNoAccess() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
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

		//Prepare, insert and assert pending bond buys
		Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
			
		System.runAs(testSalesRep) {
			//Change units and status to purchased and attempt the update
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PurchasedStatus;
				bondBuy.Units__c = unitsForPurchased;
			}
			
			Boolean errorCaught = false;
			Test.startTest();
				try {
					update bondBuysToTest;
				}
				catch (Exception ex) {
					errorCaught = true;
				}
			Test.stopTest();
	
			//Assert that the error was properly caught
			System.assert(errorCaught);
		}
	}
	
	//Method that tests update of bond buys made by a SalesRep with shared access to the Client that parents the bond Offering
	//Will only test the update with and without access for the sales rep as he only has Edit access to bond buys
	static testmethod void testUpdateSalesRepWithAccess() {
		Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data for insertion
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		
		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);
		//Share the client to provide the Sales rep access to tha offering.
		generateTestData.shareClient(testSalesRep.Id, client.Id);
		
		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		insert bondOffering;
		System.assertNotEquals(bondOffering.Id, null);

		Investor__c investor = generateTestData.getInvestor();
		insert investor;
		System.assertNotEquals(investor.Id, null);

		//Prepare, insert and assert pending bond buys
		Map<String,Object> parameters = generateTestData.prepareBondBuyParameters(false, false, bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending);
		List<Bond_Buy__c> bondBuysToTest = generateTestData.getMultipleObjects(parameters, Bond_Buy__c.getSObjectType(), maxToCreate);
		insert bondBuysToTest;
		bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,maxToCreate);
			
		System.runAs(testSalesRep) {
			//Change units and status to purchased and attempt the update
			for (Bond_Buy__c bondBuy : bondBuysToTest) {
				bondBuy.Status__c = Label.PurchasedStatus;
				bondBuy.Units__c = unitsForPurchased;
			}
			
			Boolean errorCaught = false;
			Test.startTest();
				try {
					update bondBuysToTest;
				}
				catch (Exception ex) {
					errorCaught = false;
				}
			Test.stopTest();
	
			//Assert that there was no error
			System.assert(!errorCaught);
			
			//Assert that all fields for related investor and offering were updated properly
			investor = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id = :investor.Id];
			System.assertEquals(maxToCreate, investor.Bonds_Pitched__c);
			System.assertEquals(maxToCreate, investor.Bonds_Purchased__c);
	
			bondOffering = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(0, bondOffering.Units_Pending__c);
			System.assertEquals(maxToCreate*unitsForPurchased, bondOffering.Units_Sold__c);
		}
	}
}