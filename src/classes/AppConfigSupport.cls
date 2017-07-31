public with sharing class AppConfigSupport {

	private static AppConfig__c testConfig = null;
	
	public static AppConfig__c getAppConfig()
	{
		if(Test.isRunningTest() && testConfig!=null) return testConfig;
		
		AppConfig__c theobject = AppConfig__c.getInstance('default');
		if(theObject==null || Test.isRunningTest()) 
		{
			theObject = new AppConfig__c();
			theObject.name = 'default';
			theObject.EnableDiagnostics__c = (Test.isRunningTest())? true: false;
			theObject.AppEnabled__c = true;
			if(!Test.isRunningTest()) Database.Insert(theobject);
			else testconfig = theObject;
		}
		return theObject;
	}
	
	public static Boolean diagnosticsEnabled
	{ 
		get
		{
			return GetAppConfig().EnableDiagnostics__c;
		}
	}
	
	public static Boolean appEnabled
	{
		get
		{
			return GetAppConfig().AppEnabled__c;
		}
	}

}