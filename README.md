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

Ramifications of the execution context:
 * You can have multiple triggers on an event, but have no control over the order in which they execute.
 * Limits are shared within an Execution Context, thus you may be sharing limits with other code over which you have no control and which may be added after yours is built and tested.
 * Workflows can impact the order and execution context in unpredictable ways.

### Static Variables

Static variables are maintained throughout an execution context, and are unique to an execution context.
 
Many (but not all) limits are reset between execution contexts.  For example, if governor limits restrict you to 100 database queries in an execution context, each execution context can have 100 database queries.  Different types of execution contexts may have different limits.

You know when the execution context starts.  Generally, cant know when it ends.

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
 **
