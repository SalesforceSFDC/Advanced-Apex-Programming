@isTest
private class Benchmarking {

	@istest
    public static void testNewAllocate()
    {
        for(Integer x = 0; x<10000; x++) 
            returnNewMap();
    }
    
    private static Map<Integer,String> returnNewMap()
    {
        Map<Integer,String> result = new Map<Integer,String>();
        return result;
    }
    
   @istest
    public static void testSorts()
    {
        List<Integer> unsortedData = new List<Integer>();
        for(Integer x = 0; x<500; x++)
        {
            unsortedData.add(x); unsortedData.add(x+500);
        }
		for(Integer x = 0; x< 10000; x++)
        {
            returnSorted(unsortedData);
        }

    }

    private static List<Integer> returnSorted(List<Integer> inputList)
    {
        List<Integer> sortedList1 = inputList.clone();
        sortedList1.sort();
        return sortedList1;
    }
    

   @istest
    public static void testProperties()
    {
        Lead ld = new Lead(LastName ='test', Email = 'someone@myemail.com');
		for(Integer x = 0; x< 10000; x++)
        {
            checkForSpam(ld);
        }
		for(Integer x = 0; x< 10000; x++)
        {
            checkForSpam2(ld);
        }
		for(Integer x = 0; x< 10000; x++)
        {
            checkForSpam3(ld);
        }

    }

    private static Boolean checkForSpam(Lead ld)
    {
    	if(ld.Email == null) return false;
    	if(ld.Email.endsWithIgnoreCase('@yahoo.com')) return true;
    	if(ld.Email.endsWithIgnoreCase('@gmail.com')) return true;
    	if(ld.Email.endsWithIgnoreCase('@hotmail.com')) return true;
    	return false;
    }

    private static Boolean checkForSpam2(Lead ld)
    {
    	String testEmail = ld.Email;
    	if(testEmail == null) return false;
    	if(testEmail.endsWithIgnoreCase('@yahoo.com')) return true;
    	if(testEmail.endsWithIgnoreCase('@gmail.com')) return true;
    	if(testEmail.endsWithIgnoreCase('@hotmail.com')) return true;
    	return false;
    }    

    private static Boolean checkForSpam3(Lead ld)
    {
    	String testEmail = ld.Email;
    	if(testEmail == null) return false;
    	testEmail = testEmail.toLowerCase();
    	if(testEmail.endsWith('@yahoo.com')) return true;
    	if(testEmail.endsWith('@gmail.com')) return true;
    	if(testEmail.endsWith('@hotmail.com')) return true;
    	return false;
    }  
    
}