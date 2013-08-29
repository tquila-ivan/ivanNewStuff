/**
 * Test class for the controller extension BondOfferingPageControllerExtension
 */
@isTest
private class BondOfferingPageControllerExtensionTest {
	
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
    private static final Integer controllerPageSize = 5;
    private static final Integer pageSizeForSetting = 10;

    //String constants
    private static final String pendingStatus = 'Pending';
    private static final String purchasedStatus = 'Purchased';
    private static final String passedStatus = 'Passed';
    private static final String salesRepProfile = 'CJ Sales Rep';
    private static final String accountExecProfile = 'CJ Account Executive';
    private static final String municipality = 'Municipality';
    private static final String university = 'University';
    private static final String pension = 'Pension';

	//Method that tests the constructor of the class for a new offering
	static testMethod void testConstructorNewOffering() {
        Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);

			Map<String, Object> parameters = new Map<String, Object>();
			parameters.put('investorType', university);
			List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
			insert investorList;
			Integer investorCount = [Select count() from Investor__c];
			System.assertEquals(investorCount, maxToCreate);
			
			ConfigSettings__c setting = new ConfigSettings__c(Name = 'pageSize', IntValue__c = pageSizeForSetting);
			insert setting;
			
			Bond_Offering__c bondOffering = new Bond_Offering__c();
			
			ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
		
			//Instantiate the class and assert all initial values are correct.
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
			//Test the pagesize from the custom setting
			System.assertEquals(controller.pageSize, pageSizeForSetting);
			System.assertEquals(controller.totalPages, maxToCreate/pageSizeForSetting);
			System.assertEquals(controller.investorCount, investorCount);
			System.assertEquals(controller.queryLocatorLimit,Limits.getLimitQueryLocatorRows());
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
			System.assert(!controller.tooManyPending);
		}
    }
    
    //Method that tests the constructor of the class for an existing offering
    static testMethod void testConstructorExistingOffering() {
        Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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
		
			//Instantiate the class and assert all initial values are correct.
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
			//Test the pagesize without custom setting, getting the default
			System.assertEquals(controller.pageSize, controller.defaultPageSize);
			System.assertEquals(controller.totalPages, maxToCreate/controller.defaultPageSize);
			System.assertEquals(controller.investorCount, investorCount);
			System.assertEquals(controller.queryLocatorLimit,Limits.getLimitQueryLocatorRows());
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
			System.assert(!controller.tooManyPending);
		}
    }
    
    //Method that tests the populating of the Investor type filter from the existing active Investor Type picklist values.
    static testMethod void testGetInvestorTypeFilter() {
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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
			
			//Get options and assert they are they include all the values from the field's picklist
			Test.startTest();
				List<SelectOption> options = controller.getInvestorTypeFilter();
			Test.stopTest();
			
			Set<String> labels = new Set<String>();
			for (SelectOption option : options) {
				labels.add(option.getLabel());
			}
			for (Schema.PicklistEntry entry : Investor__c.Type__c.getDescribe().getPicklistValues()) {
				System.assert(labels.contains(entry.getLabel()));
			}
			System.assertEquals(options.size(), Investor__c.Type__c.getDescribe().getPicklistValues().size() + 1);
		}
    }
    
    //Method that tests the change of the investor type filter
    static testMethod void testRefreshFilter() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);

			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
			
			//Insert Investors of University and Municipality Types
			Map<String, Object> parameters = new Map<String, Object>();
			parameters.put('investorType', university);
			List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
			parameters.put('investorType', municipality);
			investorList.addAll((List<Investor__c>)generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate));
			
			insert investorList;
			Integer investorCount = [Select count() from Investor__c];
			System.assertEquals(investorCount, maxToCreate*2);

			ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
			BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
			
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
			//Change the selected filter to municipality and assert that the pagination values are correct
			controller.selectedFilter = municipality;
			Test.startTest();
				controller.refreshBondBuys();
			Test.stopTest();
	
			System.assert(!ApexPages.hasMessages());
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(), controller.pageSize);
			System.assertEquals(controller.totalPages,maxToCreate/controller.pageSize);
		}
    }
    
    //Method that tests a change on the filter with invalid values in the units
    static testMethod void testRefreshFilterErrorInvalidUnits() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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
			
			//Set values for units to empty or not a number and assert that the page shows an error and that the filter comes back to the default
			Integer i = 0;
			for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
				if (i < controller.pageSize / 2)
					wrapper.units = '';
				else
					wrapper.units = 'NaN';
			}
			
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
			
			controller.selectedFilter = university;
			Test.startTest();
				controller.refreshBondBuys();
			Test.stopTest();
	
			System.assert(ApexPages.hasMessages());
			System.assertEquals(controller.selectedFilter, Label.InvestorTypeFilterDefault);
		}
    }
    
    //Method that tests the change of the investor type filter, with no returned records.
    static testMethod void testRefreshFilterToEmptyList() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
			Client__c client = generateTestData.getClient();
			insert client;
			System.assertNotEquals(client.Id, null);

			Bond_Offering__c bondOffering = generateTestData.getBondOffering(client.Id, interestRate, testSalesRep.Id);
			insert bondOffering;
			System.assertNotEquals(bondOffering.Id, null);
			
			//Investors are of University Type
			Map<String, Object> parameters = new Map<String, Object>();
			parameters.put('investorType', university);
			List<Investor__c> investorList = generateTestData.getMultipleObjects(parameters, Investor__c.getSObjectType(), maxToCreate);
			insert investorList;
			Integer investorCount = [Select count() from Investor__c];
			System.assertEquals(investorCount, maxToCreate);

			ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
			BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
			
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
			//Change the selected filter to one that has no records and assert that there is no error, but there are no displayed related records
			controller.selectedFilter = municipality;
			Test.startTest();
				controller.refreshBondBuys();
			Test.stopTest();
	
			System.assert(!ApexPages.hasMessages());
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),0);
			System.assertEquals(controller.totalPages,1);
		}
    }
    
    //Method that tests the funcionality of the First page button
    static testMethod void testFirstPage() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate controller, go to first page, assert that all worked properly
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
    }
    
    //Method that tests the First page button with errors on the unit values
    static testMethod void testFirstPageUnitsError() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);
		
		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate controller, place wrong values on the units, go to first page, assert that errors were handled properly
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
	
			System.assert(ApexPages.hasMessages());
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
			System.assertEquals(controller.pageNumber,1);
		}
    }
    
    //Method that tests the funcionality of the Previous page button
    static testMethod void testPreviousPage() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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
			
			//Instantiate controller, go to next page, then previous page, assert that all worked properly
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
    }
    
    //Method that tests the Previous page button with errors on the unit values
    static testMethod void testPreviousPageUnitsError() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate controller, go to next page, place wrong values on the units, go to previous page, assert that errors were handled properly
			ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
			BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
			controller.nextPage();
			System.assertEquals(controller.pageNumber, 2);
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
	
			System.assert(ApexPages.hasMessages());
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
			System.assertEquals(controller.pageNumber,2);
		}
    }
    
    //Method that tests the funcionality of the Next page button
    static testMethod void testNextPage() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate controller, go to next page, assert that all worked properly
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
    }
    
    //Method that tests the Next page button with errors on the unit values
    static testMethod void testNextPageUnitsError() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate controller, place wrong values on the units, go to next page, assert that errors were handled properly
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
	
			System.assert(ApexPages.hasMessages());
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
			System.assertEquals(controller.pageNumber,1);
		}
    }
    
    //Method that tests the funcionality of the Last page button
    static testMethod void testLastPage() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate controller, go to last page, assert that all worked properly
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
    }
    
    //Method that tests the Last page button with errors on the unit values
    static testMethod void testLastPageUnitsError() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate controller, place wrong values on the units, go to last page, assert that errors were handled properly
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
	
			System.assert(ApexPages.hasMessages());
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
			System.assertEquals(controller.pageNumber,1);
		}
    }
    
    //Method that tests the correct functionality of the Save button for an existing offering
    static testMethod void testSaveExistingOfferingCorrect() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate the controller, add all wrappers being displayed to it and save
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
			
			//Assert that all changes were saved properly
			investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
			
			for (Investor__c investor : investorList) {
				System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 1);
			}
			
			bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), totalPending);
			
			System.assert(!ApexPages.hasMessages());
		}
    }
    
    //Method that tests the correct functionality of the Save button for an new offering
    static testMethod void testSaveNewOfferingCorrect() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate the controller, add all wrappers being displayed to it and save
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
			
			//Assert that all changes were saved properly
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
    }
    
    //Method that tests the proper handling of an error provoqued by too many pending units being inserted to an existing offering
    static testMethod void testSaveTooManyPendingExistingOffering() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate controller, add a big number to every wrapper being displayed and try to save
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
			
			//Assert that all errors were properly handled
			investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
			
			for (Investor__c investor : investorList) {
				System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 0);
			}
			
			bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), 0);
			System.assert(controller.tooManyPending);
			System.assert(ApexPages.hasMessages());
		}
    }
    
    //Method that tests the proper handling of errors in the units for the save button, for an existing offering.
    static testMethod void testSaveUnitsErrorExistingOffering() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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

			//Instantiate controller, add a wrong value to the units for every wrapper being displayed and try to save
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
			
			//Assert that all errors were handled properly
			investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
			
			for (Investor__c investor : investorList) {
				System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 0);
			}
			
			bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), 0);
			System.assert(ApexPages.hasMessages());
		}
    }
    
    //Method that tests the proper handling of an error provoqued by too many pending units being inserted to a new offering through update
    static testMethod void testSaveUpdateErrorTooManyPendingNewOffering() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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
			
			//Insert bond buys, to have related records to update
			List<Bond_Buy__c> bondBuys = new List<Bond_Buy__c>();
			for (Investor__c investor : investorList) {
				bondBuys.add(generateTestData.getBondBuy(bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending));
			}
			insert bondBuys;
			System.assertEquals([Select count() from Bond_Buy__c], controllerPageSize);

			//Instantiate controller, add a big number to every wrapper being displayed and try to save
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
			
			//Assert that all errors were handled properly
			investorList = [Select Bonds_Pitched__c from Investor__c where Id in :investorIds];
			
			for (Investor__c investor : investorList) {
				System.assertEquals(Integer.valueOf(investor.Bonds_Pitched__c), 1);
			}
	
			System.assertEquals([Select count() from Bond_Offering__c], 0);
			System.assert(controller.tooManyPending);
			System.assert(ApexPages.hasMessages());
		}
    }
    
    //Method that tests the correct functionaliy of units update for an existing offering.
    static testMethod void testSaveUpdateUnitsCorrectExistingOffering() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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
			
			//Insert bond buys, to have related records to update
			List<Bond_Buy__c> bondBuys = new List<Bond_Buy__c>();
			for (Investor__c investor : investorList) {
				bondBuys.add(generateTestData.getBondBuy(bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending));
			}
			insert bondBuys;
			System.assertEquals([Select count() from Bond_Buy__c], controllerPageSize);

			//Instantiate controller, add a value that won't give an error to the units for every wrapper being displayed and try to save
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
    }
    
    //MEthod that tests the deletion of existing related bond buys without errors
    static testMethod void testSaveUpdateRemoveBondBuysExistingOffering() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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
			
			//Insert related bond buys
			List<Bond_Buy__c> bondBuys = new List<Bond_Buy__c>();
			for (Investor__c investor : investorList) {
				bondBuys.add(generateTestData.getBondBuy(bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending));
			}
			insert bondBuys;
			System.assertEquals([Select count() from Bond_Buy__c], controllerPageSize);
		
			//Instantiate controller, deselect all wrappers displayed and save. Assert that all were deleted properly
			ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
			BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
			
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);
			
			Set<Id> investorIds = new Set<Id>();
			for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
				System.assert(wrapper.selected);
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
    }
    
    //Method that makes selections, deselections and a couple of page movements to check mix correct functionalities from the page
    static testMethod void testSaveUpdateSelectAndDeselectSortingWrappers() {
    	
    	PageReference pageRef = Page.BondOfferingPage;
        Test.setCurrentPage(pageRef);
        
    	Integer bondBuyCount = [Select count() from Bond_Buy__c];
		System.assertEquals(bondBuyCount,0);

		//Prepare related data
		User testSalesRep = generateTestData.getTestUser(salesRepProfile);
		insert testSalesRep;
		System.assertNotEquals(testSalesRep.Id, null);
		User testAccountExec = generateTestData.getTestUser(accountExecProfile);
		insert testAccountExec;
		System.assertNotEquals(testAccountExec.Id, null);

		System.runAs(testAccountExec) {
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
			
			//Insert related bond buys for only the 3 first investors
			List<Bond_Buy__c> bondBuys = new List<Bond_Buy__c>();
			Integer i = 0;
			for (Investor__c investor : investorList) {
				if (i < 3) 
					bondBuys.add(generateTestData.getBondBuy(bondOffering.Id, investor.Id, Label.PendingStatus, unitsForPending));
				i++;
			}
			insert bondBuys;
			System.assertEquals([Select count() from Bond_Buy__c], 3);

			//Instantiate controller
			ApexPages.StandardController stdCtrlr = new ApexPages.StandardController(bondOffering);
			BondOfferingPageControllerExtension controller = new BondOfferingPageControllerExtension(stdCtrlr);
			
			System.assertEquals(controller.bondBuyWrapsToDisplay.size(),controller.pageSize);

			//Deselect selected and select unselected wrappers
			for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
				wrapper.selected = !wrapper.selected;
			}
	
			Test.startTest();
				//Sort the wrapper list, go to next page, go to previous page, deselect the wrappers that were selected and save
				controller.bondBuyWrapsToDisplay.sort();
				controller.nextPage();
				controller.previousPage();
				for (BondOfferingPageControllerExtension.bondBuySelectionWrapper wrapper : controller.bondBuyWrapsToDisplay) {
					if (wrapper.selected)
						wrapper.selected = false;
				}
				controller.save();
			Test.stopTest();
			
			//Assert all the results are the expected.
			bondOffering = [Select Units_Pending__c from Bond_Offering__c where Id = :bondOffering.Id];
			System.assertEquals(Integer.valueOf(bondOffering.Units_Pending__c), 0);
			System.assert(!ApexPages.hasMessages());
		}
    }
    
    //Method that asserts that the getter methods for all message labels return the correct values
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