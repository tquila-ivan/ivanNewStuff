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
    
    //AFTER INSERT - UNDELETE
    public void bondBuyAfterInsertUndelete(List<Bond_Buy__c> bondBuyListIn) {
    	
    	bondBuyListFilter(bondBuyListIn, null, false);
    	
    	Bond_Offering__c bondOffering = new Bond_Offering__c();
    	Map<Id, Bond_Offering__c> bondOfferingMap = new Map<Id, Bond_Offering__c>();
    	Investor__c investor = new Investor__c();
    	Map<Id, Investor__c> investorMap = new Map<Id, Investor__c>();
    	Boolean validInvestor = true;
    	Boolean validBondOffering = true;
    	
    	for (Bond_Buy__c bondBuy : bondBuyList) {
    		
    		validInvestor = bondBuy.Investor__c != null;
    		validBondOffering = bondBuy.Bond_Offering__c != null;
    		
    		if (validInvestor) {
    			investor = new Investor__c(Id = bondBuy.Investor__c);
	    		if (investorMap.containsKey(investor.Id))
					investor = investorMap.get(investor.Id);
				else {
					investor.Bonds_Pitched__c = bondBuy.Investor__r.Bonds_Pitched__c;
					investor.Bonds_Purchased__c = bondBuy.Investor__r.Bonds_Purchased__c;
				}
				investor.Bonds_Pitched__c ++;
    		}
			
			if (validBondOffering) {
				bondOffering = new Bond_Offering__c(Id = bondBuy.Bond_Offering__c);
				if (bondOfferingMap.containsKey(bondOffering.Id))
					bondOffering = bondOfferingMap.get(bondOffering.Id);
				else {
					bondOffering.Units_Pending__c = bondBuy.Bond_Offering__r.Units_Pending__c;
					bondOffering.Units_Sold__c = bondBuy.Bond_Offering__r.Units_Sold__c;
				}
			}
    		
    		if (bondBuy.Status__c == 'Pending') {
    			if (validBondOffering)
    				bondOffering.Units_Pending__c += bondBuy.Units__c;
    		}
    		if (bondBuy.Status__c == 'Purchased') {
    			if (validBondOffering)
    				bondOffering.Units_Sold__c +=  bondBuy.Units__c;
    			if (validInvestor)
    				investor.Bonds_Purchased__c ++;
    		}
    		
    		if (validBondOffering)
    			bondOfferingMap.put(bondOffering.Id, bondOffering);	
    		if (validInvestor)
    			investorMap.put(investor.Id, investor);
    	}

		/*List<Database.SaveResult> offeringresult = Database.update(bondOfferingMap.values(), false);
		System.debug('Trig 1: ' + offeringresult + ' ' + bondOfferingMap.size());
		for (Database.SaveResult result : offeringresult) {
			System.debug('Trig: ' + result.isSuccess() + ' ' + result.getErrors());
			if (!result.isSuccess()) {
    			for (Bond_Buy__c bondBuy : bondBuyList) {
    				System.debug('Seraaaa');
    				bondBuy.addError('Error');
    			}
			}
		}*/
    	update bondOfferingMap.values();
    	update investorMap.values();
    }
    
    public void bondBuyAfterUpdate(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyOldMap) {
    	
    	bondBuyListFilter(bondBuyListIn, bondBuyOldMap, false);
    	
    	Bond_Offering__c bondOffering = new Bond_Offering__c();
    	Investor__c investor = new Investor__c();
    	
    	Boolean offeringChanged;
    	Boolean investorChanged;
    	Boolean statusChanged;
    	Boolean unitsChanged;
    	Boolean investorAdded = false;
    	Boolean validInvestor, validOldInvestor;
    	Boolean validOffering, validOldOffering;
    	
    	Bond_Buy__c oldBondBuy = new Bond_Buy__c();
    	Bond_Offering__c oldOffering = new Bond_Offering__c();
    	Investor__c oldInvestor = new Investor__c();
    	
    	for (Bond_Buy__c bondBuy : bondBuyList) {

    		oldBondBuy = bondBuyOldMap.get(bondBuy.Id);
			validInvestor = bondBuy.Investor__c != null;
			validOldInvestor = oldBondBuy.Investor__c != null;
			validOffering = bondBuy.Bond_Offering__c != null;
			validOldOffering = oldBondBuy.Bond_Offering__c != null;
			offeringChanged = bondBuy.Bond_Offering__c != oldBondBuy.Bond_Offering__c;
			investorChanged = bondBuy.Investor__c != oldBondBuy.Investor__c;
			statusChanged = bondBuy.Status__c != oldBondBuy.Status__c;
			unitsChanged = bondBuy.Units__c != oldBondBuy.Units__c;
			
			if (validOldInvestor) {
				oldInvestor = oldInvestorMap.get(oldBondBuy.Investor__c);
				if (oldInvestor != null) {
					if (investorMap.containsKey(oldInvestor.Id))
						oldInvestor = investorMap.get(oldInvestor.Id);
				}
			}
			
			if (validInvestor) {
				investor = new Investor__c(Id = bondBuy.Investor__c);
				if (investorMap.containsKey(investor.Id))
					investor = investorMap.get(investor.Id);
				else {
					investor.Bonds_Pitched__c = bondBuy.Investor__r.Bonds_Pitched__c;
					investor.Bonds_Purchased__c = bondBuy.Investor__r.Bonds_Purchased__c;
				}
			}
			
			if (validOldOffering) {
				oldOffering = oldOfferingMap.get(oldBondBuy.Bond_Offering__c);
				if (oldOffering != null) {
					if (bondOfferingMap.containsKey(oldOffering.Id))
						oldOffering = bondOfferingMap.get(oldOffering.Id);
				}
			}
			
			if (validOffering) {
				bondOffering = new Bond_Offering__c(Id = bondBuy.Bond_Offering__c);
				if (bondOfferingMap.containsKey(bondOffering.Id))
					bondOffering = bondOfferingMap.get(bondOffering.Id);
				else {
					bondOffering.Units_Pending__c = bondBuy.Bond_Offering__r.Units_Pending__c;
					bondOffering.Units_Sold__c = bondBuy.Bond_Offering__r.Units_Sold__c;
				}
			}
					
			if (investorChanged) {
				if (validOldInvestor) {
					oldInvestor.Bonds_Pitched__c = oldInvestor.Bonds_Pitched__c - 1;
					if (oldBondBuy.Status__c == 'Purchased')
						oldInvestor.Bonds_Purchased__c = oldInvestor.Bonds_Purchased__c - 1;
					investorMap.put(oldInvestor.Id, oldInvestor);
				}
				
				if (validInvestor) {
					investor.Bonds_Pitched__c = investor.Bonds_Pitched__c + 1;
					if (bondBuy.Status__c == 'Purchased')
						investor.Bonds_Purchased__c = investor.Bonds_Purchased__c + 1;
				}
			}
			
			if (statusChanged) {
				if (oldBondBuy.Status__c == 'Pending') {
		    		if (bondBuy.Status__c == 'Passed') {
		    			if (offeringChanged) {
		    				if (validOldOffering) {
			    				oldOffering.Units_Pending__c = oldOffering.Units_Pending__c - oldBondBuy.Units__c;
			    				bondOfferingMap.put(oldOffering.Id, oldOffering);
		    				}
		    			}
		    			else {
		    				if (validOffering) {
			    				bondOffering.Units_Pending__c -= oldBondBuy.Units__c;
			    				bondOfferingMap.put(bondOffering.Id, bondOffering);
		    				}
		    			}
		    		}
		    		else if (bondBuy.Status__c == 'Purchased') {
		    			if (!investorChanged && validInvestor) {
			    			investor.Bonds_Purchased__c ++;
			    			investorMap.put(investor.Id, investor);
			    			investorAdded = true;
		    			}
	    				
		    			if (offeringChanged) {
		    				if (validOldOffering) {
			    				oldOffering.Units_Pending__c -= oldBondBuy.Units__c;
			    				bondOfferingMap.put(oldOffering.Id, oldOffering);
		    				}
		    			}
		    			else {
		    				if (validOffering)
		    					bondOffering.Units_Pending__c -= oldBondBuy.Units__c;
		    			}
		    			
		    			if (validOffering) {
			    			bondOffering.Units_Sold__c += bondBuy.Units__c;
			    			bondOfferingMap.put(bondOffering.Id, bondOffering);
		    			}
		    		}
				}
				else if (oldBondBuy.Status__c == 'Passed') {
					if (bondBuy.Status__c == 'Pending') {
						if (validOffering) {
							bondOffering.Units_Pending__c += bondBuy.Units__c;
							bondOfferingMap.put(bondOffering.Id, bondOffering);
						}
					}
		    		else if (bondBuy.Status__c == 'Purchased') {
		    			
		    			if (!investorChanged && validInvestor) {
		    				investor.Bonds_Purchased__c ++;
		    				investorMap.put(investor.Id, investor);
		    				investorAdded = true;
		    			}
		    			
		    			if(validOffering) {
			    			bondOffering.Units_Sold__c += bondBuy.Units__c;
			    			bondOfferingMap.put(bondOffering.Id, bondOffering);
		    			}
		    		}
				}
				else if (oldBondBuy.Status__c == 'Purchased') {
					if (!investorChanged && validInvestor) {
						investor.Bonds_Purchased__c --;
			    		investorMap.put(investor.Id, investor);
			    		investorAdded = true;
					}
		    		
					if (bondBuy.Status__c == 'Pending') {
						
						if (offeringChanged) {
							if (validOldOffering) {
								oldOffering.Units_Sold__c -= oldBondBuy.Units__c;
								bondOfferingMap.put(oldOffering.Id, oldOffering);
							}
						}
						else {
							if (validOffering)
								bondOffering.Units_Sold__c -= oldBondBuy.Units__c;
						}
						
						if (validOffering) {
							bondOffering.Units_Pending__c += bondBuy.Units__c;
							bondOfferingMap.put(bondOffering.Id, bondOffering);
						}
					}
					else if (bondBuy.Status__c == 'Passed') {
						if (offeringChanged) {
							if (validOldOffering) {
								oldOffering.Units_Sold__c -= oldBondBuy.Units__c;
								bondOfferingMap.put(oldOffering.Id, oldOffering);
							}
						}
						else {
							if (validOffering) {
								bondOffering.Units_Sold__c -= oldBondBuy.Units__c;
								bondOfferingMap.put(bondOffering.Id, bondOffering);
							}
						}
					}
				}
			}
			else {
				if (offeringChanged) {
					if (bondBuy.Status__c == 'Pending') {
						if (validOldOffering) {
							oldOffering.Units_Pending__c -= oldBondBuy.Units__c;
							bondOfferingMap.put(oldOffering.id, oldOffering);
						}
						if (validOffering)
							bondOffering.Units_Pending__c += bondBuy.Units__c;
					}
					else if (bondBuy.Status__c == 'Purchased') {
						if (validOldOffering) {
							oldOffering.Units_Sold__c -= oldBondBuy.Units__c;
							bondOfferingMap.put(oldOffering.id, oldOffering);
						}
						if (validOffering)
							bondOffering.Units_Sold__c += bondBuy.Units__c;
					}
					if (validOldOffering)
						bondOfferingMap.put(bondOffering.Id, bondOffering);
				}
				else if (unitsChanged && validOffering) {
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
	    	if (!investorAdded && validInvestor)
	    		investorMap.put(investor.Id, investor);
    	}
    		
    	update bondOfferingMap.values();
    	update investorMap.values();
    }
    
    public void bondBuyAfterDelete(List<Bond_Buy__c> bondBuyListIn) {
    	bondBuyListFilter(bondBuyListIn, null, true);
    	
    	Bond_Offering__c bondOffering = new Bond_Offering__c();
    	Map<Id, Bond_Offering__c> bondOfferingMap = new Map<Id, Bond_Offering__c>();
    	Investor__c investor = new Investor__c();
    	Map<Id, Investor__c> investorMap = new Map<Id, Investor__c>();
    	
    	Boolean validInvestor = true;
    	Boolean validBondOffering = true;
    	
    	for (Bond_Buy__c bondBuy : bondBuyList) {
    		
    		validInvestor = bondBuy.Investor__c != null;
    		validBondOffering = bondBuy.Bond_Offering__c != null;
    		
    		if (validInvestor) {
    			investor = new Investor__c(Id = bondBuy.Investor__c);
	    		if (investorMap.containsKey(investor.Id))
					investor = investorMap.get(investor.Id);
				else {
					investor.Bonds_Pitched__c = oldInvestorMap.get(bondBuy.Investor__c).Bonds_Pitched__c;
					investor.Bonds_Purchased__c = oldInvestorMap.get(bondBuy.Investor__c).Bonds_Purchased__c;
				}
				investor.Bonds_Pitched__c --;
    		}
			
			if (validBondOffering) {
				bondOffering = new Bond_Offering__c(Id = bondBuy.Bond_Offering__c);
				if (bondOfferingMap.containsKey(bondOffering.Id))
					bondOffering = bondOfferingMap.get(bondOffering.Id);
				else {
					bondOffering.Units_Pending__c = oldOfferingMap.get(bondBuy.Bond_Offering__c).Units_Pending__c;
					bondOffering.Units_Sold__c = oldOfferingMap.get(bondBuy.Bond_Offering__c).Units_Sold__c;
				}
			}
			
    		if (bondBuy.Status__c == 'Pending') {
    			if (validBondOffering)
    			bondOffering.Units_Pending__c -= bondBuy.Units__c;
    		}
    		if (bondBuy.Status__c == 'Purchased') {
    			if (validBondOffering)
    				bondOffering.Units_Sold__c -=  bondBuy.Units__c;
    			if (validInvestor)
    				investor.Bonds_Purchased__c --;
    		}
    		
    		if (validBondOffering)
    			bondOfferingMap.put(bondOffering.Id, bondOffering);	
    		if (validInvestor)
    			investorMap.put(investor.Id, investor);
    	}
    	
    	update bondOfferingMap.values();
    	update investorMap.values();
    }
    
    private void bondBuyListFilter(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyOldMap, Boolean isDelete) {
    	Set<Id> bondBuySet = new Set<Id>();
    	
    	Set<Id> oldOfferingIdSet = new Set<Id>();
    	Set<Id> oldInvestorIdSet = new Set<Id>();
    	
    	Boolean getOld = bondBuyOldMap != null;
    	Bond_Buy__c oldBondBuy = new Bond_Buy__c();
    	
    	for (Bond_Buy__c bondBuy : bondBuyListIn) {
    		if (bondBuy.Bond_Offering__c != null || bondBuy.Investor__c != null) {
    			if (getOld) {
    				oldBondBuy = bondBuyOldMap.get(bondBuy.Id);
    				if (bondBuy.Bond_Offering__c != oldBondBuy.Bond_Offering__c)
    					oldOfferingIdSet.add(oldBondBuy.Bond_Offering__c);
    				if (bondBuy.Investor__c != oldBondBuy.Investor__c)
    					oldInvestorIdSet.add(oldBondBuy.Investor__c);
    			}
    			if (isDelete) {
    				oldOfferingIdSet.add(bondBuy.Bond_Offering__c);
    				oldInvestorIdSet.add(bondBuy.Investor__c);
    				bondBuyList.add(bondBuy);
    			}
    			bondBuySet.add(bondBuy.Id);
    		}
    	}
    	
		if (!isDelete)
    		bondBuyList = [Select Bond_Offering__c, Investor__c, Status__c, Units__c, Bond_Offering__r.Units_Pending__c, Bond_Offering__r.Units_Sold__c, Investor__r.Bonds_Pitched__c, Investor__r.Bonds_Purchased__c from Bond_Buy__c where Id in :bondBuySet];
    	
    	if (getOld || isDelete) {
    		if (!oldOfferingIdSet.isEmpty()) {
	    		List<Bond_Offering__c> oldOfferingList = [Select Units_Pending__c, Units_Sold__c from Bond_Offering__c where Id in :oldOfferingIdSet];
	    		for (Bond_Offering__c offer : oldOfferingList) {
	    			oldOfferingMap.put(offer.Id, offer);
	    		}
    		}
	    	if (!oldInvestorIdSet.isEmpty()) {
	    		List<Investor__c> oldInvestorList = [Select Bonds_Pitched__c, Bonds_Purchased__c from Investor__c where Id in :oldInvestorIdSet];
	    		for (Investor__c investor : oldInvestorList) {
	    			oldInvestorMap.put(investor.Id, investor);
	    		}
	    	}
    	}
    }
}