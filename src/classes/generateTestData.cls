/**
 * Class that creates the objects for working with test data, used in all unit tests.
 * Only to be used by test classes, not available otherwise.
 */
@isTest
public class generateTestData {
	//Picklist entry list for Type field on investors
	private static List<Schema.PicklistEntry> investorTypePicklistValues = Investor__c.Type__c.getDescribe().getPicklistValues();
	//Id constants
    private static final String invalidInvestor = 'a01e0000001ZiSC';
	private static final String invalidOffering = 'a02e0000001VphL';

	//Gets a random integer number between low and high
	public static Integer getRandomInt (Integer low, Integer high)
	{
		return Math.round((Math.random() * (high - low)) + low);
	}

	//Method that returns a random string
	public static String getRandomName() {
		return EncodingUtil.convertToHex(crypto.generateAesKey(128)).substring(1,20);
	}

	//Method that returns an investor sObject populated with a random Type
	public static Investor__c getInvestor() {
		Investor__c investor = new Investor__c();
		investor.Name = getRandomName();
		investor.Type__c = investorTypePicklistValues.get(getRandomInt(0, 3)).getValue();
		investor.Bonds_Pitched__c = 0;
		investor.Bonds_Purchased__c = 0;
		return investor;
	}
	
	//Method that returns an investor sObject populated with a specific Type
	public static Investor__c getInvestor(String Type) {
		Investor__c investor = new Investor__c();
		investor.Name = getRandomName();
		investor.Type__c = Type;
		investor.Bonds_Pitched__c = 0;
		investor.Bonds_Purchased__c = 0;
		return investor;
	}
	
	//Method that returns a Bond Offering sObject populated with the parameters received
	public static Bond_Offering__c getBondOffering(String clientId, Double interestRate, String salesRep) {
		Bond_Offering__c bondOffering = new Bond_Offering__c();
		bondOffering.Client__c = clientId;
		bondOffering.Name = getRandomName();
		bondOffering.Interest_Rate__c = interestRate;
		bondOffering.Sales_Rep__c = salesRep;
		bondOffering.Units_Pending__c = 0;
		bondOffering.Units_Sold__c = 0;
		return bondOffering;
	}

	//Method that constructs a new Client sObject
	public static Client__c getClient() {
		return new Client__c(Name = getRandomName());
	}

	//Method that returns a Bond Buy sObject populated with the parameters received
	public static Bond_Buy__c getBondBuy(String bondOfferingId, String investorId, String status, Double units) {
		Bond_Buy__c bondBuy = new Bond_Buy__c();
		bondBuy.Bond_Offering__c = bondOfferingId;
		bondBuy.Investor__c = investorId;
		bondBuy.Status__c = status;
		bondBuy.Units__c = units;
		return bondBuy;
	}

	//Method that generates lists of all of the sObjects in this class dynamically, depending on the parameters received. 
	public static List<sObject> getMultipleObjects(Map<String, Object> parameters, Schema.SObjectType objectType, Integer quantity) {
		List<sObject> result = new List<sObject>();
		sObject tempObject;
		for (Integer i = 0; i < quantity; i++) {
			//Bond Buy
			if (objectType == Bond_Buy__c.getSObjectType())
				tempObject = getBondBuy((String)parameters.get('bondOfferingId'), (String)parameters.get('investorId'), (String)parameters.get('status'), (Double)parameters.get('units'));
			//Bond Offering
			if (objectType == Bond_Offering__c.getSObjectType())
				tempObject = getBondOffering((String)parameters.get('clientId'), (Double)parameters.get('interestRate'), (String)parameters.get('salesRep'));
			//Investor
			if (objectType == Investor__c.getSObjectType()) {
				if ((String)parameters.get('investorType') == null)
					tempObject = getInvestor();
				else
					tempObject = getInvestor((String)parameters.get('investorType'));
			}
			//Client
			if (objectType == Client__c.getSObjectType())
				tempObject = getClient();
			result.add(tempObject);
		}
		return result;
	}

	//Method that returns a new user sObject with a profile specified as a parameter
	public static User getTestUser(String profile) {
        Map<String,ID> profiles = new Map<String,String>();
        List<Profile> ps = [select id, name from Profile where name = :profile];
        for(Profile p : ps){
            profiles.put(p.name, p.id);
        }
        User returnUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName=getRandomName(), LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = profiles.get(profile), 
                TimeZoneSidKey='America/Los_Angeles', UserName=getRandomName() + '@cert501.ivan');

        return returnUser;
    }
    
    //Method that shares manually a client with a user, to provide visibility to test methods run as specific users
    public static void shareClient(Id userId, Id clientId) {
    	Client__share clientShare = new Client__share();
		clientShare.ParentId = clientId;
		clientShare.UserOrGroupId = userId;
		clientShare.AccessLevel= 'Edit';
		Database.SaveResult sr = Database.insert(clientShare,false);
		System.assert(sr.isSuccess());
    }
    
    //Method that prepares the parameters map for Bond Buy records to be created
	public static Map<String, Object> prepareBondBuyParameters(Boolean investorError, Boolean bondOfferingError, Id bondOfferingId, Id investorId, String status, Integer units) {
		Map<String, Object> parameters = new Map<String, Object>();
		if (bondOfferingError || investorError) {
			//Put invalid ids whenever the case
			if (bondOfferingError)
				parameters.put('bondOfferingId', invalidOffering);
			if (investorError)
				parameters.put('investorId', invalidInvestor);
		}
		else {
			//Put valid Ids
			parameters.put('bondOfferingId', bondOfferingId);
			parameters.put('investorId', investorId);
		}
		parameters.put('units', units);
		parameters.put('status', status);
		return parameters;
	}
}