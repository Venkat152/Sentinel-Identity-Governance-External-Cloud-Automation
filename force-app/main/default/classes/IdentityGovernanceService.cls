/**
 * @description       : Core Service class for Identity & Access Management operations.
 * Handles Credential Resets, Audit Logging, and Notifications.
 * @author            : Venkatesh M
 * @last modified on  : 03-31-2026
 */
public with sharing class IdentityGovernanceService {
    
@AuraEnabled(cacheable=true)
public static List<FileWrapper> getGoogleDriveFiles() {
    List<FileWrapper> fileList = new List<FileWrapper>();
    
    Sentinel_Integration_Setting__mdt config = Sentinel_Integration_Setting__mdt.getInstance('Google_Drive_Default');
    
    if(config == null) {
        throw new CalloutException('Sentinel Metadata configuration is missing.');
    }
    
    // THE FIX: 
    // 1. 'trashed = false' ignores deleted files.
    // 2. ''Folder_ID' in parents' restricts it to your specific Sentinel folder.
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
        throw new AuraHandledException('Drive Fetch Error: ' + e.getMessage());
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

    /**
     * Performs bulk password or MFA resets and logs the action.
     * Used primarily by the Experience Site LWC.
     */
@AuraEnabled
public static void performCredentialReset(List<Id> userIds, String resetType) {
    if (userIds == null || userIds.isEmpty()) return;

    List<User> usersToUpdate = new List<User>();
    List<Access_Audit_Log__c> auditLogs = new List<Access_Audit_Log__c>();
    String notes = 'Manual action triggered via Manager Governance Portal.';

    // 1. PERFORM SETUP OPERATIONS (User Update, MFA, Password)
    for (Id uId : userIds) {
        if (resetType == 'Password') {
            System.resetPassword(uId, true);
            auditLogs.add(createLogRecord(uId, 'Password Reset', notes));
        } 
        else if (resetType == 'MFA') {
            try {
                System.UserManagement.deregisterVerificationMethod(uId, Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
                System.UserManagement.deregisterVerificationMethod(uId, Auth.VerificationMethod.SMS);
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
    // We send the logs to the Queueable to run in a NEW transaction context.
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
            
            // Set CC to Manager if available
            // if (u.ManagerId != null && String.isNotBlank(u.Manager.Email)) {
            //     mail.setCcAddresses(new List<String>{ u.Manager.Email });
            // }

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
            et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'User_Deactivation_Template' LIMIT 1];
        } catch (QueryException e) {
            System.debug('CRITICAL: Email Template "User_Deactivation_Template" not found.');
            return; 
        }

        for (User u : users) {
            // 1. Log creation remains the same
            auditLogs.add(new Access_Audit_Log__c(
                Target_User__c = u.Id,
                Action__c = actionType,
                Performed_By__c = UserInfo.getUserId(),
                Notes__c = 'Async deactivation process started.'
            ));

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
                    mail.setSenderDisplayName('Sentinel Identity Support');
                }
            } else {
                mail.setSenderDisplayName('Sentinel Identity Support');
            }
            
            emails.add(mail);
        }

        if (!auditLogs.isEmpty()) {
            insert auditLogs;
        }

        if (!emails.isEmpty()) {
            /**
             * CHANGE 2: CAPTURE SEND RESULTS
             * We change the second parameter to 'false' to allow partial success 
             * and capture the specific error message from the mail server.
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
        // 20-Year Vet Tip: Always check if the job is already in flight
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
            throw new AuraHandledException('Identity Sync is already running. Please check back in a few minutes.');
        }
    }

    /**
     * BATCH STATUS CHECKER
     * Allows the LWC to poll for the status of a manually started job.
     */
    @AuraEnabled(cacheable=false)
    public static String checkBatchStatus(Id jobId) {
        if (jobId == null) return 'No Job ID provided';
        
        AsyncApexJob job = [SELECT Status, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id = :jobId];
        return 'Status: ' + job.Status + ' (' + job.JobItemsProcessed + '/' + job.TotalJobItems + ')';
    }

    /**
     * STAGE 3 & 6: Unified Upload Method
     * Sends a CSV string to the configured Google Drive folder
     */
    public static void uploadCSVToDrive(String fileName, String csvContent) {
        // 1. Fetch Config from Metadata
        // We use 'Google_Drive_Default' which you created in Stage 2
        Sentinel_Integration_Setting__mdt config = Sentinel_Integration_Setting__mdt.getInstance('Google_Drive_Default');
        
        if(config == null) {
            throw new CalloutException('Sentinel Metadata configuration is missing.');
        }

        // 2. Build the Multipart Body (Google's requirement)
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
        // Uses the 'callout:' prefix + the Named Credential name from Metadata
        req.setEndpoint('callout:' + config.Named_Credential__c + config.Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'multipart/related; boundary=' + boundary);
        req.setBody(body);
        req.setTimeout(60000);

        // 4. Execute Callout
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new CalloutException('Google Drive Upload Failed: ' + res.getBody());
        }
    }

    /**
     * STAGE 6.1: Fetch Team Members for the Manager
     * Shows only inactive users or those nearing expiry
     */
    @AuraEnabled(cacheable=true)
    public static List<User> getMyTeam() {
        return [
            SELECT Id, Name, Email, End_Date__c, IsActive, Access_Type__c
            FROM User 
            WHERE ManagerId = :UserInfo.getUserId()
            AND (IsActive = false OR End_Date__c <= NEXT_N_DAYS:14)
            ORDER BY End_Date__c DESC
        ];
    }

    /**
     * STAGE 6.2: The "Purge & Backup" Action
     * This calls your Google Drive service and cleans up permissions
     */
    @AuraEnabled
    public static String purgeAndBackupUser(Id userId) {
        try {
            // 1. Get User Info for the CSV
            User targetUser = [SELECT Name, Email FROM User WHERE Id = :userId LIMIT 1];
            
            // 2. Get Permission Sets
            List<PermissionSetAssignment> psaList = [
                SELECT PermissionSet.Name, PermissionSet.Label 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :userId 
                AND PermissionSet.IsOwnedByProfile = false
            ];

            if(psaList.isEmpty()) {
                return 'No custom permission sets found for this user.';
            }

            // 3. Generate CSV Content
            String csvHeader = 'User_Name,User_Email,Permission_Set_API_Name,Permission_Set_Label\n';
            String csvRows = '';
            for(PermissionSetAssignment psa : psaList) {
                csvRows += targetUser.Name + ',' + targetUser.Email + ',' + 
                           psa.PermissionSet.Name + ',' + psa.PermissionSet.Label + '\n';
            }
            String fullCsv = csvHeader + csvRows;

            // 4. CALLOUT: Send to Google Drive (Using the service we tested)
            // Generates a filename like: Backup_John_Doe_2026-04-03_14-30-05.csv
            String timestamp = DateTime.now().format('yyyy-MM-dd_HH-mm-ss');
            String fileName = 'Backup_' + targetUser.Name.replaceAll(' ', '_') + '_' + timestamp + '.csv';            // Note: In a real LWC, callouts must happen before DML
            uploadCSVToDrive(fileName, fullCsv); 

            // 5. DML: Delete Assignments
            delete psaList;

            // 6. ASYNC DML: Create Audit Log (To avoid Mixed DML)
            Access_Audit_Log__c log = new Access_Audit_Log__c(
                Target_User__c = userId,
                Action__c = 'Permission Purge',
                Notes__c = 'Access purged by Manager. Backup file created: ' + fileName
            );
            System.enqueueJob(new SentinelGovernanceQueueable(new List<Id>(),new List<Access_Audit_Log__c>{log},''));

            return 'Success: Permissions backed up to Google Drive and removed from Salesforce.';

        } catch (Exception e) {
            throw new AuraHandledException('Error during purge: ' + e.getMessage());
        }
    }
}