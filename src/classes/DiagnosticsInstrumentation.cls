public without sharing class DiagnosticsInstrumentation {

	//public static Boolean diagnosticsEnabled = true;	// Chapter 9
	public static Boolean diagnosticsEnabled = AppConfigSupport.diagnosticsEnabled;
	
	private static List<DiagnosticEntry> diagnosticLog;
	private static Integer currentLevel = 0;

	private static List<String> stackTrace = new List<String>();
	public static string exceptionTrace = '';

	private class DiagnosticEntry
	{
		Integer level;
		String description;
		
		public diagnosticEntry(string entryDescription)
		{
			level = currentLevel;
			description = entryDescription;
		}
	}

	public static void push(String functionName)
	{
		debug('Entering: ' + functionName);
		currentLevel+=1;
		stacktrace.add(functionName);
	}
	
	public static void debug(String debugString)
	{
		if(!diagnosticsEnabled) return;
		if(diagnosticLog==null) diagnosticLog = new List<DiagnosticEntry>();
		diagnosticLog.add(new DiagnosticEntry(debugString));
	}
	
	public static void debugException(Exception ex)
	{
		String exceptionInfo = 'Exception occurred line ' + 
			ex.getLineNumber() + ' - ' + ex.getMessage() + 
			' stack: ' + ex.getStackTraceString();
		debug(exceptionInfo);
		DebugInfo__c dbg = new DebugInfo__c(DebugData__c = currentLog());
		exceptionTrace = ' Exception occurred line ' + 
			ex.getLineNumber() + ' - ' + ex.getMessage();
		for(String st: stackTrace) exceptionTrace += ' | ' + st;
		exceptionTrace += ' |\n ';
		if(diagnosticsEnabled) insert dbg;
	}

	public static void pop()
	{
		if(currentLevel>0) currentLevel-=1;
		if(currentLevel==0) System.Debug(LoggingLevel.Info, 
			'Diagnostic Log\n' + currentLog());
		if(stackTrace.size()>0) 
			stackTrace.remove(stackTrace.size()-1);
	}
	
	public static void popAll()
	{
		currentLevel=0;
		pop();
	}
	
	public static String currentLog()
	{
		if(diagnosticLog == null) return null;
		String spaces = '                                                                        ';
		String result = '';
		for(DiagnosticEntry de: diagnosticLog)
		{
			Integer endIndex = 3 * de.level;
			if(endIndex >= spaces.length()) endIndex = spaces.length()-1;
			result += spaces.substring(0,endIndex) + de.description + '\n';
		}
		return result;
	}
	

}