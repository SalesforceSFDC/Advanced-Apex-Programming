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
  
An execution context has two characteristics:
  * It defines the scope and lifetime of the static variables
  * It defines the context for those governor limits that are reset between execution contexts.
  
Static variables are maintained throughout an execution context, and are unique to an execution context.
 
Many (but not all) limits are reset between execution contexts.  For example, if governor limits restrict you to 100 database queries in an execution context, each execution context can have 100 database queries.  Different types of execution contexts may have different limits.


