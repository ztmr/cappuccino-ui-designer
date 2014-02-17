@import "CPScrollView.j"
@import "CPTableColumn.j"

var CPTableViewColumnDidMoveNotification        = @"CPTableViewColumnDidMoveNotification",
	CPTableViewColumnDidResizeNotification      = @"CPTableViewColumnDidResizeNotification",
	CPTableViewSelectionDidChangeNotification   = @"CPTableViewSelectionDidChangeNotification",
	CPTableViewSelectionIsChangingNotification  = @"CPTableViewSelectionIsChangingNotification";


var CPTableViewGridNone 						= 0,
	CPTableViewSolidVerticalGridLineMask 		= 1 << 0,
	CPTableViewSolidHorizontalGridLineMask 		= 1 << 1; 

 
var CPTableViewCellEditor = null; 

@implementation _CPTableScrollView : CPScrollView 
{
	CPTableView 			_tableView @accessors(property=tableView);
}

-(void) mouseDown:(CPEvent)theEvent
{
	[_tableView._dataBodyView mouseDown:theEvent];
 
}

-(void)keyUp:(CPEvent)theEvent
{
	//do nothing
}

-(void) drawRect:(CGRect)aRect 
{
	var ctx = _graphicsContext; 
		
    var dataView = _tableView._dataBodyView; 
   // draw grid
   var  exposedRect = [dataView visibleRect],
   		exposedRows = /*CPRange */ [_tableView rowsInRect:exposedRect], 
        count = exposedRows.location + exposedRows.length,
        index = exposedRows.location,
		rheight = 0; 

	var theme = [[CPApp theme] CPTableView];
	var sourceListSelectionStartColor = [theme objectForKey:@"sourceListSelectionStartColor"],
		sourceListSelectionEndColor = [theme objectForKey:@"sourceListSelectionEndColor"],
		sourceListTopLineColor = [theme objectForKey:@"sourceListTopLineColor"],
		sourceListBottomLineColor = [theme objectForKey:@"sourceListBottomLineColor"],
		selectionColor = [theme objectForKey:@"selectionColor"],
		gridLineColor = [theme objectForKey:@"gridLineColor"];

	var st = [self scrollTop];

	ctx.fillStyle = 'transparent'
	ctx.fillRect(0, 0, _frame.size.width, _frame.size.height);

    for(; index < count; index++)
    {   
        var rowBkIndex = (index % 2 === 0) ? 0 : 1;  
		var rowRect = [_tableView rectOfRow:index];  
		
		
        if([_tableView._selectedRowIndexes containsIndex:index])
        {
        	
			 
			if([_tableView isSourceList])
			{ 
			  	var grd = ctx.createLinearGradient(0,rowRect.origin.y - st,0, rowRect.origin.y - st + rowRect.size.height);
				grd.addColorStop(0, sourceListSelectionStartColor);
				grd.addColorStop(1, sourceListSelectionEndColor);
				ctx.fillStyle = grd;
				
				ctx.fillRect(0, rowRect.origin.y - st, _frame.size.width, rowRect.size.height);
				
				ctx.fillStyle = sourceListTopLineColor;
				ctx.fillRect(0, rowRect.origin.y - st, _frame.size.width, 1);
				ctx.fillStyle = sourceListBottomLineColor;
				ctx.fillRect(0, rowRect.origin.y - st + rowRect.size.height -1, _frame.size.width, 1);				
			}
			else
			{
            	ctx.fillStyle = selectionColor ;
				ctx.fillRect(0, rowRect.origin.y - st, _frame.size.width, rowRect.size.height);
			}

			ctx.fillStyle = 'transparent'
        }
        else
        {
            if([_tableView usesAlternatingRowBackgroundColors])
                ctx.fillStyle = [[_tableView alternatingRowBackgroundColors][rowBkIndex] cssString];
            else
			{
				if([_tableView backgroundColor])
                	ctx.fillStyle = [[_tableView backgroundColor] hexString]; 
				else
					ctx.fillStyle = "#ffffff";
			}
			ctx.fillRect(0, rowRect.origin.y - st, _frame.size.width, rowRect.size.height);
        } 
			

		if(_tableView._gridStyleMask & CPTableViewSolidHorizontalGridLineMask)
        {
            ctx.fillStyle = gridLineColor ; 
            ctx.fillRect(0, rowRect.origin.y + rowRect.size.height - 1 - st, CGRectGetWidth(dataView._frame), 1);
        }

		rheight = CGRectGetMaxY(rowRect);
    }



	//add in stripes for empty area
	if([_tableView usesAlternatingRowBackgroundColors])
	{
		var index = count;
		while(rheight < CGRectGetMaxY(_tableView._frame))
		{	
			var rowBkIndex = (index % 2 === 0) ? 0 : 1; 
			ctx.fillStyle = [[_tableView alternatingRowBackgroundColors][rowBkIndex] cssString];
			ctx.fillRect(0, rheight, _frame.size.width, CPTableViewDefaultRowHeight);
			rheight+=CPTableViewDefaultRowHeight;
			index++;  
		}
		
	}

	

    if(_tableView._gridStyleMask & CPTableViewSolidVerticalGridLineMask)
    {
        var nc = [_tableView numberOfColumns],   
        index = 0;
        ctx.fillStyle = gridLineColor;
        for(; index < nc; index++)
        {
			if(![[_tableView tableColumns][index] nogrid])
			{
            	var colRect = [_tableView rectOfColumn:index];  
	            ctx.fillRect(CGRectGetMaxX(colRect) - [_tableView._scrollView scrollLeft], 0, 1, CGRectGetHeight(_tableView._scrollView._frame));
			}
        }

        ctx.fillRect(CGRectGetWidth(dataView._frame), 0, 1, CGRectGetHeight(dataView._frame));
    }

}


@end


@implementation _CPTableDataBodyView : CPView 
{
	int 				_selectionAndAnchorRow; 
	CPTableView 		_tableView @accessors(property=tableView); 
}

-(BOOL)acceptsFirstResponder
{
	return YES; 
}

-(BOOL)_getIsRowSelectable:(int)aRow 
{

	if(aRow < 0)
		return NO; 
	 
	var ok = YES; 

	if(_tableView._delegate && [_tableView._delegate respondsToSelector:@selector(tableView:shouldSelectRow:)])
	{
		ok = [_tableView._delegate tableView:_tableView shouldSelectRow:aRow];

	} 

	 

	return ok;
}

-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if( self )
	{
		_selectionAndAnchorRow = -1; 
		_isRowSelectable = {}; 

		_DOMElement.bind("dblclick", function(evt){
			
			evt.preventDefault();
			evt.stopPropagation(); 
			evt._window = [self window];

			var theEvent = [CPEvent event:evt]

			[self doubleAction:theEvent];
			
			[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
			
		});

	}

	return self; 
}

-(void) mouseDown:(CPEvent)theEvent
{
	var mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	var aRow = [_tableView rowAtPoint:mouseLocation];
	
	var aCol = [_tableView columnAtPoint:mouseLocation];

	var ok = [self _getIsRowSelectable:aRow]; 
  

	if(ok && aRow > -1)
	{	
		_tableView._clickedRow = aRow;
		_tableView._clickedColumn = aCol;

		[_tableView _noteSelectionIsChanging];

		if(_selectionAndAnchorRow > -1 && [theEvent shiftKey] 
				&& [_tableView allowsMultipleSelection])
		{
			var newSelection = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(MIN(aRow, _selectionAndAnchorRow), 
					ABS(aRow - _selectionAndAnchorRow) + 1)];
				
			[_tableView selectRowIndexes:newSelection shouldExtendSelection:NO];
		}
		else
		{
			if(aRow > -1 || [_tableView allowsEmptySelection])
			{
				_selectionAndAnchorRow= aRow;
				[_tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] shouldExtendSelection:NO];
			}
			
		}
	}
	
	[[self window] makeFirstResponder:self];

	if(CPTableViewCellEditor)
 		CPTableViewCellEditor.blur();	
  
}

-(void) doubleAction:(CPEvent) theEvent
{
	 
	var mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	var aRow = [_tableView rowAtPoint:mouseLocation];
	var aCol = [_tableView columnAtPoint:mouseLocation];
	
	_tableView._clickedRow = aRow;
	_tableView._clickedColumn = aCol;

	if(_tableView._doubleAction)
	{
		[CPApp sendAction:_tableView._doubleAction to:[_tableView target] from:_tableView];
	}
	else
	{
		[_tableView editColumn:aCol row:aRow];	
	}
}

-(void) keyDown:(CPEvent)theEvent 
{
	var KC = [theEvent keyCode];
	var currentRow = [_tableView selectedRow];

 
	if(KC === CPDownArrowKeyCode)
	{	
		currentRow++
		while(![self _getIsRowSelectable:currentRow] && currentRow < [_tableView numberOfRows])
				currentRow++;

		if(currentRow  < [_tableView numberOfRows])
		{ 
			if([self _getIsRowSelectable:currentRow])
			{
				[_tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:currentRow] shouldExtendSelection:NO];
			 	var rowbottom = (currentRow + 1)*(CPTableViewDefaultRowHeight + 3)  ; 
			 
				if(currentRow < _tableView._cachedRowHeights.length)
				{
					var h = _tableView._cachedRowHeights[currentRow];
				    rowbottom = h.heightAboveRow + h.height + 3 ; 
				}
				 
				if(![_tableView._scrollView isPointVisible:CGPointMake([_tableView._scrollView scrollLeft] + 1, 
									rowbottom )])
	            {   
				 	
				 	var sv = _tableView._scrollView; 
	                var cs = [sv scrollTop];  
	                var sh = CGRectGetHeight(sv._frame) - sv._horizontalBars*16.0;
					[_tableView._scrollView setScrollTop:(cs + (rowbottom - (cs + sh)))]; 
	            }
				
				_selectionAndAnchorRow = currentRow;
			}
			
			if(CPTableViewCellEditor)
				CPTableViewCellEditor.blur(); 
				
			[[self window] makeFirstResponder:self]; 
		}
	}
	else if(KC === CPUpArrowKeyCode)
	{
		currentRow--
		while(![self _getIsRowSelectable:currentRow] && currentRow > -1 )
				currentRow--;

		if(currentRow  > -1)
        {   
            if([self _getIsRowSelectable:currentRow])
            {
	           	[_tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:currentRow] shouldExtendSelection:NO];
				
				var rowtop = currentRow*(CPTableViewDefaultRowHeight + 3); 
				
	            if(currentRow < _tableView._cachedRowHeights.length){
	                var h = _tableView._cachedRowHeights[currentRow];
	                rowtop = h.heightAboveRow - 5;   
	            }

				if(![_tableView._scrollView isPointVisible:CGPointMake([_tableView._scrollView scrollLeft] + 1, 
										rowtop )])
	            {   
					[_tableView._scrollView setScrollTop:rowtop]; 
	            }

	            _selectionAndAnchorRow = currentRow;
	        } 

            if(CPTableViewCellEditor)
            	CPTableViewCellEditor.blur(); 
            
			[[self window] makeFirstResponder:self]; 
        }
	}
	else if(KC === CPReturnKeyCode)
	{
		[_tableView editColumn:_tableView._firstUserColumn row:currentRow];
	}
	else if(KC === CPTabKeyCode)
	{
		var ec = [_tableView editedColumn];
		if(ec + 1 >= [_tableView numberOfColumns])
			ec = _tableView._firstUserColumn-1;
		
		[_tableView editColumn:ec+1 row:currentRow];
	}
	
	[super keyDown:theEvent];
}

@end


@implementation _CPColumnDragView : CPView 
{
		CPColor 			_lineColor @accessors(property=lineColor);


}

-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if(self)
	{
		_DOMElement.addClass("cpcolumndragview");
	}

	return self; 
}

@end

@protocol CPTableViewDataSource 

-(int) numberOfRowsInTableView:(CPTableView)aTableView;
-(id) tableView:(CPTableView)tableView objectValueForTableColumn:(CPTableColumn)aColumn row:(int)row;
  
@end

@protocol CPTableViewDelegate 

-(int) tableView:(CPTableView)tableView heightForRow:(int)row;
-(BOOL) tableView:(CPTableView)tableView shouldSelectRow:(int)row; 
-(CPView)tableView:(CPTableView)tableView viewForTableColumn:(CPTableColumn)tableColumn row:(int)row; 

@end


@implementation CPTableView : CPControl
{	

	BOOL 					_allowsColumnReordering @accessors(property=allowsColumnReordering);
	BOOL 					_allowsColumnResizing @accessors(property=allowsColumnResizing);
	BOOL 					_allowsMultipleSelection @accessors(property=allowsMultipleSelection);
	BOOL 					_allowsEmptySelection @accessors(property=allowsEmptySelection);
	BOOL 					_usesAlternatingRowBackgroundColors @accessors(property=usesAlternatingRowBackgroundColors);
	BOOL 					_sourceList @accessors(getter=isSourceList, property=sourceList);
	BOOL 					_hasHeader @accessors(getter=hasHeader);

	CPArray 				_alternatingRowBackgroundColors @accessors(property=alternatingRowBackgroundColors);

	int 					_gridStyleMask @accessors(property=gridStyleMask);
	CPColor 				_gridColor @accessors(property=gridColor);

	int 					_lastSelectedRow;
	int 					_clickedColumn @accessors(getter=clickedColumn);
	int 					_clickedRow @accessors(getter=clickedRow);
	int 					_editedColumn @accessors(getter=editedColumn);
	int 					_editedRow @accessors(getter=editedRow);
	double 					_rowHeight ; 

	CPIndexSet 				_selectedColumnIndexes;
	CPIndexSet 				_selectedRowIndexes; 
	CPIndexSet 				_exposedRows;
	CPIndexSet 				_exposedColumns;

	CGRect 					_exposedRect; 

	CPArray 				_tableColumnRanges;
	int 					_dirtyTableColumnRangeIndex;
	int 					_numberOfHiddenColumns; 

	CPArray 				_sortDescriptors @accessors(getter=sortDescriptors); 

	CPString 				_emptyText @accessors(property=emptyText);

	id 						_dataSource @accessors(property=dataSource);
	id 						_delegate @accessors(getter=delegate); 


	BOOL 					_autoresizeColumns @accessors(property=autoresizeColumns); 
	int 					_firstUserColumn @accessors(property=firstUserColumn); 
	CPArray 				_tableColumns @accessors(getter=tableColumns); 
	CGSize 					_intercellSpacing;

	CPTableColumn 			_currentHighlightedTableColumn; 


	BOOL 					_reloadAllRows; 
	JSObject 				_cachedDataViews;
	JSObject				_dataViewsForTableColumns; 
	JSObject 				_objectValues; 
	CPArray 				_cachedRowHeights;
	CPArray 				_draggingViews; 
	id 						_draggedColumn;

	_CPTableDataBodyView 	_dataBodyView;
	_CPTableScrollView 		_scrollView; 

	CPTableHeaderView 		_headerView; 	


	/*data source & delegate selectors */	
	SEL 					_dataSourceGetDataSel; 
	SEL 					_dataSourceNumberOfRowsSel;
	SEL 					_dataSourceSetDataSel;
	SEL 					_delegateRowHeightSel;
	SEL 					_dataSourceSortDescChange; 

	SEL 					_doubleAction @accessors(property=doubleAction);


}

-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if(self)
	{
		[self _init];

	}

	return self; 
}

-(void) _init 
{
	_alternatingRowBackgroundColors = [[CPColor whiteColor], [CPColor colorWithHexString:@"F5F9FC"]];
	_gridColor = [CPColor colorWithHexString:@"dce0e2"];

	_delegate = nil;
	_dataSource = nil; 
	_firstUserColumn = 0; 
	_allowsEmptySelection = YES;
	_allowsMultipleSelection = NO;
	_allowsColumnResizing = YES;
	_allowsColumnReordering = YES; 
	_autoresizeColumns = NO; 
	_usesAlternatingRowBackgroundColors = NO; 
	_sourceList = NO;
	_hasHeader = YES;
	_gridStyleMask = CPTableViewSolidVerticalGridLineMask; 

	_doubleAction = nil; 
	_tableColumns = [];
	_intercellSpacing = CGSizeMake(2.0, 3.0);
	_currentHighlightedTableColumn = Nil; 
	
	_DOMElement.addClass("cptableview");

	_cachedDataViews = {};
	_cachedRowHeights = [];
	_dataViewsForTableColumns = {}; 
	_draggedColumn = null; 
	_draggingViews = [];
	_objectValues = {}; 
	_reloadAllRows = YES; 

	_emptyText = @"No Records."


	_lastSelectedRow = -1;
	_clickedColumn = -1;
	_clickedRow = -1; 
	_editedColumn = -1;
	_editedRow = -1; 
	_rowHeight = CPTableViewDefaultRowHeight;

	_selectedColumnIndexes = [CPIndexSet indexSet];
	_selectedRowIndexes = [CPIndexSet indexSet];
	_exposedRows = [CPIndexSet indexSet];
	_exposedColumns = [CPIndexSet indexSet];
	_exposedRect = null; 

	_tableColumnRanges = [];
	_dirtyTableColumnRangeIndex = 0;
	_numberOfHiddenColumns = 0; 

	_sortDescriptors = [];

	_dataSourceNumberOfRowsSel = @selector(numberOfRowsInTableView:);
	_dataSourceGetDataSel = @selector(tableView:objectValueForTableColumn:row:);
	_dataSourceSetDataSel = @selector(tableView:setObjectValue:forTableColumn:row:);
	_delegateRowHeightSel = @selector(tableView:heightForRow:);
	_dataSourceSortDescChange = @selector(tableView:sortDescriptorsDidChange:);


	[self setHeaderView:[[CPTableHeaderView alloc] initWithFrame:CGRectMake(0,0,_frame.size.width,CPTableViewHeaderHeight)]];

	_dataBodyView = [[_CPTableDataBodyView alloc] init];
	_dataBodyView._tableView = self; 

	_scrollView = [[_CPTableScrollView alloc] initWithFrame:CGRectMake(0, CPTableViewHeaderHeight*_hasHeader, _frame.size.width,
											_frame.size.height-CPTableViewHeaderHeight*_hasHeader)];
	[_scrollView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	[_scrollView setDocumentView:_dataBodyView];
	[_scrollView setTableView:self];

	[[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_onScrollLeft:)
											name:CPScrollLeftNotification object:_scrollView];

	[[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_onScrollTop:)
											name:CPScrollTopNotification object:_scrollView];
 

	[self addSubview:_scrollView];
}

-(void) layoutSubviews
{
	[self reloadData];
}


-(void) setDelegate:(id)aDelegate 
{
	if (_delegate === aDelegate)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    if (_delegate)
    {
        if ([_delegate respondsToSelector:@selector(tableViewColumnDidMove:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewColumnDidMoveNotification
                        object:self];

        if ([_delegate respondsToSelector:@selector(tableViewColumnDidResize:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewColumnDidResizeNotification
                        object:self];

        if ([_delegate respondsToSelector:@selector(tableViewSelectionDidChange:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewSelectionDidChangeNotification
                        object:self];

        if ([_delegate respondsToSelector:@selector(tableViewSelectionIsChanging:)])
            [defaultCenter
                removeObserver:_delegate
                          name:CPTableViewSelectionIsChangingNotification
                        object:self];
    }

    _delegate = aDelegate;

    if ([_delegate respondsToSelector:@selector(tableViewColumnDidMove:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewColumnDidMove:)
            name:CPTableViewColumnDidMoveNotification
            object:self];

    if ([_delegate respondsToSelector:@selector(tableViewColumnDidResize:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewColumnDidResize:)
            name:CPTableViewColumnDidResizeNotification
            object:self];

    if ([_delegate respondsToSelector:@selector(tableViewSelectionDidChange:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewSelectionDidChange:)
            name:CPTableViewSelectionDidChangeNotification
            object:self];

    if ([_delegate respondsToSelector:@selector(tableViewSelectionIsChanging:)])
        [defaultCenter
            addObserver:_delegate
            selector:@selector(tableViewSelectionIsChanging:)
            name:CPTableViewSelectionIsChangingNotification
            object:self];
}

-(void) setHasHeader:(BOOL)aFlag
{
	if(_hasHeader !== aFlag)
	{
		_hasHeader = aFlag; 

		[_headerView setHidden:!_hasHeader];
		[_scrollView setFrame:CGRectMake(0, CPTableViewHeaderHeight*_hasHeader, _frame.size.width,
											_frame.size.height-CPTableViewHeaderHeight*_hasHeader)];
	}
}


-(void) setHeaderView:(CPTableHeaderView)aHeaderView
{
	if(_hasHeader)
	{
		if (_headerView === aHeaderView)
		      return;
	
		if(_headerView)
		{
			[_headerView setTableView:nil];
			[_headerView removeFromSuperview]; 
		}

		_headerView = aHeaderView;

		if(_headerView)
		{
			[_headerView setTableView:self];
			[_headerView setFrameSize:CGSizeMake(_frame.size.width, _headerView._frame.size.height)];
		 	[self addSubview:_headerView]; 
		} 
	}

}

-(void) reloadData
{
	if(!_dataSource)
		throw new Error("TableView does not have a DataSource!");
	
	_reloadAllRows = YES;
	_objectValues = {};
	
	[self noteNumberOfRowsChanged];
  	[self load];
	
	[_headerView setNeedsLayout];
	[_headerView setNeedsDisplay:YES];
	
	[_scrollView setNeedsDisplay:YES];
}

 

-(void)_onScrollTop:(CPNotification)aNotification
{
	[self load];
}

-(void)_onScrollLeft:(CPNotification)aNotification
{
	var l = [_scrollView scrollLeft];
		
	[_headerView setBoundsOrigin:CGPointMake(l, CGRectGetMinY([_headerView bounds]))];
	[_headerView setNeedsDisplay:YES];


	[self load];
}


-(void) addTableColumn:(CPTableColumn)aTableColumn 
{
	[aTableColumn setTableView:self];
	[_tableColumns addObject:aTableColumn];
}

-(int) columnWithIdentifier:(CPString)anIdentifier
{
	var index = 0,
		count = _tableColumns.length;
		
	for(; index < count; index++)
	{
		if([_tableColumns[index] identifier] === anIdentifier)
			return index;
	}
	
	return CPNotFound; 
}

-(CPTableColumn) tableColumnWithIdentifier:(CPString)anIdentifier
{
	var index = [self columnWithIdentifier:anIdentifier];

	if(index === CPNotFound)
		return nil;

	return [_tableColumns objectAtIndex:index];
}

-(CPIndexSet) selectedRowIndexes
{
	return [_selectedRowIndexes copy];
}

-(void) _setSelectedRowIndexes:(CPIndexSet)rows 
{
	var previousSelectedIndexes = _selectedRowIndexes;

	_lastSelectedRow = ([rows count] > 0 ? [rows lastIndex] : -1);
	_selectedRowIndexes = [rows copy];


	[self _updateHighlightWithOldRows:previousSelectedIndexes newRows:_selectedRowIndexes];
	 
	if(![previousSelectedIndexes isEqual:_selectedRowIndexes])
		[self _noteSelectionDidChange];
}

-(void) selectRowIndexes:(CPIndexSet)rows shouldExtendSelection:(BOOL)shouldExtendSelection
{
	var newSelectedIndexes;
	if(shouldExtendSelection)
	{
		newSelectedIndexes = [_selectedRowIndexes copy];
		[newSelectedIndexes addIndexes:rows];
	}
	else
		newSelectedIndexes = [rows copy];
	
	[self _setSelectedRowIndexes:newSelectedIndexes];
	
	[_scrollView setNeedsDisplay:YES];
}

-(void)_updateHighlightWithOldRows:(CPIndexSet)oldRows newRows:(CPIndexSet)newRows
{
	var firstExposedRow = [_exposedRows firstIndex],
        exposedLength = [_exposedRows lastIndex] - firstExposedRow + 1,
        deselectRows = [],
 		selectRows = [],
        deselectRowIndexes = [oldRows copy],
        selectRowIndexes = [newRows copy];

	[deselectRowIndexes removeIndexes:selectRowIndexes];  

 	[deselectRowIndexes getIndexes:deselectRows maxCount:-1 inIndexRange:CPMakeRange(firstExposedRow, exposedLength)];
 	[selectRowIndexes getIndexes:selectRows maxCount:-1 inIndexRange:CPMakeRange(firstExposedRow, exposedLength)];  

    for (var identifier in _dataViewsForTableColumns)
    {
        var dataViewsInTableColumn = _dataViewsForTableColumns[identifier],
            count = deselectRows.length;
        while (count--)
        {   
            var view = dataViewsInTableColumn[deselectRows[count]];

            if(view != undefined)
				[view unsetThemeState:CPThemeStateSelected]; 
        }

        count = selectRows.length;
        while (count--)
        {
            var view = dataViewsInTableColumn[selectRows[count]];

            if(view != undefined)
			   [view setThemeState:CPThemeStateSelected]; 
        }
    }

    setTimeout(function(){window.getSelection().removeAllRanges();}, 1);
}

- (void)deselectRow:(int)aRow
{
    var selectedRowIndexes = [_selectedRowIndexes copy];
    [selectedRowIndexes removeIndex:aRow];
    [self selectRowIndexes:selectedRowIndexes byExtendingSelection:NO];
    [self _noteSelectionDidChange];
}

- (CPInteger)numberOfSelectedRows
{
    return [_selectedRowIndexes count];
}

-(void) load
{ 

	if(_reloadAllRows)
	{
		
		if([self numberOfRows] === 0 && !self._loading)
		{
			if(!self._emptyTextDiv)
			{
				self._emptyTextDiv = $("<div></div>").addClass("cptableview-empty-text");
				self._emptyTextDiv.text(_emptyText);

				_scrollView._DOMElement.append(self._emptyTextDiv);
			}
		
			return; 
		}

		if(self._emptyTextDiv)
		{
			self._emptyTextDiv.remove(); 
			self._emptyTextDiv = null; 

		}

		[self _unloadDataViewsInRows:_exposedRows columns:_exposedColumns];
		_exposedRows = [CPIndexSet indexSet];
		_exposedColumns = [CPIndexSet indexSet];
		_reloadAllRows = NO; 
	}
	
	var exposedRect = [_dataBodyView visibleRect];
	if(exposedRect.size.width > 0 && exposedRect.size.height > 0)
	{
		
		var	exposedRows = 	[CPIndexSet indexSetWithIndexesInRange:[self rowsInRect:exposedRect]],
			exposedColumns = [self columnIndexesInRect:exposedRect],
			obscuredRows = [_exposedRows copy],
			obscuredColumns = [_exposedColumns copy];
			
		[obscuredRows removeIndexes:exposedRows];
		[obscuredColumns removeIndexes:exposedColumns];
		
		var newlyExposedRows = [exposedRows copy],
			newlyExposedColumns = [exposedColumns copy];
 		
		[newlyExposedRows removeIndexes:_exposedRows];
		[newlyExposedColumns removeIndexes:_exposedColumns];
	 	
		var previouslyExposedRows = [exposedRows copy],
			previouslyExposedColumns = [exposedColumns copy];
			
		[previouslyExposedRows removeIndexes:newlyExposedRows];
		[previouslyExposedColumns removeIndexes:newlyExposedColumns];
		
		[self _unloadDataViewsInRows:previouslyExposedRows columns:obscuredColumns];
		[self _unloadDataViewsInRows:obscuredRows columns:previouslyExposedColumns];
		[self _unloadDataViewsInRows:obscuredRows columns:obscuredColumns];
		[self _unloadDataViewsInRows:newlyExposedRows columns:newlyExposedColumns];
		
		[self _loadDataViewsInRows:previouslyExposedRows columns:newlyExposedColumns];
	    [self _loadDataViewsInRows:newlyExposedRows columns:previouslyExposedColumns];
	
	    [self _loadDataViewsInRows:newlyExposedRows columns:newlyExposedColumns];
		
		_exposedRows = exposedRows;
		_exposedColumns = exposedColumns;
		
		for (var identifier in _cachedDataViews)
		{
	        var dataViews = _cachedDataViews[identifier],
	            count = dataViews.length;

	      while (count--)
	           [dataViews[count] removeFromSuperview];
	    }  
	}


}


-(void)_unloadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{	
	if (![rows count] || ![columns.count])
	      return;

	var rowArray = [], 
    	columnArray = [];  

    [rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];
    [columns getIndexes:columnArray maxCount:-1 inIndexRange:nil];
	
	var columnIndex = 0,
    columnsCount = columnArray.length;

	for (; columnIndex < columnsCount; ++columnIndex)
    {
		 
        var column = columnArray[columnIndex],
            tableColumn = _tableColumns[column],
            tableColumnUID = [tableColumn UID],
            rowIndex = 0,
            rowsCount = rowArray.length;

        for (; rowIndex < rowsCount; ++rowIndex)
        {
            var row = rowArray[rowIndex],
                dataViews = _dataViewsForTableColumns[tableColumnUID];

            if (!dataViews || row >= dataViews.length)
                continue;

            var dataView = dataViews[row];
			
			dataViews[row] = null; 
			
			[self _enqueueReusableDataView:dataView];
        }
	}

}

-(void)_loadDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{
	if (![rows count] || ![columns.count])
	      return;

	var rowArray = [], 
    	columnArray = []; 

    [rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];
    [columns getIndexes:columnArray maxCount:-1 inIndexRange:nil];
	 
    if (_dirtyTableColumnRangeIndex !== -1)
 		[self _recalculateTableColumnRanges]; 

    var columnIndex = 0,
        columnsCount = columnArray.length;

     for(; columnIndex < columnsCount; ++columnIndex)
     {
     	 var column = columnArray[columnIndex],
             tableColumn = _tableColumns[column];

         if ([tableColumn isHidden] || tableColumn === _draggedColumn)
            	continue;

         var tableColumnUID = [tableColumn UID];

        if (!_dataViewsForTableColumns[tableColumnUID])
            _dataViewsForTableColumns[tableColumnUID] = [];

        var rowIndex = 0,
            rowsCount = rowArray.length; 
		 
        for(; rowIndex < rowsCount; ++rowIndex)
        {	
			 
        	var row = rowArray[rowIndex],
                dataView = [self _newDataViewForRow:row inTableColumn:tableColumn];  

			[dataView setFrame:[self frameOfDataViewAtColumn:column row:row]]; 
			[self _setObjectValueForTableColumn:tableColumn atRow:row forView:dataView]; 
			
			if([_selectedRowIndexes containsIndex:row])
				[dataView setThemeState:CPThemeStateSelected]; 
			else
				[dataView unsetThemeState:CPThemeStateSelected]; 
							
            if ([dataView superview] !== self)
		  		[_dataBodyView addSubview:dataView]; 
	 
            _dataViewsForTableColumns[tableColumnUID][row] = dataView;
        }
     }
}


-(void)_layoutDataViewsInRows:(CPIndexSet)rows columns:(CPIndexSet)columns
{	
	if(CPTableViewCellEditor)
    {
        CPTableViewCellEditor.remove();
        CPTableViewCellEditor = null;
        _editedRow = -1;
        _editedColumn = -1; 
    }

   	var rowArray = [], 
    	columnArray = [];  

    [rows getIndexes:rowArray maxCount:-1 inIndexRange:nil];
    [columns getIndexes:columnArray maxCount:-1 inIndexRange:nil];

    var columnIndex = 0,
        columnsCount = columnArray.length;

    for (; columnIndex < columnsCount; ++columnIndex)
    {
        var column = columnArray[columnIndex],
            tableColumn = _tableColumns[column],
            tableColumnUID = [tableColumn UID],
            dataViewsForTableColumn = _dataViewsForTableColumns[tableColumnUID],
            rowIndex = 0,
            rowsCount = rowArray.length; 

        if (dataViewsForTableColumn)
        {
            for (; rowIndex < rowsCount; ++rowIndex)
            {
                var row = rowArray[rowIndex],
                    dataView = dataViewsForTableColumn[row]; 
				if(dataView)
					[dataView setFrame:[self frameOfDataViewAtColumn:column row:row]]; 
            }
        }
    }

}


-(void)_enqueueReusableDataView:(CPView)aDataView 
{
	if (!aDataView)
	     return;

    var identifier = aDataView.identifier;

    if (!_cachedDataViews[identifier])
        _cachedDataViews[identifier] = @[aDataView];
    else
        _cachedDataViews[identifier].push(aDataView);

}

-(void)_setObjectValueForTableColumn:(CPTableColumn)aTableColumn atRow:(int)aRow forView:(CPView)aDataView
{
	if(_dataSource && [_dataSource respondsToSelector:_dataSourceGetDataSel] 
			&& [aDataView respondsToSelector:@selector(setObjectValue:)])
	{	
		var value = [self _objectValueForTableColumn:aTableColumn atRow:aRow];
		if(value != null)
			[aDataView setObjectValue:value];
	}
}

-(id)_objectValueForTableColumn:(CPTableColumn)aTableColumn atRow:(int)aRowIndex
{
	var tableColumnUID = [aTableColumn UID],
	    tableColumnObjectValues = _objectValues[tableColumnUID];

    if (!tableColumnObjectValues)
    {
        tableColumnObjectValues = [];
        _objectValues[tableColumnUID] = tableColumnObjectValues;
    }

    var objectValue = tableColumnObjectValues[aRowIndex];

    if (objectValue === undefined)
    {
        if (_dataSource && [_dataSource respondsToSelector:_dataSourceGetDataSel])
        {	
			objectValue = [_dataSource performSelector:_dataSourceGetDataSel withObjects:self, aTableColumn, aRowIndex];
		   	tableColumnObjectValues[aRowIndex] = objectValue;
        }
    }

    return objectValue;

}

-(void)_recalculateTableColumnRanges
{	
	if (_dirtyTableColumnRangeIndex < 0)
        return;

    _numberOfHiddenColumns = 0;

    var index = _dirtyTableColumnRangeIndex,
        count = _tableColumns.length,
        x = index === 0 ? 0.0 : CPMaxRange(_tableColumnRanges[index - 1]);

    for (; index < count; ++index)
    {
        var tableColumn = _tableColumns[index];

        if ([tableColumn isHidden])
        {
            _numberOfHiddenColumns += 1;
            _tableColumnRanges[index] = CPMakeRange(x, 0.0);
        }
        else
        {
            var width = [_tableColumns[index] width] + _intercellSpacing.width;
            _tableColumnRanges[index] = CPMakeRange(x, width);
            x+=width;
        }
    }

    _tableColumnRanges.length = count;
    _dirtyTableColumnRangeIndex = -1;

}

-(CGRect) frameOfDataViewAtColumn:(int)aColumn row:(int)aRow 
{
	if(_dirtyTableColumnRangeIndex !== -1) 
        [self _recalculateTableColumnRanges];

    if (aColumn > [self numberOfColumns] || aRow > [self numberOfRows])
        return CGRectMakeZero(); 

    var tableColumnRange = _tableColumnRanges[aColumn],
        rectOfRow = [self rectOfRow:aRow], 
        leftInset = FLOOR(_intercellSpacing.width/2.0),
        topInset = FLOOR(_intercellSpacing.height/2.0);
		
    return CGRectMake(tableColumnRange.location + leftInset, CGRectGetMinY(rectOfRow) + topInset, 
    				  tableColumnRange.length - _intercellSpacing.width, 
    				  CGRectGetHeight(rectOfRow) - _intercellSpacing.height);

}


-(CPView) _newDataViewForRow:(int)aRow inTableColumn:(CPTableColumn)aTableColumn
{
	return [aTableColumn _newDataViewForRow:aRow];
}

-(int) numberOfColumns
{
	return _tableColumns.length; 
}

-(int) numberOfRows 
{
	if(_dataSource && [_dataSource respondsToSelector:_dataSourceNumberOfRowsSel])
		return [_dataSource performSelector:_dataSourceNumberOfRowsSel withObject:self]; 
	else
		return 0;  
}

-(CGRect) _rectOfRow:(int)aRowIndex checkRange:(BOOL)checkRange
{
	var lastIndex = [self numberOfRows] - 1;

    if (checkRange && (aRowIndex > lastIndex || aRowIndex < 0))
        return CGRectMakeZero(); 

    var y = 0; 

    if (_delegate && [_delegate respondsToSelector:_delegateRowHeightSel])
    {
        var rowToLookUp = MIN(aRowIndex, lastIndex);

        // if the row doesn't exist
        if (rowToLookUp !== -1)
        {
                y = _cachedRowHeights[rowToLookUp].heightAboveRow,
                height = _cachedRowHeights[rowToLookUp].height + _intercellSpacing.height,
                rowDelta = aRowIndex - rowToLookUp;
        }
        else
        {
            y = aRowIndex * (_rowHeight + _intercellSpacing.height);
            height = _rowHeight + _intercellSpacing.height;
        }

        // if we need the rect of a row past the last index
        if (rowDelta > 0)
        {
            y += rowDelta * (_rowHeight + _intercellSpacing.height);
            height = _rowHeight + _intercellSpacing.height;
        }
    }
    else
    {
            y = aRowIndex * (_rowHeight + _intercellSpacing.height),
            height = _rowHeight + _intercellSpacing.height;
    }

	return CGRectMake(0.0, y, CGRectGetWidth([self bounds]), height);
}


-(CGRect) rectOfRow:(int)aRowIndex
{
	return [self _rectOfRow:aRowIndex checkRange:YES];
}



-(CPRange) rowsInRect:(CGRect)aRect 
{
	if ([self numberOfRows] <= 0)
        return CPMakeRange(0, 0);

   
    var firstRow = [self rowAtPoint:aRect.origin];

    // first row has to be undershot, because if not we wouldn't be intersecting.
    if(firstRow < 0)
       firstRow = 0;

    var lastRow = [self rowAtPoint:CGPointMake(0, CGRectGetMaxY(aRect))] ;
	 
    // last row has to be overshot, because if not we wouldn't be intersecting.
    if (lastRow < 0)
        lastRow = [self numberOfRows] - 1;
	 

    return CPMakeRange(firstRow, lastRow  - firstRow + 1);

}

-(CGRect) rectOfColumn:(int)aColumnIndex 
{
	if (aColumnIndex < 0 || aColumnIndex >= _tableColumns.length)
        return CGRectMakeZero();

    var column = _tableColumns[aColumnIndex];  

    if ([column isHidden])
        return CGRectMakeZero();

    if (_dirtyTableColumnRangeIndex !== -1) 
    	[self _recalculateTableColumnRanges];

    var range = _tableColumnRanges[aColumnIndex];

    return CPMakeRect(range.location, 0.0, range.length, CGRectGetHeight([self bounds]));
}


-(CPIndexSet) columnIndexesInRect:(CGRect)aRect 
{
	var column = MAX(0, [self columnAtPoint:CGPointMake(aRect.origin.x, 0.0)]),
        lastColumn = [self columnAtPoint:CGPointMake(CGRectGetMaxX(aRect), 0.0)];

    if (lastColumn === -1)
        lastColumn = _tableColumns.length - 1;

    // Don't bother doing the expensive removal of hidden indexes if we have no hidden columns.
    if (_numberOfHiddenColumns <= 0)
    	return [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(column, lastColumn - column + 1)];

    //
    var indexSet = [CPIndexSet indexSet];

    for (; column <= lastColumn; ++column)
    {
        var tableColumn = _tableColumns[column];

        if (![tableColumn isHidden])
			[indexSet addIndex:column]; 
    }

    return indexSet;
}

-(int)columnAtPoint:(CGPoint)aPoint 
{
	var bounds = [_dataBodyView bounds];

    if (!CGRectContainsPoint(bounds, aPoint))
        return -1;
 
    if(_dirtyTableColumnRangeIndex !== -1)
 		[self _recalculateTableColumnRanges];  

    var x = aPoint.x,
        low = 0,
        high = _tableColumnRanges.length - 1;

    while (low <= high)
    {
        var middle = FLOOR(low + (high - low) / 2),
            range = _tableColumnRanges[middle];

        if (x < range.location)
            high = middle - 1;
        else if (x >= CPMaxRange(range))
            low = middle + 1;
        else
        {
            var numberOfColumns = _tableColumnRanges.length;

            while (middle < numberOfColumns && [_tableColumns[middle] isHidden])
                ++middle;

            if (middle < numberOfColumns)
                return middle;

            return -1;
        }
    }

	return -1;


}

-(int)rowAtPoint:(CGPoint)aPoint 
{	
	if (_delegate && [_delegate respondsToSelector:_delegateRowHeightSel])
    {		
    		return [_cachedRowHeights indexOfObject:aPoint 
              						  inSortedRange:nil
                    					    options:CPBinarySearchingFirstEqual
            						usingComparator:function(aPoint, rowCache){
					            		var upperBound = rowCache.heightAboveRow;
										if (aPoint.y < upperBound)
					                        return -1;

					                    if (aPoint.y > upperBound + rowCache.height + _intercellSpacing.height)
					                       return 1;

					                  return 0;
					            }]; 
    }

    var y = aPoint.y,
        row = FLOOR(y / (_rowHeight + _intercellSpacing.height));

    if (row >= [self numberOfRows])
        return -1;

    return row;

}


-(void) tile 
{
	if(_dirtyTableColumnRangeIndex !== -1)
	 	[self _recalculateTableColumnRanges]; 

    var width = _tableColumnRanges.length > 0 ? CPMaxRange([_tableColumnRanges lastObject]) : 0.0,
        superview = [self superview];

    var numRows = [self numberOfRows];

    if (!(_delegate && [_delegate respondsToSelector:_delegateRowHeightSel]))
        var height =  (_rowHeight + _intercellSpacing.height) * numRows;
    else if (numRows === 0)
        var height = 0;
    else
    {
        // if this is the fist run we need to populate the cache
        if (numRows !== _cachedRowHeights.length)
             [self noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, numRows)]];  

        var heightObject = _cachedRowHeights[_cachedRowHeights.length - 1],
            height = heightObject.heightAboveRow + heightObject.height + _intercellSpacing.height;
    }
	
	[_headerView setFrameSize:CGSizeMake(MAX(_frame.size.width, width + 20.0), CPTableViewHeaderHeight)];
   	
   	[_dataBodyView setFrameSize:CGSizeMake(width, height)]; 

}

-(void) noteHeightOfRowsWithIndexesChanged:(CPIndexSet)anIndexSet
{
	if (!(_delegate && [_delegate respondsToSelector:_delegateRowHeightSel])) 
    	return;

	// this method will update the height of those rows, but since the cached array also contains
	// the height above the row it needs to recalculate for the rows below it too
	var i = [anIndexSet firstIndex],
	    count = [self numberOfRows] - i,
	    heightAbove = (i > 0) ? _cachedRowHeights[i - 1].height + _cachedRowHeights[i - 1].heightAboveRow + _intercellSpacing.height : 0;

	for (; i < count; i++)
	{
	    // update the cache if the user told us to
	    if ([anIndexSet containsIndex:i])
	    {
	        var height = [_delegate performSelector:_delegateRowHeightSel withObjects:self, i]; 
	        _cachedRowHeights[i] = {"height":height, "heightAboveRow":heightAbove};
	        heightAbove += height + _intercellSpacing.height;
	    }
	}

}

-(void) noteNumberOfRowsChanged
{
	var oldNumberOfRows = [self numberOfRows];

    _cachedRowHeights = [];

    // this line serves two purposes
    // 1. it updates the _numberOfRows cache with the -numberOfRows call
    // 2. it updates the row height cache if needed
	[self noteHeightOfRowsWithIndexesChanged:[CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, [self numberOfRows])]]; 
	 
    // remove row indexes from the selection if they no longer exist
    var hangingSelections = oldNumberOfRows - [self numberOfRows];

    if (hangingSelections > 0)
    {
        var previousSelectionCount = [_selectedRowIndexes count]; 
		[_selectedRowIndexes removeIndexesInRange:CPMakeRange([self numberOfRows], hangingSelections)]; 

        if (![_selectedRowIndexes containsIndex:[self selectedRow]])
            _lastSelectedRow = -1;
    }
	
	[self tile];
}

-(int) selectedRow 
{
	return [_selectedRowIndexes firstIndex];
}

-(_CPColumnDragView) _createDragViewForColumn:(int)theColumnIndex 
{
	var dragView = [[_CPColumnDragView alloc] init];
	[dragView setLineColor:[CPColor grayColor]];


	var scrollViewSize = _scrollView._frame.size,
        visiRect = [_dataBodyView visibleRect], 
        tableColumn = _tableColumns[theColumnIndex],
        defaultRowHeight = CPTableViewDefaultRowHeight,
        bounds = CGRectMake(0.0, 0.0, [tableColumn width], MAX(CGRectGetHeight(_frame), CGRectGetHeight(visiRect) + defaultRowHeight)),
        columnRect = [self rectOfColumn:theColumnIndex],
        headerView = [tableColumn headerView],
        row = [_exposedRows firstIndex];

    
    while (row !== -1)
    {
        var dataView = [self _newDataViewForRow:row inTableColumn:tableColumn],
            dataViewFrame = [self frameOfDataViewAtColumn:theColumnIndex row:row];

        // Only one column is ever dragged so we just place the view at
        dataViewFrame.origin.x = 0.0;

        // Offset by table header height - scroll position
        dataViewFrame.origin.y = ( CGRectGetMinY(dataViewFrame) - CGRectGetMinY(visiRect)) + defaultRowHeight;
		[dataView setFrame:dataViewFrame]; 

        [self _setObjectValueForTableColumn:tableColumn atRow:row forView:dataView];
		[dragView addSubview:dataView]; 
		_draggingViews.push(dataView); 

        row = [_exposedRows indexGreaterThanIndex:row];

    }



    // Add a copy of the header view.
    var columnHeaderView = [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:headerView]];

    [columnHeaderView setFrameOrigin:CGPointMake(0,0)];
    columnHeaderView._DOMElement.addClass("drag");
    [dragView addSubview:columnHeaderView];

    [dragView setBackgroundColor:[CPColor whiteColor]];
    [dragView setAlphaValue:0.88];
    [dragView setFrame:bounds];

    return dragView;


}

-(void)_setDraggedColumn:(CPTableColumn)aColumn 
{
	_draggedColumn = aColumn; 
}

-(void) moveColumn:(int)fromIndex toColumn:(int)toIndex 
{

	if (fromIndex === toIndex)
        return;

    if (_dirtyTableColumnRangeIndex < 0)
        _dirtyTableColumnRangeIndex = MIN(fromIndex, toIndex);
    else
        _dirtyTableColumnRangeIndex = MIN(fromIndex, toIndex, _dirtyTableColumnRangeIndex);

    var tableColumn = _tableColumns[fromIndex];
	
	[_tableColumns removeObjectAtIndex:fromIndex];
	[_tableColumns insertObject:tableColumn atIndex:toIndex]; 

    _reloadAllRows = YES;
    _objectValues = { };
 	
	[self load];

	[_headerView setNeedsLayout];
	[_headerView setNeedsDisplay:YES];
	
	[_scrollView setNeedsDisplay:YES];
	 

}


-(void) editColumn:(int)columnIndex row:(int)rowIndex
{
	var theColumn = _tableColumns[columnIndex];
 
    if(![theColumn isEditable])
        return; 

    if(CPTableViewCellEditor)
        CPTableViewCellEditor.blur(); 

    var columnId = [_tableColumns[columnIndex] UID],
        dataViewsForTableColumn = _dataViewsForTableColumns[columnId],
        dataView = dataViewsForTableColumn[rowIndex],
        dataFrame = [dataView frame]; 

	if([dataView isKindOfClass:[CPTextField class]])
	{
    	_editedColumn = columnIndex;
	    _editedRow = rowIndex; 

        CPTableViewCellEditor = $("<textarea></textarea>").addClass("cptableview-cell-editor");
        CPTableViewCellEditor.bind("mousedown mouseup click ", function(evt){
	 
            evt.stopPropagation();
        });

        CPTableViewCellEditor.data("tableColumn", _tableColumns[columnIndex]);
        CPTableViewCellEditor.data("row", rowIndex);

        var saveEdits = function(el)
        {   
        	if(el)
        	{
	            if(_dataSource && [_dataSource respondsToSelector:_dataSourceSetDataSel])  
	            {   
	                var row = parseInt(el.data("row"),10);
	                var tableColumn = el.data("tableColumn");
	                var current = [_dataSource performSelector:_dataSourceGetDataSel withObjects:self, tableColumn, row];
	                if(el.val() !== current)
	                	[_dataSource performSelector:_dataSourceSetDataSel withObjects:self, el.val(), tableColumn, row];
	                
	            }

	            el.remove(); 
	            CPTableViewCellEditor = null; 
	            _editedColumn = -1;
	            _editedRow = -1; 
	
				[[self window] makeFirstResponder:self];  
			}
        };

        CPTableViewCellEditor.bind("blur", function(evt){
                saveEdits(CPTableViewCellEditor);
        });

        CPTableViewCellEditor.bind("keydown", function(evt){

        		if(evt.which !== CPTabKeyCode)
	                evt.stopPropagation();
	            else
	            	evt.preventDefault(); 

                if(evt.which === CPReturnKeyCode)
                {
                    evt.preventDefault(); 
                    evt.stopPropagation(); 

                    saveEdits(CPTableViewCellEditor);

                }
                else if(evt.which == CPEscapeKeyCode)
                {
                    CPTableViewCellEditor.remove(); 
                    CPTableViewCellEditor = null;
                    _editedColumn = -1;
                    _editedRow = -1; 
                     
                }

                [[self window] makeFirstResponder:_dataBodyView]; 
        });

        CPTableViewCellEditor.css({
            width : dataFrame.size.width - 3,
            height : dataFrame.size.height -3,
            font : [dataView font] ? [[dataView font] cssString] : "12px Arial,sans-serif"
        });

        CPTableViewCellEditor.html([dataView stringValue]);

        dataView._DOMElement.append(CPTableViewCellEditor);
        window.getSelection().removeAllRanges();
        setTimeout(function(){
        	 if(CPTableViewCellEditor)
        	 {
              	var v = CPTableViewCellEditor.val();
              	CPTableViewCellEditor.focus().val("").val(v);
             }
        }, 5);
	}


}

-(void) showLoading:(BOOL)state  
{
	if(state)
	{
		if(!self._loading)
		{
			self._loading = $("<div></div>").addClass("cptableview-loading");
			self._loadingDelayTimer = setTimeout(function(){
				_scrollView._DOMElement.append(self._loading);
			}, 500); 
		} 
	}
	else
	{	
		if(self._loadingDelayTimer)
			clearTimeout(self._loadingDelayTimer); 

		if(self._loading)
			self._loading.remove();

		self._loading = null;

		[self reloadData]; 
	}
}

-(void) setFrameSize:(CGSize)aSize 
{
	[self load];
	[self tile];

	[super setFrameSize:aSize];
}


-(void) resizeSubviewsWithOldSize:(CGSize)aSize 
{
	[super resizeSubviewsWithOldSize:aSize];


	if(self._sizeToFitTimer)
	{
			clearTimeout(self._sizeToFitTimer);
			self._sizeToFitTimer = null; 
	}
		
	if(_autoresizeColumns)
	{ 
		[_scrollView setHasHorizontalScroller:NO]; 
		
		self._sizeToFitTimer = setTimeout(function(){
		  	[self sizeToFit];
			//[_scrollView setHasHorizontalScroller:YES];
		}, 100);
	} 


}


-(void) sizeToFit 
{
	if (_dirtyTableColumnRangeIndex !== -1)
 		[self _recalculateTableColumnRanges]; 

    var count = _tableColumns.length,
        buffer = _scrollView._frame.size.width ; 
		
	if(!self._visColumns)	
	{		
		 	self._visColumns = []; 
		
   	 		for (var i = 0; i < count; i++)
		    {
		        var tableColumn = _tableColumns[i];
		        if (![tableColumn isHidden])
					self._visColumns.push(i); 	 
		    }
	}

    // redefine count
    count = self._visColumns.length;
	buffer = buffer - 2*count - 16; 

    //if there are columns
    if (count > 0)
    {
		var w = 0;
        for (var i = 0; i < count; i++)
        {	
			w = buffer/(count - i);
            var column = self._visColumns[i],
                columnToResize = _tableColumns[column];

			if([columnToResize isResizable])
			{
            	columnToResize._width = MIN(MAX(w, columnToResize._minWidth), columnToResize._maxWidth);

				var dirtyTableColumnRangeIndex = _dirtyTableColumnRangeIndex;

				if(dirtyTableColumnRangeIndex < 0)
					_dirtyTableColumnRangeIndex = column;
				else
					_dirtyTableColumnRangeIndex = MIN(column,_dirtyTableColumnRangeIndex);

			}

			buffer-=columnToResize._width;

			if(buffer <= 0)
				break;

        }

		var rows = _exposedRows,
			columns = [CPIndexSet indexSetWithIndexesInRange:CPMakeRange(0, _tableColumns.length)];  

		[self _layoutDataViewsInRows:rows columns:columns];
		[self load]; 
		[self tile]; 
		
		[_headerView setNeedsLayout];
		[_headerView setNeedsDisplay:YES];
		[_scrollView setNeedsDisplay:YES];
		
		 
    }

}

-(CPTableColumn)_tableColumnForSortDescriptor:(CPSortDescriptor)theSortDescriptor
{

		var count = _tableColumns.length,
			index = 0; 

	    for (; index < count; index++)
	    {
	        var tableColumn = _tableColumns[index],
	            sortDescriptorPrototype = [tableColumn sortDescriptorPrototype]; 

	        if (!sortDescriptorPrototype)
	            continue;

	        if ([sortDescriptorPrototype key] === [theSortDescriptor key])
	         	return tableColumn;
	        
	    }

	    return nil;
}


-(void) setIndicatorClass:(CPString)aClassName inTableColumn:(CPTableColumn)aTableColumn
{

	if (aTableColumn)
	{
        var headerView = [aTableColumn headerView];
        if ([headerView respondsToSelector:@selector(setIndicatorWithClassName:)])
	 		[headerView setIndicatorWithClassName:aClassName]; 	 
    }


}


-(void) setSortDescriptors:(CPArray)sortDescriptors
{

	var oldSortDescriptors = _sortDescriptors.slice(),
        newSortDescriptors = null;

    if (sortDescriptors == null)
        newSortDescriptors = [];
    else
        newSortDescriptors = sortDescriptors.slice(); 

    if ([newSortDescriptors isEqual:oldSortDescriptors])
        return;

    _sortDescriptors = newSortDescriptors;

    var oldColumn = null,
        newColumn = null;

    if (newSortDescriptors.length > 0)
    {
        var newMainSortDescriptor = newSortDescriptors[0];
        newColumn = [self _tableColumnForSortDescriptor:newMainSortDescriptor];  
	}

    if (oldSortDescriptors.length > 0)
    {
        var oldMainSortDescriptor = oldSortDescriptors[0];
        oldColumn = [self _tableColumnForSortDescriptor:oldMainSortDescriptor];
    }

    var newClass = [newMainSortDescriptor ascending] ? "cptableview-column-asc" : "cptableview-column-desc";
	
	[self setIndicatorClass:nil inTableColumn:oldColumn];
	[self setIndicatorClass:newClass inTableColumn:newColumn]; 
	
	[self _sendDataSourceSortDescriptorsDidChange:oldSortDescriptors]; 



}

-(void)_changeSortDescriptorsForClickOnColumn:(int)column 
{
	var tableColumn = _tableColumns[column],
        newMainSortDescriptor = [tableColumn sortDescriptorPrototype] ;

	 
    if (!newMainSortDescriptor)
       return;

    var oldMainSortDescriptor = nil,
        oldSortDescriptors = _sortDescriptors,
        newSortDescriptors = [CPArray arrayWithArray:oldSortDescriptors],
        count = newSortDescriptors.length,
        index = 0,
        descriptor = null,
        outdatedDescriptors = [];

    if (_sortDescriptors.length > 0)
        oldMainSortDescriptor = _sortDescriptors[0];

    // Remove every main descriptor equivalents (normally only one)
    for (; index < count; index++)
    {   
        descriptor = newSortDescriptors[index];
        if ([descriptor key] === [newMainSortDescriptor key])
            outdatedDescriptors.push(descriptor);
    }

	if(oldMainSortDescriptor) 
	{    
		// Invert the sort direction when the same column header is clicked twice
    	if ([newMainSortDescriptor key] === [oldMainSortDescriptor key])
        	newMainSortDescriptor = [oldMainSortDescriptor reversedSortDescriptor];
	}
		
	[newSortDescriptors removeObjectsInArray:outdatedDescriptors];
	[newSortDescriptors insertObject:newMainSortDescriptor atIndex:0]; 

	[self setSortDescriptors:newSortDescriptors]; 

}


-(void)_sendDataSourceSortDescriptorsDidChange:(CPArray)oldDescriptors 
{
	if(_dataSource && [_dataSource respondsToSelector:_dataSourceSortDescChange])
		[_dataSource performSelector:_dataSourceSortDescChange withObject:oldDescriptors];
}

- (void)_noteSelectionIsChanging
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionIsChangingNotification
                      object:self
                    userInfo:nil];
}

- (void)_noteSelectionDidChange
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPTableViewSelectionDidChangeNotification
                      object:self
                    userInfo:nil];
}


@end

 

var CPTableViewAllowsColumnReorderingKey 				= @"CPTableViewAllowsColumnReorderingKey",
	CPTableViewAllowsColumnResizingKey					= @"CPTableViewAllowsColumnResizingKey",
	CPTableViewAllowsMultipleSelectionKey				= @"CPTableViewAllowsMultipleSelectionKey",
	CPTableViewAllowsEmptySelectionKey					= @"CPTableViewAllowsEmptySelectionKey",
	CPTableViewUsesAlternatingRowBackgroundColorsKey	= @"CPTableViewUsesAlternatingRowBackgroundColorsKey",
	CPTableViewSourceListKey							= @"CPTableViewSourceListKey",
	CPTableViewHasHeaderKey								= @"CPTableViewHasHeaderKey",
	CPTableViewAlternatingRowBackgroundColorsKey 		= @"CPTableViewAlternatingRowBackgroundColorsKey",
	CPTableViewGridStyleMaskKey							= @"CPTableViewGridStyleMaskKey",
	CPTableViewGridColorKey								= @"CPTableViewGridColorKey",
	CPTableViewDataSourceKey							= @"CPTableViewDataSourceKey",
	CPTableViewDelegateKey								= @"CPTableViewDelegateKey",
	CPTableViewFirstUserColumnKey						= @"CPTableViewFirstUserColumnKey",
	CPTableViewTableColumnsKey 							= @"CPTableViewTableColumnsKey",
	CPTableViewDoubleActionKey 							= @"CPTableViewDoubleActionKey",
	CPTableViewEmptyTextKey								= @"CPTableViewEmptyTextKey";


@implementation CPTableView (CPCoding)


-(id) initWithCoder:(CPCoder)aCoder 
{
	self = [super initWithCoder:aCoder];

	if( self )
	{
		[self _init];

		_allowsColumnReordering = [aCoder decodeBoolForKey:CPTableViewAllowsColumnReorderingKey];
		_allowsColumnResizing = [aCoder decodeBoolForKey:CPTableViewAllowsColumnResizingKey];
		_allowsMultipleSelection = [aCoder decodeBoolForKey:CPTableViewAllowsMultipleSelectionKey];
		_allowsEmptySelection = [aCoder decodeBoolForKey:CPTableViewAllowsEmptySelectionKey];
		_usesAlternatingRowBackgroundColors = [aCoder decodeBoolForKey:CPTableViewUsesAlternatingRowBackgroundColorsKey];

		_sourceList = [aCoder decodeBoolForKey:CPTableViewSourceListKey];
		_hasHeader = [aCoder decodeBoolForKey:CPTableViewHasHeaderKey];

		_alternatingRowBackgroundColors = [aCoder decodeObjectForKey:CPTableViewAlternatingRowBackgroundColorsKey];
		_gridStyleMask = [aCoder decodeIntForKey:CPTableViewGridStyleMaskKey];
		_gridColor = [aCoder decodeObjectForKey:CPTableViewGridColorKey];

		_delegate = [aCoder decodeObjectForKey:CPTableViewDelegateKey];
		_dataSource = [aCoder decodeObjectForKey:CPTableViewDataSourceKey];

		_firstUserColumn = [aCoder decodeIntForKey:CPTableViewFirstUserColumnKey];
		_doubleAction = [aCoder decodeObjectForKey:CPTableViewDoubleActionKey];

		_tableColumns = [aCoder decodeObjectForKey:CPTableViewTableColumnsKey];
		_emptyText = [aCoder decodeObjectForKey:CPTableViewEmptyTextKey];

	}

	return self; 

}


-(void) encodeWithCoder:(CPCoder)aCoder 
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeBool:_allowsColumnReordering forKey:CPTableViewAllowsColumnReorderingKey];
	[aCoder encodeBool:_allowsColumnResizing forKey:CPTableViewAllowsColumnResizingKey];
	[aCoder encodeBool:_allowsMultipleSelection forKey:CPTableViewAllowsMultipleSelectionKey];
	[aCoder encodeBool:_allowsEmptySelection forKey:CPTableViewAllowsEmptySelectionKey];
	[aCoder encodeBool:_usesAlternatingRowBackgroundColors forKey:CPTableViewUsesAlternatingRowBackgroundColorsKey];
	[aCoder encodeBool:_hasHeader forKey:CPTableViewHasHeaderKey];
	
	[aCoder encodeObject:_alternatingRowBackgroundColors forKey:CPTableViewAlternatingRowBackgroundColorsKey];
	[aCoder encodeInt:_gridStyleMask forKey:CPTableViewGridStyleMaskKey];
	[aCoder encodeObject:_gridColor forKey:CPTableViewGridColorKey];
	
	[aCoder encodeConditionalObject:_dataSource forKey:CPTableViewDataSourceKey];
	[aCoder encodeConditionalObject:_delegate forKey:CPTableViewDelegateKey];

	[aCoder encodeInt:_firstUserColumn forKey:CPTableViewFirstUserColumnKey];
	[aCoder encodeObject:_tableColumns forKey:CPTableViewTableColumnsKey];
	[aCoder encodeObject:_doubleAction forKey:CPTableViewDoubleActionKey];
	[aCoder encodeObject:_emptyText forKey:CPTableViewEmptyTextKey];

}


@end