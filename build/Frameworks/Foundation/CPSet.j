
@import "CPObject.j"
@import "CPEnumerator.j"

var hasOwnProperty = Object.prototype.hasOwnProperty;

/*!
    @class CPSet
    @ingroup foundation
    @brief An unordered collection of objects.
*/
@implementation CPSet : CPObject
{
    Object      _contents;
    unsigned    _count;
}

/*!
    Creates and returns an empty set.
*/
+ (id)set
{
    return [[self alloc] init];
}

/*!
    Creates and returns a set containing a uniqued collection of those objects contained in a given array.
    @param anArray array containing the objects to add to the new set. If the same object appears more than once objects, it is added only once to the returned set.
*/
+ (id)setWithArray:(CPArray)anArray
{
    return [[self alloc] initWithArray:anArray];
}

/*!
    Creates and returns a set that contains a single given object.
    @param anObject The object to add to the new set.
*/
+ (id)setWithObject:(id)anObject
{
    return [[self alloc] initWithObjects:anObject];
}

/*!
    Creates and returns a set containing a specified number of objects from a given array of objects.
    @param objects A array of objects to add to the new set. If the same object appears more than once objects, it is added only once to the returned set.
    @param count The number of objects from objects to add to the new set.
*/
+ (id)setWithObjects:(id)objects count:(CPUInteger)count
{
    return [[self alloc] initWithObjects:objects count:count];
}

/*!
    Creates and returns a set containing the objects in a given argument list.
    @param anObject The first object to add to the new set.
    @param ... A comma-separated list of objects, ending with nil, to add to the new set. If the same object appears more than once objects, it is added only once to the returned set.
*/
+ (id)setWithObjects:(id)anObject, ...
{
    var argumentsArray = Array.prototype.slice.apply(arguments);

    argumentsArray[0] = [self alloc];
    argumentsArray[1] = @selector(initWithObjects:);

    return objj_msgSend.apply(this, argumentsArray);
}

/*!
    Creates and returns a set containing the objects from another set.
    @param aSet A set containing the objects to add to the new set.
*/
+ (id)setWithSet:(CPSet)set
{
    return [[self alloc] initWithSet:set];
}

/*!
    Creates and returns a set by adding anObject.
    @param anObject to add to the new set.
*/
- (id)setByAddingObject:(id)anObject
{
    return [[self class] setWithArray:[[self allObjects] arrayByAddingObject:anObject]];
}

/*!
    Creates and returns a set by adding the objects from another set.
    @param aSet to add objects to add to the new set.
*/
- (id)setByAddingObjectsFromSet:(CPSet)aSet
{
    return [self setByAddingObjectsFromArray:[aSet allObjects]];
}

/*!
    Creates and returns a set by adding the objects from an array.
    @param anArray with objects to add to a new set.
*/
- (id)setByAddingObjectsFromArray:(CPArray)anArray
{
    return [[self class] setWithArray:[[self allObjects] arrayByAddingObjectsFromArray:anArray]];
}


/*!
    Basic initializer, returns an empty set.
*/
- (id)init
{
    return [self initWithObjects:nil count:0];
}

/*!
    Initializes a newly allocated set with the objects that are contained in a given array.
    @param array An array of objects to add to the new set. If the same object appears more than once in array, it is represented only once in the returned set.
*/
- (id)initWithArray:(CPArray)anArray
{
    return [self initWithObjects:anArray count:[anArray count]];
}


/*!
    Initializes a newly allocated set with members taken from the specified list of objects.
    @param anObject The first object to add to the new set.
    @param ... A comma-separated list of objects, ending with nil, to add to the new set. If the same object appears more than once in the list, it is represented only once in the returned set.
*/
- (id)initWithObjects:(id)anObject, ...
{
    var index = 2,
        count = arguments.length;

    for (; index < count; ++index)
        if (arguments[index] === nil)
            break;

    return [self initWithObjects:Array.prototype.slice.call(arguments, 2, index) count:index - 2];
}

/*!
    Initializes a newly allocated set and adds to it objects from another given set.
    @param aSet a set containing objects to add to the new set.
*/
- (id)initWithSet:(CPSet)aSet
{
    return [self initWithArray:[aSet allObjects]];
}

/*!
    Initializes a newly allocated set and adds to it members of another given set. Only included for compatability.
    @param aSet a set of objects to add to the new set.
    @param shouldCopyItems a boolean value. If YES the objects would be copied, if NO the objects will not be copied.
*/
- (id)initWithSet:(CPSet)aSet copyItems:(BOOL)shouldCopyItems
{
    if (shouldCopyItems)
        return [aSet valueForKey:@"copy"];

    return [self initWithSet:aSet];
}

/*
    Initializes a newly allocated set with members taken from the specified list of objects.
    @param objects A array of objects to add to the new set. If the same object appears more than once objects, it is added only once to the returned set.
    @param count The number of objects from objects to add to the new set.
*/
- (id)initWithObjects:(CPArray)objects count:(CPUInteger)aCount
{
    self = [super init];

    if (self)
    {
        self._count = 0;
        self._contents = { };

        var index = 0,
            count = MIN([objects count], aCount);

        for (; index < count; ++index)
            [self addObject:objects[index]];
    }

    return self;
}

- (CPUInteger)count
{
    return self._count;
}

- (id)member:(id)anObject
{ 
    var UID = [anObject UID];

    if (hasOwnProperty.call(self._contents, UID))
        return self._contents[UID];
    else
    {
        for (var objectUID in self._contents)
        {
            if (!hasOwnProperty.call(self._contents, objectUID))
                continue;

            var object = self._contents[objectUID];

            if (object === anObject || [object isEqual:anObject])
                return object;
        }
    }

    return nil;
}

- (CPArray)allObjects
{
    var array = [],
        property;

    for (property in self._contents)
    {
        if (hasOwnProperty.call(self._contents, property))
            array.push(self._contents[property]);
    }

    return array;
}

- (CPEnumerator)objectEnumerator
{
    return [[self allObjects] objectEnumerator];
}

/*
    Adds a given object to the receiver.
    @param anObject The object to add to the receiver.
*/
- (void)addObject:(id)anObject
{
    if (anObject === nil || anObject === undefined)
        [CPException raise:CPInvalidArgumentException reason:@"attempt to insert nil or undefined"];

    if ([self containsObject:anObject])
        return;

    self._contents[[anObject UID]] = anObject;
    self._count++;
}

/*
    Removes a given object from the receiver.
    @param anObject The object to remove from the receiver.
*/
- (void)removeObject:(id)anObject
{
    // Removing nil is an error.
    if (anObject === nil || anObject === undefined)
        [CPException raise:CPInvalidArgumentException reason:@"attempt to remove nil or undefined"];

    // anObject might be isEqual: another object in the set. We need the exact instance so we can remove it by UID.
    var object = [self member:anObject];

    // ...but removing an object not present in the set is not an error.
    if (object !== nil)
    {
        delete self._contents[[object UID]];
        self._count--;
    }
}

/*
    Performance improvement.
*/
- (void)removeAllObjects
{
    self._contents = {};
    self._count = 0;
}

/*!
    Removes an array of objects from the set.
    @param anArray an array of object to remove from the set.
*/
- (void)removeObjectsInArray:(CPArray)anArray
{
    var index = 0,
        count = [anArray count];

    for (; index < count; ++index)
        [self removeObject:[anArray objectAtIndex:index]];
}

/*!
    Adds to the receiver each object contained in a given array that is not already a member.
    @param array An array of objects to add to the receiver.
*/
- (void)addObjectsFromArray:(CPArray)objects
{
    var count = [objects count];

    while (count--)
        [self addObject:objects[count]];
}

- (Class)classForCoder
{
    return [CPSet class];
}

/*!
    Returns one of the objects in the receiver, or nil if the receiver contains no objects.
*/
- (id)anyObject
{
    return [[self objectEnumerator] nextObject];
}

/*!
    Returns a Boolean value that indicates whether a given object is present in the receiver.
    @param anObject The object for which to test membership of the receiver.
*/
- (BOOL)containsObject:(id)anObject
{
    return [self member:anObject] !== nil;
}


/*!
    Sends to each object in the receiver a message specified by a given selector.
    @param aSelector A selector that specifies the message to send to the members of the receiver. The method must not take any arguments. It should not have the side effect of modifying the receiver. This value must not be NULL.
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector
{
    [self makeObjectsPerformSelector:aSelector withObjects:nil];
}

/*!
    Sends to each object in the receiver a message specified by a given selector.
    @param aSelector A selector that specifies the message to send to the receiver's members. The method must take a single argument of type id. The method should not, as a side effect, modify the receiver. The value must not be NULL.
    @param anObject The object to pass as an argument to the method specified by aSelector.
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector withObject:(id)anObject
{
    [self makeObjectsPerformSelector:aSelector withObjects:[anObject]];
}


/*!
    Sends to each object in the receiver a message specified by a given selector.
    @param aSelector A selector that specifies the message to send to the receiver's members. The method must take a single argument of type id. The method should not, as a side effect, modify the receiver. The value must not be NULL.
    @param objects The objects to pass as an argument to the method specified by aSelector.
*/
- (void)makeObjectsPerformSelector:(SEL)aSelector withObjects:(CPArray)objects
{
    var object,
        objectEnumerator = [self objectEnumerator],
        argumentsArray = [nil, aSelector].concat(objects || []);

    while ((object = [objectEnumerator nextObject]) !== nil)
    {
        argumentsArray[0] = object;
        objj_msgSend.apply(this, argumentsArray);
    }
}

/*!
    Enumberates over the objects in a set using a given function.
    @param aFunction a callback for each itteration, should be of the format: function(anObject).
*/
- (void)enumerateObjectsUsingBlock:(Function)aFunction
{
    var object,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if (aFunction(object))
            break;
}

/*!
    Returns a Boolean value that indicates whether every object in the receiver is also present in another given set.
    @param set The set with which to compare the receiver.
*/
- (BOOL)isSubsetOfSet:(CPSet)aSet
{
    var object = nil,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if (![aSet containsObject:object])
            return NO;

    return YES;
}

/*!
    Returns a Boolean value that indicates whether at least one object in the receiver is also present in another given set.
    @param set The set with which to compare the receiver.
*/
- (BOOL)intersectsSet:(CPSet)aSet
{
    if (self === aSet)
        // The empty set intersects nothing
        return [self count] > 0;

    var object = nil,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if ([aSet containsObject:object])
            return YES;

    return NO;
}

/*!
    Returns an array of the set's content sorted as specified by a given array of sort descriptors.

    @param sortDescriptors an array of CPSortDescriptor objects.
*/
- (CPArray)sortedArrayUsingDescriptors:(CPArray)someSortDescriptors
{
    return [[self allObjects] sortedArrayUsingDescriptors:someSortDescriptors];
}


/*!
    Compares the receiver to another set.
    @param set The set with which to compare the receiver.
*/
- (BOOL)isEqualToSet:(CPSet)aSet
{
    return [self isEqual:aSet];
}

/*!
    Returns YES if BOTH sets are a subset of the other.
    @param aSet a set of objects
*/
- (BOOL)isEqual:(CPSet)aSet
{
    // If both are subsets of each other, they are equal
    return  self === aSet ||
            [aSet isKindOfClass:[CPSet class]] &&
            ([self count] === [aSet count] &&
            [aSet isSubsetOfSet:self]);
}


/*!
    Adds to the receiver each object contained in another given set
    @param set The set of objects to add to the receiver.
*/
- (void)unionSet:(CPSet)aSet
{
    var object,
        objectEnumerator = [aSet objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        [self addObject:object];
}

/*!
    Removes from the receiver each object contained in another given set that is present in the receiver.
    @param set The set of objects to remove from the receiver.
*/
- (void)minusSet:(CPSet)aSet
{
    var object,
        objectEnumerator = [aSet objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        [self removeObject:object];
}

/*!
    Removes from the receiver each object that isn't a member of another given set.
    @param set The set with which to perform the intersection.
*/
- (void)intersectSet:(CPSet)aSet
{
    var object,
        objectEnumerator = [self objectEnumerator],
        objectsToRemove = [];

    while ((object = [objectEnumerator nextObject]) !== nil)
        if (![aSet containsObject:object])
            objectsToRemove.push(object);

    var count = [objectsToRemove count];

    while (count--)
        [self removeObject:objectsToRemove[count]];
}

/*!
    Empties the receiver, then adds to the receiver each object contained in another given set.
    @param set The set whose members replace the receiver's content.
*/
- (void)setSet:(CPSet)aSet
{
    [self removeAllObjects];
    [self unionSet:aSet];
}

- (CPString)description
{
    var string = "CPSet : {(\n",
        objects = [self allObjects],
        index = 0,
        count = [objects count];

    for (; index < count; ++index)
    {
        var object = objects[index];

        string += "\t" + String(object).split('\n').join("\n\t") + "\n";
    }

    return string + ")}";
}

@end



@implementation CPSet (CPCopying)

- (id)copy
{
    return [[self class] setWithSet:self];
}


@end
 
 
@implementation CPSet (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithArray:[aCoder decodeObjectForKey:@"CP.objects"]];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{   
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:[self allObjects] forKey:@"CP.objects"];
}

@end


@implementation CPSet (CPKeyValueCoding)

- (id)valueForKey:(CPString)aKey
{
    if (aKey === "@count")
        return [self count];

    var valueSet = [CPSet set],
        object,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
    {
        var value = [object valueForKey:aKey];

        [valueSet addObject:value];
    }

    return valueSet;
}

- (void)setValue:(id)aValue forKey:(CPString)aKey
{
    var object,
        objectEnumerator = [self objectEnumerator];

    while ((object = [objectEnumerator nextObject]) !== nil)
        [object setValue:aValue forKey:aKey];
}

@end