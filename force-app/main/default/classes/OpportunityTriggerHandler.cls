public with sharing class OpportunityTriggerHandler extends TriggerHandler {

    public static void setType(List<Opportunity> opps) {
                    // Set default Type for new Opportunities
        for (Opportunity opp : opps) {
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }   
        }
    }

    public static void validateCloseOpportunity(List<Opportunity> opps) {
        for (Opportunity oldOpp : opps){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
                }
            }
    }

    public static void insertTask(List<Opportunity> opps) {
        List<Task> tskList = new List<Task>();
        for (Opportunity opp : opps){
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            tskList.add(tsk);
            }
        insert tskList;
    }

    public static void updateDescriptionFromStage(List<Opportunity> opps) {
        for (Opportunity opp : opps){
            //Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
                if (opp.StageName != null){ // && opp.StageName != oldOpp.StageName
                    opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                }             
        }
    }

    public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        Map<Id, User> userMap = new Map<Id, User> ([SELECT Id, Email FROM User]);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            User oppOwner = userMap.get(opp.OwnerId);
            String[] toAddresses = new String[] {oppOwner.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    public static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Set<Id> accIdsFromOpp = new Set<Id>();
        for (Opportunity opp : oppNewMap.values()) {
            accIdsFromOpp.add(opp.AccountId);
        }
        List<Contact> primaryContacts = [SELECT Id, AccountId
                                  FROM Contact
                                  WHERE Title = 'VP Sales' 
                                  AND AccountId = :accIdsFromOpp];
        Map<Id, Contact> accIdToConMap = new Map<Id, Contact>();
        for (Contact con : primaryContacts) {
            accIdToConMap.put(con.AccountId, con);
        }
        for (Opportunity opp : oppNewMap.values()){            
            if (opp.Primary_Contact__c == null){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                Contact primaryContact = accIdToConMap.get(opp.AccountId);
                oppToUpdate.Primary_Contact__c = primaryContact.Id;
                oppMap.put(opp.Id, oppToUpdate);
            }
        }
        update oppMap.values();
    }
    public static void amountValidation(List<Opportunity> opps) {
        for(Opportunity opp : opps){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }
    public static void deleteCloseWonOpportunity(List<Opportunity> opps) {
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :opps)]);
        for(Opportunity opp : opps){
            if(opp.StageName == 'Closed Won'){
                if(accounts.get(opp.AccountId).Industry == 'Banking'){
                    opp.addError('Cannot delete a closed won opportunity for a banking account');
                }
            }
        }
    }
    public static void setPrimaryContact(List<Opportunity> opps) {
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : opps){
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for(Opportunity opp : opps){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }            
    }
}