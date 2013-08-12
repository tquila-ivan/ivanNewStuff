public with sharing class bondBuyTriggerHandler {

	private Boolean isExecuting = false;
    private Integer BatchSize = 0;
    private List<Bond_Buy__c> bondBuyList = new List<Bond_Buy__c>();
    private Map<Id,Bond_Offering__c> oldOfferingMap = new Map<Id,Bond_Offering__c>();
    private Map<Id,Investor__c> oldInvestorMap = new Map<Id,Investor__c>();
    
    private Map<Id,Investor__c> investorMap = new Map<Id,Investor__c>();
    private Map<Id, Bond_Offering__c> bondOfferingMap = new Map<Id, Bond_Offering__c>();
    
    // CONSTRUCTOR
    public bondBuyTriggerHandler(Boolean isExecuting, Integer size){
        isExecuting = isExecuting;
        BatchSize = size;
    }
    
    //AFTER INSERT
    public void bondBuyAfterInsert(List<Bond_Buy__c> bondBuyListIn) {
    	
    	bondBuyListFilter(bondBuyListIn, null);
    	
    	Bond_Offering__c bondOffering = new Bond_Offering__c();
    	Map<Id, Bond_Offering__c> bondOfferingMap = new Map<Id, Bond_Offering__c>();
    	Investor__c investor = new Investor__c();
    	Map<Id, Investor__c> investorMap = new Map<Id, Investor__c>();
    	
    	for (Bond_Buy__c bondBuy : bondBuyList) {
    		
    		bondOffering = new Bond_Offering__c(Id = bondBuy.Bond_Offering__c);
    		investor = new Investor__c(Id = bondBuy.Investor__c);
    		
    		if (investorMap.containsKey(investor.Id))
				investor = investorMap.get(investor.Id);
			else {
				investor.Bonds_Pitched__c = bondBuy.Investor__r.Bonds_Pitched__c;
				investor.Bonds_Purchased__c = bondBuy.Investor__r.Bonds_Purchased__c;
			}
			
			if (bondOfferingMap.containsKey(bondOffering.Id))
				bondOffering = bondOfferingMap.get(bondOffering.Id);
			else {
				bondOffering.Units_Pending__c = bondBuy.Bond_Offering__r.Units_Pending__c;
				bondOffering.Units_Sold__c = bondBuy.Bond_Offering__r.Units_Sold__c;
			}
    		
    		if (bondBuy.Status__c == 'Pending') 
    			bondOffering.Units_Pending__c += bondBuy.Units__c;
    		if (bondBuy.Status__c == 'Purchased') {
    			bondOffering.Units_Sold__c +=  bondBuy.Units__c;
    			investor.Bonds_Purchased__c ++;
    		}
    		
    		investor.Bonds_Pitched__c ++;
    		
    		bondOfferingMap.put(bondOffering.Id, bondOffering);	
    		investorMap.put(investor.Id, investor);
    	}
    	
    	update bondOfferingMap.values();
    	update investorMap.values();
    }
    
    public void bondBuyAfterUpdate(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyOldMap) {
    	
    	bondBuyListFilter(bondBuyListIn, bondBuyOldMap);
    	
    	Bond_Offering__c bondOffering = new Bond_Offering__c();
    	Investor__c investor = new Investor__c();
    	
    	Boolean offeringChanged;
    	Boolean investorChanged;
    	Boolean statusChanged;
    	Boolean unitsChanged;
    	Boolean investorAdded = false;
    	
    	Bond_Buy__c oldBondBuy = new Bond_Buy__c();
    	Bond_Offering__c oldOffering = new Bond_Offering__c();
    	Investor__c oldInvestor = new Investor__c();
    	
    	for (Bond_Buy__c bondBuy : bondBuyList) {

    		oldBondBuy = bondBuyOldMap.get(bondBuy.Id);
			
			offeringChanged = bondBuy.Bond_Offering__c != oldBondBuy.Bond_Offering__c;
			investorChanged = bondBuy.Investor__c != oldBondBuy.Investor__c;
			statusChanged = bondBuy.Status__c != oldBondBuy.Status__c;
			unitsChanged = bondBuy.Units__c != oldBondBuy.Units__c;
			
			bondOffering = new Bond_Offering__c(Id = bondBuy.Bond_Offering__c);
			investor = new Investor__c(Id = bondBuy.Investor__c);
			oldInvestor = oldInvestorMap.get(bondBuy.Id);
			oldOffering = oldOfferingMap.get(bondBuy.Id);
			
			if (oldInvestor != null) {
				if (investorMap.containsKey(oldInvestor.Id))
					oldInvestor = investorMap.get(oldInvestor.Id);
			}
			
			if (investorMap.containsKey(investor.Id))
				investor = investorMap.get(investor.Id);
			else {
				investor.Bonds_Pitched__c = bondBuy.Investor__r.Bonds_Pitched__c;
				investor.Bonds_Purchased__c = bondBuy.Investor__r.Bonds_Purchased__c;
			}
				
			if (oldOffering != null) {
				if (bondOfferingMap.containsKey(oldOffering.Id))
					oldOffering = bondOfferingMap.get(oldOffering.Id);
			}	
			
			if (bondOfferingMap.containsKey(bondOffering.Id))
				bondOffering = bondOfferingMap.get(bondOffering.Id);
			else {
				bondOffering.Units_Pending__c = bondBuy.Bond_Offering__r.Units_Pending__c;
				bondOffering.Units_Sold__c = bondBuy.Bond_Offering__r.Units_Sold__c;
			}
				
					
			if (investorChanged) {
				oldInvestor.Bonds_Pitched__c = oldInvestor.Bonds_Pitched__c - 1;
				if (oldBondBuy.Status__c == 'Purchased')
					oldInvestor.Bonds_Purchased__c = oldInvestor.Bonds_Purchased__c - 1;
				investorMap.put(oldInvestor.Id, oldInvestor);
				
				investor.Bonds_Pitched__c = investor.Bonds_Pitched__c + 1;
				if (bondBuy.Status__c == 'Purchased')
					investor.Bonds_Purchased__c = investor.Bonds_Purchased__c + 1;
			}
			
			if (statusChanged) {
				if (oldBondBuy.Status__c == 'Pending') {
		    		if (bondBuy.Status__c == 'Passed') {
		    			if (offeringChanged) {	
		    				oldOffering.Units_Pending__c = oldOffering.Units_Pending__c - oldBondBuy.Units__c;
		    				bondOfferingMap.put(oldOffering.Id, oldOffering);
		    			}
		    			else {
		    				bondOffering.Units_Pending__c -= oldBondBuy.Units__c;
		    				bondOfferingMap.put(bondOffering.Id, bondOffering);
		    			}
		    		}
		    		else if (bondBuy.Status__c == 'Purchased') {
		    			if (!investorChanged) {
			    			investor.Bonds_Purchased__c ++;
			    			investorMap.put(investor.Id, investor);
			    			investorAdded = true;
		    			}
	    				bondOffering.Units_Sold__c += bondBuy.Units__c;
		    				
		    			if (offeringChanged) {
		    				oldOffering.Units_Pending__c -= oldBondBuy.Units__c;
		    				bondOfferingMap.put(oldOffering.Id, oldOffering);
		    			}
		    			else {
		    				bondOffering.Units_Pending__c -= oldBondBuy.Units__c;
		    			}
		    			bondOfferingMap.put(bondOffering.Id, bondOffering);
		    		}
				}
				else if (oldBondBuy.Status__c == 'Passed') {
					if (bondBuy.Status__c == 'Pending') {
						bondOffering.Units_Pending__c += bondBuy.Units__c;
						bondOfferingMap.put(bondOffering.Id, bondOffering);
					}
		    		else if (bondBuy.Status__c == 'Purchased') {
		    			
		    			if (!investorChanged) {
		    				investor.Bonds_Purchased__c ++;
		    				investorMap.put(investor.Id, investor);
		    				investorAdded = true;
		    			}
		    			bondOffering.Units_Sold__c += bondBuy.Units__c;
		    			bondOfferingMap.put(bondOffering.Id, bondOffering);
		    		}
				}
				else if (oldBondBuy.Status__c == 'Purchased') {
					if (!investorChanged) {
						investor.Bonds_Purchased__c --;
			    		investorMap.put(investor.Id, investor);
			    		investorAdded = true;
					}
		    		
					if (bondBuy.Status__c == 'Pending') {
						bondOffering.Units_Pending__c += bondBuy.Units__c;
						if (offeringChanged) {
							oldOffering.Units_Sold__c -= oldBondBuy.Units__c;
							bondOfferingMap.put(oldOffering.Id, oldOffering);
						}
						else {
							bondOffering.Units_Sold__c -= oldBondBuy.Units__c;
						}
						bondOfferingMap.put(bondOffering.Id, bondOffering);
					}
					else if (bondBuy.Status__c == 'Passed') {
						if (offeringChanged) {
							oldOffering.Units_Sold__c -= oldBondBuy.Units__c;
							bondOfferingMap.put(oldOffering.Id, oldOffering);
						}
						else {
							bondOffering.Units_Sold__c -= oldBondBuy.Units__c;
							bondOfferingMap.put(bondOffering.Id, bondOffering);
						}
					}
				}
			}
			else {
				if (offeringChanged) {
					if (bondBuy.Status__c == 'Pending') {
						oldOffering.Units_Pending__c -= oldBondBuy.Units__c;
						bondOfferingMap.put(oldOffering.id, oldOffering);
						
						bondOffering.Units_Pending__c += bondBuy.Units__c;
					}
					else if (bondBuy.Status__c == 'Purchased') {
						oldOffering.Units_Sold__c -= oldBondBuy.Units__c;
						bondOfferingMap.put(oldOffering.id, oldOffering);
						
						bondOffering.Units_Sold__c += bondBuy.Units__c;
					}
					bondOfferingMap.put(bondOffering.Id, bondOffering);
				}
				else if (unitsChanged) {
					if (bondBuy.Status__c == 'Pending') {
						bondOffering.Units_Pending__c -= oldBondBuy.Units__c;
						bondOffering.Units_Pending__c += bondBuy.Units__c;
					}
					else if (bondBuy.Status__c == 'Purchased') {
						bondOffering.Units_Sold__c -= oldBondBuy.Units__c;
						bondOffering.Units_Sold__c += bondBuy.Units__c;
					}
					bondOfferingMap.put(bondOffering.Id, bondOffering);
				}
			}
    	}
    	
    	if (!investorAdded)
    		investorMap.put(investor.Id, investor);
    		
    	update bondOfferingMap.values();
    	update investorMap.values();
    }
    
    private void bondBuyListFilter(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyOldMap) {
    	Set<Id> bondBuySet = new Set<Id>();
    	
    	Map<Id, Id> oldOfferingIdMap = new Map<Id, Id>();
    	Map<Id, Id> oldInvestorIdMap = new Map<Id, Id>();
    	
    	Boolean getOld = bondBuyOldMap != null;
    	Bond_Buy__c oldBondBuy = new Bond_Buy__c();
    	
    	for (Bond_Buy__c bondBuy : bondBuyListIn) {
    		if (bondBuy.Bond_Offering__c != null && bondBuy.Investor__c != null) {
    			if (getOld) {
    				oldBondBuy = bondBuyOldMap.get(bondBuy.Id);
    				if (bondBuy.Bond_Offering__c != oldBondBuy.Bond_Offering__c)
    					oldOfferingIdMap.put(oldBondBuy.Bond_Offering__c, bondBuy.Id);
    				if (bondBuy.Investor__c != oldBondBuy.Investor__c)
    					oldInvestorIdMap.put(oldBondBuy.Investor__c, bondBuy.Id);
    			}
    			bondBuySet.add(bondBuy.Id);
    		}
    	}
    	bondBuyList = [Select Bond_Offering__c, Investor__c, Status__c, Units__c, Bond_Offering__r.Units_Pending__c, Bond_Offering__r.Units_Sold__c, Investor__r.Bonds_Pitched__c, Investor__r.Bonds_Purchased__c from Bond_Buy__c where Id in :bondBuySet];
    	
    	if (getOld) {
    		if (!oldOfferingIdMap.isEmpty()) {
	    		List<Bond_Offering__c> oldOfferingList = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id in :oldOfferingIdMap.keySet()];
	    		for (Bond_Offering__c offer : oldOfferingList) {
	    			oldOfferingMap.put(oldOfferingIdMap.get(offer.Id), offer);
	    		}
    		}
	    	if (!oldInvestorIdMap.isEmpty()) {
	    		List<Investor__c> oldInvestorList = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id in :oldInvestorIdMap.keySet()];
	    		for (Investor__c investor : oldInvestorList) {
	    			oldInvestorMap.put(oldInvestorIdMap.get(investor.Id), investor);
	    		}
	    	}
    	}
    }
}