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
	public String selectedFilter {
		get;
		set {
			if (String.isBlank(selectedFilter))
				previousSelectedFilter = '--Any Type--';
			previousSelectedFilter = selectedFilter;
			selectedFilter = value;
		}
	}
	public String previousSelectedFilter {get;set;}
	
	public List<bondBuySelectionWrapper> bondBuyWrapsToDisplay {get;private set;}
	private Map<Id,bondBuySelectionWrapper> wrappersChanged = new Map<Id,bondBuySelectionWrapper>();
	public Integer pageNumber {get;set;}
	public Integer pageSize = 5;
	public Integer investorCount {get;set;}
	public Integer totalPages {
		get {
			if (investorCount == 0)
				totalPages = 1;
			else
				totalPages = Integer.valueOf(Math.ceil(Double.valueOf(investorCount) / pageSize));
			
			return totalPages;
		}
		private set;
	}
	public boolean errorShown {get;set;}
	public String filterValue {get;set;}
	
	private ApexPages.StandardController controller;
	public ApexPages.StandardSetController investorSetController {get;set;}
	
	public BondOfferingPageControllerExtension(ApexPages.StandardController stdController) {
        controller = stdController;
        bondOffering = (Bond_Offering__c)stdController.getRecord();
        if (bondOffering.Id != null) {
        	bondOffering = [Select Name, Client__c, Interest_Rate__c, Sales_Rep__c, Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id = :bondOffering.Id];
        	unitsSold = Integer.valueOf(bondOffering.Units_Sold__c);
        	unitsPending = Integer.valueOf(bondOffering.Units_Pending__c);
        }

        getBondBuySelectionWrapperList();
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
	
	public Boolean allUnitsValid () {
		Boolean allValid = true;
		String errorCause = '';
		for (bondBuySelectionWrapper wrap : bondBuyWrapsToDisplay) {
			if (String.isBlank(wrap.units) || !wrap.units.isNumeric()) {
				allValid = false;
				errorCause = wrap.bondBuy.Investor__r.Name;
				break;
			}
		}
		
		if (!allValid)
			setError('Make sure you have entered a valid numbered in the units field for all investors. Investor causing the error: ' + errorCause);
		return allValid;
	}
	
	public PageReference refreshBondBuys() {
		if (allUnitsValid()) {
			storeSelected();
			return reloadList();
		}
		return null;
	}
	
	public PageReference previousPage() {
		if (allUnitsValid()) {
			storeSelected();
			investorSetController.previous();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	public PageReference nextPage() {
		if (allUnitsValid()) {
			storeSelected();
			investorSetController.next();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	public PageReference lastPage() {
		if (allUnitsValid()) {
			storeSelected();
			investorSetController.last();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	public PageReference firstPage() {
		if (allUnitsValid()) {
			storeSelected();
			investorSetController.first();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	private void storeSelected() {
		for (bondBuySelectionWrapper wrapDisplayed : bondBuyWrapsToDisplay) {
			if (wrapDisplayed.hasChanged)
				wrappersChanged.put(wrapDisplayed.bondBuy.Investor__c, wrapDisplayed);
		}
	}
	
	private PageReference reloadList () {
		if (allUnitsValid())
			getBondBuySelectionWrapperList();
		return null;
	}
	
	private void setError(String error) {
		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, error);
        ApexPages.addMessage(myMsg);
        errorShown = true;
        selectedFilter = previousSelectedFilter;
	}
	
	public void processBondBuyWrappersToDisplay(List<Investor__c> tempInvestors) {
		bondBuyWrapsToDisplay = new List<bondBuySelectionWrapper>();
		bondBuySelectionWrapper tempWrapper;
		pageNumber = investorSetController.getPageNumber();
		for (Investor__c tempInvestor : tempInvestors) {
			if (wrappersChanged.containsKey(tempInvestor.Id)) 
				tempWrapper = wrappersChanged.get(tempInvestor.Id);
			else {
				if (tempInvestor.Bond_Buys__r == null || tempInvestor.Bond_Buys__r.isEmpty())
					tempWrapper = new bondBuySelectionWrapper(new Bond_Buy__c(Status__c = 'New', Units__c = tempInvestor.Default_Bond_Units__c, Investor__r = tempInvestor, Investor__c = tempInvestor.Id), false);
				else
					tempWrapper = new bondBuySelectionWrapper(tempInvestor.Bond_Buys__r[0], true);
			}
			bondBuyWrapsToDisplay.add(tempWrapper);
		}
	}
	
	
	public void getBondBuySelectionWrapperList() {
		List<Investor__c> tempInvestors = new List<Investor__c>();
		Boolean newOffering = bondOffering.Id == null;
		List<bondBuySelectionWrapper> wrappersPerType = new List<bondBuySelectionWrapper>();
		String soqlQueryInvestors = 'Select Name, Type__c, Default_Bond_Units__c';
		String whereClause = '';
		if(!newOffering)
			soqlQueryInvestors += ', (Select Units__c, Status__c, Investor__r.Name, Investor__r.Type__c from Bond_Buys__r where Bond_Offering__c = \'' + bondOffering.Id + '\' Limit 1)';
		if (selectedFilter != '--Any type--' && !String.isBlank(selectedFilter))
			whereClause += 'where Type__c = :selectedFilter';
		
		soqlQueryInvestors += ' from Investor__c ' + whereClause + ' order by Name Asc';

		try {
			investorSetController = new ApexPages.StandardSetController(Database.getQueryLocator(soqlQueryInvestors));
			investorSetController.setPageSize(pageSize);
			investorSetController.first();
			tempInvestors = investorSetController.getRecords();
			bondBuyWrapsToDisplay = new List<bondBuySelectionWrapper>();
			investorCount = investorSetController.getResultSize();
			processBondBuyWrappersToDisplay(tempInvestors);
		}
		catch (Exception ex) {
			System.debug(ex.getMessage() + 'messss ' + ex.getStackTraceString());
		}
	}
	
	public PageReference save() {
		if (!allUnitsValid()) {
	        return null;
		}
		PageReference result = controller.save();
		bondOffering = (Bond_Offering__c) controller.getRecord();
		storeSelected();
		saveBondBuys();
		return result;
	}
	
	private void saveBondBuys() {
		List<bondBuySelectionWrapper> finalwrapperList = wrappersChanged.values();
		List<Bond_Buy__c> bondBuyListToUpsert = new List<Bond_Buy__c>();
		List<Bond_Buy__c> bondBuyListToDelete = new List<Bond_Buy__c>();
		for (bondBuySelectionWrapper wrapper : finalwrapperList) {
			if (wrapper.toUpsert) {
				if (wrapper.bondBuy.Status__c == 'New')
					wrapper.bondBuy.Status__c = 'Pending';
				wrapper.bondBuy.Bond_Offering__c = bondOffering.Id;
				wrapper.bondBuy.Units__c = Double.valueOf(wrapper.units);
				bondBuyListToUpsert.add(wrapper.bondBuy);
			}
			if (wrapper.toDelete)
				bondBuyListToDelete.add(wrapper.bondBuy);
		}
		
		upsert bondBuyListToUpsert;
		delete bondBuyListToDelete;
	}
	
	public class bondBuySelectionWrapper implements Comparable{
		public Bond_Buy__c bondBuy {get;set;}
		public Boolean selected {get;set;}
		public String units {
			get {
				if (units == null)
					units = String.valueOf(bondBuy.Units__c);
				return units;
			}
			set;
		}
		public Boolean readOnly {
			get {
				if (bondBuy != null)
					readOnly = bondBuy.Status__c != 'Pending' && bondBuy.Status__c != 'New';
				return readOnly;
			}
			private set;
		}
		
		public Boolean toUpsert {
			get {
				if (bondBuy.Status__c == 'Pending' && selected) 
					return Integer.valueOf(units) != bondBuy.Units__c;
				return selected && !readOnly;
			}
		}
		
		public Boolean toDelete {
			get {
				return !selected && bondBuy.Status__c != 'New';
			}
		}
		
		public Boolean hasChanged {
			get {
				if (bondBuy.Status__c == 'New')
					return selected || Integer.valueOf(units) != bondBuy.Investor__r.Default_Bond_Units__c;
				return toUpsert || toDelete;
			}
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