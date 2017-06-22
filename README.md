# Advanced-Apex-Programming

![Apex Code Structure](https://s-media-cache-ak0.pinimg.com/originals/3d/ae/7c/3dae7cafff48d9440cd6928a23f3e4dd.png)

Apex constructs:
 * support for single inheritance
 * interfaces
 * template support
 * control flow structures
 * operators
 * variable declarations
 
Apex concepts:
  * Execution Contexts
  * Static Variables
  * Bulk Patterns
  * Limits

### Execution Context

An execution context has two characteristics:
  * It defines the scope and lifetime of the static variables
  * It defines the context for those governor limits that are reset between execution contexts.
  * There is a limit to the size of memory heap you can use in an execution context.

Ramifications of the execution context:
 * You can have multiple triggers on an event, but have no control over the order in which they execute.
 * Limits are shared within an Execution Context, thus you may be sharing limits with other code over which you have no control and which may be added after yours is built and tested.
 * Workflows can impact the order and execution context in unpredictable ways.

### Static Variables

Static variables are maintained throughout an execution context, and are unique to an execution context.
 
Many (but not all) limits are reset between execution contexts.  For example, if governor limits restrict you to 100 database queries in an execution context, each execution context can have 100 database queries.  Different types of execution contexts may have different limits.

You know when the execution context starts.  Generally, cant know when it ends.

 * Static variable's lifetime and scope is defined by the execution context.

### Running Apex Code

An execution context begins when one of a number of possible external events or operations happen that have the ability to start running Apex code.  These include:
 * A database trigger: Triggers can occur on insertion, update, deletion or undeletion of many standard Salesforce objects and all custom objects.
 * Future call (asynchronous call): Future calls can be requested from Apex code.  They run with extended limits.
 * Scheduled Apex: You can implement an Apex class that can be called by the system on a scheduled basis.
 * Batch Apex: You can implement a class designed to process large numbers of database records.
 * Web service: You can implement a class that can be accessed via SOAP or REST from an external site or from Javascript on a web page.
 * Visualforce: Visualforce pages can execute Apex code in Visualforce controllers to retrieve or set page properties or execute methods.
 * Global Apex: You can expose a global method that can be called from other Apex code.
 * Anonymous Apex: Apex code can be compiled and executed dynamically from the developer console, Force.com IDE or through an external web service call.
 
`public Static Boolean firstcall = false;`  - Use the following design pattern in your trigger to determine if this was the first or subsequent call for this execution context 

```Apex
if(!myclass.firstcall)
{
  // First call into trigger
  myclass.firstcall = true;
}
else
{
  // Subsequent call into trigger
}
```
Static variables in Apex have execution context scope and lifetime.  

### Event Handler

 * Event handler is a callback routine that operates asynchronously and handles inputs received into a program (events).  In this context, an event is some meaningful element of application information from an underlying development framework, usually from a GUI toolkit or some kind of input routine.  
 * On the GUI side, events include key strokes, mouse activity, action selections, or timer expirations.  
 * On the input side, events include opening or closing files and data streams, reading data, etc.

### Future Calls

* Future calls execute at some indeterminate time in the future, but because platform can schedule them based on server load, they are granted higher limits than other execution contexts, and are thus ideal for computationally intensive tasks.
* You can only make up to ten future calls from an execution context, and you cant make a future call from a future context.
* In Apex, you have no way knowing that you are exiting the execution context.

```Apex
// indicates that the call has already been made
public class SomeFutureOperations {
 private static Boolean FutureCallCalled = false;
 public static void DoFutureCall()
 {
  if(FutureCallCalled || 
   System.isFuture()) return;
  FutureCallCalled = true;
  ActualFutureCall();
 }
 
 @future
 private static void ActualFutureCall()
 {
  // Actual async code here
  system.debug('ActualFutureCall async operation');
 }
  
}
```

### Trigger Patterns

https://help.salesforce.com/articleView?id=000176390&type=1


### Testing, Debugging and Deployment

* You must have unit tests that cover at least 75% of your code to deploy software to production org.
* 

```Apex
public static String CurrentLog()
{
    if(DiagnosticLog == null) return null;
    String spaces = '                       ';
    String result = '';
    for(DiagnosticEntry de: DiagnosticLog)
    {
        Integer endindex = 3 * de.level;
        if(endindex >= spaces.length())
            endindex = spaces.length()-1;
        result += spaces.substring(0,endindex) +
            de.description + '\n';
    }
    return result;
}
```

### Debugging and Diagnostics

Test-driven development environment.

* Debugging is the process of figuring out why software is working incorrectly and fixing the problem.  To debug software you want to have the following:
    * A way to reproduce the problem
    * A way to capture data about the problem
    * A way to modify the code to try different ways of solvign the problem
    
* Diagnostics - capturing data about the operation of the software.

During development, the easiest way to reproduce an error is using test classes.

* `SeeAllData` attribute on a test class to view or hide existing data in an org.  
* Unlike test classes, anonymous Apex works on actual data.
* Breakpoints - 
* Watchpoints - 

* The primary source for capturing runtime data from Apex are the debug logs.  The debug logs have the following characteristics:
   * They are limited in size.
   * You can control the level of detail of the data you are capturing at the class level.  Capture enough detail and you can view the values of variables - but you are more likely to exceed the max log size.
   * You can use the System.debug statement to add debug data to the log.  Those statements can hard to find in large debug logs.
   * The Developer Console has the ability to extract and organize data from the debug logs, but only if the debug logs dont exceed a certain size.
   * The platform stores only a limited number of debug logs.
   * When instructed to capture debug logs, the monitoring continues for a limited time or number of logs.  Continuous logging is possible for the current user using the Developer Console, though the number of logs kept is limited.
   * Debug logs are generated for a particular running user.
   * Debug logs do not capture detailed data from managed packages unless you are the package owner and log in via the Subscriber portal.

Debug cycle:
* Reproduce the error to obtain a log file and find a problem
* Add some debugging code
* Override the detail level of one or more classes so as not to exceed the max debug log size
* Repeat

The DiagnosticInstrumentation class starts by defining some static variables along with the DiagnosticEntry class that contains the current level and description of a diagnostic entry:

```Apex
public static Boolean DiagnosticEnabled = true;

private static List<DiagnosticEntry> DiagnosticLog;
private static Integer CurrentLevel = 0;

private class DiagnosticEntry
{
  Integer level;
  String description;
  
  public DiagnosticEntry(string entrydescription)
  {
    level = CurrentLevel;
    description = entrydescription;
  }
}
```

The DiagnosticEnabled flag makes it possible to enable or disable the diagnostic system.  This is important because the diagnostics code does use script lines, and in later implementations, performs SOQL and DML calls as well.  Disable the diagnostics in cases where limits are an issue.

### Benchmarking

* Place the operation you want to measure inside of the loop, perform the operation multiple times, then divide the time spent by the number of iterations.

```Apex
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
```
## Bulk Patterns

* Salesforce does not support triggers on the `OpportunityContactRole` object.
* Test-driven design methodology.
Test goals: 
	* Does the code work?
	* Obtaining code coverage
	* Handling invalid input
	* 
