
@import "CPObject.j"
@import "CPEnumerator.j"
@import "CPNull.j"
@import "CPRange.j"


var CPBinarySearchingFirstEqual = 0,
    CPBinarySearchingLastEqual = 1 << 1,
    CPBinarySearchingInsertionIndex = 1 << 2; 


var concat = Array.prototype.concat,
    indexOf = Array.prototype.indexOf,
    join = Array.prototype.join,
    pop = Array.prototype.pop,
    push = Array.prototype.push,
    slice = Array.prototype.slice,
    splice = Array.prototype.splice;

@implementation CPArray : CPObject
{

}

+ (id)alloc
{
    return [];
}

+ (CPArray)array
{
    return [];
}

+ (id)arrayWithArray:(CPArray)anArray
{
    return [[self alloc] initWithArray:anArray];
}


+ (id)arrayWithObject:(id)anObject
{
    return [anObject];
}

+(id) arrayWithObjects:(id)anObject, ...
{
    // The arguments array contains self and _cmd, so the first object is at position 2.
    var index = 2,
        count = arguments.length;

    for (; index < count; ++index)
        if (arguments[index] === nil)
            break;

    return self.slice.call(arguments, 2, index);
}

- (id)initWithArray:(CPArray)anArray
{
    return [self initWithArray:anArray copyItems:NO];
}

- (id)initWithArray:(CPArray)anArray copyItems:(BOOL)shouldCopyItems
{
    if (!shouldCopyItems && [anArray isKindOfClass:[CPArray class]])
        return slice.call(anArray, 0);

    self = [super init];

    var index = 0;

    if ([anArray isKindOfClass:[CPArray class]])
    {
        // If we're this far, shouldCopyItems must be YES.
        var count = anArray.length;

        for (; index < count; ++index)
        {
            var object = anArray[index];

            self[index] = (object && object.isa) ? [object copy] : object;
        }

        return self;
    }

    var count = [anArray count];

    for (; index < count; ++index)
    {
        var object = [anArray objectAtIndex:index];

        self[index] = (shouldCopyItems && object && object.isa) ? [object copy] : object;
    }

    return self;
}

- (id)initWithObjects:(id)anObject, ...
{
    // The arguments array contains self and _cmd, so the first object is at position 2.
    var index = 2,
        count = arguments.length;

    for (; index < count; ++index)
        if (arguments[index] === nil)
            break;

    return self.slice.call(arguments, 2, index);
}  


- (id)initWithObjects:(CPArray)objects count:(CPUInteger)aCount
{
    if ([objects isKindOfClass:[CPArray class]])
        return self.slice.call(objects, 0);

    var array = [],
        index = 0;

    for (; index < aCount; ++index)
        self.push.call(array, [objects objectAtIndex:index]);

    return array;
}

- (id)initWithCapacity:(CPUInteger)aCapacity
{
    return self;
}

- (BOOL)count
{
    return self.length;
}



- (id)objectAtIndex:(CPUInteger)anIndex
{
    if (anIndex >= self.length || anIndex < 0)
        _CPRaiseRangeException(self, _cmd, anIndex, self.length);
 
    return self[anIndex];
}

 
- (CPArray)objectsAtIndexes:(CPIndexSet)indexes
{
    if ([indexes lastIndex] >= self.length)
        [CPException raise:CPRangeException reason:_cmd + " indexes out of bounds"];

    var ranges = indexes._ranges,
        count  = ranges.length,
        result = [],
        i = 0;

    for (; i < count; i++)
    {
        var range = ranges[i],
            loc = range.location,
            len = range.length,
            subArray = self.slice(loc, loc + len);

        result.splice.apply(result, [result.length, 0].concat(subArray));
    }

    return result;
}

-(BOOL) containsObject:(id)anObject
{
	return [self indexOfObject:anObject inRange:nil] != CPNotFound; 
}
 
- (CPUInteger)indexOfObject:(id)anObject inRange:(CPRange)aRange
{
    // Only use isEqual: if our object is a CPObject.
    if (anObject && anObject.isa)
    {
        var index = aRange ? aRange.location : 0,
            count = aRange ? CPMaxRange(aRange) : self.length;

        for (; index < count; ++index)
            if ([self[index] isEqual:anObject])
                return index;

        return CPNotFound;
    }

    return [self indexOfObjectIdenticalTo:anObject inRange:aRange];
}

- (CPUInteger)indexOfObjectIdenticalTo:(id)anObject 
{
    return [self indexOfObjectIdenticalTo:anObject inRange:nil];
}


- (CPUInteger)indexOfObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    if (indexOf && !aRange)
        return indexOf.call(self, anObject);

    var index = aRange ? aRange.location : 0,
        count = aRange ? CPMaxRange(aRange) : self.length;

    for (; index < count; ++index)
        if (self[index] === anObject)
            return index;

    return CPNotFound;
}

- (void)makeObjectsPerformSelector:(SEL)aSelector withObjects:(CPArray)objects
{
    if (!aSelector)
        _CPRaiseInvalidArgumentException(self, _cmd, 'attempt to pass a nil selector');

    var index = 0,
        count = self.length;

    if ([objects count])
    {
        var argumentsArray = [[nil, aSelector] arrayByAddingObjectsFromArray:objects];

        for (; index < count; ++index)
        {
            argumentsArray[0] = self[index];
            objj_msgSend.apply(this, argumentsArray);
        }
    }

    else
        for (; index < count; ++index)
            objj_msgSend(self[index], aSelector);
}

 
- (CPArray)arrayByAddingObject:(id)anObject
{
    // concat flattens arrays, so wrap it in an *additional* array if anObject is an array itself.
    if (anObject && anObject.isa && [anObject isKindOfClass:[CPArray class]])
        return self.concat.call(self, [anObject]);

    return self.concat.call(self, anObject);
}

- (CPArray)arrayByAddingObjectsFromArray:(CPArray)anArray
{
    if (!anArray)
        return [self copy];

    return self.concat.call(self, [anArray isKindOfClass:[CPArray class]] ? anArray : [anArray _javaScriptArrayCopy]);
}

- (CPArray)subarrayWithRange:(CPRange)aRange
{
    if (aRange.location < 0 || CPMaxRange(aRange) > self.length)
        [CPException raise:CPRangeException reason:_cmd + " aRange out of bounds"];

    return self.slice.call(self, aRange.location, CPMaxRange(aRange));
}

- (CPString)componentsJoinedByString:(CPString)aString
{
    return join.call(self, aString);
}

- (void)insertObject:(id)anObject atIndex:(int)anIndex
{
    if (anIndex > self.length || anIndex < 0)
        _CPRaiseRangeException(self, _cmd, anIndex, self.length);

    self.splice.call(self, anIndex, 0, anObject);
}

- (void)removeObjectAtIndex:(int)anIndex
{
    if (anIndex >= self.length || anIndex < 0)
        _CPRaiseRangeException(self, _cmd, anIndex, self.length);

    self.splice.call(self, anIndex, 1);
}

- (void)removeObjectIdenticalTo:(id)anObject
{
    if (indexOf)
    {
        var anIndex;
        while ((anIndex = indexOf.call(self, anObject)) !== -1)
            self.splice.call(self, anIndex, 1);
    }
    else
        [super removeObjectIdenticalTo:anObject inRange:CPMakeRange(0, self.length)];
}

 
- (void)removeObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    if (indexOf && !aRange)
        [self removeObjectIdenticalTo:anObject];

    [super removeObjectIdenticalTo:anObject inRange:aRange];
}

- (void)addObject:(id)anObject
{
    self.push.call(self, anObject);
}

- (void)removeAllObjects
{
    self.splice.call(self, 0, self.length);
}

- (void)removeLastObject
{
    self.pop.call(self);
}

- (void)removeObjectsInRange:(CPRange)aRange
{
    if (aRange.location < 0 || CPMaxRange(aRange) > self.length)
        [CPException raise:CPRangeException reason:_cmd + " aRange out of bounds"];

    self.splice.call(self, aRange.location, aRange.length);
}



   /// Returns the first object in the array. If the array is empty, returns \c nil

- (id)firstObject
{
    var count = [self count];

    if (count > 0)
        return [self objectAtIndex:0];

    return nil;
}


 //   Returns the last object in the array. If the array is empty, returns \c nil

- (id)lastObject
{
    var count = [self count];

    if (count <= 0)
        return nil;

    return [self objectAtIndex:count - 1];
}



- (void)replaceObjectAtIndex:(int)anIndex withObject:(id)anObject
{
    if (anIndex >= self.length || anIndex < 0)
        _CPRaiseRangeException(self, _cmd, anIndex, self.length);

    self[anIndex] = anObject;
}

- (void)replaceObjectsInRange:(CPRange)aRange withObjectsFromArray:(CPArray)anArray range:(CPRange)otherRange
{
    if (aRange.location < 0 || CPMaxRange(aRange) > self.length)
        [CPException raise:CPRangeException reason:_cmd + " aRange out of bounds"];

    if (otherRange && (otherRange.location < 0 || CPMaxRange(otherRange) > anArray.length))
        [CPException raise:CPRangeException reason:_cmd + " otherRange out of bounds"];

    if (otherRange && (otherRange.location !== 0 || otherRange.length !== [anArray count]))
        anArray = [anArray subarrayWithRange:otherRange];

    if (anArray.isa !== [CPArray class])
        anArray = [anArray _javaScriptArrayCopy];

    self.splice.apply(self, [aRange.location, aRange.length].concat(anArray));
}

- (void)setArray:(CPArray)anArray
{
    if ([anArray isKindOfClass:[CPArray class]])
        self.splice.apply(self, [0, self.length].concat(anArray));

    else
        [super setArray:anArray];
}

- (void)addObjectsFromArray:(CPArray)anArray
{
    if ([anArray isKindOfClass:[CPArray class]])
        self.splice.apply(self, [self.length, 0].concat(anArray));

    else
        [super addObjectsFromArray:anArray];
}

/*!

    Returns the objects at \c indexes in a new CPArray.
    @param indexes the set of indices
    @throws CPRangeException if any of the indices is greater than or equal to the length of the array */

- (CPArray)objectsAtIndexes:(CPIndexSet)indexes
{
    var index = CPNotFound,
        objects = [];

    while ((index = [indexes indexGreaterThanIndex:index]) !== CPNotFound)
        objects.push([self objectAtIndex:index]);

    return objects;
}

/*!
    Returns an enumerator describing the array sequentially
    from the first to the last element. You should not modify
    the array during enumeration. */

- (CPEnumerator)objectEnumerator
{
    return [[_CPArrayEnumerator alloc] initWithArray:self];
}

/*!
    Returns an enumerator describing the array sequentially
    from the last to the first element. You should not modify
    the array during enumeration. */

- (CPEnumerator)reverseObjectEnumerator
{
    return [[_CPReverseArrayEnumerator alloc] initWithArray:self];
}


- (void)copy
{
    return self.slice.call(self, 0);
}



- (Class)classForCoder
{
    return CPArray;
}



- (void)makeObjectsPerformSelector:(SEL)aSelector withObjects:(CPArray)objects
{
    if (!aSelector)
        [CPException raise:CPInvalidArgumentException
                    reason:"makeObjectsPerformSelector:withObjects: 'aSelector' can't be nil"];

    var index = 0,
        count = [self count];

    if ([objects count])
    {
        var argumentsArray = [[nil, aSelector] arrayByAddingObjectsFromArray:objects];

        for (; index < count; ++index)
        {
            argumentsArray[0] = [self objectAtIndex:index];
            objj_msgSend.apply(this, argumentsArray);
        }
    }

    else
        for (; index < count; ++index)
            objj_msgSend([self objectAtIndex:index], aSelector);
}


- (void)enumerateObjectsUsingBlock:(Function)aFunction
{
   
    var index = 0,
        count = [self count];
         

    for (; index < count; ++index)
    {
        var shouldStop = aFunction([self objectAtIndex:index], index);

        if (shouldStop)
            return;
    }
}

// Comparing arrays
/*!
     Returns the first object found in the receiver (starting at index 0) which is present in the
    \c otherArray as determined by using the \c -containsObject: method.
    @return the first object found, or \c nil if no common object was found. */
 
- (id)firstObjectCommonWithArray:(CPArray)anArray
{
    var count = [self count];

    if (![anArray count] || !count)
        return nil;

    var index = 0;

    for (; index < count; ++index)
    {
        var object = [self objectAtIndex:index];

        if ([anArray containsObject:object])
            return object;
    }

    return nil;
}

 
  /*!  Returns true if anArray contains exactly the same objects as the receiver. */
 
- (BOOL)isEqualToArray:(id)anArray
{
    if (self === anArray)
        return YES;

    if (![anArray isKindOfClass:CPArray])
        return NO;

    var count = [self count],
        otherCount = [anArray count];

    if (anArray === nil || count !== otherCount)
        return NO;

    var index = 0;

    for (; index < count; ++index)
    {
        var lhs = [self objectAtIndex:index],
            rhs = [anArray objectAtIndex:index];

        // If they're not equal, and either doesn't have an isa, or they're !isEqual (not isEqual)
        if (lhs !== rhs && (lhs && !lhs.isa || rhs && !rhs.isa || ![lhs isEqual:rhs]))
            return NO;
    }

    return YES;
}

- (BOOL)isEqual:(id)anObject
{
    return (self === anObject) || [self isEqualToArray:anObject];
}

- (Array)_javaScriptArrayCopy
{
    var index = 0,
        count = [self count],
        copy = [];

    for (; index < count; ++index)
        push.call(copy, [self objectAtIndex:index]);

    return copy;
}


// Deriving new arrays
 
 /*!   Returns a copy of this array plus \c anObject inside the copy.
    @param anObject the object to be added to the array copy
    @throws CPInvalidArgumentException if \c anObject is \c nil
    @return a new array that should be n+1 in size compared to the receiver. */
 
- (CPArray)arrayByAddingObject:(id)anObject
{
    var argumentArray = [self _javaScriptArrayCopy];

    // We push instead of concat,because concat flattens arrays, so if the object
    // passed in is an array, we end up with its contents added instead of itself.
    self.push.call(argumentArray, anObject);

    return objj_msgSend([self class], @selector(arrayWithArray:), argumentArray);
}

 
 /*!   Returns a new array which is the concatenation of \c self and otherArray (in this precise order).
    @param anArray the array that will be concatenated to the receiver's copy */
 
- (CPArray)arrayByAddingObjectsFromArray:(CPArray)anArray
{
    if (!anArray)
        return [self copy];

    var anArray = anArray.isa === [CPArray class] ? anArray : [anArray _javaScriptArrayCopy],
        argumentArray = concat.call([self _javaScriptArrayCopy], anArray);

    return objj_msgSend([self class], @selector(arrayWithArray:), argumentArray);
}

 
 

 
 /*!   Adds the objects in \c anArray to the receiver array.
    @param anArray the array of objects to add to the end of the receiver */
 
- (void)addObjectsFromArray:(CPArray)anArray
{
    var index = 0,
        count = [anArray count];

    for (; index < count; ++index)
        [self addObject:[anArray objectAtIndex:index]];
}

 
  /*!  Returns the index of \c anObject in this array.
    If the object is not in the array,
    returns \c CPNotFound. It first attempts to find
    a match using \c -isEqual:, then \c ===.
    @param anObject the object to search for */
 
- (CPUInteger)indexOfObject:(id)anObject
{
    return [self indexOfObject:anObject inRange:nil];
}


- (CPUInteger)indexOfObject:(id)anObject
              inSortedRange:(CPRange)aRange
                    options:(CPBinarySearchingOptions)options
            usingComparator:(Function)aComparator
{
    // FIXME: comparator is not a function
    if (!aComparator)
        _CPRaiseInvalidArgumentException(self, _cmd, "comparator is nil");

    if ((options & CPBinarySearchingFirstEqual) && (options & CPBinarySearchingLastEqual))
        _CPRaiseInvalidArgumentException(self, _cmd,
            "both CPBinarySearchingFirstEqual and CPBinarySearchingLastEqual options cannot be specified");

    var count = [self count];

    if (count <= 0)
        return (options & CPBinarySearchingInsertionIndex) ? 0 : CPNotFound;

    var first = aRange ? aRange.location : 0,
        last = (aRange ? CPMaxRange(aRange) : [self count]) - 1;

    if (first < 0)
        _CPRaiseRangeException(self, _cmd, first, count);

    if (last >= count)
        _CPRaiseRangeException(self, _cmd, last, count);

    while (first <= last)
    {
        var middle = FLOOR((first + last) / 2),
            result = aComparator(anObject, [self objectAtIndex:middle]);

        if (result > 0)
            first = middle + 1;

        else if (result < 0)
            last = middle - 1;

        else
        {
            if (options & CPBinarySearchingFirstEqual)
                while (middle > first && aComparator(anObject, [self objectAtIndex:middle - 1]) === CPOrderedSame)
                    --middle;

            else if (options & CPBinarySearchingLastEqual)
            {
                while (middle < last && aComparator(anObject, [self objectAtIndex:middle + 1]) === CPOrderedSame)
                    ++middle;

                if (options & CPBinarySearchingInsertionIndex)
                    ++middle;
            }

            return middle;
        }
    }

    if (options & CPBinarySearchingInsertionIndex)
        return MAX(first, 0);

    return CPNotFound;
}


 /*!
    Inserts the objects in the provided array into the receiver at the indexes specified.
    @param objects the objects to add to this array
    @param anIndexSet the indices for the objects */
 
- (void)insertObjects:(CPArray)objects atIndexes:(CPIndexSet)indexes
{
    var indexesCount = [indexes count],
        objectsCount = [objects count];

    if (indexesCount !== objectsCount)
        [CPException raise:CPRangeException reason:"the counts of the passed-in array (" + objectsCount + ") and index set (" + indexesCount + ") must be identical."];

    var lastIndex = [indexes lastIndex];

    if (lastIndex >= [self count] + indexesCount)
        [CPException raise:CPRangeException reason:"the last index (" + lastIndex + ") must be less than the sum of the original count (" + [self count] + ") and the insertion count (" + indexesCount + ")."];

    var index = 0,
        currentIndex = [indexes firstIndex];

    for (; index < objectsCount; ++index, currentIndex = [indexes indexGreaterThanIndex:currentIndex])
        [self insertObject:[objects objectAtIndex:index] atIndex:currentIndex];
}

- (unsigned)insertObject:(id)anObject inArraySortedByDescriptors:(CPArray)descriptors
{
    var index,
        count = [descriptors count];

    if (count)
        index = [self indexOfObject:anObject
                      inSortedRange:nil
                            options:CPBinarySearchingInsertionIndex
                    usingComparator:function(lhs, rhs)
        {
            var index = 0,
                result = CPOrderedSame;

            while (index < count && ((result = [[descriptors objectAtIndex:index] compareObject:lhs withObject:rhs]) === CPOrderedSame))
                ++index;

            return result;
        }];

    else
        index = [self count];

    [self insertObject:anObject atIndex:index];

    return index;
}


 /*!   Replace the elements at the indices specified by \c anIndexSet with
    the objects in \c objects.
    @param anIndexSet the set of indices to array positions that will be replaced */
 
- (void)replaceObjectsAtIndexes:(CPIndexSet)indexes withObjects:(CPArray)objects
{
    var i = 0,
        index = [indexes firstIndex];

    while (index !== CPNotFound)
    {
        [self replaceObjectAtIndex:index withObject:[objects objectAtIndex:i++]];
        index = [indexes indexGreaterThanIndex:index];
    }
}

 
 /*!   Replaces some of the receiver's objects with objects from \c anArray. Specifically, the elements of the
    receiver in the range specified by \c aRange,
    with the elements of \c anArray in the range specified by \c otherRange.
    @param aRange the range of elements to be replaced in the receiver
    @param anArray the array to retrieve objects for placement into the receiver
    @param otherRange the range of objects in \c anArray to pull from for placement into the receiver */
 
- (void)replaceObjectsInRange:(CPRange)aRange withObjectsFromArray:(CPArray)anArray range:(CPRange)otherRange
{
    [self removeObjectsInRange:aRange];

    if (otherRange && (otherRange.location !== 0 || otherRange.length !== [anArray count]))
        anArray = [anArray subarrayWithRange:otherRange];

    var indexes = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(aRange.location, [anArray count])];

    [self insertObjects:anArray atIndexes:indexes];
}

 
 /*!   Replaces some of the receiver's objects with the objects from
    \c anArray. Specifically, the elements of the
    receiver in the range specified by \c aRange.
    @param aRange the range of elements to be replaced in the receiver
    @param anArray the array to retrieve objects for placement into the receiver */
 
- (void)replaceObjectsInRange:(CPRange)aRange withObjectsFromArray:(CPArray)anArray
{
    [self replaceObjectsInRange:aRange withObjectsFromArray:anArray range:nil];
}

 
 /*!   Sets the contents of the receiver to be identical to the contents of \c anArray.
    @param anArray the array of objects used to replace the receiver's objects */
 
- (void)setArray:(CPArray)anArray
{
    if (self === anArray)
        return;

    [self removeAllObjects];
    [self addObjectsFromArray:anArray];
}


 
 /*!   Removes all entries of \c anObject from the array.
    @param anObject the object whose entries are to be removed */
 
- (void)removeObject:(id)anObject
{
    [self removeObject:anObject inRange:CPMakeRange(0, [self count])];
}

 
 /*!   Removes all entries of \c anObject from the array, in the range specified by \c aRange.
    @param anObject the object to remove
    @param aRange the range to search in the receiver for the object */
 
- (void)removeObject:(id)anObject inRange:(CPRange)aRange
{
    var index;

    while ((index = [self indexOfObject:anObject inRange:aRange]) != CPNotFound)
    {
        [self removeObjectAtIndex:index];
        aRange = CPIntersectionRange(CPMakeRange(index, [self count] - index), aRange);
    }
}

 

 
 /*!   Removes the objects at the indices specified by \c CPIndexSet.
    @param anIndexSet the indices of the elements to be removed from the array */
 
- (void)removeObjectsAtIndexes:(CPIndexSet)anIndexSet
{
    var index = [anIndexSet lastIndex];

    while (index !== CPNotFound)
    {
        [self removeObjectAtIndex:index];
        index = [anIndexSet indexLessThanIndex:index];
    }
}

 
 /*!   Remove all instances of \c anObject from the array.
    The search for the object is done using \c ==.
    @param anObject the object to remove */
 
- (void)removeObjectIdenticalTo:(id)anObject
{
    [self removeObjectIdenticalTo:anObject inRange:CPMakeRange(0, [self count])];
}

 
 /*!   Remove the first instance of \c anObject from the array,
    within the range specified by \c aRange.
    The search for the object is done using \c ==.
    @param anObject the object to remove
    @param aRange the range in the array to search for the object */
 
- (void)removeObjectIdenticalTo:(id)anObject inRange:(CPRange)aRange
{
    var index,
        count = [self count];

    while ((index = [self indexOfObjectIdenticalTo:anObject inRange:aRange]) !== CPNotFound)
    {
        [self removeObjectAtIndex:index];
        aRange = CPIntersectionRange(CPMakeRange(index, (--count) - index), aRange);
    }
}

 /*!
    Remove the objects in \c anArray from the receiver array.
    @param anArray the array of objects to remove from the receiver */
 
- (void)removeObjectsInArray:(CPArray)anArray
{
    var index = 0,
        count = [anArray count];

    for (; index < count; ++index)
        [self removeObject:[anArray objectAtIndex:index]];
}

 
 /*!   Removes all the objects in the specified range from the receiver.
    @param aRange the range of objects to remove */
 
- (void)removeObjectsInRange:(CPRange)aRange
{
    var index = aRange.location,
        count = CPMaxRange(aRange);

    while (count-- > index)
        [self removeObjectAtIndex:index];
}

// Rearranging objects
 
 /*!   Swaps the elements at the two specified indices.
    @param anIndex the first index to swap from
    @param otherIndex the second index to swap from */
 
- (void)exchangeObjectAtIndex:(unsigned)anIndex withObjectAtIndex:(unsigned)otherIndex
{
    if (anIndex === otherIndex)
        return;

    var temporary = [self objectAtIndex:anIndex];

    [self replaceObjectAtIndex:anIndex withObject:[self objectAtIndex:otherIndex]];
    [self replaceObjectAtIndex:otherIndex withObject:temporary];
}

- (void)sortUsingDescriptors:(CPArray)descriptors
{
    var i = [descriptors count],
        jsDescriptors = [];

    // Revert the order of the descriptors
    while (i--)
    {
        var d = [descriptors objectAtIndex:i];
        [jsDescriptors addObject:{ "k": [d key], "a": [d ascending], "s": [d selector]}];
    }
    sortArrayUsingJSDescriptors(self, jsDescriptors);
}

 
/*!    Sorts the receiver array using a JavaScript function as a comparator, and a specified context.
    @param aFunction a JavaScript function that will be called to compare objects
    @param aContext an object that will be passed to \c aFunction with comparison */
 
- (void)sortUsingFunction:(Function)aFunction context:(id)aContext
{
    sortArrayUsingFunction(self, aFunction, aContext);
}

 /*!
    Sorts the receiver array using an Objective-J method as a comparator.
    @param aSelector the selector for the method to call for comparison */
 
- (void)sortUsingSelector:(SEL)aSelector
{
    sortArrayUsingFunction(self, selectorCompare, aSelector);
}

// Sorting arrays
 
    
 
- (CPArray)sortedArrayUsingDescriptors:(CPArray)descriptors
{
    var sorted = [self copy];

    [sorted sortUsingDescriptors:descriptors];

    return sorted;
}

 
   /*! Return a copy of the receiver sorted using the function passed into the first parameter. */
 
- (CPArray)sortedArrayUsingFunction:(Function)aFunction
{
    return [self sortedArrayUsingFunction:aFunction context:nil];
}

 /*!
    Returns an array in which the objects are ordered according
    to a sort with \c aFunction. This invokes
    \c -sortUsingFunction:context.
    @param aFunction a JavaScript 'Function' type that compares objects
    @param aContext context information
    @return a new sorted array */
 
- (CPArray)sortedArrayUsingFunction:(Function)aFunction context:(id)aContext
{
    var sorted = [self copy];

    [sorted sortUsingFunction:aFunction context:aContext];

    return sorted;
}

 /*!
    Returns a new array in which the objects are ordered according to a sort with \c aSelector.
    @param aSelector the selector that will perform object comparisons */
 
- (CPArray)sortedArrayUsingSelector:(SEL)aSelector
{
    var sorted = [self copy];

    [sorted sortUsingSelector:aSelector];

    return sorted;
}

 /*!
    Returns a subarray of the receiver containing the objects found in the specified range \c aRange.
    @param aRange the range of objects to be copied into the subarray
    @throws CPRangeException if the specified range exceeds the bounds of the array */
 
- (CPArray)subarrayWithRange:(CPRange)aRange
{
    if (!aRange)
        return [self copy];

    if (aRange.location < 0 || CPMaxRange(aRange) > self.length)
        [CPException raise:CPRangeException reason:"subarrayWithRange: aRange out of bounds"];

    var index = aRange.location,
        count = CPMaxRange(aRange),
        argumentArray = [];

    for (; index < count; ++index)
        push.call(argumentArray, [self objectAtIndex:index]);

    return objj_msgSend([self class], @selector(arrayWithArray:), argumentArray);
}

// Working with string elements

 /*!
    Returns a string formed by concatenating the objects in the
    receiver, with the specified separator string inserted between each part.
    If the element is a Objective-J object, then the \c -description
    of that object will be used, otherwise the default JavaScript representation will be used.
    @param aString the separator that will separate each object string
    @return the string representation of the array */
 
- (CPString)componentsJoinedByString:(CPString)aString
{
    return self.join.call([self _javaScriptArrayCopy], aString);
}


-(CPString)description
{
	return self; 
} 

- (CPString)UID
{   
     if(!self._UID)
        self._UID = objj_generateObjectUID(); 
     
     return self._UID; 
}

@end 


@implementation CPArray (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [aCoder decodeObjectForKey:@"CP.objects"];
}

- (void) encodeWithCoder:(CPCoder)aCoder
{   
    [super encodeWithCoder:aCoder];

    [aCoder _encodeArrayOfObjects:self forKey:@"CP.objects"];
}

@end

@implementation _CPArrayEnumerator : CPEnumerator
{
    CPArray _array;
    int     _index;
}

- (id)initWithArray:(CPArray)anArray
{
    self = [super init];

    if (self)
    {
        self._array = anArray;
        self._index = -1;
    }

    return self;
}

- (id)nextObject
{
    if (++self._index >= [self._array count])
        return nil;

    return [self._array objectAtIndex:self._index];
}

@end

/* @ignore */
@implementation _CPReverseArrayEnumerator : CPEnumerator
{
    CPArray _array;
    int     _index;
}

- (id)initWithArray:(CPArray)anArray
{
    self = [super init];

    if (self)
    {
        self._array = anArray;
        self._index = [self._array count];
    }

    return self;
}

- (id)nextObject
{
    if (--self._index < 0)
        return nil;

    return [self._array objectAtIndex:self._index];
}

@end


 
var selectorCompare = function(object1, object2, selector)
{
    return [object1 performSelector:selector withObject:object2];
};

var sortArrayUsingFunction = function(array, aFunction, aContext)
{
    var h,
        i,
        j,
        k,
        l,
        m,
        n = array.length,
        o;

    var A,
        B = [];

    for (h = 1; h < n; h += h)
    {
        for (m = n - 1 - h; m >= 0; m -= h + h)
        {
            l = m - h + 1;
            if (l < 0)
                l = 0;

            for (i = 0, j = l; j <= m; i++, j++)
                B[i] = array[j];

            for (i = 0, k = l; k < j && j <= m + h; k++)
            {
                A = array[j];
                o = aFunction(A, B[i], aContext);

                if (o >= 0)
                    array[k] = B[i++];
                else
                {
                    array[k] = A;
                    j++;
                }
            }

            while (k < j)
                array[k++] = B[i++];
        }
    }
}

// This is for speed
var CPMutableArrayNull = [CPNull null];

// Observe that the sort descriptors has the reversed order by the caller
var sortArrayUsingJSDescriptors = function(a, d)
{
    var h,
        i,
        j,
        k,
        l,
        m,
        n = a.length,
        dl = d.length - 1,
        o,
        c = {};

    var A,
        B = [],
        C1,
        C2,
        cn,
        aUID,
        bUID,
        key,
        dd,
        value1,
        value2,
        cpNull = CPMutableArrayNull;

    if (dl < 0)
        return;

    for (h = 1; h < n; h += h)
    {
        for (m = n - 1 - h; m >= 0; m -= h + h)
        {
            l = m - h + 1;

            if (l < 0)
                l = 0;

            for (i = 0, j = l; j <= m; i++, j++)
                B[i] = a[j];

            for (i = 0, k = l; k < j && j <= m + h; k++)
            {
                A = a[j];
                aUID = A._UID;

                if (!aUID)
                    aUID = [A UID];

                C1 = c[aUID];

                if (!C1)
                {
                    C1 = {};
                    cn = dl;

                    do
                    {
                        key = d[cn].k;
                        C1[key] = [A valueForKeyPath:key];
                    } while (cn--)

                    c[aUID] = C1;
                }

                bUID = B[i]._UID;

                if (!bUID)
                    bUID = [B[i] UID];

                C2 = c[bUID];

                if (!C2)
                {
                    C2 = {};
                    cn = dl;

                    do
                    {
                        key = d[cn].k;
                        C2[key] = [B[i] valueForKeyPath:key];
                    } while (cn--)

                    c[bUID] = C2;
                }

                cn = dl;

                do
                {
                    dd = d[cn];
                    key = dd.k;
                    value1 = C1[key];
                    value2 = C2[key];
                    if (value1 === nil || value1 === cpNull)
                        o = value2 === nil || value2 === cpNull ? CPOrderedSame : CPOrderedAscending;
                    else
                        o = value2 === nil || value2 === cpNull ? CPOrderedDescending : objj_msgSend(value1, dd.s, value2);

                    if (o && !dd.a)
                        o = -o;
                } while (cn-- && o == CPOrderedSame)

                if (o >= 0)
                    a[k] = B[i++];
                else
                {
                    a[k] = A;
                    j++;
                }
            }

            while (k < j)
                a[k++] = B[i++];
        }
    }
} 


Array.prototype.isa = CPArray;
