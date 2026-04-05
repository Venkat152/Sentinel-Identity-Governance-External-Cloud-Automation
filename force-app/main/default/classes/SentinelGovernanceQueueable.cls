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
        // Handle Emails
        if(deactivatedIds != null && !deactivatedIds.isEmpty()) {
            IdentityGovernanceService.sendDeactivationEmailsSync(deactivatedIds, actionType);
        }
        // Handle Logs
        if(pendingLogs != null && !pendingLogs.isEmpty()) {
            insert pendingLogs;
        }
    }
}