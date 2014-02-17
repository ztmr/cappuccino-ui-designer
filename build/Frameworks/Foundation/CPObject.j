/*! 
    @class CPObject
    @ingroup foundation
    @brief Base class for all CP Objects
*/


@import "CPObjJRuntime.j"


@implementation CPObject
{
    Class   isa;

    
}

+ (void)load
{
}

+ (void)initialize
{    
}

/*!
    Allocates a new instance of the receiver, and sends it an \c -init
    @return the new object
*/
+ (id)new
{
    return [[self alloc] init];
}

/*!
    Allocates a new instance of the receiving class
*/
+ (id)alloc
{
     
    return class_createInstance(self);
}



+ (id)allocWithCoder:(CPCoder)aCoder
{
    return [self alloc];
}

/*!
    Initializes the receiver
    @return the initialized receiver
*/
- (id)init
{      
    return self;
}

/*!
    Makes a deep copy of the receiver. The copy should be functionally equivalent to the receiver.
    @return the copy of the receiver
*/
- (id)copy
{
    return self;
}

/*!
    Creates a deep mutable copy of the receiver.
    @return the mutable copy of the receiver
*/
- (id)mutableCopy
{
    return [self copy];
}

// Identifying classes
/*!
    Returns the Class object for this class definition.
*/
+ (Class)class
{
    return self.isa ;
}

/*!
    Returns the receiver's Class
*/
- (Class) class
{
    return self.isa ;
}

/*!
    Returns the class object super class
*/
+ (Class)superclass
{
    return self.super_class;
}

/*!
    Returns \c YES if the receiving class is a subclass of \c aClass.
    @param aClass the class to test inheritance from
*/
+ (BOOL)isSubclassOfClass:(Class)aClass
{
    var theClass = self.isa;

    for (; theClass; theClass = theClass.super_class)
        if (theClass === aClass)
            return YES;

    return NO;
}

/*!
    Returns \c YES if the receiver is a \c aClass type, or a subtype of it.
    @param aClass the class to test as the receiver's class or super class.
*/
- (BOOL)isKindOfClass:(Class)aClass
{
    return [self.isa isSubclassOfClass:aClass];
}

+ (BOOL)isKindOfClass:(Class)aClass
{
    return [self isSubclassOfClass:aClass];
}

/*!
    Returns \c YES if the receiver is of the \c aClass class type.
    @param aClass the class to test the receiver
*/
- (BOOL)isMemberOfClass:(Class)aClass
{
    return self.isa === aClass;
}

+ (BOOL)isMemberOfClass:(Class)aClass
{
    return self === aClass;
}

/*!
    Determines whether the receiver's root object is a proxy.
    @return \c YES if the root object is a proxy
*/
- (BOOL)isProxy
{
    return NO;
}

// Testing class functionality
/*!
    Test whether instances of this class respond to the provided selector.
    @param aSelector the selector for which to test the class
    @return \c YES if instances of the class respond to the selector
*/
+ (BOOL)instancesRespondToSelector:(SEL)aSelector
{
    return !!class_getInstanceMethod(self, aSelector);
}

/*!
    Tests whether the receiver responds to the provided selector.
    @param aSelector the selector for which to test the receiver
    @return \c YES if the receiver responds to the selector
*/
- (BOOL)respondsToSelector:(SEL)aSelector
{
    // isa is isa.isa in class case.
    return !!class_getInstanceMethod(self.isa, aSelector);
}

/*!
    Tests whether the receiver implements to the provided selector regardless of inheritance.
    @param aSelector the selector for which to test the receiver
    @return \c YES if the receiver implements the selector
*/
- (BOOL)implementsSelector:(SEL)aSelector
{
    var methods = class_copyMethodList(self.isa),
        count = methods.length;

    while (count--)
        if (method_getName(methods[count]) === aSelector)
            return YES;

    return NO;
}

// Obtaining method information

/*!
    Returns the implementation of the receiver's method for the provided selector.
    @param aSelector the selector for the method to return
    @return the method implementation ( a function )
*/
- (IMP)methodForSelector:(SEL)aSelector
{
    return class_getMethodImplementation(self.isa, aSelector);
}

/*!
    Returns the implementation of the receiving class' method for the provided selector.
    @param aSelector the selector for the class method to return
    @return the method implementation ( a function )
*/
+ (IMP)instanceMethodForSelector:(SEL)aSelector
{
    return class_getMethodImplementation(self, aSelector);
}

/*!
    Returns the method signature for the provided selector.
    @param aSelector the selector for which to find the method signature
    @return the selector's method signature
*/
- (CPMethodSignature)methodSignatureForSelector:(SEL)aSelector
{
    // FIXME: We need to implement method signatures.
    return nil;
}

// Describing objects
/*!
    Returns a human readable string describing the receiver
*/
- (CPString)description
{
    return "<" + self.isa.name + " 0x" + [NSString stringWithHash:[self UID]] + ">";
}

+ (CPString)description
{
    return self.isa.name; 
}

// Sending Messages
/*!
    Sends the specified message to the receiver.
    @param aSelector the message to send
    @return the return value of the message
*/
- (id)performSelector:(SEL)aSelector
{
    return objj_msgSend(self, aSelector);
}

/*!
    Sends the specified message to the receiver, with one argument.
    @param aSelector the message to send
    @param anObject the message argument
    @return the return value of the message
*/
- (id)performSelector:(SEL)aSelector withObject:(id)anObject
{
    return objj_msgSend(self, aSelector, anObject);
}

/*!
    Sends the specified message to the receiver, with two arguments.
    @param aSelector the message to send
    @param anObject the first message argument
    @param anotherObject the second message argument
    @return the return value of the message
*/
- (id)performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject
{
    return objj_msgSend(self, aSelector, anObject, anotherObject);
}

/*!
    Sends the specified message to the reciever, with any number of arguments.
    @param aSelector the message to send
    @param anObject... comma seperated objects to pass to the selector
    @return the return value of the message
*/
- (id)performSelector:(SEL)aSelector withObjects:(id)anObject, ...
{
    var params = [self, aSelector].concat(Array.prototype.slice.apply(arguments, [3]));
    return objj_msgSend.apply(this, params);
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return nil;
}

// Forwarding Messages
/*!
    Subclasses can override this method to forward message to
    other objects. Overwriting this method in conjunction with
    \c -methodSignatureForSelector: allows the receiver to
    forward messages for which it does not respond, to another object that does.
*/
- (void)forwardInvocation:(CPInvocation)anInvocation
{
    [self doesNotRecognizeSelector:[anInvocation selector]];
}

// Error Handling
/*!
    Called by the Objective-J runtime when an object can't respond to
    a message. It's not recommended to call this method directly, unless
    you need your class to not support a method that it has inherited from a super class.
*/
- (void)doesNotRecognizeSelector:(SEL)aSelector
{
     CPLog.error(self.isa.name + "does not recognize selector " + aSelector);
}
 
/*!
    Returns the class name
*/
- (CPString)className
{ 
    return self.isa.name;
}



/*!
    Returns a hash for the object
*/
- (unsigned)hash
{
    return [self UID];
}

- (CPString)UID
{
     return self._UID; 
}

/*!
    Determines if \c anObject is functionally equivalent to the receiver.
    @return \c YES if \c anObject is functionally equivalent to the receiver.
*/
- (BOOL)isEqual:(id)anObject
{
    return self === anObject || [self UID] === [anObject UID];
}

/*!
    Does nothing.
    @return the receiver
*/
- (id)retain
{
    return self;
}
 
/*!
    Returns the receiver.
*/
- (id)self
{
    return self;
}

/*!
    Returns the receiver's super class.
*/
- (Class)superclass
{
    return self.isa.super_class;
}

// Archiving
/*!
    Subclasses override this method to possibly substitute
    the unarchived object with another. This would be
    useful if your program utilizes a
    <a href="http://en.wikipedia.org/wiki/Flyweight_pattern">flyweight pattern</a>.
    The method is called by CPCoder.
    @param aCoder the coder that contained the receiver's data
*/
- (id)awakeAfterUsingCoder:(CPCoder)aCoder
{
    return self;
}

/*!
    Can be overridden by subclasses to substitute a different class to represent the receiver for keyed archiving.
    @return the class to use. A \c nil means to ignore the method result.
*/
- (Class)classForKeyedArchiver
{
    return [self classForCoder];
}

/*!
    Can be overridden by subclasses to substitute a different class to represent the receiver during coding.
    @return the class to use for coding
*/
- (Class)classForCoder
{
    return [self class];
}

/*!
    Can be overridden by subclasses to substitute another object during archiving.
    @param anArchiver that archiver
    @return the object to archive
*/
- (id)replacementObjectForArchiver:(CPArchiver)anArchiver
{
    return [self replacementObjectForCoder:anArchiver];
}

/*!
    Can be overridden by subclasses to substitute another object during keyed archiving.
    @param anArchive the keyed archiver
    @return the object to archive
*/
- (id)replacementObjectForKeyedArchiver:(CPKeyedArchiver)anArchiver
{
    return [self replacementObjectForCoder:anArchiver];
}

/*!
    Can be overridden by subclasses to substitute another object during coding.
    @param aCoder the coder
    @return the object to code
*/
- (id)replacementObjectForCoder:(CPCoder)aCoder
{
    return self;
}

@end







function CPDescriptionOfObject(anObject)
{
    if (anObject.isa)
    {
        if ([anObject isKindOfClass:[CPString class]])
            return '@"' + [anObject description] + '"';
        return [anObject description];
    }

    if (typeof(anObject) !== "object")
        return String(anObject);

    var desc = "JavaScriptObject\n\n";
    for (var property in anObject)
    {
        if (anObject.hasOwnProperty(property))
            desc += "   " + property + ": " + CPDescriptionOfObject(anObject[property]) + "\n";
    }
    desc += "}";

    return desc.split('\n').join("\n\t");
}
 





