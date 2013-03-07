CocoaPort
=========

CocoaPort is an asynchronous, futures-based distributed objects library for Objective-C.

It is loosely modeled on the distributed objects system included with Mac OS X (NSPort/NSConnection/NSDistantObject) however, it differs in a number of ways:


### Non-blocking remote method calls

References to distant objects are treated differently. In Foundation's distributed objects system, an NSDistantObject is a transparent proxy of the distant object. This has a number of problems. Calling a method on a distant object where the return value is required will block until the result is received. This is easy to do, as distant objects otherwise behave like the objects they represent:

	// returns an NSDistantObject
	employee = [self findEmployee];

	[employeeField setTextValue:[employee name]];


Calling a method with a return value on a CocoaPort distant object returns immediately. The returned object is a future, representing the message invocation. The method is not actually called until we resolve the future by sending it over the port.

This separates the act of constructing a remote invocation from the act of invoking it, which (aside from other benefits), allows us to adapt methods with return values into methods that return via an asynchronous callback. It also makes it much more explicit when we're doing something that might have some latency:

	// returns a future
	employee = [self findEmployee];

	[port send:[employee name] copyResponse:^(NSString* name, NSError* error){
		[employeeField setTextValue:name];
	}];


### Extensible transport methods

Although there are various NSConnection subclasses for different connection types, it is not extensible. CocoaPort currently defines one connection type --- CPSocketConnection --- which wraps an instance of GCDAsyncSocket. It would be quite straightforward to allow connections over XPC, http, Bluetooth, Mach ports, and so on, by creating new classes that conform to CPConnection.

### Support for iOS

Communication between iOS and OSX is possible and working. Not thoroughly tested.



Usage
-----

### Basic

The two principle interfaces in CocoaPort are the class CPPort and the protocol CPConnection. A CPConnection represents a connection between two CPPort instances. A CPPort is initialized with a CPConnection. Once two connected CPPorts are set up, they are able to exchange messages.

Each CPPort instance has a property rootObject:

	_employee = [[Employee alloc] init];
	[_port setRootObject:_employee]


Once set, calling [port remote] on the other CPPort returns a future representing the root object:

	// returns a future
	employee = [port remote];


Messages sent to this object return a future that can be sent over the port...

	[port send:[employee name] copyResponse:^(NSString* name, NSError* error){
		[employeeField setTextValue:name];
	}];


... or used to create another future. This gives us a method of constructing complex invocations that are resolved all at once:

	// returns a future representing the root object
	employee = [port remote];

	// returns a future representing [<root object> department]
	department = [employee department];

	// returns a future representing [[<root object> department] building]
	building = [department building];

	[port send:[building name] copyResponse:^(NSString* name, NSError* error){
		[buildingField setTextValue:name];
	}];


Futures created by passing an object as an argument will archive the object when sent...

	[aFuture employeeWithID:@"3105"]


... when received, the argument is unarchived and passed to the method:

	- (Employee*) employeeWithID:(NSString*)eid
	{
		// receives an NSString*
	}


However, if a future is created by passing another future as an argument...

	[aFuture departmentForEmployee:[aFuture employeeWithID:@"3105"]];



... the future is resolved, and the result is passed as the argument:

	- (Department*) departmentForEmployee:(Employee*)employee
	{
		// receives an Employee*
	}


### Obtaining futures

Calling [CPPort remote] and sending messages to a future are two ways of getting futures. There are several others:

- Just as the method [CPPort send:copyResult:] sends a future and responds with a copy of its resolution, [CPPort send:refResult:] sends a future, and responds with a future referencing the result of the sent future. The referenced object will be retained until the reference is deallocated or the port is disconnected.

- The methods describe so far are all initiated by the user of the future. When a method expects to receive af CPPort method [CPPort reference:] returns a proxy object allowing a reference to a local object to to passed to a remote method expecting a future.

- If a remote object is observed using KVO, changes can be sent as copies or references.


Status
------

CocoaPort is functional but should be considered unfinished and not yet ready for use in production. However, if you are interested in using this in an application (and some people are), you are more than welcome to contribute and help it get to a production-ready state!

Known issues:

- The current API for CPSocketConnection does not enforce the use of SSL, or any alternative methods of verifying the authenticity of messages. At present, if used over a socket, the socket should at minimum be secured using SSL. This may not be suitable for certain applications, so the API should be improved to support alternative methods of message authentication (eg., via a security key).
- Methods that take non-object types as arguments do not work.
- Test coverage could be improved.


Contributing
------------

Pull requests welcome! When contributing, please:

* Make your changes on a branch.
* Write tests that reproduce any bugs you have fixed / test the feature you've added.
* Raise an issue suggesting the changes you want to make before doing any work to alter the API or change from current behaviour. 


Licence
-------

CocoaPort is released under an MIT licence.
