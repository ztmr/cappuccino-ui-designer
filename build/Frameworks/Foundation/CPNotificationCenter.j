/*
 * CPNotificationCenter.j
 * Foundation
 */


@import "CPDictionary.j" 
@import "CPNotification.j"
@import "CPNull.j"
@import "CPSet.j"
//@import "CPKeyValueCoding.j"

var CPNotificationDefaultCenter = nil;

/*!
    @class CPNotificationCenter
    @ingroup foundation
    @brief Sends messages (CPNotification) between objects.
 
*/
@implementation CPNotificationCenter : CPObject
{
    CPDictionary     _namedRegistries;
    _CPNotificationRegistry _unnamedRegistry;
}

/*!
    Returns the application's notification center
*/
+ (CPNotificationCenter)defaultCenter
{
    if (!CPNotificationDefaultCenter)
        CPNotificationDefaultCenter = [[CPNotificationCenter alloc] init];

    return CPNotificationDefaultCenter;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        self._namedRegistries = [CPDictionary dictionary];
        self._unnamedRegistry = [[_CPNotificationRegistry alloc] init];
    }
   return self;
}

/*!
    Adds an object as an observer. The observer will receive notifications with the specified name
    and/or containing the specified object (depending on if they are \c nil.
    @param anObserver the observing object
    @param aSelector the message sent to the observer when a notification occurs
    @param aNotificationName the name of the notification the observer wants to watch
    @param anObject the object in the notification the observer wants to watch
*/
- (void)addObserver:(id)anObserver selector:(SEL)aSelector name:(CPString)aNotificationName object:(id)anObject
{
    var registry,
        observer = [[_CPNotificationObserver alloc] initWithObserver:anObserver selector:aSelector];

    if (aNotificationName == nil)
        registry = self._unnamedRegistry;
    else if (!(registry = [self._namedRegistries objectForKey:aNotificationName]))
    {

        registry = [[_CPNotificationRegistry alloc] init];
        [self._namedRegistries setObject:registry forKey:aNotificationName];
    }

    [registry addObserver:observer object:anObject];
}

/*!
    Unregisters the specified observer from all notifications.
    @param anObserver the observer to unregister
*/
- (void)removeObserver:(id)anObserver
{
    var name = nil,
        names = [self._namedRegistries allKeys],
        count = names.length,
        index = 0; 

     for(; index < count; index++)
     {
        name = names[index];
        [[self._namedRegistries objectForKey:name] removeObserver:anObserver object:nil];

     }

    [self._unnamedRegistry removeObserver:anObserver object:nil];
}

/*!
    Unregisters the specified observer from notifications matching the specified name and/or object.
    @param anObserver the observer to remove
    @param aNotificationName the name of notifications to no longer watch
    @param anObject notifications containing this object will no longer be watched
*/
- (void)removeObserver:(id)anObserver name:(CPString)aNotificationName object:(id)anObject
{
    if (aNotificationName == nil)
    {
        var name = nil,
            names = [self._namedRegistries allKeys],
            count = names.length,
            index = 0;

        for(; index < count; index++)
        {
            name = names[index];
            [[self._namedRegistries objectForKey:name] removeObserver:anObserver object:anObject];

        }
        

        [self._unnamedRegistry removeObserver:anObserver object:anObject];
    }
    else
        [[self._namedRegistries objectForKey:aNotificationName] removeObserver:anObserver object:anObject];
}

/*!
    Posts a notification to all observers that match the specified notification's name and object.
    @param aNotification the notification being posted
    @throws CPInvalidArgumentException if aNotification is nil
*/
- (void)postNotification:(CPNotification)aNotification
{
    if (!aNotification)
         throw new Exception("postNotification: does not except 'nil' notifications");

    _CPNotificationCenterPostNotification(self, aNotification);
}

/*!
    Posts a new notification with the specified name, object, and dictionary.
    @param aNotificationName the name of the notification name
    @param anObject the associated object
    @param aUserInfo the associated dictionary
*/
- (void)postNotificationName:(CPString)aNotificationName object:(id)anObject userInfo:(CPDictionary)aUserInfo
{
   _CPNotificationCenterPostNotification(self, [[CPNotification alloc] initWithName:aNotificationName object:anObject userInfo:aUserInfo]);
}

/*!
    Posts a new notification with the specified name and object.
    @param aNotificationName the name of the notification
    @param anObject the associated object
*/
- (void)postNotificationName:(CPString)aNotificationName object:(id)anObject
{ 
   _CPNotificationCenterPostNotification(self, [[CPNotification alloc] initWithName:aNotificationName object:anObject userInfo:nil]);
}

@end

var _CPNotificationCenterPostNotification = function(/* CPNotificationCenter */ self, /* CPNotification */ aNotification)
{
     
    [self._unnamedRegistry postNotification:aNotification];
    [[self._namedRegistries objectForKey:[aNotification name]] postNotification:aNotification];
 
};

/*
    Mapping of Notification Name to listening object/selector.
    @ignore
 */
@implementation _CPNotificationRegistry : CPObject
{
    CPDictionary    _objectObservers;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        self._objectObservers = [CPDictionary dictionary];
    }

    return self;
}

- (void)addObserver:(_CPNotificationObserver)anObserver object:(id)anObject
{
    // If there's no object, then we're listening to this
    // notification regardless of whom sends it.
    if (!anObject)
        anObject = [CPNull null];

    // Grab all the listeners for this notification/object pair
    var observers = [self._objectObservers objectForKey:[anObject UID]];

    if (!observers)
    {
        observers = [CPSet set];
        [self._objectObservers setObject:observers forKey:[anObject UID]];
    }

    // Add this observer.
    [observers addObject:anObserver];
}

- (void)removeObserver:(id)anObserver object:(id)anObject
{
    var removedKeys = [];

    // This means we're getting rid of EVERY instance of this observer.
    if (anObject == nil)
    {
        var key = nil,
            keys = [self._objectObservers allKeys],
            count = keys.length,
            index = 0; 

        // Iterate through every set of observers
        for(; index < count; index++)
        {
            var key = keys[index],
                observers = [[self._objectObservers objectForKey:key] allObjects],
                observer = nil,
                observerCount = [observers count],
                observerIndex = 0;

            for(; observerIndex < observerCount; observerIndex++)
            {
                observer = [observers objectAtIndex:observerIndex];
                if ([observer observer] == anObserver)
                    [observers removeObject:observer];
            }

            if (![observers count])
                removedKeys.push(key);
        }
    }
    else
    {
        var key = [anObject UID],
            observers = [[self._objectObservers objectForKey:key] allObjects],
            observer = nil,
            observerCount = [observers count],
            observerIndex = 0;

        for(; observerIndex < observerCount; observerIndex++)
        {   
            observer = [observers objectAtIndex:observerIndex];
            if ([observer observer] == anObserver)
                [observers removeObject:observer];
        }

        if (![observers count])
            removedKeys.push(key);
    }

    var count = removedKeys.length;

    while (count--)
        [self._objectObservers removeObjectForKey:removedKeys[count]];
}

- (void)postNotification:(CPNotification)aNotification
{
    // We don't want to erroneously send notifications to observers that get removed
    // during the posting of this notification, nor observers that get added.  The
    // best way to do this is to make a copy of the current observers (this avoids
    // new observers from being notified) and double checking every observer against
    // the current set (this avoids removed observers from receiving notifications).
    var object = [aNotification object],
        currentObservers = nil;

    if (object != nil && (currentObservers = [self._objectObservers objectForKey:[object UID]]))
    {
        var observers = [[currentObservers copy] allObjects],
            observer = nil,
            observerCount = [observers count] ,
            observerIndex = 0;

      
        for(; observerIndex < observerCount; observerIndex++)
        { 
            // CPSet containsObject is N(1) so this is a fast check.
            observer = [observers objectAtIndex:observerIndex];

            //if ([currentObservers containsObject:observer])
                [observer postNotification:aNotification];
        }
    }

    // Now do the same for the nil object observers...
    currentObservers = [self._objectObservers objectForKey:[[CPNull null] UID]];

    if (!currentObservers)
        return;

    var observers = [[currentObservers copy] allObjects], 
        observerCount = [observers count],
        observerIndex = 0;

        for(; observerIndex < observerCount; observerIndex++)
        { 
             // CPSet containsObject is N(1) so this is a fast check.
            observer = [observers objectAtIndex:observerIndex];
            if ([currentObservers containsObject:observer])
                [observer postNotification:aNotification];
        }

}


     

- (unsigned)count
{
    return [self._objectObservers count];
}

@end

/* @ignore */
@implementation _CPNotificationObserver : CPObject
{
    id  _observer;
    SEL _selector;
}

- (id)initWithObserver:(id)anObserver selector:(SEL)aSelector
{
    if (self)
    {
        self._observer = anObserver;
        self._selector = aSelector;
    }

   return self;
}

- (id)observer
{
    return self._observer;
}

- (void)postNotification:(CPNotification)aNotification
{
    [self._observer performSelector:self._selector withObject:aNotification];

    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

@end
