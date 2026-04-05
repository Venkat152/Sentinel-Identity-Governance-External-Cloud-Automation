public with sharing class UsersDeactivationAndNotificationBatch implements Database.Batchable<sObject>, Schedulable{
 
    public enum EMAIL_TEMPLATE_NAME { USER_DEACTIVATION_TEMPLATE, USER_EXPIRY_14_DAYS_TEMPLATE }
    
    private static final String TODAY_DEACTIVATION_TEMPLATE =Label.User_InActive_Template;
    private static final String ADVANCE_NOTIFY_TEMPLATE ='User_Expiry_14_Days_Template';
    private static final Integer BATCH_SIZE = 200;
    private static Governance_Config__mdt CONFIG = CustomSettingAndMetaDataUtil.getGovernanceConfig();
    private static Date TODAY = Date.today();
    
    // Days offset from Metadata (defaults to 15 if null)
    private static Integer NOTICE_DAYS = (CONFIG != null && CONFIG.Days_Before_Expiry__c != null) 
                                        ? Integer.valueOf(CONFIG.Days_Before_Expiry__c) : 15;
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
            List<User> usersToNotify = new List<User>();


            for (User u : scope) {
                // SCENARIO 1: DEACTIVATION TODAY
                if (u.End_Date__c == TODAY) {
                    u.IsActive = false;
                    usersToDeactivateToday.add(u);
                    deactivationIdsForEmail.add(u.Id);
                    combinedLogs.add(IdentityGovernanceService.createLogRecord(u.Id,Label.Auto_Deactivation_Action, Label.User_Deactivation_Notes));
                } 
                // SCENARIO 2: ADVANCE NOTIFICATION
                else if (u.End_Date__c == ADVANCE_DATE) {
                    usersToNotify.add(u);
                    combinedLogs.add(IdentityGovernanceService.createLogRecord(u.Id,Label.Notification_Status, NOTICE_DAYS + Label.Expiry_Email_Note));
                }
            }

            if (!usersToDeactivateToday.isEmpty()) {
                Database.update(usersToDeactivateToday, false); 
            }
            if(!usersToNotify.isEmpty()) {
                sendAdvanceNoticeEmails(usersToNotify);
            }

            //(Deactivation Emails + All Logs) in one single transaction
            if (!deactivationIdsForEmail.isEmpty() || !combinedLogs.isEmpty()) {
                System.enqueueJob(new SentinelGovernanceQueueable(
                    deactivationIdsForEmail, 
                    combinedLogs, 
                    ''
                ));
            }
        }

    public void finish(Database.BatchableContext BC) {
        // Send batch summary to Admin (Need to Implement in Future)
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, BATCH_SIZE);
    }

    // --- Helper Methods ---

    private static String mapTemplateName(EMAIL_TEMPLATE_NAME tn) {
        switch on tn {
            when USER_DEACTIVATION_TEMPLATE { return TODAY_DEACTIVATION_TEMPLATE; }
            when USER_EXPIRY_14_DAYS_TEMPLATE { return ADVANCE_NOTIFY_TEMPLATE; }
        }
        return null;
    }

    public static void sendAdvanceNoticeEmails(List<User> users) {
        if (users == null || users.isEmpty()) return;
        
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
                email.setSenderDisplayName(Label.fallback_sender);
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