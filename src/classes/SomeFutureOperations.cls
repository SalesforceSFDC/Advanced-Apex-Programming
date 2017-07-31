public class SomeFutureOperations {
	
	private static Boolean futureCallCalled = false;
	
	public static void doFutureCall()
	{
		if(futureCallCalled || System.isFuture()) return;
		futureCallCalled = true;
		actualFutureCall();
		// Code to call async here
	}
	
	@future
	private static void actualFutureCall()
	{
		// Actual async code here
		system.debug('actualFutureCall async operation');
	}
	
	

}