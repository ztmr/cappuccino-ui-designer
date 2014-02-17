@import <Foundation/CPSortDescriptor.j>
@import <Foundation/CPIndexSet.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>


@import "CPTableHeaderView.j"

var CPTableViewDefaultRowHeight = 20.0;  


@implementation CPTableColumn : CPObject 
{
	CPString 					_identifier @accessors(property=identifier); 


	BOOL 						_editable @accessors(property=editable, getter=isEditable);
	BOOL						_draggable @accessors(property=draggable, getter=isDraggable);
	BOOL 						_resizable @accessors(property=resizable, getter=isResizable); 
	BOOL 						_nogrid @accessors(property=nogrid); 
	BOOL 						_hidden @accessors(property=hidden, getter=isHidden); 


	CPString 					_title @accessors(getter=title); 

	CPSortDescriptor 			_sortDescriptorPrototype @accessors(property=sortDescriptorPrototype); 


	double 						_maxWidth @accessors(property=maxWidth);
	double 						_minWidth @accessors(property=minWidth);


	double 						_width @accessors(getter=width);

	JSObject 					_dataViewData; 

	_CPTableColumnHeaderView 	_headerView @accessors(property=headerView); 
	CPTableView 				_tableView @accessors(property=tableView);
	CPView 						_dataView @accessors(property=dataView);
}

-(id) init 
{
	return [[self alloc] initWithIdentifier:@""];
}

-(id) initWithIdentifier:(CPString)anIdentifier
{
	self = [super init];

	if(self)
	{
		_identifier = anIdentifier; 
		_editable = YES;
		_resizable = YES;
		_draggable = YES;

		_maxWidth = Number.MAX_VALUE;
		_minWidth = 10.0;

		_width = 120.0; 

		_title = @""; 

		_nogrid = NO; 

		_sortDescriptorPrototype = nil; 

		_dataViewData = {};
		_hidden = NO; 

		_headerView = [[_CPTableColumnHeaderView alloc] initWithFrame:CGRectMake(0,0, _width, 15)];

		var textView = [CPTextField labelWithString:@""];
		[textView setLineBreakMode:CPLineBreakByWordWrapping];
		[textView setFrameSize:CGSizeMake(_width, CPTableViewDefaultRowHeight)];

		[self setDataView:textView];


	}

	return self; 
}


-(void) setWidth:(double)aWidth
{
	if(!_resizable)
		return;
			
	var newWidth = MIN(MAX(aWidth, _minWidth), _maxWidth);
	
	if(_width === newWidth)
		return;
		
	var oldWidth = _width;
	
	_width = newWidth;
	
	[_headerView setFrameSize:CGSizeMake(_width -10, _headerView._frame.size.height)];
	
	if(_tableView)
	{
		var index = [_tableView tableColumns].indexOf(self),
			dirtyTableColumnRangeIndex = _tableView._dirtyTableColumnRangeIndex;
			
		if(dirtyTableColumnRangeIndex < 0)
			_tableView._dirtyTableColumnRangeIndex = index;
		else
			_tableView._dirtyTableColumnRangeIndex = MIN(index, _tableView._dirtyTableColumnRangeIndex);
			
		var rows = _tableView._exposedRows,
			columns = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(index, 
							[_tableView._exposedColumns lastIndex] -index +1 )];

		
		[_tableView _layoutDataViewsInRows:rows columns:columns];
		[_tableView load];
		[_tableView tile]; 
		[_tableView._scrollView setNeedsDisplay:YES];
		
		[self _postDidResizeNotificationWithOldWidth:oldWidth];
	}
}

-(void) setMinWidth:(double)aMinWidth
{
	if(_minWidth === aMinWidth)
		return;
	
	_minWidth = aMinWidth;
	
	var newWidth = MAX(_width, _minWidth);
	
	if(_width != newWidth)
		[self setWidth:newWidth];
}


-(void) setMaxWidth:(double)aMaxWidth
{
	if(_maxWidth === aMaxWidth)
		return;
	
	_maxWidth = aMaxWidth;
	
	var newWidth = MIN(_width, _maxWidth);
	
	if(_width !== newWidth)
		[self setWidth:newWidth];
}

-(void) setTitle:(CPString)aString
{
	_title = aString; 
	[_headerView setStringValue:_title];
	[_headerView setNeedsLayout];
		 
}

-(void) sizeToFit
{	
	var width = CGRectGetWidth(_headerView._frame);
		
	if (width < _minWidth)
		[self setMinWidth:width]; 
    else if (width > _maxWidth)
        [self setMaxWidth:width];

    if (_width !== width)
		[self setWidth:width]; 

}

-(CPView) dataViewForRow:(int)aRowIndex
{

	var dataViewUID = [self UID] + "," + aRowIndex; 

	var x = _tableView._cachedDataViews[dataViewUID];
	
	if(x && x.length)
	{ 
		var view = x.pop();
		return view; 
	}
 	
 	if(_tableView._delegate && 
		[_tableView._delegate respondsToSelector:@selector(tableView:viewForTableColumn:row:)])
	{

		var view =  [_tableView._delegate tableView:_tableView viewForTableColumn:self row:aRowIndex];
	
		if(view)
		{ 	
			view.identifier = dataViewUID; 
			view.column = self;
			view.row = aRowIndex; 
			return view;  
		}
			 
	}


	var uid = [_dataView UID];

	// if we haven't cached an archive of the data view, do it now
	if (!_dataViewData[uid])
	{
        _dataViewData[uid] = [CPKeyedArchiver archivedDataWithRootObject:_dataView]; 
 		 
    }
    // unarchive the data view cache
 
    var newDataView = [CPKeyedUnarchiver unarchiveObjectWithData:_dataViewData[uid]]; 
    newDataView.identifier = dataViewUID;
    newDataView.column = self;
    newDataView.row = aRowIndex; 

    // make sure only we have control over the size and placement
	[newDataView setAutoresizingMask:CPViewNotSizable];
    newDataView._DOMElement.addClass("cptableview-dataview");

    return newDataView; 
}

-(CPView) _newDataViewForRow:(int)aRowIndex
{

	return [self dataViewForRow:aRowIndex]
	 

}

-(void) _postDidResizeNotificationWithOldWidth:(double)oldWidth
{
	[[CPNotificationCenter defaultCenter] postNotificationName:CPTableViewColumnDidResizeNotification
														object:_tableView 
													  userInfo:@{@"tableColumn" : self, @"oldWidth" : oldWidth}];

	


}





@end

var CPTableColumnIdentifierKey 					= @"CPTableColumnIdentifierKey",
	CPTableColumnEditableKey 					= @"CPTableColumnEditableKey",
	CPTableColumnDraggableKey					= @"CPTableColumnDraggableKey", 
	CPTableColumnResizableKey					= @"CPTableColumnResizableKey",
	CPTableColumnNoGridKey						= @"CPTableColumnNoGridKey",
	CPTableColumnHiddenKey						= @"CPTableColumnHiddenKey",
	CPTableColumnTitleKey						= @"CPTableColumnTitleKey",
	CPTableColumnMaxWidthKey					= @"CPTableColumnMaxWidthKey",
	CPTableColumnMinWidthKey					= @"CPTableColumnMinWidthKey",
	CPTableColumnWidthKey 						= @"CPTableColumnWidthKey",
	CPTableColumnDataViewKey 					= @"CPTableColumnDataViewKey",
	CPTableColumnSortDescriptorPrototypeKey		= @"CPTableColumnSortDescriptorPrototypeKey";

@implementation CPTableColumn (CPCoding)

-(void) encodeWithCoder:(CPCoder)aCoder 
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:_identifier forKey:CPTableColumnIdentifierKey];
	[aCoder encodeBool:_editable forKey:CPTableColumnEditableKey];
	[aCoder encodeBool:_draggable forKey:CPTableColumnDraggableKey];
	[aCoder encodeBool:_resizable forKey:CPTableColumnResizableKey];
	[aCoder encodeBool:_nogrid forKey:CPTableColumnNoGridKey];
	[aCoder encodeBool:_hidden forKey:CPTableColumnHiddenKey];
	[aCoder encodeObject:_title forKey:CPTableColumnTitleKey];
	[aCoder encodeNumber:_maxWidth forKey:CPTableColumnMaxWidthKey];
	[aCoder encodeNumber:_minWidth forKey:CPTableColumnMinWidthKey];
	[aCoder encodeNumber:_width forKey:CPTableColumnWidthKey];
	[aCoder encodeObject:_dataView forKey:CPTableColumnDataViewKey];
	[aCoder encodeObject:_sortDescriptorPrototype forKey:CPTableColumnSortDescriptorPrototypeKey];

}


-(id) initWithCoder:(CPCoder)aCoder 
{
	self = [super initWithCoder:aCoder];
	if( self )
	{
		_identifier = [aCoder decodeObjectForKey:CPTableColumnIdentifierKey]; 
		_editable =   [aCoder decodeBoolForKey:CPTableColumnEditableKey];
		_resizable = [aCoder decodeBoolForKey:CPTableColumnResizableKey];
		_draggable = [aCoder decodeBoolForKey:CPTableColumnDraggableKey];

		_maxWidth = [aCoder decodeNumberForKey:CPTableColumnMaxWidthKey];
		_minWidth = [aCoder decodeNumberForKey:CPTableColumnMinWidthKey];

		_width = [aCoder decodeNumberForKey:CPTableColumnWidthKey]; 

		_title = [aCoder decodeObjectForKey:CPTableColumnTitleKey]; 

		_nogrid = [aCoder decodeBoolForKey:CPTableColumnNoGridKey]; 

		_sortDescriptorPrototype = [aCoder decodeObjectForKey:CPTableColumnSortDescriptorPrototypeKey]; 

		_dataViewData = {};
		_hidden = [aCoder decodeBoolForKey:CPTableColumnHiddenKey]; 

		_headerView = [[_CPTableColumnHeaderView alloc] initWithFrame:CGRectMake(0,0, _width, 15)];
		
		[self setDataView:[aCoder decodeObjectForKey:CPTableColumnDataViewKey]];

	}

	return self; 
}



@end