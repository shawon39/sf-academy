/**
 * Auth0ProvisioningQueueable — Module 2 mini-project, Session C.
 *
 * The "threading" half of the automation: triggers may NOT make callouts
 * (they run inside the database save), so ContactTrigger enqueues this
 * background job instead. It runs seconds later, calls Auth0, and writes
 * the outcome back onto each Contact.
 *
 * 'implements Database.AllowsCallouts' is the permission slip that lets an
 * async job make HTTP callouts.
 */
public with sharing class Auth0ProvisioningQueueable
        implements Queueable, Database.AllowsCallouts {

    private List<Id> contactIds;

    public Auth0ProvisioningQueueable(List<Id> contactIds) {
        this.contactIds = contactIds;
    }

    public void execute(QueueableContext ctx) {
        List<Contact> toUpdate = new List<Contact>();

        for (Contact c : [SELECT Id, Email FROM Contact
                          WHERE Id IN :contactIds AND Email != null]) {
            try {
                // Random starter password — the portal user resets it on first login.
                String tempPassword = 'Aa1!' + EncodingUtil.convertToHex(
                    Crypto.generateAesKey(128)).left(12);

                String userId = Auth0UserService.createUser(c.Email, tempPassword);

                toUpdate.add(new Contact(
                    Id = c.Id,
                    Auth0_User_Id__c = userId,
                    Provisioning_Status__c = 'Provisioned ' + Date.today().format()
                ));
            } catch (Exception e) {
                // Failures land on the record where an admin will SEE them —
                // never let an integration fail invisibly at 2 AM.
                toUpdate.add(new Contact(
                    Id = c.Id,
                    Provisioning_Status__c = ('ERROR: ' + e.getMessage()).left(255)
                ));
            }
        }
        update toUpdate;
    }
}
