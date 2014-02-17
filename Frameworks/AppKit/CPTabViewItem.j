@import "CPView.j"

@implementation CPTabViewItem : CPObject 
{
	 CPView 					_view @accessors(getter=view); 


	 CPString					_identifier @accessors(property=identifier); 
	 CPString					_label @accessors(property=label); 

	 CPTabView 					_tabView @accessors(getter=tabView); 

}


- (id)init
{
    return [self initWithIdentifier:@""];
}

/*!
    Initializes the tab view item with the specified identifier.
    @return the initialized CPTabViewItem
*/
- (id)initWithIdentifier:(id)anIdentifier
{
    self = [super init];

    if (self)
        _identifier = anIdentifier;

    return self;
}

// Assigning a View
/*!
    Sets the view that gets displayed in this tab.
*/
- (void)setView:(CPView)aView
{
    if (_view == aView)
        return;

    _view = aView;

    if ([_tabView selectedTabViewItem] == self)
        [_tabView _setContentViewFromItem:self];
}

/*!
    @ignore
*/
- (void)_setTabView:(CPTabView)aView
{
    _tabView = aView;
}

@end


var CPTabViewItemIdentifierKey  = "CPTabViewItemIdentifierKey",
    CPTabViewItemLabelKey       = "CPTabViewItemLabelKey",
    CPTabViewItemViewKey        = "CPTabViewItemViewKey",
    CPTabViewItemAuxViewKey     = "CPTabViewItemAuxViewKey";


@implementation CPTabViewItem (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _identifier     = [aCoder decodeObjectForKey:CPTabViewItemIdentifierKey];
        _label          = [aCoder decodeObjectForKey:CPTabViewItemLabelKey];

        _view           = [aCoder decodeObjectForKey:CPTabViewItemViewKey]; 
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{	
	[super encodeWithCoder:aCoder];
    [aCoder encodeObject:_identifier forKey:CPTabViewItemIdentifierKey];
    [aCoder encodeObject:_label forKey:CPTabViewItemLabelKey];

    [aCoder encodeObject:_view forKey:CPTabViewItemViewKey]; 
}

@end