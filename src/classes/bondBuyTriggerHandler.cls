/**
 * Handler class that implements the behaviour of the different events fired in the bondBuyTrigger
 */
public with sharing class bondBuyTriggerHandler {

	//Administrative properties
	private Boolean isExecuting = false;
    private Integer BatchSize = 0;
    
    //Trigger elements list and maps
    private List<Bond_Buy__c> bondBuyList = new List<Bond_Buy__c>();
    private Map<Id,Bond_Offering__c> oldOfferingMap = new Map<Id,Bond_Offering__c>();
    private Map<Id, Bond_Offering__c> bondOfferingMap = new Map<Id, Bond_Offering__c>();
    private Map<Id,Investor__c> oldInvestorMap = new Map<Id,Investor__c>();
    private Map<Id,Investor__c> investorMap = new Map<Id,Investor__c>();
    
    //Object labels
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
    	//Check if all the related Ids used to create the bond buys are valid. This will provide better error messages.
    	checkValidBeforeRelatedRecords(bondBuyListIn);
    }
    
    //AFTER INSERT - UNDELETE
    public void bondBuyAfterInsertUndelete(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyNewMap) {
    	
    	//Filter the elements that fired the trigger to get only the ones being processed.
    	bondBuyListFilter(bondBuyListIn, null, false);
    	
    	//Initialize control variables
    	Bond_Offering__c bondOffering = new Bond_Offering__c();
    	Investor__c investor = new Investor__c();
    	Boolean validInvestor = true;
    	Boolean validBondOffering = true;
    	
    	for (Bond_Buy__c bondBuy : bondBuyList) {
    		try {
    			//Set all boolean flags and objects to avoid null values in every loop
	    		validInvestor = bondBuy.Investor__c != null;
	    		validBondOffering = bondBuy.Bond_Offering__c != null;
	    		
	    		/**
	    		 * Get the information previously processed in the trigger if the investor and/or bond offering related to
	    		 * the bond buy being processed was already referenced in previous loops. This way it will continue to add to it,
	    		 * instead of overwriting the values every time.
	    		 */
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
	    		
	    		//Manage new Pending bond buys
	    		if (bondBuy.Status__c == Label.PendingStatus) {
	    			if (validBondOffering)
	    				bondOffering.Units_Pending__c += bondBuy.Units__c;
	    		}
	    		//Manage new Purchased bond buys
	    		if (bondBuy.Status__c == Label.PurchasedStatus) {
	    			if (validBondOffering)
	    				bondOffering.Units_Sold__c +=  bondBuy.Units__c;
	    			if (validInvestor)
	    				investor.Bonds_Purchased__c ++;
	    		}
	    		
	    		//Populate maps for later insertion
	    		if (validBondOffering)
	    			bondOfferingMap.put(bondOffering.Id, bondOffering);	
	    		if (validInvestor)
	    			investorMap.put(investor.Id, investor);
    		}
    		catch (Exception ex) {
    			//Handle any individual unexpected error, providing a friendly error message
    			bondBuyNewMap.get(bondBuy.Id).addError(Label.IndividualError);
    			//Set the static variable from the controller to true to signal that an error has occurred for rollback.
    			BondOfferingPageControllerExtension.DMLerrors = true;
    		}
    	}

		saveAndHandleErrors(bondOfferingMap.values(), investorMap.values(), bondBuyListIn);
    }
    
    //BEFORE UPDATE
    public void bondBuyBeforeUpdate(List<Bond_Buy__c> bondBuyListIn) {
    	//Check if all the related Ids used to create the bond buys are valid. This will provide better error messages.
    	checkValidBeforeRelatedRecords(bondBuyListIn);
    }
    
    //AFTER UPDATE
    public void bondBuyAfterUpdate(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyOldMap, Map<Id, Bond_Buy__c> bondBuyNewMap) {
    	
    	//Filter the elements that fired the trigger to get only the ones being processed.
    	bondBuyListFilter(bondBuyListIn, bondBuyOldMap, false);
    	
    	//Initialize control variables
    	Bond_Offering__c bondOffering = new Bond_Offering__c();
    	Investor__c investor = new Investor__c();
    	Bond_Buy__c oldBondBuy = new Bond_Buy__c();
    	Bond_Offering__c oldOffering = new Bond_Offering__c();
    	Investor__c oldInvestor = new Investor__c();
    	Boolean offeringChanged;
    	Boolean investorChanged;
    	Boolean statusChanged;
    	Boolean unitsChanged;
    	Boolean investorAdded = false;
    	Boolean validInvestor, validOldInvestor;
    	Boolean validOffering, validOldOffering;
    	
    	for (Bond_Buy__c bondBuy : bondBuyList) {
			try {
				//Set all boolean flags and objects to avoid null values in every loop
	    		oldBondBuy = bondBuyOldMap.get(bondBuy.Id);
				validInvestor = bondBuy.Investor__c != null;
				validOldInvestor = oldBondBuy.Investor__c != null;
				validOffering = bondBuy.Bond_Offering__c != null;
				validOldOffering = oldBondBuy.Bond_Offering__c != null;
				offeringChanged = bondBuy.Bond_Offering__c != oldBondBuy.Bond_Offering__c;
				investorChanged = bondBuy.Investor__c != oldBondBuy.Investor__c;
				statusChanged = bondBuy.Status__c != oldBondBuy.Status__c;
				unitsChanged = bondBuy.Units__c != oldBondBuy.Units__c;
				
				/**
	    		 * Get the information previously processed in the trigger if the investor and/or bond offering related to
	    		 * the bond buy being processed was already referenced in previous loops. This way it will continue to add to it,
	    		 * instead of overwriting the values every time. This is true for old and new values in case of Update.
	    		 */

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
				
				//Handle the change of the related investor	
				if (investorChanged) {
					//Update old investor
					if (validOldInvestor) {
						oldInvestor.Bonds_Pitched__c = oldInvestor.Bonds_Pitched__c - 1;
						//Investor changed for a Purchased bond buy
						if (oldBondBuy.Status__c == Label.PurchasedStatus)
							oldInvestor.Bonds_Purchased__c = oldInvestor.Bonds_Purchased__c - 1;
						investorMap.put(oldInvestor.Id, oldInvestor);
					}
					
					//Update new investor
					if (validInvestor) {
						investor.Bonds_Pitched__c = investor.Bonds_Pitched__c + 1;
						if (bondBuy.Status__c == Label.PurchasedStatus)
							investor.Bonds_Purchased__c = investor.Bonds_Purchased__c + 1;
					}
				}
				
				//Manage status changes
				if (statusChanged) {
					//Changes from Pending status
					if (oldBondBuy.Status__c == Label.PendingStatus) {
						//To Passed status
			    		if (bondBuy.Status__c == Label.PassedStatus) {
			    			//Check if the related bond offering has changed, update both old and new in that case, else only the new one, if valid
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
			    		//To purchased status
			    		else if (bondBuy.Status__c == Label.PurchasedStatus) {
			    			//Manage change to the unchanged investor, if valid
			    			if (!investorChanged && validInvestor) {
				    			investor.Bonds_Purchased__c ++;
				    			investorMap.put(investor.Id, investor);
				    			investorAdded = true;
			    			}
		    				
		    				//Check if the related bond offering has changed, update both old and new in that case, else only the new one, if valid
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
					//Changes from Passed status
					else if (oldBondBuy.Status__c == Label.PassedStatus) {
						//To Pending status
						if (bondBuy.Status__c == Label.PendingStatus) {
							//Only update the new offering, if valid. As the old one was Passed, it's not affected.
							if (validOffering) {
								bondOffering.Units_Pending__c += bondBuy.Units__c;
								bondOfferingMap.put(bondOffering.Id, bondOffering);
							}
						}
						//To Purchased status
			    		else if (bondBuy.Status__c == Label.PurchasedStatus) {
			    			//Update unchanged status, if valid
			    			if (!investorChanged && validInvestor) {
			    				investor.Bonds_Purchased__c ++;
			    				investorMap.put(investor.Id, investor);
			    				investorAdded = true;
			    			}
			    			
			    			//Only update the new offering, if valid. As the old one was Passed, it's not affected.
			    			if(validOffering) {
				    			bondOffering.Units_Sold__c += bondBuy.Units__c;
				    			bondOfferingMap.put(bondOffering.Id, bondOffering);
			    			}
			    		}
					}
					//Changes from Purchased status
					else if (oldBondBuy.Status__c == Label.PurchasedStatus) {
						//Update the unchanged investor, if valid.
						if (!investorChanged && validInvestor) {
							investor.Bonds_Purchased__c --;
				    		investorMap.put(investor.Id, investor);
				    		investorAdded = true;
						}
			    		
			    		//To Pending status
						if (bondBuy.Status__c == Label.PendingStatus) {
							//Check if the related bond offering has changed, update both old and new in that case, else only the new one, if valid
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
						//To Passed status
						else if (bondBuy.Status__c == Label.PassedStatus) {
							//Check if the related bond offering has changed, update only old in that case (the new is not affected), else only the new one, if valid
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
				//If status is not changed
				else {
					//Offering changed
					if (offeringChanged) {
						//Offering change for a pending bond buy. Update both old and new offerings to accomodate new values.
						if (bondBuy.Status__c == Label.PendingStatus) {
							if (validOldOffering) {
								oldOffering.Units_Pending__c -= oldBondBuy.Units__c;
								bondOfferingMap.put(oldOffering.id, oldOffering);
							}
							if (validOffering)
								bondOffering.Units_Pending__c += bondBuy.Units__c;
						}
						//Offering change for a purchased bond buy. Update both old and new offerings to accomodate new values.
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
					//Offering is not changed, units are changed
					else if (unitsChanged && validOffering) {
						//Remove old pending values, update with new values.
						if (bondBuy.Status__c == Label.PendingStatus) {
							bondOffering.Units_Pending__c -= oldBondBuy.Units__c;
							bondOffering.Units_Pending__c += bondBuy.Units__c;
						}
						//Remove old purchased values, update with new values.
						else if (bondBuy.Status__c == Label.PurchasedStatus) {
							bondOffering.Units_Sold__c -= oldBondBuy.Units__c;
							bondOffering.Units_Sold__c += bondBuy.Units__c;
						}
						bondOfferingMap.put(bondOffering.Id, bondOffering);
					}
				}
				//If the investor hasn't been added to the map for update before, add it now.
		    	if (!investorAdded && validInvestor)
		    		investorMap.put(investor.Id, investor);
			}
    		catch (Exception ex) {
    			//Handle any individual unexpected error, providing a friendly error message
    			bondBuyNewMap.get(bondBuy.Id).addError(Label.IndividualError);
    			//Set the static variable from the controller to true to signal that an error has occurred for rollback.
    			BondOfferingPageControllerExtension.DMLerrors = true;
    		}
    	}
    	saveAndHandleErrors(bondOfferingMap.values(), investorMap.values(), bondBuyListIn);
    }
    
    //AFTER DELETE
    public void bondBuyAfterDelete(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyOldMap) {
    	
    	//Filter the elements that fired the trigger to get only the ones being processed.
    	bondBuyListFilter(bondBuyListIn, null, true);
    	
    	//Initialize control variables
    	Bond_Offering__c bondOffering = new Bond_Offering__c();
    	Investor__c investor = new Investor__c();
    	Boolean validInvestor = true;
    	Boolean validBondOffering = true;
    	
    	for (Bond_Buy__c bondBuy : bondBuyList) {
    		try {
    			//Set all boolean flags and objects to avoid null values in every loop
	    		validInvestor = bondBuy.Investor__c != null;
	    		validBondOffering = bondBuy.Bond_Offering__c != null;
	    		
	    		/**
	    		 * Get the information previously processed in the trigger if the investor and/or bond offering related to
	    		 * the bond buy being processed was already referenced in previous loops. This way it will continue to add to it,
	    		 * instead of overwriting the values every time. This is true for substracting values when appropriate in delete.
	    		 */
	    		
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
				
				//Manage deletion of pending bond buy
	    		if (bondBuy.Status__c == Label.PendingStatus) {
	    			if (validBondOffering)
	    			bondOffering.Units_Pending__c -= bondBuy.Units__c;
	    		}
	    		//Manage deletion of purchased bond buy
	    		if (bondBuy.Status__c == Label.PurchasedStatus) {
	    			if (validBondOffering)
	    				bondOffering.Units_Sold__c -=  bondBuy.Units__c;
	    			if (validInvestor)
	    				investor.Bonds_Purchased__c --;
	    		}
	    		
	    		//Adding objects to list for updates
	    		if (validBondOffering)
	    			bondOfferingMap.put(bondOffering.Id, bondOffering);	
	    		if (validInvestor)
	    			investorMap.put(investor.Id, investor);
    		}
    		catch (Exception ex) {
    			//Handle any individual unexpected error, providing a friendly error message
    			bondBuyOldMap.get(bondBuy.Id).addError(Label.IndividualError);
    			//Set the static variable from the controller to true to signal that an error has occurred for rollback.
    			BondOfferingPageControllerExtension.DMLerrors = true;
    		}
    	}
    	saveAndHandleErrors(bondOfferingMap.values(), investorMap.values(), bondBuyListIn);
    }
    
    /**
     * Method that filters the list of inserted, updated, deleted or undeleted bond buys to get the actual list to be processed.
     * This means that the trigger will only work with the ones that have either a related investor, a related offering or both.
     *
     * There is no restriction in the requirements over what happens to bond buys that have no related objects. As there is no
     * validation rules that prohibit them to be created/updated either, nothing will be done with them and they'll be allowed to proceed
     * without any processing from this handler.
     * 
     * This method also gets all the related info for Old investor and offering values, when it is called from an update or a delete event.
     */
    private void bondBuyListFilter(List<Bond_Buy__c> bondBuyListIn, Map<Id, Bond_Buy__c> bondBuyOldMap, Boolean isDelete) {
    	
    	//Initialise sets used for querying
    	Set<Id> bondBuySet = new Set<Id>();
    	Set<Id> oldOfferingIdSet = new Set<Id>();
    	Set<Id> oldInvestorIdSet = new Set<Id>();
    	
    	//Initialise control variables
    	Boolean getOld = bondBuyOldMap != null;
    	Bond_Buy__c oldBondBuy = new Bond_Buy__c();
    	
    	for (Bond_Buy__c bondBuy : bondBuyListIn) {
    		//Filter records with no related objects, add Ids to sets for querying and set old values
    		if (bondBuy.Bond_Offering__c != null || bondBuy.Investor__c != null) {
    			if (getOld) {
    				oldBondBuy = bondBuyOldMap.get(bondBuy.Id);
    				//Get old information from changed offerings and investors
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
    	
    	//Query new values if the event is not delete
		if (!isDelete)
    		bondBuyList = [Select Bond_Offering__c, Investor__c, Status__c, Units__c, Bond_Offering__r.Units_Pending__c, Bond_Offering__r.Units_Sold__c, Investor__r.Bonds_Pitched__c, Investor__r.Bonds_Purchased__c from Bond_Buy__c where Id in :bondBuySet];
    	
    	//If the event is delete or update, it creates maps of offerings and investors to gather all old information from them
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
    
    //Method that saves updated offerings and investors and handle errors to be displayed
    public void saveAndHandleErrors(List<Bond_Offering__c> bondOfferingsForUpdate, List<Investor__c> inverstorsForUpdate, List<Bond_Buy__c> bondBuyListIn) {
	    if (!bondOfferingsForUpdate.isEmpty() || !inverstorsForUpdate.isEmpty()) {
		    try {
		    	//Perform the updates and get error messages from the results
				Map<Id, String> wrongObjectsErrorMap = new Map<Id, String>();
				List<Database.SaveResult> offeringResults = Database.update(bondOfferingsForUpdate, false);
				processDatabaseSaveResults(wrongObjectsErrorMap, bondOfferingsForUpdate, offeringResults, bondOfferingLabel);
				List<Database.SaveResult> investorResults = Database.update(inverstorsForUpdate, false);
				processDatabaseSaveResults(wrongObjectsErrorMap, inverstorsForUpdate, investorResults, investorLabel);
				
				//Prepare and add errors to trigger records.
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
				//Handle any unexpected exception produced in the updates and the error adding process
				for (Bond_Buy__c bb : bondBuyListIn) {
					bb.addError(String.format(Label.UpdateGeneralError, new List<String>{bondOfferingLabel, investorLabel, bondBuyLabel}));
					//Set the static variable from the controller to true to signal that an error has occurred for rollback.
					BondOfferingPageControllerExtension.DMLerrors = true;
				}
			}
	    }
	}
	
	//Method that loops through the SaveResults generically to get appropriate error messages.
	private void processDatabaseSaveResults(Map<Id, String> wrongObjectsErrorMap, List<sObject> sObjectForUpdate, List<Database.SaveResult> saveResults, String sObjectLabel) {
		Integer i = 0;
		String tempError = '';
		for (Database.SaveResult result : saveResults) {
			if (!result.isSuccess()) {
				for (Database.Error error : result.getErrors()) {
					//If the error was a custom validation, use the message from the validation rule for the error.
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
	
	/**
	 * Method that checks that "Before" records have null or valid Ids for related investors and bond offerings
	 * This is needed to provide custom and friendly error messages if the data being updated or inserted is referencing
	 * a deleted or otherwise no longer valid Id.
	 */
	public void checkValidBeforeRelatedRecords(List<Bond_Buy__c> bondBuyListIn) {
    	Set<Id> offeringIds = new Set<Id>();
    	Set<Id> investorIds = new Set<Id>();
    	//Get the non null values
    	for (Bond_Buy__c bondBuy : bondBuyListIn) {
    		if (bondBuy.Bond_Offering__c != null)
    			offeringIds.add(bondBuy.Bond_Offering__c);
    		if (bondBuy.Investor__c != null)
    			investorIds.add(bondBuy.Investor__c);
    	}
    	
    	//Query offerings and investors and check that every Id queryed has a valid Id, otherwise, set a friendly error message.
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