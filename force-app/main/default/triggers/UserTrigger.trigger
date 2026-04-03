trigger UserTrigger on User (before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        UserTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        UserTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}