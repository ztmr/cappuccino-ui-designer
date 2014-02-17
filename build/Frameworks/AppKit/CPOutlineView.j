@import "CPTableView.j"


var CPOutlineViewItemDidCollapseNotification        = @"CPOutlineViewItemDidCollapseNotification",
	CPOutlineViewItemDidExpandNotification          = @"CPOutlineViewItemDidExpandNotification",
	CPOutlineViewItemWillCollapseNotification       = @"CPOutlineViewItemWillCollapseNotification",
	CPOutlineViewItemWillExpandNotification         = @"CPOutlineViewItemWillExpandNotification",
	CPOutlineViewSelectionDidChangeNotification     = @"CPOutlineViewSelectionDidChangeNotification",
	CPOutlineViewSelectionIsChangingNotification    = @"CPOutlineViewSelectionIsChangingNotification";

@implementation _CPOutlineViewDataSource : CPObject 
{

	CPOutlineView 			_outlineView @accessors(property=outlineView); 

}

-(int) numberOfRowsInTableView:(CPTableView)tableView 
{
	return _outlineView._itemsForRows.length; 

}

-(id) tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)tableColumn row:(int)row
{
	if([tableColumn identifier] !== @"disclosureColumn")
	{
		var item = [_outlineView itemAtRow:row];
		return [_outlineView._outlineViewDataSource performSelector:@selector(outlineView:objectValueForTableColumn:byItem:)
			withObjects:_outlineView, tableColumn, item]; 
	}
	 
	
	return nil;

}

-(void) tableView:(CPTableView)tableView setObjectValue:(id)value forTableColumn:(CPTableColumn)tableColumn row:(int)row
{	
	if([_outlineView._outlineViewDataSource respondsToSelector:@selector(outlineView:setObjectValue:forTableColumn:byItem:)])
	{
			var item = [_outlineView itemAtRow:row];

			[_outlineView._outlineViewDataSource performSelector:@selector(outlineView:setObjectValue:forTableColumn:byItem:)
					withObjects:_outlineView, value,tableColumn,item];
	} 

}

-(void) tableView:(CPTableView)tableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{	
	if([_outlineView._outlineViewDataSource respondsToSelector:@selector(outlineView:sortDescriptorsDidChange:)])
	{
		[_outlineView._outlineViewDataSource performSelector:@selector(outlineView:sortDescriptorsDidChange:)
				withObjects:_outlineView, oldDescriptors];
	}
	 
}

-(void)tableView:(CPTableView)tableView heightForRow:(int)row 
{
	if(_outlineView._outlineViewDelegate)
	{		
		if([_outlineView._outlineViewDelegate respondsToSelector:@selector(tableView:heightForRow:)])
		{
			var item = [_outlineView itemAtRow:row];
			return [_outlineView._outlineViewDelegate outlineView:_outlineView heightForItem:item];
		}	
 
	}
		
	return CPTableViewDefaultRowHeight;
}

 

@end 


@implementation CPOutlineViewDisclosureButton : CPButton 
{

}

-(id) initWithFrame:(CGRectMake)aFrame 
{
	self = [super initWithFrame:aFrame];

	if(self)
	{	

		[self setImagePosition:CPImageOnly];

		_DOMElement.addClass("cpoutlineview-disclosure-control");
 
		[self setBordered:NO];
		[self setBackgroundColor:[CPColor clearColor]];

	}

	return self; 
}

-(CGSize) imageSize
{
	return CGSizeMake(11,11);
}
 
@end


@implementation CPOutlineView : CPTableView 
{
		id 					_outlineViewDataSource; 
		id 					_outlineViewDelegate; 
 
		JSObject 			_itemsForRows; 
		CPArray 			_disclosureControlsForRows; 
		JSObject 			_rootItemInfo; 
		JSObject 			_itemInfosForItems; 

		BOOL 				_firstLoad; 
}


-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if(self)
	{
		_firstUserColumn = 1; 
		_outlineViewDataSource = nil;
		_outlineViewDelegate = nil;

		_dataSource = [[_CPOutlineViewDataSource alloc] init];
		[_dataSource setOutlineView:self];
		_delegate = _dataSource; 

		_itemsForRows = [];
		_rootItemInfo = { isExpanded:true, isExpandable:false, level:-1, row:-1, children:[], weight:0 };
		_itemInfosForItems = {};
		_disclosureControlsForRows = [];

		_gridStyleMask = CPTableViewGridNone; 

		 
		var disclosureCol = [[CPTableColumn alloc] initWithIdentifier:@"disclosureColumn"];
		
		 
		[disclosureCol setWidth:16];
		[disclosureCol setResizable:NO];
		[disclosureCol setEditable:NO];
		[disclosureCol setDraggable:NO];

		[self addTableColumn:disclosureCol];
		_firstLoad = YES; 
	}


	return self; 

}

-(void) setDataSource:(id)ds 
{
	_outlineViewDataSource = ds; 
}

-(id) dataSource 
{
	return _outlineViewDataSource; 
}

-(void) setDelegate:(id)aDelegate 
{
	if (_outlineViewDelegate === aDelegate)
			return;

	var defaultCenter = [CPNotificationCenter defaultCenter];

    if (_outlineViewDelegate)
    {

        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewSelectionDidChange:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewSelectionDidChangeNotification
                        object:self];

        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewSelectionIsChanging:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewSelectionIsChangingNotification
                        object:self];



        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemWillExpand:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewItemWillExpandNotification
                        object:self];


        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemDidExpand:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewItemDidExpandNotification
                        object:self];


        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemWillCollapse:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewItemWillCollapseNotification
                        object:self];


        if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemDidCollapse:)])
            [defaultCenter
                removeObserver:_outlineViewDelegate
                          name:CPOutlineViewItemDidCollapseNotification
                        object:self];



    }

    _outlineViewDelegate = aDelegate; 



    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewSelectionDidChange:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewSelectionDidChange:)
            name:CPOutlineViewSelectionDidChangeNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewSelectionIsChanging:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewSelectionIsChanging:)
            name:CPOutlineViewSelectionIsChangingNotification
            object:self];


    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemWillExpand:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewItemWillExpand:)
            name:CPOutlineViewItemWillExpandNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemDidExpand:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewItemDidExpand:)
            name:CPOutlineViewItemDidExpandNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemWillCollapse:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewItemWillCollapse:)
            name:CPOutlineViewItemWillCollapseNotification
            object:self];

    if ([_outlineViewDelegate respondsToSelector:@selector(outlineViewItemDidCollapse:)])
        [defaultCenter
            addObserver:_outlineViewDelegate
            selector:@selector(outlineViewItemDidCollapse:)
            name:CPOutlineViewItemDidCollapseNotification
            object:self];
}

-(id) delegate
{
	return _outlineViewDelegate; 
}


-(BOOL) isExpandable:(id)anItem 
{
	if(!anItem)
		return YES;

	var itemInfo = _itemInfosForItems[[anItem UID]];

	if(!itemInfo)
		return NO;

	return itemInfo.isExpandable;
}

-(BOOL) isItemExpanded:(id)anItem 
{
	if(!anItem)
		return YES; 

	var itemInfo = _itemInfosForItems[[anItem UID]];

	if(!itemInfo)
		return NO;

	return itemInfo.isExpanded; 
}

-(int) levelForItem:(id)anItem 
{
	if(!anItem)
		return _rootItemInfo.level;

	var itemInfo = _itemInfosForItems[[anItem UID]];

	if(!itemInfo)
		return -1;

	return itemInfo.level; 

}

-(int) levelForRow:(int)row 
{
	return [self levelForItem:[self itemAtRow:row]];
}

-(id) itemAtRow:(int)anIndex 
{
	return _itemsForRows[anIndex] ; 
}

-(int) rowForItem:(id)anItem 
{
	if(!anItem)
		return _rootItemInfo.row;

	var itemInfo = _itemInfosForItems[[anItem UID]];

	if(!itemInfo)
		return -1;

	return itemInfo.row; 
}


-(void) expandItem:(id)anItem
{
	[self expandItem:anItem shouldExpandChildren:NO];
}

-(void)expandItem:(id)anItem shouldExpandChildren:(BOOL)shouldExpandChildren
{
	var itemInfo = nil;
	if (!anItem)
		    itemInfo = _rootItemInfo;
		else
		    itemInfo = _itemInfosForItems[[anItem UID]];

		if (!itemInfo)
        	return;

		// to prevent items which are already expanded from firing notifications
	    if (!itemInfo.isExpanded)
	    {
			var previousRowCount = [self numberOfRows];
			[self _noteItemWillExpand:anItem];
	        itemInfo.isExpanded = true;
	        [self reloadItem:anItem shouldReloadChildren:YES];
	        [self _noteItemDidExpand:anItem];
	         
			var rowCountDelta = [self numberOfRows] - previousRowCount;
		    if (rowCountDelta)
	        {
	            var selection =  [self selectedRowIndexes],
	             	expandIndex = [self rowForItem:anItem] + 1;
			 	
			 	if([selection intersectsIndexesInRange:CPMakeRange(expandIndex, _itemsForRows.length)])
			 	{
			 		[selection shiftIndexesStartingAtIndex:expandIndex by:rowCountDelta];
			 		[self _setSelectedRowIndexes:selection];
			 		 
			 		
			 	} 
	        }
	 
	    }

	    if (shouldExpandChildren)
	    {
	        var children = itemInfo.children,
	            childIndex = children.length;

	        while (childIndex--)
	        	[self expandItem:children[childIndex] shouldExpandChildren:YES]; 
	    }
}


-(void) collapseItem:(id)anItem
{

		if (!anItem)
	        return;

	    var itemInfo = _itemInfosForItems[[anItem UID]];

	    if (!itemInfo)
	        return;

	    if (!itemInfo.isExpanded)
	        return;
	
		 var collapseTopIndex = [self rowForItem:anItem],  
		     topLevel = [self levelForRow:collapseTopIndex],
		     collapseEndIndex = collapseTopIndex;

		    while (collapseEndIndex + 1 < _itemsForRows.length && [self levelForRow:collapseEndIndex + 1] > topLevel)
		        collapseEndIndex++;

		    var collapseRange = CPMakeRange(collapseTopIndex + 1, collapseEndIndex - collapseTopIndex);

		    if (collapseRange.length)
		    {
		        var selection = [self selectedRowIndexes];

		        if([selection intersectsIndexesInRange:collapseRange])
		        {
		        	[selection removeIndexesInRange:collapseRange];
		        	[self _setSelectedRowIndexes:selection];
		        } 

		        if([selection intersectsIndexesInRange:CPMakeRange(collapseEndIndex + 1, _itemsForRows.length)])
		        {
		        	[selection shiftIndexesStartingAtIndex:collapseEndIndex by:-collapseRange.length];
		        	[self _setSelectedRowIndexes:selection];
		        } 
		
				[_scrollView setNeedsDisplay:YES]; 
		    }
	
		[self _noteItemWillCollapse:anItem];	
	    itemInfo.isExpanded = false;
	    [self reloadItem:anItem shouldReloadChildren:YES]; 
	    [self _noteItemDidCollapse:anItem];
}

-(void) reloadItem:(id)anItem 
{
	[self reloadItem:anItem shouldReloadChildren:NO];
}

-(void) reloadItem:(id)anItem shouldReloadChildren:(BOOL)shouldReloadChildren
{
	if (!!shouldReloadChildren || !anItem)
		[self _loadItemInfoForItem:anItem isIntermediate:NO];
	else
 		[self _reloadItem:anItem];
	
	
    [super reloadData];  
}


-(CGRect) frameOfDataViewAtColumn:(int)column row:(int)row 
{
		var frame = CGRectCreateCopy([super frameOfDataViewAtColumn:column row:row]);
	
		if(column === 1)
		{
			var indentationWidth = [self levelForRow:row] * 14.0;
			frame.origin.x += indentationWidth; 
			frame.size.width -= indentationWidth;
			
			return frame; 
		}
		
		
		return frame; 
}


-(CPArray) _loadItemInfoForItem:(id)anItem isIntermediate:(BOOL)isIntermediate
{
	 
	var itemInfosForItems = _itemInfosForItems,
		       dataSource = _outlineViewDataSource;
		
	var itemInfo;
	if (anItem == null)
		itemInfo = _rootItemInfo;
	else
	{
		// Get the existing info if it exists.
		var itemUID = [anItem UID],
		itemInfo = itemInfosForItems[itemUID]; 
        // If we're not in the tree, then just bail.
        if (!itemInfo)
            return [];
		 
        itemInfo.isExpandable = [dataSource outlineView:self isItemExpandable:anItem];  
      
		if (!itemInfo.isExpandable && itemInfo.isExpanded)
        {
            itemInfo.isExpanded = false;
            itemInfo.children = [];
        } 
	}
	
	var weight = itemInfo.weight,
		descendants = anItem ? [anItem] : [];
  	
	if(itemInfo.isExpanded)
	{
		var index = 0,
	        count = [dataSource outlineView:self numberOfChildrenOfItem:anItem];
	        level = itemInfo.level + 1;
	 	
		itemInfo.children = []; 
		for (; index < count; index++)
		{
	        var childItem = [dataSource outlineView:self child:index ofItem:anItem];
	        childItemInfo = itemInfosForItems[[childItem UID]];
			 	
            if (!childItemInfo)
            {
                childItemInfo = { isExpanded:false, isExpandable:false, children:[], weight:1, 
                	parent : anItem, level : level};
                
                itemInfosForItems[[childItem UID]] = childItemInfo;
            }

            itemInfo.children[index] = childItem;
			
            var childDescendants = [self _loadItemInfoForItem:childItem isIntermediate:YES];
            descendants = descendants.concat(childDescendants);
        } 
	} 
	
	itemInfo.weight = descendants.length;
 	
	if (!isIntermediate)
	{
    	// row = -1 is the root item, so just go to row 0 since it is ignored.
        var index = MAX(itemInfo.row, 0),
            itemsForRows = _itemsForRows;
		 
        descendants.unshift(index, weight);

        itemsForRows.splice.apply(itemsForRows, descendants);
	  
        var count = itemsForRows.length;

        for (; index < count; index++)
            itemInfosForItems[[itemsForRows[index] UID]].row = index;

        var deltaWeight = itemInfo.weight - weight;

        if (deltaWeight !== 0)
        {
            var parent = itemInfo.parent;

            while (parent)
            {
                var parentItemInfo = itemInfosForItems[[parent UID]];

                parentItemInfo.weight += deltaWeight;
                parent = parentItemInfo.parent;
            }

            if (anItem)
                _rootItemInfo.weight += deltaWeight;
        }
	} 	

 
	return descendants; 

}


-(void) _reloadItem:(id)anItem 
{

	if (!anItem)
	     return;
	
	// Get the existing info if it exists.
    var itemInfosForItems = _itemInfosForItems,
        dataSource = _outlineViewDataSource,
        itemUID = [anItem UID],
        itemInfo = itemInfosForItems[itemUID];

    // If we're not in the tree, then just bail.
    if (!itemInfo)
        return [];

    // See if the item itself can be swapped out.
    var parent = itemInfo.parent,
        parentItemInfo = parent ? itemInfosForItems[[parent UID]] : _rootItemInfo,
        parentChildren = parentItemInfo.children,
        index = parentChildren.indexOf(anItem),
        newItem = [dataSource outlineView:self child:index ofItem:parent];
         

    if (anItem !== newItem)
    {
        itemInfosForItems[[anItem UID]] = null;
        itemInfosForItems[[newItem UID]] = itemInfo;

        parentChildren[index] = newItem;
        _itemsForRows[itemInfo.row] = newItem;
    }

    itemInfo.isExpandable = [dataSource outlineView:self isItemExpandable:newItem];
    itemInfo.isExpanded = itemInfo.isExpandable && itemInfo.isExpanded;
}
 

-(void) reloadData 
{	
	[self reloadItem:nil shouldReloadChildren:NO];
}
 
 

-(void)_loadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
	[super _loadDataViewsInRows:rows columns:columns];

	/*add in expanders */
	var rowArray = [];

	[rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];
		
	var rowIndex = 0,
	    rowsCount = rowArray.length;

	 
	for (; rowIndex < rowsCount; rowIndex++)
	{
		var row = rowArray[rowIndex],
	        item = _itemsForRows[row],
            isExpandable = [self isExpandable:item],
			isExpanded = [self isItemExpanded:item];

        if (!isExpandable)
            continue;
		
		[_disclosureControlsForRows[row] removeFromSuperview]; 
		
		var dataViewFrame = [self frameOfDataViewAtColumn:1 row:row];  
		
		var control = [[CPOutlineViewDisclosureButton alloc] initWithFrame:
				CGRectMake(dataViewFrame.origin.x-18, dataViewFrame.origin.y+1  
					  , 16,16)];

		[control setTarget:self];
		[control setAction:@selector(_toggleDisclosureControl:)];		
 
	
		if(isExpanded)
		 	[control setState:CPControlSelectedState];
			 
	
		control.row = row;  
  
		[_dataBodyView addSubview:control];
		

		_disclosureControlsForRows[row] = control;
		
		 
	 
	}  
}

-(void)_unloadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{

	[super _unloadDataViewsInRows:rows columns:columns];
 	
 	for(var key in _disclosureControlsForRows)
	{
		var control = _disclosureControlsForRows[key];

		if(!control)
			continue;
			
		[control removeFromSuperview]; 
		
		_disclosureControlsForRows[key] = Nil; 
	} 
}


- (void)_noteSelectionIsChanging
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewSelectionIsChangingNotification
                      object:self
                    userInfo:nil];
}

- (void)_noteSelectionDidChange
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewSelectionDidChangeNotification
                      object:self
                    userInfo:nil];
}

- (void)_noteItemWillExpand:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemWillExpandNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:item forKey:"CPObject"]];
}

- (void)_noteItemDidExpand:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemDidExpandNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:item forKey:"CPObject"]];
}

- (void)_noteItemWillCollapse:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemWillCollapseNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:item forKey:"CPObject"]];
}

- (void)_noteItemDidCollapse:(id)item
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPOutlineViewItemDidCollapseNotification
                      object:self
                    userInfo:[CPDictionary dictionaryWithObject:item forKey:"CPObject"]];
}


-(void)_toggleDisclosureControl:(id)sender 
{
	 
	if([sender state] == CPControlNormalState)
	   	[self expandItem:[self itemAtRow:sender.row]];
	else
	   	[self collapseItem:[self itemAtRow:sender.row]];
}

@end