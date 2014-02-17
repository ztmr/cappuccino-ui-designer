@import "CPControl.j"

#define CPTableViewHeaderHeight 22.0

@implementation _CPTableColumnHeaderView : CPControl
{
	CPTextField					_textField; 

	DOMElement 					_imageIndicator; 
}

-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];

	if(self)
	{
	 	_textField = [[CPTextField alloc] labelWithString:@""];
	}

	return self; 
}

-(void) setObjectValue:(id)value 
{
	[super setObjectValue:value];

	[_textField setStringValue:value];
}



-(void) layoutSubviews
{	

	[self setFont:[CPFont systemFontOfSize:12.0]];

	_DOMElement.addClass("cptablecolumnheaderview");

	if(!_textField)
		_textField = _subviews[0];

 	[_textField setThemeAttributes:_themeAttributes];
	[_textField sizeToFit];

	[_textField setFrame:CGRectMake(4, (CPTableViewHeaderHeight-CGRectGetHeight([_textField frame]))/2.0, 
				_frame.size.width-8, CGRectGetHeight([_textField frame]))];

	if([_textField superview] !== self)
		[self addSubview:_textField];
}


-(void) setFrameSize:(CGSize)aSize 
{
	[super setFrameSize:aSize];

	[self setNeedsLayout];
}

-(void) setIndicatorWithClassName:(CPString)aClassName
{
	if(_imageIndicator)
		_imageIndicator.remove();
		
	if(aClassName)
	{
		_imageIndicator = $("<div></div>").addClass(aClassName);
		_DOMElement.append(_imageIndicator);
	}
}



@end

@implementation CPTableHeaderView : CPView 
{
	CGPoint 				_mouseDownLocation;
	CGPoint 				_previousTrackingLocation;

	int 					_activeColumn;
	int 					_pressedColumn; 

	BOOL 					_isResizing;
	BOOL 					_isDragging;
	BOOL 					_isTrackingColumn; 
	BOOL 					_drawsColumnLines; 

	double 					_columnOldWidth ;
	int 					_draggedStartXPos ;



	CPView 					_columnDragView; 

	CPTableView 			_tableView @accessors(property=tableView); 


}

-(id) initWithFrame:(CGRect)aFrame 
{
	 self = [super initWithFrame:aFrame];

	 if(self)
	 {	
	 	_mouseDownLocation = CGPointMake(0,0);
	 	_previousTrackingLocation = CGPointMake(0,0);

	 	_activeColumn = -1;
	 	_pressedColumn = -1; 

	 	_isResizing = NO;
	 	_isDragging = NO;
	 	_isTrackingColumn = NO;
	 	_drawsColumnLines = YES;


	 	_columnOldWidth = 0.0;
	 	_draggedStartXPos = -1;

	 	_columnDragView = Nil;  

	 	_DOMElement.addClass("cptableviewheader");

	 	_DOMElement.bind("dblclick", function(evt){
			
			evt.preventDefault();
			evt.stopPropagation();
			evt._window = [self window];

			[self doubleAction:[CPEvent event:evt]];	

		});

	 }


	 return self; 
}

-(void) doubleAction:(CPEvent)theEvent
{
	var currentLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	var col = [self columnAtPoint:currentLocation];
	
	[_tableView _changeSortDescriptorsForClickOnColumn:col];

}

-(void)_moveColumn:(int)aFromIndex toColumn:(int)aToIndex 
{
		[_tableView moveColumn:aFromIndex toColumn:aToIndex];
		_activeColumn = aToIndex;
		_pressedColumn = _activeColumn;


		[self setNeedsDisplay:YES];
}

-(CPTableColumn) columnAtPoint:(CGPoint)aPoint
{
	return [_tableView columnAtPoint:CGPointCreateCopy(aPoint)];

}

-(CGRect) headerRectOfColumn:(int)aColumnIndex 
{
	var headerRect = [self bounds],
		columnRect = [_tableView rectOfColumn:aColumnIndex];

	headerRect.origin.x = CGRectGetMinX(columnRect);
	headerRect.size.width = CGRectGetWidth(columnRect);

	return headerRect; 
}

-(CGRect) _cursorRectForColumn:(int)aColumnIndex
{
	if(aColumnIndex < 0)
		return CGRectMakeZero();

	var rect = [self headerRectOfColumn:aColumnIndex];
	rect.origin.x = CGRectGetMaxX(rect) - 3;
	rect.size.width = 6;

	return rect; 
}

-(void)_setPressedColumn:(int)aColumnIndex
{
	if(_pressedColumn >= 0)
	{
		var headerView = [[_tableView tableColumns][_pressedColumn] headerView];
		[headerView unsetThemeState:@"highlighted"];
	}

	if(aColumnIndex >= 0)
	{
		var headerView = [[_tableView tableColumns][aColumnIndex] headerView];
		[headerView setThemeState:@"highlighted"];

	}

	_pressedColumn = aColumnIndex;
}

-(void) mouseDown:(CPEvent)theEvent
{
	var currentLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	currentLocation.x-=5.0;
		
	var columnIndex = [self columnAtPoint:currentLocation],
		shouldResize = [self shouldResizeTableColumn:columnIndex 
												   at:CGPointMake(currentLocation.x + 5.0, currentLocation.y)];
			
		if(columnIndex < 0)
			return;
		
		_mouseDownLocation = currentLocation;
		_activeColumn = columnIndex;
		
		if(shouldResize)
			[self startResizingTableColumn:columnIndex at:currentLocation];
		else
		{
			[self startTrackingTableColumn:columnIndex at:currentLocation];
			_isTrackingColumn = YES; 
		}
		
		_previousTrackingLocation = currentLocation;
}

-(void) mouseExited:(CPEvent)theEvent
{
	if(!_isResizing)
		_DOMElement.css("cursor", "inherit");
}

-(void) mouseDragged:(CPEvent)theEvent
{
	if(_activeColumn > -1)
	{
		var currentLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		currentLocation.x-=5.0;
		
		var columnIndex = [self columnAtPoint:currentLocation],
			tableColumn = [_tableView tableColumns][columnIndex],
			shouldResize = [self shouldResizeTableColumn:columnIndex
											at:CGPointMake(currentLocation.x + 5.0, currentLocation.y)];
			
		if(shouldResize)
			[self continueResizingTableColumn:_activeColumn at:currentLocation];
		else
		{
			if(_activeColumn === columnIndex && CGRectContainsPoint([self headerRectOfColumn:columnIndex], currentLocation))
			{
				if(_isTrackingColumn && _pressedColumn >= 0)
					[self continueTrackingTableColumn:columnIndex at:currentLocation];
				else
					[self startTrackingTableColumn:columnIndex at:currentLocation];
			}
			else if(_isTrackingColumn && _pressedColumn >= 0)
			{
				[self stopTrackingTableColumn:_activeColumn at:currentLocation];
			}
		}
		
		_previousTrackingLocation = currentLocation;
		
		if(_isDragging)
		{
			var draggedRect = [self headerRectOfColumn:_activeColumn],
				viewLocation = CGPointMake(0,0);
			
			viewLocation.x= MAX(1, _draggedStartXPos + currentLocation.x - _mouseDownLocation.x) ;
            viewLocation.y = 0;

			[_columnDragView setFrameOrigin:CGPointMake(viewLocation.x - 2*CGRectGetMinX([self bounds]), 0)];
			
			var hoveredColumn = [self columnAtPoint:CGPointMake(viewLocation.x - CGRectGetMinX([self bounds]), 0)];
			if(hoveredColumn === _activeColumn)
				hoveredColumn = [self columnAtPoint:CGPointMake(viewLocation.x + draggedRect.size.width - CGRectGetMinX([self bounds]), 0)];
			
	 
			if(hoveredColumn >= 0 && hoveredColumn !== _activeColumn 
				&& [[_tableView tableColumns][hoveredColumn] isDraggable])
			{
				 var columnRect = [self headerRectOfColumn:hoveredColumn],
                     columnCenterPoint = CGPointMake(CGRectGetMidX(columnRect) - CGRectGetMinX([self bounds]), CGRectGetMidY(columnRect));

                 if ((hoveredColumn < _activeColumn && CGRectGetMinX(_columnDragView._frame) < columnCenterPoint.x) ||
                  	(hoveredColumn > _activeColumn && CGRectGetMaxX(_columnDragView._frame) > columnCenterPoint.x))
                        [self _moveColumn:_activeColumn toColumn:hoveredColumn]; 
				
			}
		   
		}
	}
}


-(void) mouseMoved:(CPEvent)theEvent
{
	 
	var currentLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		currentLocation.x-=5.0;
		var columnIndex =  [self columnAtPoint:currentLocation],
			shouldResize = [self shouldResizeTableColumn:columnIndex 
										at:CGPointMake(currentLocation.x + 5.0, currentLocation.y)];
		
		if(shouldResize)
		{
			_DOMElement.css("cursor", "col-resize");
		}else
			_DOMElement.css('cursor', "inherit");
}

-(void) mouseUp:(CPEvent)theEvent
{
	var currentLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	currentLocation.x-=5.0;
	var columnIndex =  [self columnAtPoint:currentLocation],
		shouldResize = [self shouldResizeTableColumn:columnIndex 
										at:CGPointMake(currentLocation.x + 5.0, currentLocation.y)];
		
		
	
	if(shouldResize)
		[self stopResizingTableColumn:_activeColumn at:currentLocation];
	else if([self _shouldStopTrackingTableColumn:columnIndex at:currentLocation])
	{
		[self stopTrackingTableColumn:columnIndex at:currentLocation];
		_isTrackingColumn = false; 
	}
	
	_DOMElement.css("cursor", "inherit");
	
	_isDragging = NO;
	_isTrackingColumn = NO;
	
	[_tableView _setDraggedColumn:nil]
	
	if(_columnDragView && _activeColumn >= 0)
	{
		[[[_tableView tableColumns][_activeColumn] headerView] setHidden:NO];

		[self stopTrackingTableColumn:_activeColumn at:currentLocation];
		[_columnDragView removeFromSuperview];
		_columnDragView._DOMElement.remove();
		_columnDragView = null;
		
		[_tableView reloadData];
		
		document.onselectstart = function(){return true;} //re-enable text select
	}
	
	_activeColumn = -1;
	_previousTrackingLocation = currentLocation;

}

-(BOOL) _shouldDragTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
	var theColumn = [_tableView tableColumns][aColumnIndex];
		
	return ([theColumn isDraggable] && [_tableView allowsColumnReordering] && 
			ABS(aPoint.x - _mouseDownLocation.x) > 10.0)
}


-(BOOL) shouldResizeTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
	 
	if(aColumnIndex > -1 && aColumnIndex < [[_tableView tableColumns] count])  
			if(![[_tableView tableColumns][aColumnIndex] isResizable])
				return NO;
			
	if (_isTrackingColumn)
		return NO;
		
	if (_isResizing)
		return YES;

	return [_tableView allowsColumnResizing] && 
			CGRectContainsPoint([self _cursorRectForColumn:aColumnIndex], aPoint); 
}


-(void) startResizingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
	_isResizing = YES; 
}

-(void) stopResizingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint 
{
	_isResizing = NO; 
}

-(void) continueResizingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint 
{	
	if(aColumnIndex >= 0 && aColumnIndex < [_tableView numberOfColumns])
    { 
        var tableColumn = [_tableView tableColumns][aColumnIndex], 
            columnRect = [self headerRectOfColumn:aColumnIndex],  
            newWidth = [tableColumn width] + aPoint.x - _previousTrackingLocation.x;
	 
		newWidth = MAX([tableColumn minWidth], MIN(newWidth, [tableColumn maxWidth]));	
			
        [tableColumn setWidth:newWidth];
		
		[self setNeedsLayout];
		[self setNeedsDisplay:YES];
		
		if(newWidth === [tableColumn minWidth] || newWidth === [tableColumn maxWidth])
			_isResizing = NO; 
		 
    }

}

-(void) startTrackingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint
{
	[self _setPressedColumn:aColumnIndex];
}

-(BOOL)_shouldStopTrackingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint 
{
	return 	_isTrackingColumn && _activeColumn === aColumnIndex &&
		         CGRectContainsPoint([self headerRectOfColumn:aColumnIndex], aPoint);  
}	

-(void) stopTrackingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint 
{
	[self _setPressedColumn:-1];
}

-(BOOL) continueTrackingTableColumn:(int)aColumnIndex at:(CGPoint)aPoint 
{
	if ([self _shouldDragTableColumn:aColumnIndex at:aPoint] && !_isDragging )
	{	

	   	_isDragging = YES; 

        if(!_columnDragView)
        {
			document.onselectstart = function() {return false;}  //turn of text selection temporarily
            _columnDragView = [_tableView _createDragViewForColumn:aColumnIndex]; 
			[_tableView addSubview:_columnDragView];  

            var column = [_tableView tableColumns][aColumnIndex];  
			[[column headerView] setHidden:YES]; 


			[_tableView _setDraggedColumn:column]; 

            var draggedRect = [self headerRectOfColumn:aColumnIndex];  

            viewLocation = CGPointMake(CGRectGetMinX(draggedRect) + CGRectGetMinX([self bounds]) + aPoint.x - _mouseDownLocation.x, 0); 
            _draggedStartXPos = viewLocation.x; 
			[_columnDragView setFrameOrigin:viewLocation]; 


        }
	    
		return NO;
	}
		
	return YES;
}


-(void) layoutSubviews 
{
	var tableColumns = [_tableView tableColumns],
	    count = tableColumns.length,
		index = 0; 

	    for (; index < count; index++)
	    {
	        var column = tableColumns[index],
	            headerView = [column headerView],
	            frame = [self headerRectOfColumn:index]; 

	        // Make space for the gridline on the right.
	        frame.origin.x +=1.0  ;
	        frame.size.width -= 1.0;
	        frame.size.height -=0.5;
			
			[headerView setFrame:frame]; 
			
	        if ([headerView superview] !== self)
				[self addSubview:headerView]; 
		}

}


-(void) drawRect:(CGRect)aRect 
{
	var ctx = _graphicsContext; 
	var tableColumns = [_tableView tableColumns],
	    count = tableColumns.length,
		index = 0;

	ctx.fillStyle = "#b5b5b5";
	for (; index < count; index++)
    {
		if(![tableColumns[index] nogrid])
		{
        	var colRect = [self headerRectOfColumn:index];
        	ctx.fillRect(CGRectGetMaxX(colRect) - CGRectGetMinX([self bounds]), 0, 1, colRect.size.height);
		}
	}

}

@end


