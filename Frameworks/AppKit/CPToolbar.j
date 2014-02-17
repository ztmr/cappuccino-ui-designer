@import <Foundation/CPArray.j>
@import <Foundation/CPException.j>
@import <Foundation/CPData.j>

@import "CPToolbarItem.j"
@import "CPImage.j"
@import "CPButton.j"
@import "CPMenu.j"
@import "CPWindow.j"

/*! 

	Toolbar delegate must implement :
	
	toolbarItemIdentifiers (returns an array of toolbar item identifiers)
	toolbarItemForIdentifier (returns toolbarItem for a given id)

*/

#define CPTOOLBAR_HEIGHT 58.0

@implementation CPToolbar : CPObject
{

	id 							_delegate @accessors(getter=delegate); 
	CPString 					_identifier; 
	double 						_height @accessors(getter=height); 
	double 						_minWidth; 

	BOOL 						_visible @accessors(getter=isVisible);

	CPView 						_itemsView;

	CPWindow 					_window @accessors(getter=window); 


	CPButton					_overflowArrow; 
	CPMenu						_overflowMenu; 


	CPArray						_flexSpaceItems;
	CPArray 					_toolItems;
	CPArray						_items @accessors(getter=items);

	JSTimer 					_posTimer; 


}



-(id) init 
{
	return [[self alloc] initWithIdentifier:@""];
}

-(id) initWithIdentifier:(CPString)anIden
{
	self = [super init];

	if( self )
	{
		[self _init];
	}

	return self; 
}

-(void) _init
{

	_itemsView = [[CPView alloc] initWithFrame:CGRectMake(0,0, 100, CPTOOLBAR_HEIGHT)];

	_itemsView._DOMElement.addClass("cptoolbar");

	_overflowArrow = [[CPButton alloc] initWithFrame:CGRectMake(76, 0, 24, CPTOOLBAR_HEIGHT-1)];
	[_overflowArrow setBezelStyle:CPRegularSquareBezelStyle];
	[_overflowArrow setAutoresizingMask:CPViewMinXMargin];
	[_overflowArrow setImagePosition:CPImageOnly];
	[_overflowArrow setImageSize:CGSizeMake(10,15)];
	[_overflowArrow setTarget:self];
	[_overflowArrow setAction:@selector(_showOverflowMenu:)];

	var arrowImgData = [[CPApp theme] themeAttribute:@"overflow-arrow-image" forClass:[CPToolbar class]];
 
	[_overflowArrow setBordered:NO];
	[_overflowArrow setBackgroundColor:[CPColor clearColor]];
	[_overflowArrow setImage:[[CPImage alloc] initWithData:[CPData dataWithBase64:arrowImgData]]];


	_overflowMenu = [[CPMenu alloc] init];
	[_overflowMenu setTitle:@"overflow items"];

	[_itemsView addSubview:_overflowArrow];

	[_overflowArrow setHidden:YES];

	_flexSpaceItems = [];
	_toolItems = [];
	_items = [];
	_posTimer = null;
	_delegate = null; 
	_minWidth = -1; 
	_height = CPTOOLBAR_HEIGHT; 


	[self setVisible:YES]; 


}

-(void) setDelegate:(id)delegate 
{
	if(_delegate === delegate)
		return; 

	_delegate = delegate;

	[_items removeAllObjects];
	[_flexSpaceItems removeAllObjects];
	[_toolItems removeAllObjects];

	[self loadItems];

}

-(void) setVisible:(BOOL)aFlag
{
	_visible = aFlag;
	[_itemsView setHidden:!aFlag];
}


-(void) layout
{	
		[self _adjustFlexSpaceItems]; 
		
		[_overflowMenu removeAllItems];
		
		var x = 6;

		var count = _items.length,
			index = 0;

		for(; index < count; index++)
		{
			var item = _items[index];
			if(x + CGRectGetWidth(item._toolbarItemView._frame) > CGRectGetWidth(_itemsView._frame) - CGRectGetWidth(_overflowArrow._frame) + 9  
					&& CGRectGetWidth(_itemsView._frame) <= _minWidth)
			{	
				
				[item._toolbarItemView setHidden:YES]

				var itemID = [item itemIdentifier];
				if(itemID !== CPToolbarFlexibleSpaceItemIdentifier && itemID !== CPToolbarSeparatorItemIdentifier)
				{ 	
					var overflowItem = [CPMenuItem menuItemWithTitle:[item label]]; 
					[overflowItem setIcon:([item image] ? [[item image] copy] : nil)];
					
					if(!item._view)
					{
						[overflowItem setTarget:[item target]];
						[overflowItem setAction:[item action]];
						[overflowItem setEnabled:[item isEnabled]];
					}
					 
					[_overflowMenu addItem:overflowItem];
				  
				} 
			}
			else if([item itemIdentifier] === CPToolbarSeparatorItemIdentifier)
			{	
				[item._toolbarItemView setFrameOrigin:CGPointMake(x,4)];
				[item._toolbarItemView setHidden:NO]; 
			}
			else
			{	
				[item layout];
				[item._toolbarItemView setFrameOrigin:CGPointMake(x,0)];
				[item._toolbarItemView setHidden:NO]; 
			}

			x+=(CGRectGetWidth(item._toolbarItemView._frame) + 6);

		} 
			
		if([_overflowMenu numberOfItems] > 0)
			[_overflowArrow setHidden:NO];
		else
			[_overflowArrow setHidden:YES]; 

}

-(void) _showOverflowMenu:(id)sender
{
		var frame =	[_window frame];
	  	[_overflowMenu setPosition:CGPointMake(CGRectGetMaxX(frame) - [_overflowMenu width] - 2, 
	  											_itemsView._DOMElement.offset().top + CPTOOLBAR_HEIGHT - 20)];
	    setTimeout(function(){
	    	 [_overflowMenu show:nil]; 
		}, 50);
}

-(void) loadItems
{	
	 
 	if(_items.length === 0)
 	{
		if(_delegate && [_delegate respondsToSelector:@selector(toolbarItemIdentifiers:)])
		{
			var itemIds = [_delegate toolbarItemIdentifiers:self];
		 
			if([_delegate respondsToSelector:@selector(toolbar:itemForItemIdentifier:)])
			{	
				var count = itemIds.length,
					index = 0;

				for(; index < count; index++)
				{
					var item = [_delegate toolbar:self itemForItemIdentifier:itemIds[index]];
					[item setToolbar:self];

					if([item itemIdentifier] === CPToolbarFlexibleSpaceItemIdentifier)
						[_flexSpaceItems addObject:item];
					else
						[_toolItems addObject:item];
						
						
					if([item itemIdentifier] === CPToolbarSeparatorItemIdentifier)
					 	[item._toolbarItemView setFrameSize:CGSizeMake(1, CGRectGetHeight(item._toolbarItemView._frame) - 6)];
					
					[_items addObject:item];
					[_itemsView addSubview:item._toolbarItemView];	
				     
				} 

			}else
			{
				[CPException raise:@"CPToolbarDelegateException" reason:"CPToolbar delegate does not implement toolbar:itemForItemIdentifier:"];
			} 
		}else
		{	
			[CPException raise:@"CPToolbarDelegateException" reason:"CPToolbar delegate does not implemenet selector toolbarItemIdentifiers:"]; 
		}
	}
}

-(void) _adjustFlexSpaceItems
{
		
		if(_flexSpaceItems.length > 0)
		{	
			var remWidth = CGRectGetWidth(_itemsView._frame) - 6*_items.length - 12; 
			var minWidth = 0; 	

			var count = _toolItems.length,
				index = 0;

			for(; index < count; index++)
			{
				var item = _toolItems[index];
				remWidth = remWidth - CGRectGetWidth(item._toolbarItemView._frame) ; 
				minWidth+=(CGRectGetWidth(item._toolbarItemView._frame) + 6);

			} 

			var share = MAX(0, remWidth)/_flexSpaceItems.length; 

			count = _flexSpaceItems.length,
			index = 0;

			for(; index < count; index++)
			{
				var item = _flexSpaceItems[index];
				[item._toolbarItemView setFrameSize:CGSizeMake(share, _height)]; 
			}

			_minWidth = minWidth + 12;
		}
}


-(void) setWindow:(CPWindow)aWindow
{
	_window = aWindow;
	
	[_itemsView _setWindow:_window];
	[_itemsView setNextResponder:_window];
}


@end


var CPToolbarItemsKey 					= @"CPToolbarItemsKey", 
	CPToolbarDelegateKey				= @"CPToolbarDelegateKey";

@implementation CPToolbar (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];

	if(self)
	{
		[self _init];

		_items = [aCoder decodeObjectForKey:CPToolbarItemsKey];
 
		var count = _items.length,
			index = 0;

		for(; index < count; index++)
		{
			var item = _items[index];
			[item setToolbar:self];

			if([item itemIdentifier] === CPToolbarFlexibleSpaceItemIdentifier)
				[_flexSpaceItems addObject:item];
			else
				[_toolItems addObject:item];
				
				
			if([item itemIdentifier] === CPToolbarSeparatorItemIdentifier)
			 	[item._toolbarItemView setFrameSize:CGSizeMake(1, CGRectGetHeight(item._toolbarItemView._frame) - 6)];
			
			[_itemsView addSubview:item._toolbarItemView];
		}
	

		[self setDelegate:[aCoder decodeObjectForKey:CPToolbarDelegateKey]];
	}

	return self; 
}

-(void) encodeWithCoder:(CPCoder)aCoder 
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:_items forKey:CPToolbarItemsKey];
	[aCoder encodeConditionalObject:_delegate forKey:CPToolbarDelegateKey];
}

@end