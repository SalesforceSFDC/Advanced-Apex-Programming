@isTest
private class Benchmarking {
	
    @istest
    public static void TestNewAllocate()
    {
        for(Integer x = 0; x < 10000; x++)
            ReturnNewMap();
    }    
    
    private static Map<Integer,String> ReturnNewMap()
    {
        Map<Integer,String> result = new Map<Integer,String>();
        return result;
    }
}
