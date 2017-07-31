public class PersonAccountSupport {

	@TestVisible public static Boolean fakePersonAccountDuringTest = false;

	private static Set<string> accountFields = null;

    public static Boolean isPersonAccountOrg()
    {
    	if(accountFields==null) accountFields = 
    		Schema.Sobjecttype.Account.fields.getMap().keyset();
    	return AccountFields.contains('personcontactid');
    }
    
    // Map from contact field to account field
    public static String getPersonAccountAlias(String fieldName)
	{
		fieldName = fieldname.toLowerCase();	// Case insensitive
		
		// Unchanged - FirstName, LastName, etc.
		if(accountFields.contains(fieldName)) return fieldName;

		// Replace aliased __c with __pc
		fieldName = fieldName.replace('__c', '__pc');
		if(accountFields.contains(fieldName)) return fieldname;

		if(accountFields.contains('person' + fieldName)) 
			return ('person' + fieldName);

		return null;
	}
	
	public static void processContactTrigger1(
		Boolean isBefore, List<Contact> newList, Map<ID, Contact> oldMap)
	{
		for(Contact ct: newList)
		{
			if(ct.LeadSource=='Web' || ct.LeadSource=='Phone Inquiry') 
				ct.Level2__c = 'Primary'; 
				else ct.Level2__c = 'Secondary';
		}
	}
	
	public static List<ID> fakePersonContactIDs = null;
	
	private static Boolean updatingPersonContact = false;

	public static void processAccountTrigger1(
		Boolean isBefore, List<Account> newList, Map<ID, Account> oldMap)
	{
		if(!isPersonAccountOrg() && !fakePersonAccountDuringTest || 
			updatingPersonContact) return;

		if(isBefore)
		{
			// Using before approach
			String leadSourceAlias = getPersonAccountAlias('LeadSource');
			String levelAlias = getPersonAccountAlias('Level2__c');
			for(Account act: newList)
			{
				if(leadSourceAlias!=null && levelAlias!=null && 
					(!fakePersonAccountDuringTest && act.get('PersonContactID')!=null))
				{	// Will only be valid on person accounts
					if(act.get(leadSourceAlias)=='Web' || 
						act.get(leadSourceAlias)=='Phone Inquiry')
						act.put(levelAlias,'Primary'); 
						else act.put(levelAlias,'Secondary');
				}
			}
		}
		else
		{	// Better approach can work on after trigger
			Set<ID> personContactIds = new Set<ID>();
			for(Integer x = 0; x<newList.size(); x++)
			{
				if(fakePersonAccountDuringTest || 
					newlist[x].get('PersonContactID')!=null ) 
					personContactIds.add( 
						(fakePersonAccountDuringTest)? 
						fakePersonContactIDs[x]: 
						(ID)newList[x].get('PersonContactID') );
			}
			if(personContactIds.size()==0) return;
			Map<ID, Contact> personContacts = 
				new Map<ID, Contact>(
					[Select ID, LeadSource, Level2__c 
					from Contact where ID in :personContactIds]);
			processContactTrigger1(true, 
				personcontacts.values(), personcontacts);
			updatingPersonContact = true;
			update personcontacts.values();
			updatingPersonContact = false;
		}
		
		
	}
	
}