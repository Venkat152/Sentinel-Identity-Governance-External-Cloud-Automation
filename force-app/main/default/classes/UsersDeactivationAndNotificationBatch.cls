public with sharing class UsersDeactivationAndNotificationBatch implements Database.Batchable<sObject>, Schedulable{
 
    public enum EMAIL_TEMPLATE_NAME { USER_DEACTIVATION_TEMPLATE, USER_EXPIRY_14_DAYS_TEMPLATE }
    
    private static final Integer BATCH_SIZE = 200;
    private static final String FALLBACK_SENDER = 'Sentinel Identity Support';

    // Fetch config once to use throughout the execution
    private static Governance_Config__mdt CONFIG = CustomSettingAndMetaDataUtil.getGovernanceConfig();
    private static Date TODAY = Date.today();
    
    // Days offset from Metadata (defaults to 14 if null)
    private static Integer NOTICE_DAYS = (CONFIG != null && CONFIG.Days_Before_Expiry__c != null) 
                                        ? Integer.valueOf(CONFIG.Days_Before_Expiry__c) : 14;
    private static Date ADVANCE_DATE = TODAY.addDays(NOTICE_DAYS);

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> targetProfileNames = CustomSettingAndMetaDataUtil.getTargetProfileNamesFromMetadata();
        
        return Database.getQueryLocator([
            SELECT Id, Email, ManagerId, Manager.Email, Manager.IsActive, Access_Type__c, End_Date__c, IsActive
            FROM User
            WHERE IsActive = true
              AND ManagerId <> null
              AND Profile.Name IN :targetProfileNames
              AND (End_Date__c = :TODAY OR End_Date__c = :ADVANCE_DATE)
        ]);
    }
        public void execute(Database.BatchableContext BC, List<User> scope) {
            if (scope == null || scope.isEmpty()) return;

            List<User> usersToDeactivateToday = new List<User>();
            List<Id> deactivationIdsForEmail = new List<Id>();
            List<Access_Audit_Log__c> combinedLogs = new List<Access_Audit_Log__c>();

            for (User u : scope) {
                // SCENARIO 1: DEACTIVATION TODAY
                if (u.End_Date__c == TODAY) {
                    u.IsActive = false;
                    usersToDeactivateToday.add(u);
                    deactivationIdsForEmail.add(u.Id);
                    
                    // Create the deactivation log here instead of relying on the trigger
                    combinedLogs.add(new Access_Audit_Log__c(
                        Target_User__c = u.Id,
                        Action__c = 'Auto-Deactivation',
                        Performed_By__c = UserInfo.getUserId(),
                        Notes__c = 'User deactivated by Sentinel Batch based on End Date.'
                    ));
                } 
                // SCENARIO 2: ADVANCE NOTIFICATION
                else if (u.End_Date__c == ADVANCE_DATE) {
                    // We handle the email for these immediately (Non-Setup)
                    // or pass them to the queueable if the method is heavy
                    combinedLogs.add(new Access_Audit_Log__c(
                        Target_User__c = u.Id,
                        Action__c = 'Notification Sent',
                        Performed_By__c = UserInfo.getUserId(),
                        Notes__c = NOTICE_DAYS + '-day expiry warning email triggered.'
                    ));
                }
            }

            // 1. Perform Setup DML (Update Users)
            if (!usersToDeactivateToday.isEmpty()) {
                // Database.update with allOrNone=false to prevent one failure from killing the batch
                Database.update(usersToDeactivateToday, false); 
            }

            // 2. Handle Advance Notification Emails
            // Find the users in the advance list to send emails
            List<User> usersToNotify = new List<User>();
            for(User u : scope) {
                if(u.End_Date__c == ADVANCE_DATE) usersToNotify.add(u);
            }
            if(!usersToNotify.isEmpty()) {
                sendAdvanceNoticeEmails(usersToNotify);
            }

            // 3. THE FIX: ONE SINGLE QUEUEABLE CALL
            // We send everything (Deactivation Emails + All Logs) in one single transaction
            if (!deactivationIdsForEmail.isEmpty() || !combinedLogs.isEmpty()) {
                System.enqueueJob(new SentinelGovernanceQueueable(
                    deactivationIdsForEmail, 
                    combinedLogs, 
                    ''
                ));
            }
        }

    public void finish(Database.BatchableContext BC) {
        // Optional: Send summary email to Admin
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, BATCH_SIZE);
    }

    // --- Helper Methods ---

    private static String mapTemplateName(EMAIL_TEMPLATE_NAME tn) {
        switch on tn {
            when USER_DEACTIVATION_TEMPLATE { return 'User_Deactivation_Template'; }
            when USER_EXPIRY_14_DAYS_TEMPLATE { return 'User_Expiry_14_Days_Template'; }
        }
        return null;
    }

    public static void sendAdvanceNoticeEmails(List<User> users) {
        if (users == null || users.isEmpty()) return;
        
        // Use OWA ID from Metadata
        String owaId = (CONFIG != null) ? CONFIG.OWA_Email_Id__c : null;

        Id templateId;
        try {
            String templateDevName = mapTemplateName(EMAIL_TEMPLATE_NAME.USER_EXPIRY_14_DAYS_TEMPLATE);
            templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateDevName LIMIT 1].Id;
        } catch (Exception e) { return; }

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        Map<Id, String> userIdToManagerEmail = buildManagerCcMap(users);

        for (User u : users) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(templateId);
            email.setTargetObjectId(u.Id);
            email.setSaveAsActivity(false);
            email.setWhatId(u.Id);

            if (String.isNotBlank(owaId)) {
                email.setOrgWideEmailAddressId(owaId);
            } else {
                email.setSenderDisplayName(FALLBACK_SENDER);
            }
            emailsToSend.add(email);
        }
        Messaging.sendEmail(emailsToSend, false);
    }

    private static Map<Id, String> buildManagerCcMap(List<User> users) {
        Map<Id, String> result = new Map<Id, String>();
        for (User u : users) {
            if (u.ManagerId != null && u.Manager.IsActive && String.isNotBlank(u.Manager.Email)) {
                result.put(u.Id, u.Manager.Email);
            }
        }
        return result;
    }
}