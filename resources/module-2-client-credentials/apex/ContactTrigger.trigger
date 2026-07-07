/**
 * ContactTrigger — Module 2 mini-project, Session C.
 *
 * Kept tiny on purpose: triggers decide WHEN, classes decide WHAT.
 * When "Provision Portal Access" is newly ticked on a Contact that has no
 * Auth0 id yet, enqueue the background job that calls Auth0.
 *
 * Prerequisite fields on Contact:
 *   Provision_Portal_Access__c (Checkbox)
 *   Auth0_User_Id__c           (Text 100)
 *   Provisioning_Status__c     (Text 255)
 */
trigger ContactTrigger on Contact (after insert, after update) {

    List<Id> needProvisioning = new List<Id>();

    for (Contact c : Trigger.new) {
        Contact old = Trigger.isUpdate ? Trigger.oldMap.get(c.Id) : null;

        Boolean justTicked = c.Provision_Portal_Access__c
            && (old == null || !old.Provision_Portal_Access__c);

        if (justTicked && c.Auth0_User_Id__c == null) {
            needProvisioning.add(c.Id);
        }
    }

    if (!needProvisioning.isEmpty()) {
        System.enqueueJob(new Auth0ProvisioningQueueable(needProvisioning));
    }
}
