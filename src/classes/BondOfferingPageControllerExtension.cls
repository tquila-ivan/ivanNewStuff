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
			if (unitsAvailable == null)
				unitsAvailable = 1000 - unitsSold;
			return unitsAvailable;
		}
		set;
	}
	public Integer unitsPendingOriginal {
		get {
			if (unitsPendingOriginal == null)
				unitsPendingOriginal = 0;
			return unitsPendingOriginal;
		}
		set;
	}
	public Integer unitsSold {
		get {
			if (unitsSold == null)
				unitsSold = 0;
			return unitsSold;
		}
		private set;
	}
	public Integer unitsPending {
		get {
			if (unitsPending == null)
				unitsPending = unitsPendingOriginal;
			return unitsPending;
		}
		private set;
	}
	public Boolean tooManyPending {
		get {
			return unitsPending > unitsAvailable * 2;
		}
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
	public Integer investorCountOver {get;set;}
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
	public boolean errorShown {
		get {
			if (errorShown == null)
				errorShown = false;
			return errorShown;
		}
		set;
	}
	public String filterValue {get;set;}
	private Boolean isNewOffering = true;
	private ApexPages.StandardController controller;
	public ApexPages.StandardSetController investorSetController {get;set;}
	
	public static Boolean DMLerrors {
    	get {
    		if (DMLerrors == null)
    			DMLerrors = false;
    		return DMLerrors;
    	}
		set;
    }
    
    public Integer queryLocatorLimit {
    	get {
    		return Limits.getLimitQueryLocatorRows();
    	}
    }
	public BondOfferingPageControllerExtension(ApexPages.StandardController stdController) {
        controller = stdController;
        bondOffering = (Bond_Offering__c)stdController.getRecord();
        if (bondOffering.Id != null) {
        	isNewOffering = false;
        	bondOffering = [Select Name, Client__c, Interest_Rate__c, Sales_Rep__c, Units_Pending__c, Units_Sold__c, Units_Remaining__c from Bond_Offering__c where Id = :bondOffering.Id];
        	unitsPendingOriginal = Integer.valueOf(bondOffering.Units_Pending__c);
        	unitsSold = Integer.valueOf(bondOffering.Units_Sold__c);
        	unitsAvailable = Integer.valueOf(bondOffering.Units_Remaining__c);
        }

        getBondBuySelectionWrapperList(false);
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
			updateStats();
			return reloadList();
		}
		return null;
	}
	
	public PageReference previousPage() {
		if (allUnitsValid()) {
			storeSelected();
			updateStats();
			investorSetController.previous();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	public PageReference nextPage() {
		if (allUnitsValid()) {
			storeSelected();
			updateStats();
			investorSetController.next();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	public PageReference lastPage() {
		if (allUnitsValid()) {
			storeSelected();
			updateStats();
			investorSetController.last();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	public PageReference firstPage() {
		if (allUnitsValid()) {
			storeSelected();
			updateStats();
			investorSetController.first();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	private void storeSelected() {
		for (bondBuySelectionWrapper wrapDisplayed : bondBuyWrapsToDisplay) {
			if (wrapDisplayed.hasChanged) {
				wrappersChanged.put(wrapDisplayed.bondBuy.Investor__c, wrapDisplayed);
			}
			if (!wrapDisplayed.selected && wrapDisplayed.bondBuy.Status__c == 'New' && wrappersChanged.containsKey(wrapDisplayed.bondBuy.Investor__c))
				wrappersChanged.remove(wrapDisplayed.bondBuy.Investor__c);
		}
	}
	
	private void updateStats() {
		Integer unitsPendingChange = 0;
		for (bondBuySelectionWrapper wrapperChanged : wrappersChanged.values()) {
			if (wrapperChanged.selected)
				if (wrapperChanged.bondBuy.Status__c == 'New')
					unitsPendingChange += Integer.valueOf(wrapperChanged.units);
				else
					unitsPendingChange += (Integer.valueOf(wrapperChanged.units) - Integer.valueOf(wrapperChanged.bondBuy.Units__c));
			else
				unitsPendingChange -= Integer.valueOf(wrapperChanged.bondBuy.Units__c);
		}
		unitsPending = unitsPendingOriginal + unitsPendingChange;
	}
	
	private PageReference reloadList () {
		if (allUnitsValid())
			getBondBuySelectionWrapperList(false);
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
					tempWrapper = new bondBuySelectionWrapper(new Bond_Buy__c(Status__c = 'New', Units__c = tempInvestor.Default_Bond_Units__c, Investor__r = tempInvestor, Investor__c = tempInvestor.Id), false, true);
				else
					tempWrapper = new bondBuySelectionWrapper(tempInvestor.Bond_Buys__r[0], true, false);
			}
			bondBuyWrapsToDisplay.add(tempWrapper);
		}
	}
	
	public void getBondBuySelectionWrapperList(Boolean isRollBack) {
		List<Investor__c> tempInvestors = new List<Investor__c>();
		String soqlQueryInvestors = 'Select Name, Type__c, Default_Bond_Units__c';
		String whereClause = '';
		if(bondOffering.Id != null)
			soqlQueryInvestors += ', (Select Units__c, Status__c, Investor__r.Name, Investor__r.Type__c from Bond_Buys__r where Bond_Offering__c = \'' + bondOffering.Id + '\' Limit 1)';
		if (selectedFilter != '--Any type--' && !String.isBlank(selectedFilter))
			whereClause += 'where Type__c = :selectedFilter';
		
		soqlQueryInvestors += ' from Investor__c ' + whereClause + ' order by Name Asc limit ' + String.valueOf(queryLocatorLimit);

		try {
			investorSetController = new ApexPages.StandardSetController(Database.getQueryLocator(soqlQueryInvestors));
			investorSetController.setPageSize(pageSize);
			if (isRollBack)
				investorSetController.setPageNumber(pageNumber);
			else
				investorSetController.first();
			tempInvestors = investorSetController.getRecords();
			bondBuyWrapsToDisplay = new List<bondBuySelectionWrapper>();
			investorCount = investorSetController.getResultSize();
			if (investorCount == queryLocatorLimit)
				investorCountOver = Database.countQuery('Select count() from Investor__c ' + whereClause);
			else
				investorCountOver = investorCount;
			processBondBuyWrappersToDisplay(tempInvestors);
		}
		catch (Exception ex) {
			setError('There was an error loading the records, please contact your administrator.');
		}
	}
	
	public PageReference save() {
		if (!allUnitsValid())
	        return null;
	    storeSelected();
	    
	    Savepoint sp = Database.setSavepoint();
	    
	    if (!isNewOffering)
        	bondOffering = [Select Units_Pending__c, Units_Sold__c, Units_Remaining__c from Bond_Offering__c where Id = :bondOffering.Id];
        else
        	bondOffering.Client__c = ((Bond_Offering__c) controller.getRecord()).Client__c;
	    bondOffering.Name = ((Bond_Offering__c) controller.getRecord()).Name;
	    bondOffering.Interest_Rate__c = ((Bond_Offering__c) controller.getRecord()).Interest_Rate__c;
	    bondOffering.Sales_Rep__c = ((Bond_Offering__c) controller.getRecord()).Sales_Rep__c;
	    upsert bondOffering;
		PageReference result = new PageReference('/' + bondOffering.Id);
		Id newOfferId = bondOffering.Id;
		Set<Id> relatedBondBuys = saveBondBuys(newOfferId);
		if (errorShown || DMLerrors) {
			Database.rollback(sp);
			rollBackWrappers(relatedBondBuys);
			if (isNewOffering) {
				bondOffering = new Bond_Offering__c(Id = null, Name = bondOffering.Name, Client__c = bondOffering.Client__c, Interest_Rate__c = bondOffering.Interest_Rate__c, Sales_Rep__c = bondOffering.Sales_Rep__c);
			}
			controller = new ApexPages.Standardcontroller(bondOffering);
			getBondBuySelectionWrapperList(true);	
			updateStats();
			return null;
		}
		return result;
	}
	
	private Set<Id> saveBondBuys(Id newOfferId) {
		List<bondBuySelectionWrapper> finalwrapperList = wrappersChanged.values();
		List<Bond_Buy__c> bondBuyListToInsert = new List<Bond_Buy__c>();
		List<Bond_Buy__c> bondBuyListToUpdate = new List<Bond_Buy__c>();
		List<Bond_Buy__c> bondBuyListToDelete = new List<Bond_Buy__c>();
		Set<Id> relatedBondBuys = new Set<Id>();
		for (bondBuySelectionWrapper wrapper : finalwrapperList) {
			if (wrapper.toUpsert) {
				if (wrapper.bondBuy.Status__c == 'New')
					wrapper.bondBuy.Status__c = 'Pending';
				wrapper.bondBuy.Bond_Offering__c = newOfferId;
				wrapper.bondBuy.Units__c = Double.valueOf(wrapper.units);
				if (wrapper.bondBuy.Id != null) {
					relatedBondBuys.add(wrapper.bondBuy.Id);
					bondBuyListToUpdate.add(wrapper.bondBuy);
				}
				else
					bondBuyListToInsert.add(wrapper.bondBuy);
			}
			if (wrapper.toDelete)
				bondBuyListToDelete.add(wrapper.bondBuy);
		}
		
		errorShown = false;
		
		try {
			delete bondBuyListToDelete;
		}
		catch (Exception ex) {
			errorShown = true;
		}
		try {
			update bondBuyListToUpdate;
		}
		catch (Exception ex) {
			errorShown = true;
		}
		
		try {
			insert bondBuyListToInsert ;
		}
		catch (Exception ex) {
			errorShown = true;
		}
		
		return relatedBondBuys;
	}
	
	private void rollBackWrappers(Set<Id> relatedBondBuys) {
		Bond_Buy__c tempBondBuy;
		Map<Id, Bond_Buy__c> bondBuysMap = new Map<Id, Bond_Buy__c>([Select Units__c from Bond_Buy__c where Id in :relatedBondBuys]);
		for (bondBuySelectionWrapper wrapper : wrappersChanged.values()) {
			if (wrapper.bondBuy.Id == null || wrapper.isNew) {
				tempBondBuy = new Bond_Buy__c(Status__c = 'New', Units__c = Double.valueOf(wrapper.units), Investor__r = wrapper.bondBuy.Investor__r, Investor__c = wrapper.bondBuy.Investor__c);
				wrapper.bondBuy = tempBondBuy;
			}
			else {
				if (bondBuysMap.containsKey(wrapper.bondBuy.Id))
					wrapper.bondBuy.Units__c = bondBuysMap.get(wrapper.bondBuy.Id).Units__c;
			}
		}
		
		if (!isNewOffering) {
        	unitsPendingOriginal = Integer.valueOf(bondOffering.Units_Pending__c);
        	unitsSold = Integer.valueOf(bondOffering.Units_Sold__c);
        	unitsAvailable = Integer.valueOf(bondOffering.Units_Remaining__c);
        }
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
				return toUpsert || toDelete;
			}
		}
		
		public Boolean isNew {get;set;}
		
		public bondBuySelectionWrapper (Bond_Buy__c bondBuyIn, Boolean selectedIn, Boolean isNewIn) {
			bondBuy = bondBuyIn;
			selected = selectedIn;
			isNew = isNewIn;
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