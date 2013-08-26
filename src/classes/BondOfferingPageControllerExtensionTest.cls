/**
 * 
 */
@isTest
private class BondOfferingPageControllerExtensionTest {
	
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
    private static final Integer controllerPageSize = 5;

    //Strings
    private static final String pendingStatus = 'Pending';
    private static final String purchasedStatus = 'Purchased';
    private static final String passedStatus = 'Passed';
    private static final String salesRepProfile = 'CJ Sales Rep';
    private static final String municipality = 'Municipality';
    private static final String university = 'University';
    private static final String pension = 'Pension';

	static testMethod void testConstructorNewOffering() {
        Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		Bond_Offering__c bondOffering = new Bond_Offering__c();
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		
		Test.startTest();
			BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		Test.stopTest();
		
		assertLabels(controller);
		System.assertEquals(controller.unitsAvailable, 1000);
		System.assert(!controller.errorShown);
		System.assertEquals(controller.subtitle, String.format(Label.NewOfferingSubtitle, new List<String>{bondOfferingLabel}));
		System.assertEquals(controller.unitsPendingOriginal, 0);
		System.assertEquals(controller.unitsSold, 0);
		System.assertEquals(controller.unitsPending, 0);
		System.assertEquals(controller.pageNumber, 1);
		System.assertEquals(controller.pageSize, 5);
		System.assertEquals(controller.totalPages, maxToCreate/5);
		System.assertEquals(controller.investorCount, investorCount);
		System.assertEquals(controller.queryLocatorLimit,Limits.getLimitQueryLocatorRows());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assert(!controller.tooManyPending);
    }
    
    static testMethod void testConstructorExistingOffering() {
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

		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		
		Test.startTest();
			BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		Test.stopTest();
		
		bondOffering = [Select Name, Units_Sold__c, Units_Pending__c, Units_Remaining__c from Bond_Offering__c where Id = :bondOffering.Id];
		
		assertLabels(controller);
		System.assertEquals(controller.subtitle,bondOffering.Name);
		System.assert(!controller.errorShown);
		System.assertEquals(controller.unitsAvailable, bondOffering.Units_Remaining__c);
		System.assertEquals(controller.unitsPendingOriginal, bondOffering.Units_Pending__c);
		System.assertEquals(controller.unitsSold, bondOffering.Units_Sold__c);
		System.assertEquals(controller.unitsPending, bondOffering.Units_Pending__c);
		System.assertEquals(controller.pageNumber, 1);
		System.assertEquals(controller.pageSize, 5);
		System.assertEquals(controller.totalPages, maxToCreate/5);
		System.assertEquals(controller.investorCount, investorCount);
		System.assertEquals(controller.queryLocatorLimit,Limits.getLimitQueryLocatorRows());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assert(!controller.tooManyPending);
    }
    
    static testMethod void testGetInvestorTypeFilter() {
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		Test.startTest();
			List<SelectOption> options = controller.getInvestorTypeFilter();
		Test.stopTest();
		
		System.assertEquals(options.size(), Investor__c.Type__c.getDescribe().getPicklistValues().size() + 1);
    }
    
    static testMethod void testRefreshFilterErrorInvalidUnits() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		Integer i = 0;
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			if (i < controller.pageSize / 2)
				wrapper.units = '';
			else
				wrapper.units = 'NaN';
		}
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		
		controller.selectedFilter = municipality;
		Test.startTest();
			controller.refreshBondBuys();
		Test.stopTest();

		System.assert(ApexPages.hasMessages());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
    }
    
    static testMethod void testRefreshFilterToEmptyList() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		
		controller.selectedFilter = municipality;
		Test.startTest();
			controller.refreshBondBuys();
		Test.stopTest();

		System.assert(!ApexPages.hasMessages());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),0);
		System.assertEquals(controller.totalPages,1);
    }
    
    static testMethod void testFirstPage() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);

		Test.startTest();
			controller.firstPage();
		Test.stopTest();

		System.assert(!ApexPages.hasMessages());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assertEquals(controller.pageNumber,1);
    }
    
    static testMethod void testFirstPageUnitsError() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);

		Integer i = 0;
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			if (i < controller.pageSize / 2)
				wrapper.units = '';
			else
				wrapper.units = 'NaN';
		}
		
		Test.startTest();
			controller.firstPage();
		Test.stopTest();

		System.assert(!ApexPages.hasMessages());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assertEquals(controller.pageNumber,1);
    }
    
    static testMethod void testPreviousPage() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		controller.nextPage();
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assertEquals(controller.pageNumber,2);

		Test.startTest();
			controller.previousPage();
		Test.stopTest();

		System.assert(!ApexPages.hasMessages());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assertEquals(controller.pageNumber,1);
    }
    
    static testMethod void testPreviousPageUnitsError() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);

		Integer i = 0;
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			if (i < controller.pageSize / 2)
				wrapper.units = '';
			else
				wrapper.units = 'NaN';
		}
		
		Test.startTest();
			controller.previousPage();
		Test.stopTest();

		System.assert(!ApexPages.hasMessages());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assertEquals(controller.pageNumber,1);
    }
    
    static testMethod void testNextPage() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);

		Test.startTest();
			controller.nextPage();
		Test.stopTest();

		System.assert(!ApexPages.hasMessages());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assertEquals(controller.pageNumber,2);
    }
    
    static testMethod void testNextPageUnitsError() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);

		Integer i = 0;
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			if (i < controller.pageSize / 2)
				wrapper.units = '';
			else
				wrapper.units = 'NaN';
		}
		
		Test.startTest();
			controller.nextPage();
		Test.stopTest();

		System.assert(!ApexPages.hasMessages());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assertEquals(controller.pageNumber,1);
    }
    
    static testMethod void testLastPage() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);

		Test.startTest();
			controller.lastPage();
		Test.stopTest();

		System.assert(!ApexPages.hasMessages());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assertEquals(controller.pageNumber,controller.totalPages);
    }
    
    static testMethod void testLastPageUnitsError() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);

		Integer i = 0;
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			if (i < controller.pageSize / 2)
				wrapper.units = '';
			else
				wrapper.units = 'NaN';
		}
		
		Test.startTest();
			controller.lastPage();
		Test.stopTest();

		System.assert(!ApexPages.hasMessages());
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		System.assertEquals(controller.pageNumber,1);
    }
    
    static testMethod void testSaveExistingOfferingCorrect() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		
		Integer totalPending = 0;
		Set<Id> investorIds = new Set<Id>();
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			wrapper.selected = true;
			totalPending += Integer.valueOf(wrapper.units);
			investorIds.add(wrapper.bondBuy.Investor__c);
		}

		Test.startTest();
			controller.save();
		Test.stopTest();
		
		investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
		
		for (Investor__c investor : investorList) {
			System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 1);
		}
		
		bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), totalPending);
		
		System.assert(!ApexPages.hasMessages());
    }
    
    static testMethod void testSaveNewOfferingCorrect() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		System.assertEquals(bondOffering.Id, null);
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		
		Integer totalPending = 0;
		Set<Id> investorIds = new Set<Id>();
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			wrapper.selected = true;
			totalPending += Integer.valueOf(wrapper.units);
			investorIds.add(wrapper.bondBuy.Investor__c);
		}

		Test.startTest();
			controller.save();
		Test.stopTest();
		
		Integer bondOfferingCount = [Select count() from Bond_Offering__c];
		
		System.assertEquals(bondOfferingCount, 1);
		
		investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
		
		for (Investor__c investor : investorList) {
			System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 1);
		}
		
		bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), totalPending);
		
		System.assert(!ApexPages.hasMessages());
    }
    
    static testMethod void testSaveTooManyPendingExistingOffering() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		
		Set<Id> investorIds = new Set<Id>();
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			wrapper.selected = true;
			wrapper.units = '1000';
			investorIds.add(wrapper.bondBuy.Investor__c);
		}

		Test.startTest();
			controller.save();
		Test.stopTest();
		
		investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
		
		for (Investor__c investor : investorList) {
			System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 0);
		}
		
		bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), 0);
		System.assert(controller.tooManyPending);
		System.assert(ApexPages.hasMessages());
    }
    
    static testMethod void testSaveUnitsErrorExistingOffering() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, maxToCreate);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		
		Set<Id> investorIds = new Set<Id>();
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			wrapper.selected = true;
			wrapper.units = '';
			investorIds.add(wrapper.bondBuy.Investor__c);
		}

		Test.startTest();
			controller.save();
		Test.stopTest();
		
		investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
		
		for (Investor__c investor : investorList) {
			System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 0);
		}
		
		bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), 0);
		System.assert(ApexPages.hasMessages());
    }
    
    static testMethod void testSaveUpdateErrorTooManyPendingNewOffering() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);

		Client__c client = generateTestData.getClient();
		insert client;
		System.assertNotEquals(client.Id, null);

		Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
		System.assertEquals(bondOffering.Id, null);
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), controllerPageSize);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, controllerPageSize);
		
		List<Bond_Buy__c> bondBuys = new List<Bond_Buy__c>();
		
		for (Investor__c investor : investorList) {
			bondBuys.add(generateTestData.getBondBuy(bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending));
		}
		insert bondBuys;
		System.assertEquals([Select count() from Bond_Buy__c], controllerPageSize);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		
		Set<Id> investorIds = new Set<Id>();
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			wrapper.selected = true;
			wrapper.units = '1000';
			investorIds.add(wrapper.bondBuy.Investor__c);
		}

		Test.startTest();
			controller.save();
		Test.stopTest();
		
		investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
		
		for (Investor__c investor : investorList) {
			System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 1);
		}

		System.assertEquals([Select count() from Bond_Offering__c], 0);
		System.assert(controller.tooManyPending);
		System.assert(ApexPages.hasMessages());
    }
    
    static testMethod void testSaveUpdateUnitsCorrectExistingOffering() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), controllerPageSize);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, controllerPageSize);
		
		List<Bond_Buy__c> bondBuys = new List<Bond_Buy__c>();
		
		for (Investor__c investor : investorList) {
			bondBuys.add(generateTestData.getBondBuy(bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending));
		}
		insert bondBuys;
		System.assertEquals([Select count() from Bond_Buy__c], controllerPageSize);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		
		Set<Id> investorIds = new Set<Id>();
		String unitsChange = '5';
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			wrapper.units = unitsChange;
			investorIds.add(wrapper.bondBuy.Investor__c);
		}

		Test.startTest();
			controller.nextPage();
			controller.save();
		Test.stopTest();
		
		investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
		
		for (Investor__c investor : investorList) {
			System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 1);
		}

		bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), Integer.valueOf(unitsChange)*controllerPageSize);
		System.assert(!ApexPages.hasMessages());
    }
    
    static testMethod void testSaveUpdateRemoveBondBuysExistingOffering() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), controllerPageSize);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, controllerPageSize);
		
		List<Bond_Buy__c> bondBuys = new List<Bond_Buy__c>();
		
		for (Investor__c investor : investorList) {
			bondBuys.add(generateTestData.getBondBuy(bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending));
		}
		insert bondBuys;
		System.assertEquals([Select count() from Bond_Buy__c], controllerPageSize);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		
		Set<Id> investorIds = new Set<Id>();
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			wrapper.selected = false;
			investorIds.add(wrapper.bondBuy.Investor__c);
		}

		Test.startTest();
			controller.save();
		Test.stopTest();
		
		investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
		
		for (Investor__c investor : investorList) {
			System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 0);
		}
		
		bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), 0);
		System.assert(!ApexPages.hasMessages());
    }
    
    static testMethod void testSaveUpdateSelectAndDeselectSortingWrappers() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
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
		
		Map<String, Object> parameters = new Map<String, Object>();
		parameters.put('investorType', university);
		List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), controllerPageSize);
		insert investorList;
		Integer investorCount = [Select count() from Investor__c];
		System.assertEquals(investorCount, controllerPageSize);
		
		List<Bond_Buy__c> bondBuys = new List<Bond_Buy__c>();
		
		Integer i = 0;
		for (Investor__c investor : investorList) {
			if (i < 3) 
				bondBuys.add(generateTestData.getBondBuy(bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending));
			i++;
		}
		insert bondBuys;
		System.assertEquals([Select count() from Bond_Buy__c], 3);
		
		ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
		
		System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
		
		Set<Id> investorIds = new Set<Id>();
		for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
			wrapper.selected = !wrapper.selected;
		}

		Test.startTest();
			controller.bondBuyWrapsToDisplay.sort();
			controller.nextPage();
			controller.previousPage();
			for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
				if (wrapper.selected)
					wrapper.selected = false;
			}
			controller.save();
		Test.stopTest();
		
		bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
		System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), 0);
		System.assert(!ApexPages.hasMessages());
    }
    
    private static void assertLabels(BondOfferingPageControllerExtension controller) {
    	System.assertEquals(controller.displayingRecordsMessage, String.format(Label.DisplayingRecordsMessage, new List<String>{String.valueOf(controller.bondBuyWrapsToDisplay.size()), String.valueOf(controller.investorCount)}));
    	System.assertEquals(controller.tooManyInvestorsWarning, String.format(Label.TooManyInvestorsWarning, new List<String>{String.valueOf(controller.investorCountOver), investorPluralLabel, String.valueOf(controller.queryLocatorLimit)}));
    	System.assertEquals(controller.pageNumberOfTotalLabel, String.format(Label.pageNumberOfTotal, new List<String>{String.valueOf(controller.pageNumber), String.valueOf(controller.totalPages)}));
    	System.assertEquals(controller.bondOfferingBuilderLabel, String.format(Label.BondOfferingBuilder, new List<String>{bondOfferingLabel}));
    	System.assertEquals(controller.bondOfferingDetailsLabel, String.format(Label.BondOfferingDetails, new List<String>{bondOfferingLabel}));
    	System.assertEquals(controller.bondOfferingProgressLabel, String.format(Label.BondOfferingProgress, new List<String>{bondOfferingLabel}));
    	System.assertEquals(controller.investorTypeFilterLabel, String.format(Label.InvestorTypeFilter, new List<String>{investorLabel}));
    }
}