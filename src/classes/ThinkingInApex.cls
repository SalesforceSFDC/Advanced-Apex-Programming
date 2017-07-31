public class ThinkingInApex {

	public class SimpleFieldAccess {
		User u = [Select UserIsSpecial__c from User 
					where ID = :UserInfo.getUserId()];
	    Boolean userIsSpecial = u.UserIsSpecial__c;
	}

/* First example

	private static Boolean isUserSpecialChecked = false;
	private static Boolean userIsSpecial = false;
	
	public static Boolean isUserSpecial()
	{
		if(isUserSpecialChecked) return userIsSpecial;
		
		User u = [Select UserIsSpecial__c from User 
			where ID = :UserInfo.getUserId()];
    	userIsSpecial = u.UserIsSpecial__c;
    	isUserSpecialChecked = true;
    	return userIsSpecial;
		
	}

*/

	private static Boolean userCacheLoaded = false;
	private static Boolean userIsSpecial = false;
	private static String userTimeZone = null;	

	public static Boolean isUserSpecial()
	{
		if(userCacheLoaded) return userIsSpecial;
		cacheUserInfo();
		return userIsSpecial;	
	}

	public static String userTimeZone()
	{
		if(userCacheLoaded) return userTimeZone;
		cacheUserInfo();
		return userTimeZone;	
	}

	
	private static void cacheUserInfo()
	{
		if(userCacheLoaded) return;
		User u = [Select UserIsSpecial__c, TimeZoneSidKey 
			from User where ID = :UserInfo.getUserId()];
    	userIsSpecial = u.UserIsSpecial__c;
    	userTimeZone = u.TimeZoneSidKey;
		userCacheLoaded = true;
	}


	public static List<Contact> associateContacts = null;

	/* First version of afterInsertOpportunity - does not insert opportunity contact roles 
	
	public static void afterInsertOpportunity(
		List<Opportunity> newList, Map<ID, Opportunity> newMap)
	{

		List<OpportunityContactRole> ocrs = 
			[SELECT ID, ContactID, IsPrimary, OpportunityID 
				from OpportunityContactRole 
				where OpportunityID in :newMap.keyset()];

		Set<ID> ocrOpportunities = new Set<ID>();

		for(OpportunityContactRole ocr: ocrs) 
			ocrOpportunities.add(ocr.OpportunityID);
		
		for(Opportunity op: newList)
		{
			if(! ocrOpportunities.contains(op.id)) 
				op.addError('Opportunity Contact Role is required to create an opportunity');
		}
		
		// Other functionality
		
	}
	*/
	
	public static void afterInsertOpportunity(
		List<Opportunity> newList, Map<ID, Opportunity> newMap)
	{

		if(AssociateContacts!=null) 
			createSomeContactRoles(newList, associateContacts);
		
		List<OpportunityContactRole> ocrs = 
			[SELECT ID, ContactID, IsPrimary, OpportunityID 
				from OpportunityContactRole 
				where OpportunityID in :newMap.keyset()];

		Set<ID> ocrOpportunities = new Set<ID>();

		for(OpportunityContactRole ocr: ocrs) 
			ocrOpportunities.add(ocr.OpportunityID);
		
		for(Opportunity op: newList)
		{
			if(! ocrOpportunities.contains(op.id)) 
				op.addError('Opportunity Contact Role is required to create an opportunity');
		}
		
		// Other functionality
		
	}

	
	private static void createSomeContactRoles(
		List<Opportunity> ops, List<Contact> cts)
	{
		List<OpportunityContactRole> newOcrs = 
			new List<OpportunityContactRole>();
		
		for(Integer x = 0; x< ops.size(); x++)
		{
			newOcrs.add(
				new OpportunityContactRole(
					OpportunityID = ops[x].id, 
					ContactID = cts[x].id, 
					IsPrimary = true));
		}
		insert newOcrs;		
	}




}