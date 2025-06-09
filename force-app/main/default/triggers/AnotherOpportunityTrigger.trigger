/*
AnotherOpportunityTrigger Overview

This trigger was initially created for handling various events on the Opportunity object. It was developed by a prior developer and has since been noted to cause some issues in our org.

IMPORTANT:
- This trigger does not adhere to Salesforce best practices.
- It is essential to review, understand, and refactor this trigger to ensure maintainability, performance, and prevent any inadvertent issues.

ISSUES:
Avoid nested for loop - 1 instance - done
Avoid DML inside for loop - 1 instance -done
Bulkify Your Code - 1 instance - done
Avoid SOQL Query inside for loop - 2 instances
Stop recursion - 1 instance - done

RESOURCES: 
https://www.salesforceben.com/12-salesforce-apex-best-practices/
https://developer.salesforce.com/blogs/developer-relations/2015/01/apex-best-practices-15-apex-commandments
*/
trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {

    switch on Trigger.operationType {
         when BEFORE_INSERT {
            OpportunityTriggerHandler.setType(Trigger.new);
          }
          when BEFORE_UPDATE {
            OpportunityTriggerHandler.updateDescriptionFromStage(Trigger.new);
          }
          when BEFORE_DELETE {
            OpportunityTriggerHandler.validateCloseOpportunity(Trigger.old);
          }
          when AFTER_INSERT {
            OpportunityTriggerHandler.insertTask(Trigger.new);
          }
          when AFTER_UPDATE {

          }
          when AFTER_DELETE {
            OpportunityTriggerHandler.notifyOwnersOpportunityDeleted(Trigger.old);
          }
          when AFTER_UNDELETE {
            OpportunityTriggerHandler.assignPrimaryContact(Trigger.newMap);
          }
    }
}