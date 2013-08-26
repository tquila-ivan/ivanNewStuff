@isTest
public class generateTestData {
	private static List<Schema.PicklistEntry> investorTypePicklistValues = Investor__c.Type__c.getDescribe().getPicklistValues();

	/**
	 * Gets a random integer number between lower (inclusive) and upper (exclusive)
	 */
	public static Integer getRandomInt (Integer lower, Integer upper)
	{
		return Math.round((Math.random() * (upper - lower)) + lower);
	}

	public static String getRandomName() {
		return EncodingUtil.convertToHex(crypto.generateAesKey(128)).substring(1,20);
	}

	public static Investor__c getInvestor() {
		Investor__c investor = new Investor__c();
		investor.Name = getRandomName();
		investor.Type__c = investorTypePicklistValues.get(getRandomInt(0, 3)).getValue();
		investor.Bonds_Pitched__c = 0;
		investor.Bonds_Purchased__c = 0;
		return investor;
	}
	
	public static Investor__c getInvestor(String Type) {
		Investor__c investor = new Investor__c();
		investor.Name = getRandomName();
		investor.Type__c = Type;
		investor.Bonds_Pitched__c = 0;
		investor.Bonds_Purchased__c = 0;
		return investor;
	}
	
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

	public static Client__c getClient() {
		return new Client__c(Name = getRandomName());
	}

	public static Bond_Buy__c getBondBuy(String bondOfferingId, String investorId, String status, Double units) {
		Bond_Buy__c bondBuy = new Bond_Buy__c();
		bondBuy.Bond_Offering__c = bondOfferingId;
		bondBuy.Investor__c = investorId;
		bondBuy.Status__c = status;
		bondBuy.Units__c = units;
		return bondBuy;
	}

	public static List<sObject> getMultipleObjects(Map<String, Object> parameters, Schema.SObjectType objectType, Integer quantity) {
		List<sObject> result = new List<sObject>();
		sObject tempObject;
		for (Integer i = 0; i < quantity; i++) {
			if (objectType == Bond_Buy__c.getSObjectType())
				tempObject = getBondBuy((String)parameters.get('bondOfferingId'), (String)parameters.get('investorId'), (String)parameters.get('status'), (Double)parameters.get('units'));
			if (objectType == Bond_Offering__c.getSObjectType())
				tempObject = getBondOffering((String)parameters.get('clientId'), (Double)parameters.get('interestRate'), (String)parameters.get('salesRep'));
			if (objectType == Investor__c.getSObjectType()) {
				if ((String)parameters.get('investorType') == null)
					tempObject = getInvestor();
				else
					tempObject = getInvestor((String)parameters.get('investorType'));
			}
			if (objectType == Client__c.getSObjectType())
				tempObject = getClient();
			result.add(tempObject);
		}
		return result;
	}

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
}