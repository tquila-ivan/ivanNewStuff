public with sharing class bondBuyTriggerHandler {

	private Boolean isExecuting = false;
    private Integer BatchSize = 0;
    private List<Bond_Buy__c> bondBuyList = new List<Bond_Buy__c>();
    private Map<Id,Bond_Offering__c> oldOfferingMap = new Map<Id,Bond_Offering__c>();
    private Map<Id,Investor__c> oldInvestorMap = new Map<Id,Investor__c>();
    
    private Map<Id,Investor__c> investorMap = new Map<Id,Investor__c>();
    private Map<Id, Bond_Offering__c> bondOfferingMap = new Map<Id, Bond_Offering__c>();
    private String bondOfferingLabel = Bond_Offering__c.sObjectType.getDescribe().getLabel();
    private String investorLabel = Investor__c.sObjectType.getDescribe().getLabel();
    private String bondBuyLabel = Bond_Buy__c.sObjectType.getDescribe().getLabel();
    
    // CONSTRUCTOR
    public bondBuyTriggerHandler(Boolean isExecuting, Integer size){
        isExecuting = isExecuting;
        BatchSize = size;
    }
    
    //BEFORE INSERT
    public void bondBuyBeforeInsert(List<Bond_Buy__c> bondBuyListIn) {
    	checkValidBeforeRelatedRecords(bondBuyListIn);
    }
    
    //AFTER INSERT - UNDELETE
    public void bondBuyAfterInsertUndelete(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyNewMap) {
    	
    	bondBuyListFilter(bondBuyListIn, null, false);
    	
    	Bond_Offering__c bondOffering = new Bond_Offering__c();
    	Map<Id, Bond_Offering__c> bondOfferingMap = new Map<Id, Bond_Offering__c>();
    	Investor__c investor = new Investor__c();
    	Map<Id, Investor__c> investorMap = new Map<Id, Investor__c>();
    	Boolean validInvestor = true;
    	Boolean validBondOffering = true;
    	
    	for (Bond_Buy__c bondBuy : bondBuyList) {
    		try {
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
	    		
	    		if (bondBuy.Status__c == Label.PendingStatus) {
	    			if (validBondOffering)
	    				bondOffering.Units_Pending__c += bondBuy.Units__c;
	    		}
	    		if (bondBuy.Status__c == Label.PurchasedStatus) {
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
    		catch (Exception ex) {
    			bondBuyNewMap.get(bondBuy.Id).addError(Label.IndividualError);
    			BondOfferingPageControllerExtension.DMLerrors = true;
    		}
    	}

		saveAndHandleErrors(bondOfferingMap.values(), investorMap.values(), bondBuyListIn);
    }
    
    //BEFORE UPDATE
    public void bondBuyBeforeUpdate(List<Bond_Buy__c> bondBuyListIn) {
    	checkValidBeforeRelatedRecords(bondBuyListIn);
    }
    
    //AFTER UPDATE
    public void bondBuyAfterUpdate(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyOldMap, Map<Id, Bond_Buy__c> bondBuyNewMap) {
    	
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
			try {
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
						if (oldBondBuy.Status__c == Label.PurchasedStatus)
							oldInvestor.Bonds_Purchased__c = oldInvestor.Bonds_Purchased__c - 1;
						investorMap.put(oldInvestor.Id, oldInvestor);
					}
					
					if (validInvestor) {
						investor.Bonds_Pitched__c = investor.Bonds_Pitched__c + 1;
						if (bondBuy.Status__c == Label.PurchasedStatus)
							investor.Bonds_Purchased__c = investor.Bonds_Purchased__c + 1;
					}
				}
				
				if (statusChanged) {
					if (oldBondBuy.Status__c == Label.PendingStatus) {
			    		if (bondBuy.Status__c == Label.PassedStatus) {
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
			    		else if (bondBuy.Status__c == Label.PurchasedStatus) {
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
					else if (oldBondBuy.Status__c == Label.PassedStatus) {
						if (bondBuy.Status__c == Label.PendingStatus) {
							if (validOffering) {
								bondOffering.Units_Pending__c += bondBuy.Units__c;
								bondOfferingMap.put(bondOffering.Id, bondOffering);
							}
						}
			    		else if (bondBuy.Status__c == Label.PurchasedStatus) {
			    			
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
					else if (oldBondBuy.Status__c == Label.PurchasedStatus) {
						if (!investorChanged && validInvestor) {
							investor.Bonds_Purchased__c --;
				    		investorMap.put(investor.Id, investor);
				    		investorAdded = true;
						}
			    		
						if (bondBuy.Status__c == Label.PendingStatus) {
							
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
						else if (bondBuy.Status__c == Label.PassedStatus) {
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
						if (bondBuy.Status__c == Label.PendingStatus) {
							if (validOldOffering) {
								oldOffering.Units_Pending__c -= oldBondBuy.Units__c;
								bondOfferingMap.put(oldOffering.id, oldOffering);
							}
							if (validOffering)
								bondOffering.Units_Pending__c += bondBuy.Units__c;
						}
						else if (bondBuy.Status__c == Label.PurchasedStatus) {
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
						if (bondBuy.Status__c == Label.PendingStatus) {
							bondOffering.Units_Pending__c -= oldBondBuy.Units__c;
							bondOffering.Units_Pending__c += bondBuy.Units__c;
						}
						else if (bondBuy.Status__c == Label.PurchasedStatus) {
							bondOffering.Units_Sold__c -= oldBondBuy.Units__c;
							bondOffering.Units_Sold__c += bondBuy.Units__c;
						}
						bondOfferingMap.put(bondOffering.Id, bondOffering);
					}
				}
		    	if (!investorAdded && validInvestor)
		    		investorMap.put(investor.Id, investor);
			}
    		catch (Exception ex) {
    			bondBuyNewMap.get(bondBuy.Id).addError(Label.IndividualError);
    			BondOfferingPageControllerExtension.DMLerrors = true;
    		}
    	}
    	saveAndHandleErrors(bondOfferingMap.values(), investorMap.values(), bondBuyListIn);
    }
    
    //AFTER DELETE
    public void bondBuyAfterDelete(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyOldMap) {
    	bondBuyListFilter(bondBuyListIn, null, true);
    	
    	Bond_Offering__c bondOffering = new Bond_Offering__c();
    	Map<Id, Bond_Offering__c> bondOfferingMap = new Map<Id, Bond_Offering__c>();
    	Investor__c investor = new Investor__c();
    	Map<Id, Investor__c> investorMap = new Map<Id, Investor__c>();
    	
    	Boolean validInvestor = true;
    	Boolean validBondOffering = true;
    	
    	for (Bond_Buy__c bondBuy : bondBuyList) {
    		try {
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
				
	    		if (bondBuy.Status__c == Label.PendingStatus) {
	    			if (validBondOffering)
	    			bondOffering.Units_Pending__c -= bondBuy.Units__c;
	    		}
	    		if (bondBuy.Status__c == Label.PurchasedStatus) {
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
    		catch (Exception ex) {
    			bondBuyOldMap.get(bondBuy.Id).addError(Label.IndividualError);
    			BondOfferingPageControllerExtension.DMLerrors = true;
    		}
    	}
    	
    	saveAndHandleErrors(bondOfferingMap.values(), investorMap.values(), bondBuyListIn);
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
    
    public void saveAndHandleErrors(List<Bond_Offering__c> bondOfferingsForUpdate, List<Investor__c> inverstorsForUpdate, List<Bond_Buy__c> bondBuyListIn) {
	    try {
			Map<Id, String> wrongObjectsErrorMap = new Map<Id, String>();
			
			List<Database.SaveResult> offeringResults = Database.update(bondOfferingsForUpdate, false);
			processDatabaseSaveResults(wrongObjectsErrorMap, bondOfferingsForUpdate, offeringResults, bondOfferingLabel);
			
			List<Database.SaveResult> investorResults = Database.update(inverstorsForUpdate, false);
			processDatabaseSaveResults(wrongObjectsErrorMap, inverstorsForUpdate, investorResults, investorLabel);
			
			String errorMessage = '';
			for(Bond_Buy__c bb : bondBuyListIn) {
				errorMessage = '';
				if (wrongObjectsErrorMap.containsKey(bb.Bond_Offering__c))
					errorMessage = String.format(Label.ErrorEncounteredMessage, new List<String>{bondOfferingLabel,wrongObjectsErrorMap.get(bb.Bond_Offering__c)});
				if (wrongObjectsErrorMap.containsKey(bb.Investor__c)) {
					if (errorMessage != '')
						errorMessage += ' --- ' + String.format(Label.ErrorEncounteredMessage, new List<String>{investorLabel, wrongObjectsErrorMap.get(bb.Investor__c)});
					else
						errorMessage = String.format(Label.ErrorEncounteredMessage, new List<String>{investorLabel, wrongObjectsErrorMap.get(bb.Investor__c)});
				}
				if (errorMessage != '') {
					bb.addError(errorMessage);
					BondOfferingPageControllerExtension.DMLerrors = true;
				}
			}
		}
		catch (Exception ex) {	
			for (Bond_Buy__c bb : bondBuyListIn) {
				bb.addError(String.format(Label.UpdateGeneralError, new List<String>{bondOfferingLabel, investorLabel, bondBuyLabel}));
				BondOfferingPageControllerExtension.DMLerrors = true;
			}
		}
	}
	
	private void processDatabaseSaveResults(Map<Id, String> wrongObjectsErrorMap, List<sObject> sObjectForUpdate, List<Database.SaveResult> saveResults, String sObjectLabel) {
		Integer i = 0;
		String tempError = '';
		for (Database.SaveResult result : saveResults) {
			if (!result.isSuccess()) {
				for (Database.Error error : result.getErrors()) {
					if (error.getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
						tempError = error.getMessage();
				}
				if (String.isBlank(tempError))
					tempError = String.format(Label.NotCustomValidationError, new List<String>{sObjectLabel, bondBuyLabel});
    			wrongObjectsErrorMap.put(sObjectForUpdate.get(i).Id, tempError);
			}
			i++;
		}
	}
	
	public void checkValidBeforeRelatedRecords(List<Bond_Buy__c> bondBuyListIn) {
    	Set<Id> offeringIds = new Set<Id>();
    	Set<Id> investorIds = new Set<Id>();
    	for (Bond_Buy__c bondBuy : bondBuyListIn) {
    		if (bondBuy.Bond_Offering__c != null)
    			offeringIds.add(bondBuy.Bond_Offering__c);
    		if (bondBuy.Investor__c != null)
    			investorIds.add(bondBuy.Investor__c);
    	}
    	
    	Map<Id, Bond_Offering__c> validOfferingsMap = new Map<Id, Bond_Offering__c>([Select Id from Bond_Offering__c where Id in :offeringIds]);
    	Map<Id, Investor__c> validInvestorsMap = new Map<Id, Investor__c>([Select Id from Investor__c where Id in :investorIds]);
    	String errorMessage = '';
    	for (Bond_Buy__c bondBuy : bondBuyListIn) {
    		errorMessage = '';
    		if(bondBuy.Bond_Offering__c != null)
	    		if (!validOfferingsMap.containsKey(bondBuy.Bond_Offering__c))
	    			errorMessage = String.format(Label.InvalidIdIntroduced, new List<String>{bondOfferingLabel});
	    	if(bondBuy.Investor__c != null)
	    		if (!validInvestorsMap.containsKey(bondBuy.Investor__c)) {
	    			if (errorMessage == '')
	    				errorMessage = String.format(Label.InvalidIdIntroduced, new List<String>{investorLabel});
	    			else
	    				errorMessage += '. ' + String.format(Label.InvalidIdIntroduced, new List<String>{investorLabel});
	    		}
	    	
	    	if (!String.isBlank(errorMessage))
	    		bondBuy.addError(errorMessage);
    	}
    }
}