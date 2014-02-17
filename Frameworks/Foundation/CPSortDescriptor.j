/*
 * CPSortDescriptor.j
 * Foundation
 *
 */

@import "CPObject.j"
@import "CPObjJRuntime.j"  

 
/*!
    @class CPSortDescriptor
    @ingroup foundation
    @brief Holds attributes necessary to describe how to sort a set of objects.

    A CPSortDescriptor holds the attributes necessary to describe how
    to sort a set of objects. The sort descriptor instance holds a property key path
    to the sort item of the objects to compare, the method selector to call for sorting and the sort order.
*/
@implementation CPSortDescriptor : CPObject
{
    CPString    _key;
    SEL         _selector;
    BOOL        _ascending;
}

+ (id)sortDescriptorWithKey:(CPString)aKey ascending:(BOOL)isAscending
{
    return [[self alloc] initWithKey:aKey ascending:isAscending];
}

// Initializing a sort descriptor
/*!
    Initializes the sort descriptor.
    @param aKey the property key path to sort
    @param isAscending the sort order
    @return the initialized sort descriptor
*/
- (id)initWithKey:(CPString)aKey ascending:(BOOL)isAscending
{
    return [self initWithKey:aKey ascending:isAscending selector:@selector(compare:)];
}

+ (id)sortDescriptorWithKey:(CPString)aKey ascending:(BOOL)isAscending selector:(SEL)aSelector
{
    return [[self alloc] initWithKey:aKey ascending:isAscending selector:aSelector];
}

/*!
    Initializes the sort descriptor
    @param aKey the property key path to sort
    @param isAscending the sort order
    @param aSelector this method gets called to compare objects. The method will take one argument
    (the object to compare against itself, and must return a CPComparisonResult.
*/
- (id)initWithKey:(CPString)aKey ascending:(BOOL)isAscending selector:(SEL)aSelector
{
    self = [super init];

    if (self)
    {
        _key = aKey;
        _ascending = isAscending;
        _selector = aSelector;
    }

    return self;
}

// Getting information about a sort descriptor
/*!
    Returns \c YES if the sort descriptor's order is ascending.
*/
- (BOOL)ascending
{
    return _ascending;
}

/*!
    Returns the descriptor's property key
*/
- (CPString)key
{
    return _key;
}

/*!
    Returns the selector of the method to call when comparing objects.
*/
- (SEL)selector
{
    return _selector;
}

// Using sort descriptors
/*!
    Compares two objects.
    @param lhsObject the left hand side object to compare
    @param rhsObject the right hand side object to compare
    @return the comparison result
*/
- (CPComparisonResult)compareObject:(id)lhsObject withObject:(id)rhsObject
{
    return (_ascending ? 1 : -1) * [[lhsObject valueForKeyPath:_key] performSelector:_selector withObject:[rhsObject valueForKeyPath:_key]];
}

/*!
    Makes a copy of this sort descriptor with a reversed sort order.
    @return the reversed copy of the sort descriptor
*/
- (id)reversedSortDescriptor
{
    return [[[self class] alloc] initWithKey:_key ascending:!_ascending selector:_selector];
}
 
 
@end

var CPSortDescriptorKeyKey          = @"CPSortDescriptorKeyKey", // Don't you just love naming schemes ;)
    CPSortDescriptorAscendingKey    = @"CPSortDescriptorAscendingKey",
    CPSortDescriptorSelectorKey     = @"CPSortDescriptorSelectorKey";

@implementation CPSortDescriptor (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _key = [aCoder decodeObjectForKey:CPSortDescriptorKeyKey];
        _ascending = [aCoder decodeBoolForKey:CPSortDescriptorAscendingKey];
        _selector = CPSelectorFromString([aCoder decodeObjectForKey:CPSortDescriptorSelectorKey]);
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_key forKey:CPSortDescriptorKeyKey];
    [aCoder encodeBool:_ascending forKey:CPSortDescriptorAscendingKey];
    [aCoder encodeObject:CPStringFromSelector(_selector) forKey:CPSortDescriptorSelectorKey];
}

@end