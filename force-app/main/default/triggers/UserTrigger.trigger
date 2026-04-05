trigger UserTrigger on User (before insert, before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        UserTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        UserTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isBefore && Trigger.IsInsert){
        UserTriggerHandler.handlerBeforeInsert(Trigger.new);
    }
}