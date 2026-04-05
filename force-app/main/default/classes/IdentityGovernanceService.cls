/**
 * @description       : Core Service class for Identity & Access Management operations.
 * Handles Credential Resets, Audit Logging, and Notifications.
 * @author            : Venkatesh M
 * @last modified on  : 03-31-2026
 */
public with sharing class IdentityGovernanceService {
    
private static final String GOOGLE_DRIVE_INSTANCE ='Google_Drive_Default';
@AuraEnabled(cacheable=true)
public static List<FileWrapper> getGoogleDriveFiles() {
    List<FileWrapper> fileList = new List<FileWrapper>();
    
    Sentinel_Integration_Setting__mdt config = Sentinel_Integration_Setting__mdt.getInstance(GOOGLE_DRIVE_INSTANCE);
    
    if(config == null) {
        throw new CalloutException(Label.Metadata_Configuration_Missing);
    }
    
    // ''Folder_ID' in parents' restricts it to your specific Sentinel folder.
    String query = 'name contains \'Backup_\' AND trashed = false';
    
    if(String.isNotBlank(config.Folder_ID__c)) {
        query += ' AND \'' + config.Folder_ID__c + '\' in parents';
    }

    String endpoint = 'callout:' + config.Named_Credential__c + 
                     '/drive/v3/files?q=' + EncodingUtil.urlEncode(query, 'UTF-8') + 
                     '&fields=files(id,name,mimeType,createdTime,webViewLink)';
                     
    Http http = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('GET');
    
    try {
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> files = (List<Object>)results.get('files');
            
            for (Object f : files) {
                Map<String, Object> fileData = (Map<String, Object>)f;
                fileList.add(new FileWrapper(
                    (String)fileData.get('id'),
                    (String)fileData.get('name'),
                    (String)fileData.get('createdTime'),
                    (String)fileData.get('webViewLink')
                ));
            }
        }
    } catch (Exception e) {
        throw new AuraHandledException(Label.GoogleD_Fetch_Error + e.getMessage());
    }
    return fileList;
}

public class FileWrapper {
    @AuraEnabled public String id;
    @AuraEnabled public String name;
    @AuraEnabled public String createdTime;
    @AuraEnabled public String webViewLink;

    public FileWrapper(String id, String name, String createdTime, String webViewLink) {
        this.id = id; this.name = name; this.createdTime = createdTime; this.webViewLink = webViewLink;
    }
}


@AuraEnabled
public static void performCredentialReset(List<Id> userIds, String resetType) {
    if (userIds == null || userIds.isEmpty()) return;

    List<User> usersToUpdate = new List<User>();
    List<Access_Audit_Log__c> auditLogs = new List<Access_Audit_Log__c>();
    String notes = Label.Manual_Action_Notes;

    // 1. PERFORM SETUP OPERATIONS (User Update, MFA, Password)
    for (Id uId : userIds) {
        if (resetType == 'Password') {
            System.resetPassword(uId, true);
            auditLogs.add(createLogRecord(uId, 'Password Reset', notes));
        } 
        else if (resetType == 'MFA') {
            try {
                System.UserManagement.deregisterVerificationMethod(uId, Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
                System.UserManagement.deregisterVerificationMethod(uId, Auth.VerificationMethod.U2F);
                auditLogs.add(createLogRecord(uId, 'MFA Reset', 'MFA Methods Deregistered: ' + notes));
            } catch (Exception e) {
                System.debug('MFA Method removal skipped: ' + e.getMessage());
            }
        }
        else if (resetType == 'Deactivate') {
            usersToUpdate.add(new User(Id = uId, IsActive = false));
        }
    }

    if (!usersToUpdate.isEmpty()) {
        update usersToUpdate; // This is a Setup DML
    }

    // 2. ENQUEUE NON-SETUP OPERATIONS (Audit Logs)
    if (!auditLogs.isEmpty()) {
        System.enqueueJob(new SentinelGovernanceQueueable(userIds, auditLogs, resetType));
    }
}
    /**
     * Creates a standardized Audit Log record.
     * This can be called from Batch, Triggers, or LWC.
     */
    public static Access_Audit_Log__c createLogRecord(Id targetUserId, String action, String notes) {
        return new Access_Audit_Log__c(
            Target_User__c = targetUserId,
            Action__c = action,
            Performed_By__c = UserInfo.getUserId(),
            Notes__c = notes
        );
    }

    /**
     * Generic method to send emails using Org-Wide Address and Templates.
     * Centralizing this ensures all emails follow the same security/branding.
     */
    public static void sendGovernanceEmail(List<User> users, String templateDevName) {
        if (users == null || users.isEmpty()) return;

        Governance_Config__mdt config = CustomSettingAndMetaDataUtil.getGovernanceConfig();
        String owaId = (config != null) ? config.OWA_Email_Id__c : null;

        EmailTemplate et;
        try {
            et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateDevName LIMIT 1];
        } catch (QueryException e) {
            System.debug('Email Template Not Found: ' + templateDevName);
            return;
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (User u : users) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(et.Id);
            mail.setTargetObjectId(u.Id);
            mail.setSaveAsActivity(false);
            
            if (String.isNotBlank(owaId)) {
                mail.setOrgWideEmailAddressId(owaId);
            }
            emails.add(mail);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }

/**
 * @description Sends deactivation emails and creates audit logs asynchronously 
 * to avoid MIXED_DML_OPERATION errors between User (Setup) and Audit Log (Non-Setup) objects.
 * @param userIds List of User IDs that were deactivated.
 */
public static void sendDeactivationEmailsSync(List<Id> userIds,String actionType) {
    if (userIds == null || userIds.isEmpty()) return;
    String Notes ='';

    try {
        List<User> users = [
            SELECT Id, Email, ManagerId, Manager.Email, Manager.IsActive, IsActive 
            FROM User 
            WHERE Id IN :userIds
        ];

        if (users.isEmpty()) return;

        List<Access_Audit_Log__c> auditLogs = new List<Access_Audit_Log__c>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        Governance_Config__mdt config = CustomSettingAndMetaDataUtil.getGovernanceConfig();
        String owaId = (config != null) ? config.OWA_Email_Id__c : null;

        EmailTemplate et;
        try {
            et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :Label.User_InActive_Template LIMIT 1];
        } catch (QueryException e) {
            System.debug('CRITICAL: Email Template "User_Deactivation_Template" not found.');
            return; 
        }

        if(actionType==Label.Manual_Deactivation_Action){
            Notes=Label.Manual_Deactivation_Notes;
        }else if(actionType==Label.Auto_Deactivation_Action){
            Notes=Label.Automated_Deactivation_Notes;
        }

        for (User u : users) {
            
           auditLogs.add(createLogRecord(u.Id,actionType,Notes));
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(et.Id);
            mail.setTargetObjectId(u.Id);
            mail.setSaveAsActivity(false);
            mail.setWhatId(u.Id);

            if (String.isNotBlank(owaId)) {
                try {
                    mail.setOrgWideEmailAddressId(owaId);
                } catch(Exception e) {
                    System.debug('OWA ID invalid or not verified. Falling back to Display Name.');
                    mail.setSenderDisplayName(Label.fallback_sender);
                }
            } else {
                mail.setSenderDisplayName(Label.fallback_sender);
            }
            
            emails.add(mail);
        }

        if (!auditLogs.isEmpty()) {
            insert auditLogs;
        }

        if (!emails.isEmpty()) {
            /**
             * CHANGE 2: CAPTURE SEND RESULTS

             */
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
            
            for (Messaging.SendEmailResult res : results) {
                if (!res.isSuccess()) {
                    // This will tell you exactly WHY the email didn't send (e.g., "Invalid Address", "Limit Exceeded")
                    System.debug('EMAIL FAILURE ERROR: ' + res.getErrors()[0].getMessage());
                } else {
                    System.debug('EMAIL SUCCESS: Handed to mail server.');
                }
            }
        }

    } catch (Exception e) {
        System.debug('Error in sendDeactivationEmails: ' + e.getMessage());
    }
}
    /**
     * MANUAL BATCH TRIGGER
     * Starts the deactivation batch if one isn't already running.
     */
    @AuraEnabled
    public static Id runComplianceBatch() {
        List<AsyncApexJob> activeJobs = [
            SELECT Id FROM AsyncApexJob 
            WHERE JobType = 'BatchApex' 
            AND Status IN ('Queued', 'Preparing', 'Processing')
            AND ApexClass.Name = 'UsersDeactivationAndNotificationBatch'
            LIMIT 1
        ];

        if (activeJobs.isEmpty()) {
            // Instantiate the batch and execute
            UsersDeactivationAndNotificationBatch batchInstance = new UsersDeactivationAndNotificationBatch();
            return Database.executeBatch(batchInstance, 200);
        } else {
            throw new AuraHandledException(Label.Identity_Sync_Running);
        }
    }

    /**
     * Allows the LWC to poll for the status of a manually started job.
     */
    @AuraEnabled(cacheable=false)
    public static String checkBatchStatus(Id jobId) {
        if (jobId == null) return 'No Job ID provided';
        
        AsyncApexJob job = [SELECT Status, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id = :jobId];
        return 'Status: ' + job.Status + ' (' + job.JobItemsProcessed + '/' + job.TotalJobItems + ')';
    }

    /**
     * Sends a CSV string to the configured Google Drive folder
     */
    public static void uploadCSVToDrive(String fileName, String csvContent) {
        // 1. Fetch Config from Metadata
        Sentinel_Integration_Setting__mdt config = Sentinel_Integration_Setting__mdt.getInstance(GOOGLE_DRIVE_INSTANCE);
        
        if(config == null) {
            throw new CalloutException(Label.Metadata_Configuration_Missing);
        }

        // 2. Build the Multipart Body
        String boundary = 'sentinel_boundary_' + DateTime.now().getTime();
        String body = '--' + boundary + '\r\n' +
            'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
            '{ ' +
            '"name": "' + fileName + '", ' +
            '"mimeType": "' + config.Mime_Type__c + '", ' +
            '"parents": ["' + config.Folder_ID__c + '"] ' + 
            '}\r\n' +
            '--' + boundary + '\r\n' +
            'Content-Type: text/csv\r\n\r\n' +
            csvContent + '\r\n' +
            '--' + boundary + '--';

        // 3. Setup the Request using the Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + config.Named_Credential__c + config.Endpoint__c);
        req.setMethod(config.HTTP_Method__c);
        req.setHeader('Content-Type', 'multipart/related; boundary=' + boundary);
        req.setBody(body);
        req.setTimeout(60000);

        // 4. Execute Callout
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new CalloutException(Label.GoogleD_Upload_Failed + res.getBody());
        }
    }


        /**
     * This calls your Google Drive service and cleans up permissions
     */
        @AuraEnabled
        public static String purgeAndBackupUser(List<Id> userIds) {
            try {
                if (userIds == null || userIds.isEmpty()) {
                    AuraHandledException ex = new AuraHandledException('No users selected.');
                    ex.setMessage('No users selected.');
                    throw ex;
                }

                List<User> targetUsers = [
                    SELECT Id, Name, Email
                    FROM User
                    WHERE Id IN :userIds
                ];
                Map<Id, User> userMap = new Map<Id, User>(targetUsers);

                List<PermissionSetAssignment> psaList = [
                    SELECT Id, AssigneeId, PermissionSet.Name, PermissionSet.Label
                    FROM PermissionSetAssignment
                    WHERE AssigneeId IN :userIds
                    AND PermissionSet.IsOwnedByProfile = false
                ];

                if (psaList.isEmpty()) {
                    return Label.No_Custom_Permission_Sets_Found;
                }

                List<String> csvLines = new List<String>();
                Set<Id> usersWithAssignments = new Set<Id>();

                for (PermissionSetAssignment psa : psaList) {
                    User u = userMap.get(psa.AssigneeId);
                    if (u != null) {
                        usersWithAssignments.add(u.Id);
                        csvLines.add(
                            escapeCsv(u.Name) + ',' +
                            escapeCsv(u.Email) + ',' +
                            escapeCsv(psa.PermissionSet.Name) + ',' +
                            escapeCsv(psa.PermissionSet.Label)
                        );
                    }
                }

                String csvHeader = Label.User_Permission_Sets_Export_Template;
                String fullCsv = csvHeader + '\n' + String.join(csvLines, '\n') + '\n';

                String timestamp = Datetime.now().format('yyyy-MM-dd_HH-mm-ss');
                String fileName = 'Backup_Psets_' + timestamp + '.csv';

                uploadCSVToDrive(fileName, fullCsv);

                delete psaList;

                List<Access_Audit_Log__c> logs = new List<Access_Audit_Log__c>();
                for (Id userId : usersWithAssignments) {
                    logs.add(
                        createLogRecord(
                            userId,
                            Label.Permission_Purge_Action,
                            Label.Access_Purged_By_Manager + fileName
                        )
                    );
                }

                if (!logs.isEmpty()) {
                    System.enqueueJob(
                        new SentinelGovernanceQueueable(
                            new List<Id>(),
                            logs,
                            ''
                        )
                    );
                }

                return Label.Permissions_Backed_Up_Successfully;

            } catch (Exception e) {
                AuraHandledException ex = new AuraHandledException('Error during purge: ' + e.getMessage());
                ex.setMessage('Error during purge: ' + e.getMessage());
                throw ex;
            }
        }

        private static String escapeCsv(String value) {
            if (String.isBlank(value)) {
                return '';
            }
            String escaped = value.replace('"', '""');
            return '"' + escaped + '"';
        }

@AuraEnabled(cacheable=true)
public static List<UserTeamWrapper> getMyTeam() {
    List<User> users = [
        SELECT Id, Name, Email, End_Date__c, IsActive, Access_Type__c
        FROM User
        WHERE Manager__c = :UserInfo.getUserId()
        ORDER BY End_Date__c DESC
    ];

    Map<Id, Integer> customPsetCountMap = new Map<Id, Integer>();
    List<Id> userIds = new List<Id>();

    for (User u : users) {
        userIds.add(u.Id);
    }

    if (!userIds.isEmpty()) {
        List<AggregateResult> psetCounts = [
            SELECT AssigneeId, COUNT(Id) psetCount
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :userIds
            AND PermissionSet.IsOwnedByProfile = false  // Only custom permission sets
            GROUP BY AssigneeId
        ];

        for (AggregateResult ar : psetCounts) {
            customPsetCountMap.put(
                (Id) ar.get('AssigneeId'),
                (Integer) ar.get('psetCount')
            );
        }
    }

    List<UserTeamWrapper> teamWrappers = new List<UserTeamWrapper>();
    for (User u : users) {
        Integer psetCount = customPsetCountMap.containsKey(u.Id) 
            ? customPsetCountMap.get(u.Id) 
            : 0;
        teamWrappers.add(new UserTeamWrapper(u, psetCount));
    }

    return teamWrappers;
}
public class UserTeamWrapper {
    @AuraEnabled public Id Id;
    @AuraEnabled public String Name;
    @AuraEnabled public String Email;
    @AuraEnabled public Date EndDate; 
    @AuraEnabled public Boolean IsActive;
    @AuraEnabled public String AccessType;
    @AuraEnabled public Integer PsetCount;

    public UserTeamWrapper(User u, Integer psetCount) {
        this.Id = u.Id;
        this.Name = u.Name;
        this.Email = u.Email;
        this.EndDate = u.End_Date__c;  
        this.IsActive = u.IsActive;
        this.AccessType = u.Access_Type__c;
        this.PsetCount = psetCount;
    }
}



}