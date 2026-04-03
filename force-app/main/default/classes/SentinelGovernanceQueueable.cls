public class SentinelGovernanceQueueable implements System.Queueable {
    private List<Id> deactivatedIds;
    private List<Access_Audit_Log__c> pendingLogs;
    private String actionType;

    public SentinelGovernanceQueueable(List<Id> ids, List<Access_Audit_Log__c> logs, String type) {
        this.deactivatedIds = ids;
        this.pendingLogs = logs;
        this.actionType = type;
    }

public void execute(System.QueueableContext context) {
    // 1. Handle Emails First
    if (deactivatedIds != null && !deactivatedIds.isEmpty()) {
        try {
            IdentityGovernanceService.sendDeactivationEmailsSync(deactivatedIds, actionType);
        } catch (Exception e) {
            System.debug('Email processing failed: ' + e.getMessage());
        }
    }

    // 2. Handle Logs with Partial Success Allowed
    if (pendingLogs != null && !pendingLogs.isEmpty()) {
        // allOrNone = false allows valid logs to insert even if some fail
        Database.SaveResult[] results = Database.insert(pendingLogs, false);
        
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Log Insertion Error: ' + err.getMessage());
                }
            }
        }
    }
}
}