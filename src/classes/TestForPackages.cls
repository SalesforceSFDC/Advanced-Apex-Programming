@istest(seealldata = true)
public class TestForPackages {

    static testMethod void recordTypeTest() {
    	// This will fail to work on any org that doesn't have record types defined on leads
    	// List<Lead> rtypes = [Select ID, RecordTypeID from Lead Limit 1];

		Boolean leadHasRecordType = 
			Schema.Sobjecttype.Lead.Fields.getMap().containskey('recordtypeid');
		
		String fieldString = 'ID ';
		if(leadHasRecordType) fieldString += ', RecordTypeID ';
		List<Lead> rtypes = 
			Database.Query('Select ' + fieldstring + ' from Lead Limit 1');
		if(rtypes.size()>0 && leadHasRecordType)
		{
			system.debug(rtypes[0].get('RecordTypeID'));
		}    	
    	system.debug(fieldString + ' ' + rtypes);
    }
    
    static testMethod void addProduct()
    {
    	// Adding this line adds a Product2 dependency to the package
    	//List<Product2> aproduct = [Select ID from Product2 Limit 1];
    }
    
	static testmethod void testPersonAccount()
	{
		PersonAccountSupport.isPersonAccountOrg();
	}
	
	static testmethod void testCorporateCurrency()
	{
		String corporate = corporateCurrency;
	}
	
	private static Map<String,double> 
		cachedCurrencyConversionMap = null;
	
	private static string m_CorporateCurrency = null;
	
	public static string corporateCurrency {
		get {
			getCurrencyConversionMap();
			return corporateCurrency;
		}
	}
	
	public static Map<String, double> getCurrencyConversionMap()
	{
		Boolean currencyTestMode = false;

		if(cachedCurrencyConversionMap!=null) 
			return cachedCurrencyConversionMap;

		if(Test.isRunningTest() && 
			!userinfo.isMultiCurrencyOrganization()) 
			currencyTestMode = true;
		if(!userinfo.isMultiCurrencyOrganization() && 
			!currencyTestMode) return null;

		List <SObject> ctypes = null;
		if(!currencyTestMode) ctypes  = 
			database.query('Select conversionrate, isocode, iscorporate from currencytype');

		Map<String, double> isoMap = new Map<String, double>();
		if(!currencyTestMode)
		{
			for(SObject ct: ctypes)
			{
				string ctCode = string.ValueOf(ct.get('isocode'));
				if(Boolean.valueOf(ct.get('iscorporate'))) 
				{
					m_CorporateCurrency = ctCode;
				}
				double conversionRate = double.valueOf(ct.get('conversionrate'));
				if(conversionRate!=0) isoMap.put(ctcode, 1/conversionRate);
			}
		}
		cachedCurrencyConversionMap = (currencyTestMode)? null: isoMap;
		return cachedCurrencyConversionMap;	
	}	
}