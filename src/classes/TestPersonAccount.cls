@istest
public class TestPersonAccount {

    static testMethod void testWithContacts() {
        List<Contact> contacts = TestDiagnostics2.createContacts('patst', 3);
        contacts[0].LeadSource='Web';
        contacts[1].LeadSource='Phone Inquiry';
        contacts[2].LeadSource='Other';
        Test.StartTest();
        insert contacts;
        Test.StopTest();
        // Seealldata is false, so we'll get the same 3 contacts
        Map<ID, Contact> contactMap = 
        	new Map<ID, Contact>([Select ID, Level2__c from Contact Limit 3]);
       	system.assertEquals(contactMap.get(contacts[0].id).Level2__c,'Primary');
       	system.assertEquals(contactMap.get(contacts[1].id).Level2__c,'Primary');
       	system.assertEquals(contactMap.get(contacts[2].id).Level2__c,'Secondary');
    }
    
    static testMethod void testWithAccounts() {
        List<Contact> contacts = 
        	TestDiagnostics2.createContacts('patst', 3);
        List<Account> accounts = 
        	TestDiagnostics2.createAccounts('patest', 3);
        contacts[0].LeadSource='Web';
        contacts[1].LeadSource='Phone Inquiry';
        contacts[2].LeadSource='Other';
        PersonAccountSupport.fakePersonContactIDs = new List<ID>();
        PersonAccountSupport.fakePersonAccountDuringTest = true;
        insert contacts;
        for(Contact ct: contacts) 
        	PersonAccountSupport.fakePersonContactIDs.add(ct.id);
        Test.StartTest();
        insert accounts;
        Test.StopTest();
        // Seealldata is false, so we'll get the same 3 contacts
        Map<ID, Contact> contactMap = 
        	new Map<ID, Contact>(
        		[Select ID, Level2__c 
        		from Contact Limit 3]);
       	system.assertEquals(contactMap.get(contacts[0].id).Level2__c,'Primary');
       	system.assertEquals(contactMap.get(contacts[1].id).Level2__c,'Primary');
       	system.assertEquals(contactMap.get(contacts[2].id).Level2__c,'Secondary');
    }  

}