@import "CPBox.j"
@import "CPSegmentedControl.j"
@import "CPTabViewItem.j"
@import "CPView.j"


var CPTopTabsBezelBorder     = 0,
	//CPLeftTabsBezelBorder  = 1,
	CPBottomTabsBezelBorder  = 2,
	//CPRightTabsBezelBorder = 3,
	CPNoTabsBezelBorder      = 4, //Displays no tabs and has a bezeled border.
	CPNoTabsLineBorder       = 5, //Has no tabs and displays a line border.
	CPNoTabsNoBorder         = 6; //Displays no tabs and no border.


var CPTabViewDidSelectTabViewItemSelector           = 1,
    CPTabViewShouldSelectTabViewItemSelector        = 2,
    CPTabViewWillSelectTabViewItemSelector          = 4,
    CPTabViewDidChangeNumberOfTabViewItemsSelector  = 8;


@implementation CPTabView : CPView
{
	CPSegmentedControl						_tabs; 
	CPArray             					_items;

	int 									_type @accessors(getter=type); 

	CPBox               					_box;

	int 									_selectedIndex; 

	id                  					_delegate;
	unsigned            					_delegateSelectors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        _items = [CPArray array];

        [self _init];
        [self setTabViewType:CPTopTabsBezelBorder];

    }

    return self;
}

- (void)_init
{
    _selectedIndex = CPNotFound;

    _tabs = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  	[_tabs setTarget:self];
  	[_tabs setAction:@selector(_tabSelectionChanged:)];

    var height = 50.0;
    [_tabs setFrameSize:CGSizeMake(0, height)];

    _box = [[CPBox alloc] initWithFrame:[self  bounds]];

    [_ephemeralSubviews addObject:_tabs];
    [_ephemeralSubviews addObject:_box];
  
    [self addSubview:_box];
    [self addSubview:_tabs];
}

// Adding and Removing Tabs
/*!
    Adds a CPTabViewItem to the tab view.
    @param aTabViewItem the item to add
*/
- (void)addTabViewItem:(CPTabViewItem)aTabViewItem
{
    [self insertTabViewItem:aTabViewItem atIndex:[_items count]];
}

/*!
    Inserts a CPTabViewItem into the tab view at the specified index.
    @param aTabViewItem the item to insert
    @param anIndex the index for the item
*/
- (void)insertTabViewItem:(CPTabViewItem)aTabViewItem atIndex:(unsigned)anIndex
{
    [_items insertObject:aTabViewItem atIndex:anIndex];

    [self _updateItems];
    [self _repositionTabs];

    [aTabViewItem _setTabView:self];

    if (_delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

/*!
    Removes the specified tab view item from the tab view.
    @param aTabViewItem the item to remove
*/
- (void)removeTabViewItem:(CPTabViewItem)aTabViewItem
{
    var count = [_items count];
    for (var i = 0; i < count; i++)
    {
        if ([_items objectAtIndex:i] === aTabViewItem)
        {
            [_items removeObjectAtIndex:i];
            break;
        }
    }

    [self _updateItems];
    [self _repositionTabs];

    [aTabViewItem _setTabView:nil];

    if (_delegateSelectors & CPTabViewDidChangeNumberOfTabViewItemsSelector)
        [_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

// Accessing Tabs
/*!
    Returns the index of the specified item
    @param aTabViewItem the item to find the index for
    @return the index of aTabViewItem or CPNotFound
*/
- (int)indexOfTabViewItem:(CPTabViewItem)aTabViewItem
{
    return [_items indexOfObjectIdenticalTo:aTabViewItem];
}

/*!
    Returns the index of the CPTabViewItem with the specified identifier.
    @param anIdentifier the identifier of the item
    @return the index of the tab view item identified by anIdentifier, or CPNotFound
*/
- (int)indexOfTabViewItemWithIdentifier:(CPString)anIdentifier
{
    for (var index = [_items count]; index >= 0; index--)
        if ([[_items[index] identifier] isEqual:anIdentifier])
            return index;

    return CPNotFound;
}

/*!
    Returns the number of items in the tab view.
    @return the number of tab view items in the receiver
*/
- (unsigned)numberOfTabViewItems
{
    return [_items count];
}

/*!
    Returns the CPTabViewItem at the specified index.
    @return a tab view item, or nil
*/
- (CPTabViewItem)tabViewItemAtIndex:(unsigned)anIndex
{
    return [_items objectAtIndex:anIndex];
}

/*!
    Returns the array of items that backs this tab view.
    @return a copy of the array of items in the receiver
*/
- (CPArray)tabViewItems
{
    return [_items copy]; // Copy?
}

// Selecting a Tab
/*!
    Sets the first tab view item in the array to be displayed to the user.
    @param aSender the object making this request
*/
- (void)selectFirstTabViewItem:(id)aSender
{
    if ([_items count] === 0)
        return; // throw?

    [self selectTabViewItemAtIndex:0];
}

/*!
    Sets the last tab view item in the array to be displayed to the user.
    @param aSender the object making this request
*/
- (void)selectLastTabViewItem:(id)aSender
{
    if ([_items count] === 0)
        return; // throw?

    [self selectTabViewItemAtIndex:[_items count] - 1];
}

/*!
    Sets the next tab item in the array to be displayed.
    @param aSender the object making this request
*/
- (void)selectNextTabViewItem:(id)aSender
{
    if (_selectedIndex === CPNotFound)
        return;

    var nextIndex = _selectedIndex + 1;

    if (nextIndex === [_items count])
        // does nothing. According to spec at (http://developer.apple.com/mac/library/DOCUMENTATION/Cocoa/Reference/ApplicationKit/Classes/NSTabView_Class/Reference/Reference.html#//apple_ref/occ/instm/NSTabView/selectNextTabViewItem:)
        return;

    [self selectTabViewItemAtIndex:nextIndex];
}

/*!
    Selects the previous item in the array for display.
    @param aSender the object making this request
*/
- (void)selectPreviousTabViewItem:(id)aSender
{
    if (_selectedIndex === CPNotFound)
        return;

    var previousIndex = _selectedIndex - 1;

    if (previousIndex < 0)
        return; // does nothing. See above.

    [self selectTabViewItemAtIndex:previousIndex];
}

/*!
    Displays the specified item in the tab view.
    @param aTabViewItem the item to display
*/
- (void)selectTabViewItem:(CPTabViewItem)aTabViewItem
{
    [self selectTabViewItemAtIndex:[self indexOfTabViewItem:aTabViewItem]];
}

/*!
    Selects the item at the specified index.
    @param anIndex the index of the item to display.
*/
- (BOOL)selectTabViewItemAtIndex:(unsigned)anIndex
{
    if (anIndex === _selectedIndex)
        return;

    var aTabViewItem = [self tabViewItemAtIndex:anIndex];

    if ((_delegateSelectors & CPTabViewShouldSelectTabViewItemSelector) && ![_delegate tabView:self shouldSelectTabViewItem:aTabViewItem])
        return NO;

    if (_delegateSelectors & CPTabViewWillSelectTabViewItemSelector)
        [_delegate tabView:self willSelectTabViewItem:aTabViewItem];

    
    [_tabs selectSegmentWithTag:anIndex];
    
    [self _setSelectedIndex:anIndex];

    if (_delegateSelectors & CPTabViewDidSelectTabViewItemSelector)
        [_delegate tabView:self didSelectTabViewItem:aTabViewItem];

    return YES;
}

/*!
    Returns the current item being displayed.
    @return the tab view item currenly being displayed by the receiver
*/
- (CPTabViewItem)selectedTabViewItem
{
    if (_selectedIndex != CPNotFound)
        return [_items objectAtIndex:_selectedIndex];

    return nil;
} 

//
/*!
    Sets the tab view type.
    @param aTabViewType the view type
*/
- (void)setTabViewType:(CPTabViewType)aTabViewType
{
    if (_type === aTabViewType)
        return;

    _type = aTabViewType;

    if (_type !== CPTopTabsBezelBorder && _type !== CPBottomTabsBezelBorder)
        [_tabs removeFromSuperview];
    else
        [self addSubview:_tabs];

    switch (_type)
    {
        case CPTopTabsBezelBorder:
        case CPBottomTabsBezelBorder:
        case CPNoTabsBezelBorder:
            [_box setBorderWidth:1.0];
            break;
        case CPNoTabsLineBorder:
            [_box setBorderWidth:1.0];
            break;
        case CPNoTabsNoBorder:
            [_box setBorderWidth:0.0];
            break;
    }

    [self setNeedsLayout];
}


- (void)layoutSubviews
{
   
    var aFrame = [self frame],
        segmentedHeight = CGRectGetHeight([_tabs frame]),
        origin = _type === CPTopTabsBezelBorder ? segmentedHeight / 2 : 0;
         
        [_box setFrame:CGRectMake(0, origin, CGRectGetWidth(aFrame),
                                   CGRectGetHeight(aFrame) - segmentedHeight / 2 - 1)];


        [self _repositionTabs];
}

/*!
    Returns the receiver's delegate.
    @return the receiver's delegate
*/
- (id)delegate
{
    return _delegate;
}

/*!
    Sets the delegate for this tab view.
    @param aDelegate the tab view's delegate
*/
- (void)setDelegate:(id)aDelegate
{
    if (_delegate == aDelegate)
        return;

    _delegate = aDelegate;

    _delegateSelectors = 0;

    if ([_delegate respondsToSelector:@selector(tabView:shouldSelectTabViewItem:)])
        _delegateSelectors |= CPTabViewShouldSelectTabViewItemSelector;

    if ([_delegate respondsToSelector:@selector(tabView:willSelectTabViewItem:)])
        _delegateSelectors |= CPTabViewWillSelectTabViewItemSelector;

    if ([_delegate respondsToSelector:@selector(tabView:didSelectTabViewItem:)])
        _delegateSelectors |= CPTabViewDidSelectTabViewItemSelector;

    if ([_delegate respondsToSelector:@selector(tabViewDidChangeNumberOfTabViewItems:)])
        _delegateSelectors |= CPTabViewDidChangeNumberOfTabViewItemsSelector;
}

-(void) setBorderColor:(CPColor)aColor
{
    [_box setBorderColor:aColor];
}

-(CPColor)setBorderColor{
    return [_box borderColor];
}

- (void)setBackgroundColor:(CPColor)aColor
{
    [_box setBackgroundColor:aColor];
}


- (CPColor)backgroundColor
{
    return [_box backgroundColor];
}

-(CGSize) controlSize 
{	
	return [_tabs frameSize];
}

-(void) setControlSize:(CGSize)aSize 
{	
	_tabs._segmentWidths = {}; 
	
	[_tabs setFrameSize:aSize];
	[self _repositionTabs];
}

-(void) _tabSelectionChanged:(id)sender 
{	
	var idx = [_tabs selectedSegment];
	[self selectTabViewItemAtIndex:idx]
}


- (void)_repositionTabs
{
    var horizontalCenterOfSelf = (CGRectGetWidth([self bounds])) / 2,
        verticalCenterOfTabs = CGRectGetHeight([_tabs bounds]) / 2;

    if (_type === CPBottomTabsBezelBorder)
        [_tabs setCenter:CGPointMake(horizontalCenterOfSelf, CGRectGetHeight([self bounds]) - verticalCenterOfTabs)];
    else
        [_tabs setCenter:CGPointMake(horizontalCenterOfSelf, verticalCenterOfTabs)];
}

- (void)_setSelectedIndex:(CPNumber)index
{
    _selectedIndex = index;
    [self _setContentViewFromItem:[_items objectAtIndex:_selectedIndex]];
}

- (void)_setContentViewFromItem:(CPTabViewItem)anItem
{
    [_box setContentView:[anItem view]];

    [[self window] recalculateKeyViewLoop];
}

- (void)_updateItems
{
    var count = [_items count];
    [_tabs setSegmentCount:count];

    for (var i = 0; i < count; i++)
    {
        [_tabs setLabel:[[_items objectAtIndex:i] label] forSegment:i];
        [_tabs setTag:i forSegment:i];
    }

    [_tabs sizeToFit];

    if (_selectedIndex === CPNotFound)
        [self selectFirstTabViewItem:self];
}

 
@end

var CPTabViewItemsKey           = @"CPTabViewItemsKey",
    CPTabViewTypeKey            = @"CPTabViewTypeKey",
    CPTabViewDelegateKey        = @"CPTabViewDelegateKey";


@implementation CPTabView (CPCoding)


-(id) initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if( self )
    {      
        _items = []; 
      
    

        [self _init];




        [self setTabViewType:[aCoder decodeIntForKey:CPTabViewTypeKey]];
        [self setDelegate:[aCoder decodeObjectForKey:CPTabViewDelegateKey]];

        var theItems = [aCoder decodeObjectForKey:CPTabViewItemsKey],
            count = theItems.length,
            index = 0;

        for(; index < count; index++)
            [self addTabViewItem:theItems[index]];
         
    }

    return self; 

}


-(void) encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_items forKey:CPTabViewItemsKey];
    [aCoder encodeInt:_type forKey:CPTabViewTypeKey];
    [aCoder encodeConditionalObject:_delegate forKey:CPTabViewDelegateKey];
  
}



@end