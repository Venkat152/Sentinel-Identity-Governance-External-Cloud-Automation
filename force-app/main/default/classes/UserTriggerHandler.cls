/**
 * @description       : Handler for User Trigger to manage Compliance and Data Integrity.
 * @author            : Venkatesh M
 */
public with sharing class UserTriggerHandler {

    /**
     * BEFORE UPDATE LOGIC
     * Ensures End_Date__c is populated if a user is deactivated.
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
     * AFTER UPDATE LOGIC
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

            // 2. THE GUARD: Do not enqueue if we are in a Batch context 
            // (Because the Batch method above is already handling the Queueable)
            if (!deactivatedUserIds.isEmpty() && !System.isBatch()) {
                System.enqueueJob(new SentinelGovernanceQueueable(deactivatedUserIds, new List<Access_Audit_Log__c>(), 'Manual Deactivation'));
            }
        }
}