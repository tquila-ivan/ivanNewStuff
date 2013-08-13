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
	private Map<String,bondBuySelectionWrapper> wrappersShown = new Map<String,bondBuySelectionWrapper>();
	public Integer pageNumber {get;set;}
	public Integer pageSize = 5;
	private Double investorCount;
	public Integer totalPages {
		get {
			return Integer.valueOf(Math.ceil(investorCount / pageSize));
		}
		private set;
	}
	
	public String filterValue {get;set;}
	
	public BondOfferingPageControllerExtension(ApexPages.StandardController stdController) {
        bondOffering = (Bond_Offering__c)stdController.getRecord();
        if (bondOffering.Id != null) {
        	bondOffering = [Select Name, Client__c, Interest_Rate__c, Sales_Rep__c, Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
        	unitsSold = Integer.valueOf(bondOffering.Units_Sold__c);
        	unitsPending = Integer.valueOf(bondOffering.Units_Pending__c);
        }
        
        pageNumber = 0;
        bondBuyWrapsToSave = getBondBuySelectionWrapperList();
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
		pageNumber = 0;
		bondBuyWrapsToDisplay = getBondBuySelectionWrapperList();
		return null;
	}
	
	public PageReference previousPage() {
		pageNumber --;
		bondBuyWrapsToDisplay = getBondBuySelectionWrapperList();
		return null;
	}
	
	public PageReference nextPage() {
		pageNumber ++;
		bondBuyWrapsToDisplay = getBondBuySelectionWrapperList();
		return null;
	}
	
	public PageReference lastPage() {
		pageNumber = totalPages - 1;
		bondBuyWrapsToDisplay = getBondBuySelectionWrapperList();
		return null;
	}
	
	public PageReference firstPage() {
		pageNumber = 0;
		bondBuyWrapsToDisplay = getBondBuySelectionWrapperList();
		return null;
	}
	
	public List<bondBuySelectionWrapper> getBondBuySelectionWrapperList() {
		List<bondBuySelectionWrapper> bondBuyWrappers = new List<bondBuySelectionWrapper>();
		Map<Id, bondBuySelectionWrapper> bondBuyWrappersMap = new Map<Id, bondBuySelectionWrapper>();
		Map<Id, Investor__c> tempInvestors = new Map<Id, Investor__c>();
		Boolean newOffering = bondOffering.Id == null;
		List<Bond_Buy__c> tempBondBuys = new List<Bond_Buy__c>();
		String soqlQueryInvestors = 'Select Name, Type__c from Investor__c ';
		
		if (selectedFilter != null && selectedFilter != '' && selectedFilter != '--Any Type--') {
			soqlQueryInvestors += ' where Type__c = :selectedFilter ';
			investorCount = [Select count() from Investor__c where Type__c = :selectedFilter];
		}
		else
			investorCount = [Select count() from Investor__c];
		Integer offSet = pageNumber*pagesize;
		soqlQueryInvestors += ' Order by Name Asc LIMIT :pageSize OFFSET :offSet';
		try {
			tempInvestors = new Map<Id, Investor__c>((List<Investor__c>)Database.query(soqlQueryInvestors));
			System.debug(tempInvestors);
			if (!newOffering) {
				tempBondBuys = [Select Units__c, Status__c, Investor__r.Name, Investor__r.Type__c from Bond_Buy__c where Bond_Offering__c = :bondOffering.Id and Investor__c in :tempInvestors.keySet()];
				
				for (Bond_Buy__c tempBondBuy : tempBondBuys) {
					if (!wrappersShown.containsKey(tempBondBuy.Investor__c))
						wrappersShown.put(tempBondBuy.Investor__c, new bondBuySelectionWrapper(tempBondBuy, false));
					bondBuyWrappersMap.put(tempBondBuy.Investor__c,wrappersShown.get(tempBondBuy.Investor__c));
				}
			}
			
			for (Investor__c tempInvestor : tempInvestors.values()) {
				if (!wrappersShown.containsKey(tempInvestor.Id))
					wrappersShown.put(tempInvestor.Id,new bondBuySelectionWrapper(new Bond_Buy__c(Status__c = 'New', Units__c = 0, Investor__r = tempInvestor), false));
				bondBuyWrappersMap.put(tempInvestor.Id, wrappersShown.get(tempInvestor.Id));
			}
		}
		catch (Exception ex) {
			System.debug(ex.getMessage() + 'messss ' + ex.getStackTraceString());
		}
		bondBuyWrappers = bondBuyWrappersMap.values();
		bondBuyWrappers.sort();
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