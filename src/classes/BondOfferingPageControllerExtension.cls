public with sharing class BondOfferingPageControllerExtension {
	
	private Bond_Offering__c bondOffering;
	public String subTitle {
		get {
			if (bondOffering.Id == null)
				subtitle = 'New Bond Offering';
			else
				subtitle = bondOffering.Name;
			return subtitle;
		}
		private set;
	}
	
	public Integer unitsAvailable {
		get {
			return 1000 - unitsSold;
		}
		set;
	}
	public Integer unitsSold {
		get {
			if (unitsSold == null)
				unitsSold = 0;
			return unitsSold;
		}
		set;
	}
	public Integer unitsPending {
		get {
			if (unitsPending == null)
				unitsPending = 0;
			return unitsPending;
		}
		set;
	}
	public String selectedFilter {get;set;}
	public List<bondBuySelectionWrapper> bondBuyWrapsToDisplay {get;set;}
	public List<bondBuySelectionWrapper> bondBuyWrapsToSave {get;set;}
	private Map<String,List<bondBuySelectionWrapper>> wrappersByTypeMap = new Map<String,List<bondBuySelectionWrapper>>();
	public Integer pageNumber {get;set;}
	public Integer pageSize = 5;
	
	
	public String filterValue {get;set;}
	
	public BondOfferingPageControllerExtension(ApexPages.StandardController stdController) {
        bondOffering = (Bond_Offering__c)stdController.getRecord();
        if (bondOffering.Id != null) {
        	bondOffering = [Select Name, Client__c, Interest_Rate__c, Sales_Rep__c, Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
        	unitsSold = Integer.valueOf(bondOffering.Units_Sold__c);
        	unitsPending = Integer.valueOf(bondOffering.Units_Pending__c);
        }
        
        bondBuyWrapsToSave = getBondBuySelectionWrapperList();        
        pageNumber = 0;
        getbondBuyWrapsToDisplay();
    }
	
	private void getbondBuyWrapsToDisplay(){
		bondBuyWrapsToDisplay = new List<bondBuySelectionWrapper>();
		for (Integer i = pageNumber*pagesize; i < pageSize; i++) {
        	if (i >= bondBuyWrapsToSave.size())
        		break;
        	bondBuyWrapsToDisplay.add(bondBuyWrapsToSave.get(i));
        }
	}
	
	public List<SelectOption> getInvestorTypeFilter()
	{
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('--Any Type--', '--Any Type--'));
		Schema.DescribeFieldResult investorTypeFieldDescribe = Investor__c.Type__c.getDescribe();
		List<Schema.PicklistEntry> investorTypePicklistValues = investorTypeFieldDescribe.getPicklistValues();      
		for( Schema.PicklistEntry investorTypePicklistValue : investorTypePicklistValues)
		{
			options.add(new SelectOption(investorTypePicklistValue.getLabel(), investorTypePicklistValue.getValue()));
		}       
		return options;
	}
	
	public PageReference refreshBondBuys() {
		if (selectedFilter != '--Any Type--')
			bondBuyWrapsToDisplay = wrappersByTypeMap.get(selectedFilter);
		else
			getbondBuyWrapsToDisplay();
		return null;
	}
	
	public List<bondBuySelectionWrapper> getBondBuySelectionWrapperList() {
		List<bondBuySelectionWrapper> bondBuyWrappers = new List<bondBuySelectionWrapper>();
		List<Investor__c> tempInvestors = new List<Investor__c>();
		Boolean newOffering = bondOffering.Id == null;
		Map<Id, Bond_Buy__c> tempBondBuyMap = new Map<Id, Bond_Buy__c>();
		String soqlQueryBondBuys = '';
		String investorType = 'Null';
		if (!newOffering) {
			soqlQueryBondBuys = 'Select Units__c, Status__c, Investor__r.Name, Investor__r.Type__c from Bond_Buy__c where Bond_Offering__c = \'' + bondOffering.Id + '\'';
			tempBondBuyMap = new Map<Id, Bond_Buy__c>((List<Bond_Buy__c>)Database.query(soqlQueryBondBuys));
		}
		String soqlQueryInvestors = 'Select Name, Type__c from Investor__c ';
		
		if (!tempBondBuyMap.isEmpty()) {
			Set<Id> bondBuyInvestors = new Set<Id>();
			for (Bond_Buy__c tempBondBuy : tempBondBuyMap.values()) {
				//bondBuyWrappers.add(new bondBuySelectionWrapper (tempBondBuy, false));
				
				if (tempBondBuy.Investor__c != null) {
					bondBuyInvestors.add(tempBondBuy.Investor__c);
					investorType = tempBondBuy.Investor__r.Type__c;
				}
				
				if (!wrappersByTypeMap.containsKey(investorType))
					wrappersByTypeMap.put(investorType, new List<bondBuySelectionWrapper>());
				wrappersByTypeMap.get(investorType).add(new bondBuySelectionWrapper(tempBondBuy, false));
			}
			if (soqlQueryInvestors.contains('where'))
				soqlQueryInvestors += ' and Id not in :bondBuyInvestors';
			else
				soqlQueryInvestors += ' where Id not in :bondBuyInvestors';
		}
		
		tempInvestors = Database.query(soqlQueryInvestors);
		
		for (Investor__c tempInvestor: tempInvestors) {
			investorType = tempInvestor.Type__c;
			if (!wrappersByTypeMap.containsKey(investorType))
					wrappersByTypeMap.put(investorType, new List<bondBuySelectionWrapper>());
			wrappersByTypeMap.get(investorType).add(new bondBuySelectionWrapper(new Bond_Buy__c(Status__c = 'New', Units__c = 0, Investor__r = tempInvestor, Bond_Offering__c = bondOffering.Id), false));
		}
		
		bondBuyWrappers = new List<bondBuySelectionWrapper>();
		
		for (String invType : wrappersByTypeMap.keyset()) {	
			bondBuyWrappers.addAll(wrappersByTypeMap.get(invType));
		}
		return bondBuyWrappers;
	}
	
	public class bondBuySelectionWrapper implements Comparable{
		public Bond_Buy__c bondBuy {get;set;}
		public Boolean selected {get;set;}
		public String status {get;set;}
		public Double units {
			get {
				if (units == null)
					units = bondBuy.Units__c;
				return units;
			}
			set;
		}
		
		public bondBuySelectionWrapper (Bond_Buy__c bondBuyIn, Boolean selectedIn) {
			bondBuy = bondBuyIn;
			selected = selectedIn;
		}
		
		public Integer compareTo(Object compareTo) {
			bondBuySelectionWrapper wrapperToCompare = (bondBuySelectionWrapper) compareTo;
			if (bondBuy.Investor__r.Name == wrapperToCompare.bondBuy.Investor__r.Name)
				return 0;
			if (bondBuy.Investor__r.Name > wrapperToCompare.bondBuy.Investor__r.Name)
				return 1;
			return -1;
		}
	}
}