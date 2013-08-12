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
	
	public List<investorSelectionWrapper> investorWraps {
		get;
		set;
	}
	
	public String filterValue {get;set;}
	
	public BondOfferingPageControllerExtension(ApexPages.StandardController stdController) {
        bondOffering = (Bond_Offering__c)stdController.getRecord();
        if (bondOffering.Id != null) {
        	bondOffering = [Select Name, Client__c, Interest_Rate__c, Sales_Rep__c, Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
        	unitsSold = Integer.valueOf(bondOffering.Units_Sold__c);
        	unitsPending = Integer.valueOf(bondOffering.Units_Pending__c);
        }
        
        investorWraps = getInvestorSelectionWrapperList(selectedFilter);
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
		//System.debug('filter seleccion ' + countries);
		investorWraps = getInvestorSelectionWrapperList(selectedFilter);
		return null;
	}
	
	public List<investorSelectionWrapper> getInvestorSelectionWrapperList(String typeFilter) {
		List<investorSelectionWrapper> investorWrappers = new List<investorSelectionWrapper>();
		String soqlQuery = 'Select Name, Type__c from Investor__c';
		if (typeFilter != null && typeFilter != '' && typeFilter != '--Any Type--')
			soqlQuery += ' where Type__c = \'' + typeFilter + '\' order by Name Asc';
		
		
		List<Investor__c> tempInvestors = Database.query(soqlQuery);
		
		for (Investor__c tempInvestor : tempInvestors) {
			investorWrappers.add(new investorSelectionWrapper(tempInvestor, false, 0, 'New'));
		}
		return investorWrappers;
	}
	
	public class investorSelectionWrapper {
		public Investor__c investor {get;set;}
		public Boolean selected {get;set;}
		public Integer units {get;set;}
		public String status {get;set;}
		
		public investorSelectionWrapper (Investor__c investorIn, Boolean selectedIn, Integer unitsIn, String statusIn) {
			investor = investorIn;
			selected = selectedIn;
			units = unitsIn;
			status = statusIn;
		}
	}
}