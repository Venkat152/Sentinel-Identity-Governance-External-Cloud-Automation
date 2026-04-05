/**
 * @description       : Handler for User Trigger to manage Compliance and Data Integrity.
 * @author            : Venkatesh M
 */
public with sharing class UserTriggerHandler {

    public static void handlerBeforeInsert(List<User> newLIst){
        for(User u: newLIst){
            if(u.IsActive==true && u.Start_Date__c ==null){
                u.Start_Date__c = Date.today();
            }
        }
    }
    
    /**
     * Handles automatic setting of End_Date__c when a user is deactivated manually.
     * This ensures that the batch process can identify these users for proper logging and notifications.
     */
    
    public static void handleBeforeUpdate(List<User> newList, Map<Id, User> oldMap) {
        for (User u : newList) {
            User oldUser = oldMap.get(u.Id);
            
            // Logic: User is being deactivated AND End_Date__c is currently empty
            if (oldUser.IsActive && !u.IsActive && u.End_Date__c == null) {
                u.End_Date__c = Date.today();
            }
        }
    }

    /**
     * Handles Notifications and Audit Logging.
     */
        public static void handleAfterUpdate(List<User> newList, Map<Id, User> oldMap) {
            List<Id> deactivatedUserIds = new List<Id>();

            // 1. Only identify users deactivated manually
            for (User u : newList) {
                User oldUser = oldMap.get(u.Id);
                if (oldUser.IsActive && !u.IsActive) {
                    deactivatedUserIds.add(u.Id);
                }
            }
            if (!deactivatedUserIds.isEmpty() && !System.isBatch()) {
                System.enqueueJob(new SentinelGovernanceQueueable(deactivatedUserIds, new List<Access_Audit_Log__c>(), Label.Manual_Deactivation_Action));
            }
        }
}