/**
 * Controller class that handles the behaviour of the page BondOfferingPage
 */
public with sharing class BondOfferingPageControllerExtension {
	
	//Main bond offering object
	private Bond_Offering__c bondOffering;
	
	//Describes to get object labels
	private String bondOfferingLabel = Bond_Offering__c.sObjectType.getDescribe().getLabel();
    private String investorLabel = Investor__c.sObjectType.getDescribe().getLabel();
    private String investorPluralLabel = Investor__c.sObjectType.getDescribe().getLabelPlural();
    private String bondBuyLabel = Bond_Buy__c.sObjectType.getDescribe().getLabel();
	
	//Units related properties
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
	
	//Filter properties
	public String selectedFilter {
		get;
		set {
			if (String.isBlank(selectedFilter))
				previousSelectedFilter = Label.InvestorTypeFilterDefault;
			previousSelectedFilter = selectedFilter;
			selectedFilter = value;
		}
	}
	public String previousSelectedFilter {get;set;}
	
	//Wrappers to display and wrappers to manage changes
	public List<bondBuySelectionWrapper> bondBuyWrapsToDisplay {get;private set;}
	private Map<Id,bondBuySelectionWrapper> wrappersChanged = new Map<Id,bondBuySelectionWrapper>();
	
	//Custom Settings
	public Map<String, ConfigSettings__c> configSettings = ConfigSettings__c.getAll();
	
	//Pagination properties
	public Integer pageNumber {get;set;}
	public Integer defaultPageSize {
		get {
			return 5;
		}
	}
	//If the custom setting is in place, use the pageSize IntValue field for the page size. This is used to change the page size easily if needed
	public Integer pageSize {
		get{
			if (configSettings.containsKey('pageSize'))
				return Integer.valueOf(configSettings.get('pageSize').IntValue__c);
			else
				return defaultPageSize;
		}	
	}
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
	public Integer investorCount {get;set;}
	public Integer investorCountOver {get;set;}
	
	//Booleans for managing page
	public boolean errorShown {
		get {
			if (errorShown == null)
				errorShown = false;
			return errorShown;
		}
		set;
	}
	private Boolean isNewOffering = true;
	
	//Controllers
	private ApexPages.StandardController controller;
	public ApexPages.StandardSetController investorSetController {get;set;}
	
	//Static variable shared by trigger
	public static Boolean DMLerrors {
    	get {
    		if (DMLerrors == null)
    			DMLerrors = false;
    		return DMLerrors;
    	}
		set;
    }
    
    //Limits
    public Integer queryLocatorLimit {
    	get {
    		return Limits.getLimitQueryLocatorRows();
    	}
    }
    
    //Labels
    public String displayingRecordsMessage {
    	get {
    		return String.format(Label.DisplayingRecordsMessage, new List<String>{String.valueOf(bondBuyWrapsToDisplay.size()), String.valueOf(investorCount)});
    	}
    }
    public String tooManyInvestorsWarning {
    	get {
    		return String.format(Label.TooManyInvestorsWarning, new List<String>{String.valueOf(investorCountOver), investorPluralLabel, String.valueOf(queryLocatorLimit)});
    	}
    }
    public String pageNumberOfTotalLabel {
    	get {
    		return String.format(Label.pageNumberOfTotal, new List<String>{String.valueOf(pageNumber), String.valueOf(totalPages)});
    	}
    }
    public String bondOfferingBuilderLabel {
    	get {
    		return String.format(Label.BondOfferingBuilder, new List<String>{bondOfferingLabel});
    	}
    }
    public String bondOfferingDetailsLabel {
    	get {
    		return String.format(Label.BondOfferingDetails, new List<String>{bondOfferingLabel});
    	}
    }
    public String bondOfferingProgressLabel {
    	get {
    		return String.format(Label.BondOfferingProgress, new List<String>{bondOfferingLabel});
    	}
    }
    public String investorTypeFilterLabel {
    	get {
    		return String.format(Label.InvestorTypeFilter, new List<String>{investorLabel});
    	}
    }
	public String subTitle {
		get {
			if (bondOffering.Id == null)
				subtitle = String.format(Label.NewOfferingSubtitle, new List<String>{bondOfferingLabel});
			else
				subtitle = bondOffering.Name;
			return subtitle;
		}
		private set;
	}
    
    //Constructor that initialises units' properties and gets the wrappers to display when the page is first loaded
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
		selectedFilter = Label.InvestorTypeFilterDefault;
        getBondBuySelectionWrapperList(false);
    }
	
	//Method that returns a list of select options built from the Picklist values of the Type field in Investor__c.
	public List<SelectOption> getInvestorTypeFilter()
	{
		List<SelectOption> options = new List<SelectOption>();
		//Create default value to choose
		options.add(new SelectOption(Label.InvestorTypeFilterDefault, Label.InvestorTypeFilterDefault));
		Schema.DescribeFieldResult investorTypeFieldDescribe = Investor__c.Type__c.getDescribe();
		List<Schema.PicklistEntry> investorTypePicklistValues = investorTypeFieldDescribe.getPicklistValues();      
		for( Schema.PicklistEntry investorTypePicklistValue : investorTypePicklistValues)
		{
			options.add(new SelectOption(investorTypePicklistValue.getLabel(), investorTypePicklistValue.getValue()));
		}       
		return options;
	}
	
	//Method that sets an error as a message in the page and sets the boolean value to display it
	private void setError(String error) {
		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, error);
        ApexPages.addMessage(myMsg);
        errorShown = true;
        selectedFilter = previousSelectedFilter;
	}
	
	//Method that validates that all units presented have a valid number in them
	private Boolean allUnitsValid () {
		Boolean allValid = true;
		String errorCause = '';
		for (bondBuySelectionWrapper wrap : bondBuyWrapsToDisplay) {
			if (String.isBlank(wrap.units) || !wrap.units.isNumeric()) {
				allValid = false;
				errorCause = wrap.bondBuy.Investor__r.Name;
				break;
			}
		}
		
		//If at least one of the units have an invalid value, build the message showing the investor row where the error happened
		if (!allValid)
			setError(String.format(Label.InvalidUnitsMessage, new List<String>{investorPluralLabel, investorLabel, errorCause}));
		return allValid;
	}
	
	//Method that store the wrappers that have changed into the controlling map, to keep the information whithin the page
	private void storeSelected() {
		for (bondBuySelectionWrapper wrapDisplayed : bondBuyWrapsToDisplay) {
			if (wrapDisplayed.hasChanged) {
				wrappersChanged.put(wrapDisplayed.bondBuy.Investor__c, wrapDisplayed);
			}
			//If the wrapper is New and was selected previously and deselected again, it gets removed from the map
			if (!wrapDisplayed.selected && wrapDisplayed.bondBuy.Status__c == Label.NewStatus && wrappersChanged.containsKey(wrapDisplayed.bondBuy.Investor__c))
				wrappersChanged.remove(wrapDisplayed.bondBuy.Investor__c);
		}
	}
	
	/**
	 * Method that updates the stats for pending units displayed in the page. The units sold and remaining aren't
	 * changed by this method because there's no way in the page to update status of a bond buy to Purchased
	 */
	private void updateStats() {
		Integer unitsPendingChange = 0;
		//Loop through all the wrappers, get the difference in the units pending and add it to the original values (substract if it's negative)
		for (bondBuySelectionWrapper wrapperChanged : wrappersChanged.values()) {
			if (wrapperChanged.selected) {
				if (wrapperChanged.bondBuy.Status__c == Label.NewStatus)
					unitsPendingChange += Integer.valueOf(wrapperChanged.units);
				else
					unitsPendingChange += (Integer.valueOf(wrapperChanged.units) - Integer.valueOf(wrapperChanged.bondBuy.Units__c));
			}
			else
				unitsPendingChange -= Integer.valueOf(wrapperChanged.bondBuy.Units__c);
		}
		unitsPending = unitsPendingOriginal + unitsPendingChange;
	}
	
	//Method thatpopulates the wrappers to display in the page
	private void processBondBuyWrappersToDisplay(List<Investor__c> tempInvestors) {
		bondBuyWrapsToDisplay = new List<bondBuySelectionWrapper>();
		bondBuySelectionWrapper tempWrapper;
		pageNumber = investorSetController.getPageNumber();
		//Loop through the investors
		for (Investor__c tempInvestor : tempInvestors) {
			//Check if they exist in the controlling map to choose them
			if (wrappersChanged.containsKey(tempInvestor.Id)) 
				tempWrapper = wrappersChanged.get(tempInvestor.Id);
			else {
				//If the investor doesn't have an associated bond buy for this offering, create a new wrapper with default information
				if (tempInvestor.Bond_Buys__r == null || tempInvestor.Bond_Buys__r.isEmpty())
					tempWrapper = new bondBuySelectionWrapper(new Bond_Buy__c(Status__c = Label.NewStatus, Units__c = tempInvestor.Default_Bond_Units__c, Investor__r = tempInvestor, Investor__c = tempInvestor.Id), false, true);
				else
					//Create the new wrapper with info for the related bond buy. It's assumed that every investor has one bond buy for every bond offering at most, as per the requirements.
					tempWrapper = new bondBuySelectionWrapper(tempInvestor.Bond_Buys__r[0], true, false);
			}
			bondBuyWrapsToDisplay.add(tempWrapper);
		}
	}
	
	/**
	 * Method that prepares the Standard set controller with the selected filter. It sets the standard controller for the 
	 * Investor__c object, to get the proper pagination functionalities.
	 * 
	 * This assumes that there aren't more than 10000 investors for any given filter, as it's stated in the requirements for data volumes.
	 * In case of having more than 10000 investors in the system for the filter, the page will display a warning and work with the first
	 * 10000. This limit is enforced by the Database.QueryLocator, that takes up to 10000 records (outside of batch classes).
	 * Normally, this will happen for the '--Any Type--' filter, in case there's more than 10000 records. But when you move through the filters
	 * you'll be able to get them all (as long as there aren't more than 10000 investors of every type).
	 * 
	 * This method is developed in a way that if this limit is changed, the page will function up to the enforced limit, getting it
	 * dynamically with the Limist class.
	 */
	private void getBondBuySelectionWrapperList(Boolean isRollBack) {
		List<Investor__c> tempInvestors = new List<Investor__c>();
		//Prepare query for Set Controller
		String soqlQueryInvestors = 'Select Name, Type__c, Default_Bond_Units__c';
		String whereClause = '';
		if(bondOffering.Id != null)
			soqlQueryInvestors += ', (Select Units__c, Status__c, Investor__r.Name, Investor__r.Type__c from Bond_Buys__r where Bond_Offering__c = \'' + bondOffering.Id + '\' Limit 1)';
		if (selectedFilter != Label.InvestorTypeFilterDefault && !String.isBlank(selectedFilter))
			whereClause += 'where Type__c = :selectedFilter';
		
		//Set where (if filtered) and set dynamic limit
		soqlQueryInvestors += ' from Investor__c ' + whereClause + ' order by Name Asc limit ' + String.valueOf(queryLocatorLimit);

		try {
			//Get set controller for the query built previously and populate all its properties
			investorSetController = new ApexPages.StandardSetController(Database.getQueryLocator(soqlQueryInvestors));
			investorSetController.setPageSize(pageSize);
			//Stay in the same page if rolling back errors, going to the first page if filtering
			if (isRollBack)
				investorSetController.setPageNumber(pageNumber);
			else
				investorSetController.first();
			tempInvestors = investorSetController.getRecords();
			bondBuyWrapsToDisplay = new List<bondBuySelectionWrapper>();
			investorCount = investorSetController.getResultSize();
			//In case of working up to the queryLoactor limit, get the actual count of investors for the warning
			if (investorCount == queryLocatorLimit)
				investorCountOver = Database.countQuery('Select count() from Investor__c ' + whereClause);
			else
				investorCountOver = investorCount;
			processBondBuyWrappersToDisplay(tempInvestors);
		}
		catch (Exception ex) {
			//Handle and display any unexpected error in a friendly way.
			setError(String.format(Label.ErrorLoadingInvestors, new List<String>{investorLabel, ex.getMessage()}));
		}
	}

	/**
	 * Method that handles the changes on the selected filter. It stores the changed wrappers, 
	 * updates stats and builds the Set controller for the new filter.
	 */
	public PageReference refreshBondBuys() {
		if (allUnitsValid()) {
			storeSelected();
			updateStats();
			getBondBuySelectionWrapperList(false);
		}
		return null;
	}
	
	/**
	 * Method that handles the button that goes to the first page. It stores the changed wrappers, 
	 * updates stats and updates the wrappers displayed to those on the first page
	 */
	public PageReference firstPage() {
		if (allUnitsValid()) {
			storeSelected();
			updateStats();
			investorSetController.first();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	/**
	 * Method that handles the button that goes to the previous page. It stores the changed wrappers, 
	 * updates stats and updates the wrappers displayed to those on the previous page.
	 */
	public PageReference previousPage() {
		if (allUnitsValid()) {
			storeSelected();
			updateStats();
			investorSetController.previous();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	/**
	 * Method that handles the button that goes to the next page. It stores the changed wrappers, 
	 * updates stats and updates the wrappers displayed to those on the next page.
	 */
	public PageReference nextPage() {
		if (allUnitsValid()) {
			storeSelected();
			updateStats();
			investorSetController.next();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	/**
	 * Method that handles the button that goes to the last page. It stores the changed wrappers, 
	 * updates stats and updates the wrappers displayed to those on the last page.
	 */
	public PageReference lastPage() {
		if (allUnitsValid()) {
			storeSelected();
			updateStats();
			investorSetController.last();
			processBondBuyWrappersToDisplay(investorSetController.getRecords());
		}
		return null;
	}
	
	//Method that performs the DML actions to save the changed wrappers
	private Set<Id> saveBondBuys(Id newOfferId) {
		//Initialise lists
		List<bondBuySelectionWrapper> finalwrapperList = wrappersChanged.values();
		List<Bond_Buy__c> bondBuyListToInsert = new List<Bond_Buy__c>();
		List<Bond_Buy__c> bondBuyListToUpdate = new List<Bond_Buy__c>();
		List<Bond_Buy__c> bondBuyListToDelete = new List<Bond_Buy__c>();
		Set<Id> relatedBondBuys = new Set<Id>();
		for (bondBuySelectionWrapper wrapper : finalwrapperList) {
			//If the wrapper needs to be upserted, populate the proper values and add to correct list
			if (wrapper.toUpsert) {
				if (wrapper.bondBuy.Status__c == Label.NewStatus)
					wrapper.bondBuy.Status__c = Label.PendingStatus;
				wrapper.bondBuy.Bond_Offering__c = newOfferId;
				wrapper.bondBuy.Units__c = Double.valueOf(wrapper.units);
				if (wrapper.bondBuy.Id != null) {
					relatedBondBuys.add(wrapper.bondBuy.Id);
					bondBuyListToUpdate.add(wrapper.bondBuy);
				}
				else
					bondBuyListToInsert.add(wrapper.bondBuy);
			}
			//If the wrapper needs to be deleted, add to proper list
			if (wrapper.toDelete)
				bondBuyListToDelete.add(wrapper.bondBuy);
		}
		
		//Clear all errors prior to processing
		errorShown = false;
		
		//Try all DML operations and handle any exception to update flag for error and rollback
		//First delete, then update and then insert new values, this order is meant to minimise unit errors
		try {
			delete bondBuyListToDelete;
		}
		catch (Exception ex) {
			errorShown = true;
			if (!ApexPages.hasMessages())
				setError(Label.UnexpectedErrorMessage);
		}
		try {
			update bondBuyListToUpdate;
		}
		catch (Exception ex) {
			errorShown = true;
			if (!ApexPages.hasMessages())
				setError(Label.UnexpectedErrorMessage);
		}
		
		try {
			insert bondBuyListToInsert;
		}
		catch (Exception ex) {
			errorShown = true;
			if (!ApexPages.hasMessages())	
				setError(Label.UnexpectedErrorMessage);
		}
		
		//Return a set of Ids from bond buys that already existed, in case they need to be rolled back in the wrapper
		return relatedBondBuys;
	}

	//Method that overrides the standard save() method, making it work for the specific functionalities for the page.
	public PageReference save() {
		//Validate all units
		if (!allUnitsValid())
	        return null;
	    storeSelected();
	    
	    /**
	     * Get the latest field values from the database for aggregates, to have them in case of rollback.
	     * This will help if outside the page a change is made to the units pending and sold. This way the error
	     * will be in line with the stats displayed.
	     */
	    if (!isNewOffering)
        	bondOffering = [Select Units_Pending__c, Units_Sold__c, Units_Remaining__c from Bond_Offering__c where Id = :bondOffering.Id];
        else
        	bondOffering.Client__c = ((Bond_Offering__c) controller.getRecord()).Client__c;
        
        //Get latest info from the page controller
	    bondOffering.Name = ((Bond_Offering__c) controller.getRecord()).Name;
	    bondOffering.Interest_Rate__c = ((Bond_Offering__c) controller.getRecord()).Interest_Rate__c;
	    bondOffering.Sales_Rep__c = ((Bond_Offering__c) controller.getRecord()).Sales_Rep__c;
        
        //Stablish a Savepoint in case of rollback	
	    Savepoint sp = Database.setSavepoint();

		//Upsert bondOffering values, set the pagereference to go to the newly created/updated bond offering and perform DML operations for the bond buys.
	    upsert bondOffering;
		PageReference result = new PageReference('/' + bondOffering.Id);
		Id newOfferId = bondOffering.Id;
		Set<Id> relatedBondBuys = saveBondBuys(newOfferId);
		
		//In case of an error, perform a rollback to the savepoint previously created, rollback wrappers, clear Ids, update stats and refresh the page being displayed.
		if (errorShown || DMLerrors) {
			Database.rollback(sp);
			rollBackWrappers(relatedBondBuys);
			if (isNewOffering)
				bondOffering = new Bond_Offering__c(Id = null, Name = bondOffering.Name, Client__c = bondOffering.Client__c, Interest_Rate__c = bondOffering.Interest_Rate__c, Sales_Rep__c = bondOffering.Sales_Rep__c);
			getBondBuySelectionWrapperList(true);	
			updateStats();
			return null;
		}
		//If all goes well, go to the detail page
		return result;
	}
	
	//Method that performs a rollback all the wrappers that had been changed, in case of an error
	private void rollBackWrappers(Set<Id> relatedBondBuys) {
		Bond_Buy__c tempBondBuy;
		//Initialise a map of the wrappers that contained existing bond buys
		Map<Id, Bond_Buy__c> bondBuysMap = new Map<Id, Bond_Buy__c>([Select Units__c from Bond_Buy__c where Id in :relatedBondBuys]);
		for (bondBuySelectionWrapper wrapper : wrappersChanged.values()) {
			//Clear Ids and set default status for new wrappers
			if (wrapper.bondBuy.Id == null || wrapper.isNew) {
				tempBondBuy = new Bond_Buy__c(Status__c = Label.NewStatus, Units__c = Double.valueOf(wrapper.units), Investor__r = wrapper.bondBuy.Investor__r, Investor__c = wrapper.bondBuy.Investor__c);
				wrapper.bondBuy = tempBondBuy;
			}
			else {
				//For wrappers that contain existing bond buys, set the units for the related bond buy record to it's original value 
				//to rollback the change made, leaving the units property from the wrapper without rollback.
				if (bondBuysMap.containsKey(wrapper.bondBuy.Id))
					wrapper.bondBuy.Units__c = bondBuysMap.get(wrapper.bondBuy.Id).Units__c;
			}
		}
		
		//If the page is editing an existing offering, update the original units properties for the stats to be updated afterwards.
		if (!isNewOffering) {
        	unitsPendingOriginal = Integer.valueOf(bondOffering.Units_Pending__c);
        	unitsSold = Integer.valueOf(bondOffering.Units_Sold__c);
        	unitsAvailable = Integer.valueOf(bondOffering.Units_Remaining__c);
        }
	}
	
	//Wrapper class to handle the creation of bond buy records related to the offering from the page and to any existing investor.
	public class bondBuySelectionWrapper implements Comparable{
		//Properties to populate
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
		//Properties for monitoring changes
		public Boolean readOnly {
			get {
				if (bondBuy != null)
					readOnly = bondBuy.Status__c != Label.PendingStatus && bondBuy.Status__c != Label.NewStatus;
				return readOnly;
			}
			private set;
		}
		public Boolean toUpsert {
			get {
				if (bondBuy.Status__c == Label.PendingStatus && selected) 
					return Integer.valueOf(units) != bondBuy.Units__c;
				return selected && !readOnly;
			}
		}
		public Boolean toDelete {
			get {
				return !selected && bondBuy.Status__c != Label.NewStatus;
			}
		}
		public Boolean hasChanged {
			get {
				return toUpsert || toDelete;
			}
		}
		public Boolean isNew {get;set;}
		
		//Constructor
		public bondBuySelectionWrapper (Bond_Buy__c bondBuyIn, Boolean selectedIn, Boolean isNewIn) {
			bondBuy = bondBuyIn;
			selected = selectedIn;
			isNew = isNewIn;
		}
		
		//Method implemented from the Comparable interface, if any sorting of lists of wrappers is needed
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