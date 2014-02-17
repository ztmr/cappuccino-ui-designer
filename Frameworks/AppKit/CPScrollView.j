@import "CPView.j"
@import "CPScroller.j"

var CPScrollLeftNotification 		= @"CPScrollLeftNotification",
	CPScrollTopNotification			= @"CPScrollTopNotification";



@implementation CPScrollView : CPView
{
		CPView 					_documentView; 
		CPView 					_clipView; 


		CPScroller 				_verticalScroller; 
		CPScroller				_horizontalScroller; 


		BOOL					_hasVerticalScroller;
		BOOL 					_hasHorizontalScroller; 


		BOOL					_horizontalBars;
		BOOL 					_verticalBars;
		BOOL					_mousewheelXStart;
		BOOL 					_mousewheelYStart; 

}


-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if(self)
	{
		_mousewheelYStart = NO;
		_mousewheelXStart = NO;
		_horizontalBars = NO;
		_verticalBars = NO;  
		_hasHorizontalScroller = YES;
		_hasVerticalScroller = YES; 

		[self _init];
	}

	return self; 
}

-(void) _init 
{
	_DOMElement.addClass("cpscrollview");
	
	if(!_clipView)
	{
		_clipView = [[CPView alloc] initWithFrame:[self bounds]];
		[_clipView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

		[_ephemeralSubviews addObject:_clipView];

		[self addSubview:_clipView];
	}

	var st = [self valueForThemeAttribute:@"scroller-thickness"];

	if(!_verticalScroller)
	{
		_verticalScroller = [[CPScroller alloc] initWithFrame:CGRectMake(_frame.size.width-st, 0, st, _frame.size.height)];
		[_verticalScroller setOrientation:CPScrollerVertical];
		[_verticalScroller setAutoresizingMask:CPViewMinXMargin|CPViewHeightSizable];
		[_verticalScroller setTarget:self];
		[_verticalScroller setAction:@selector(_onMoveVerticalScroller:)];

		[_verticalScroller setHidden:YES];

		[_ephemeralSubviews addObject:_verticalScroller];

		[self addSubview:_verticalScroller];

	}


	if(!_horizontalScroller)
	{
		_horizontalScroller = [[CPScroller alloc] initWithFrame:CGRectMake(0,_frame.size.height-st,_frame.size.width,st)];
		[_horizontalScroller setOrientation:CPScrollerHorizontal];
		[_horizontalScroller setAutoresizingMask:CPViewMinYMargin|CPViewWidthSizable];
		[_horizontalScroller setTarget:self];
		[_horizontalScroller setAction:@selector(_onMoveHorizontalScroller:)];

		[_horizontalScroller setHidden:YES];

		[_ephemeralSubviews addObject:_horizontalScroller];

		[self addSubview:_horizontalScroller];
	}


	if(!_documentView)
		_documentView = [[CPView alloc] initWithFrame:[self bounds]];

	if(_documentView)
	{
		[[CPNotificationCenter defaultCenter] addObserver:self 
											  selector:@selector(_computeScrollerSizes)  
											  name:CPViewFrameDidChangeNotification 
											  object:_documentView];

		[_clipView addSubview:_documentView];
	}

	_DOMElement.append($("<div></div>").addClass("cpscrollview-bottom-right"));

	[self _computeScrollerSizes];
}


-(void) _onMoveHorizontalScroller:(id)sender
{
	var knobPos = [sender knobPosition];
	var pps = [sender pointsPerScroll];

	[self setScrollLeft:knobPos*pps];
}

-(void)_onMoveVerticalScroller:(id)sender
{
	var knobPos = [sender knobPosition];
	var pps = [sender pointsPerScroll];

	[self setScrollTop:knobPos*pps];
}


-(void) setScrollLeft:(double)leftVal
{
	var oldPos = [self scrollLeft];

	if(_documentView)
	{
		var leftVal = MAX(0, MIN(leftVal, _documentView._frame.size.width - _horizontalScroller._frame.size.width));
		[_clipView setBoundsOrigin:CGPointMake(leftVal, _clipView._bounds.origin.y)];
		[_horizontalScroller setKnobPosition:(leftVal/[_horizontalScroller pointsPerScroll])];
	}

	if(oldPos !== leftVal)
	{	
		[[CPNotificationCenter defaultCenter] postNotificationName:CPScrollLeftNotification object:self];
	  	[self setNeedsDisplay:YES]; 
	}
}

-(void) setScrollTop:(double)topVal
{
	var oldPos = [self scrollTop];

	if(_documentView)
	{	
		topVal = MAX(0, MIN(topVal, _documentView._frame.size.height - _verticalScroller._frame.size.height));
		[_clipView setBoundsOrigin:CGPointMake(_clipView._bounds.origin.x, topVal)];
		
		[_verticalScroller setKnobPosition:topVal/[_verticalScroller pointsPerScroll]];
		
	}

	if(oldPos !== topVal)
	{
		[[CPNotificationCenter defaultCenter] postNotificationName:CPScrollTopNotification object:self];
	  	[self setNeedsDisplay:YES]; 
	}
}

-(void) scrollToBottom
{
	[self setScrollTop:Number.MAX_VALUE];
}

-(void) scrollToTop 
{
	[self setScrollTop:0];
}

-(double) scrollLeft
{
	if(_clipView)
		return _clipView._bounds.origin.x; 

	return 0; 
}

-(double)scrollTop
{
	if(_clipView)
		return _clipView._bounds.origin.y; 

	return 0; 
}


-(void) setDocumentView:(CPView)aView 
{
	if(_documentView)
	{
		[[CPNotificationCenter defaultCenter] removeObserver:self name:CPViewFrameDidChangeNotification object:_documentView];
		[_documentView removeFromSuperview];
	}	


	 _documentView = aView;

	 if(_documentView)
	{
		[[CPNotificationCenter defaultCenter] addObserver:self 
											  selector:@selector(_computeScrollerSizes)  
											  name:CPViewFrameDidChangeNotification 
											  object:_documentView];

		[_clipView addSubview:_documentView];
	}
 	
 	[self _computeScrollerSizes];

}

-(void) mouseDown:(CPEvent)theEvent
{
	[[self window] makeFirstResponder:self];
	[super mouseDown:theEvent];
}

-(void) keyUp:(CPEvent)theEvent
{
	var kc =  [theEvent keyCode];

	if(kc === CPUpArrowKeyCode && _verticalBars)
 		[self setScrollTop:MAX(0, [self scrollTop] - 10.0)];
	else if(kc === CPDownArrowKeyCode && _verticalBars)
		[self setScrollTop:[self scrollTop] + 10.0]; 
	else if(kc === CPLeftArrowKeyCode && _horizontalBars)
		[self setScrollLeft:MAX(0, [self scrollLeft] - 10.0)]; 
	else if(kc === CPRightArrowKeyCode && _horizontalBars)
		[self setScrollLeft:[self scrollLeft] + 10.0]; 
		
	[super keyUp:theEvent];

}


-(void) scrollWheel:(CPEvent)theEvent
{		

		var deltaY = [theEvent deltaY];
		var deltaX = [theEvent deltaX]; 
 	
		if(deltaY != 0)
		{
			 
			if(_mousewheelYStart &&  _verticalBars)
			{	
				var vp = [self scrollTop] - deltaY*50; 
				[self setScrollTop:vp];
			}

			_mousewheelYStart = true;
			_mousewheelXStart = false; 
		}
		else if(deltaX != 0)
		{
			if(_mousewheelXStart && _horizontalBars) 
			{
				 
				var hp = [self scrollLeft] + deltaX*10; 
				[self setScrollLeft:hp]; 
			}

			_mousewheelYStart = false;
			_mousewheelXStart = true;

		}
}

-(void) setFrameSize:(CGSize)aSize 
{
	[super setFrameSize:aSize];
	[self _computeScrollerSizes];
}

-(void) setHasHorizontalScroller:(BOOL)aFlag
{
	_hasHorizontalScroller = aFlag; 
	[_horizontalScroller setHidden:!aFlag];
}

-(void) setHasVerticalScroller:(BOOL)aFlag
{
	_hasVerticalScroller = aFlag;
	[_verticalScroller setHidden:!aFlag];
}

-(BOOL) hasVerticalScroller 
{
	return ![_verticalScroller isHidden];
}

-(BOOL) hasHorizontalScroller 
{
	return ![_horizontalScroller isHidden];
}

-(void) _computeScrollerSizes
{

	if(_documentView)
	{ 
		_horizontalBars = NO;
		_verticalBars = NO; 

		var cwidth = _documentView._frame.size.width;
		var cheight = _documentView._frame.size.height; 

		/* initial check for bars */
		_horizontalBars = (cwidth > _frame.size.width) && _hasHorizontalScroller;
		_verticalBars = (cheight > _frame.size.height) && _hasVerticalScroller;

		var scrollViewWidth = _frame.size.width - _verticalBars*14.0;	 
		var scrollViewHeight = _frame.size.height - _horizontalBars*14.0;

		/*check again, due to interdependence */
		_horizontalBars = (cwidth > scrollViewWidth) && _hasHorizontalScroller;
		_verticalBars = (cheight > scrollViewHeight) && _hasVerticalScroller;

		scrollViewWidth = _frame.size.width - _verticalBars*14.0;
 		scrollViewHeight = _frame.size.height - _horizontalBars*14.0;
		
		[_horizontalScroller setScrollLength:cwidth];
		[_verticalScroller setScrollLength:cheight]; 

		if(!_horizontalBars)
		{
			[_horizontalScroller setHidden:YES];
			[self setScrollLeft:0];
		}
		else
		{	
			var newFrame = [_horizontalScroller frame];
			newFrame.size.width = scrollViewWidth; 
			[_horizontalScroller setFrameSize:newFrame.size];	
			[_horizontalScroller setHidden:NO];

		}

		if(!_verticalBars)
		{
			[_verticalScroller setHidden:YES];
			[self setScrollTop:0];
		}
		else
		{

			var newFrame = [_verticalScroller frame];
			newFrame.size.height = scrollViewHeight;
			[_verticalScroller setFrameSize:newFrame.size];
			[_verticalScroller setHidden:NO];

		}

		[_horizontalScroller computeKnobProportion]; 
		[_verticalScroller computeKnobProportion]; 


		if(_horizontalBars && _verticalBars)
		{
			if(_DOMElement.children(".cpscrollview-bottom-right"))
			{
				_DOMElement.children(".cpscrollview-bottom-right").show(); 
			}
		}
		else
		{
			if(_DOMElement.children(".cpscrollview-bottom-right"))
			{
				_DOMElement.children(".cpscrollview-bottom-right").hide(); 
			}
		}

	}
}

-(BOOL) isRectVisible:(CGRect)aRect
{ 
	return CGRectContainsRect([_documentView visibleRect], aRect);
}

-(BOOL) isPointVisible:(CGPoint)aPoint
{
	return CGRectContainsPoint([_documentView visibleRect], aPoint);
}


@end

var CPScrollViewHasHorizontalScrollerKey 			= @"CPScrollViewHasHorizontalScrollerKey",
	CPScrollViewHasVerticalScrollerKey				= @"CPScrollViewHasVerticalScrollerKey",
	CPScrollViewDocumentViewKey						= @"CPScrollViewDocumentViewKey";

@implementation CPScrollView (CPCoding)


-(id) initWithCoder:(CPCoder)aCoder
{	
	self = [super initWithCoder:aCoder];

	if( self )
	{	
		_mousewheelYStart = NO;
		_mousewheelXStart = NO;
		_horizontalBars = NO;
		_verticalBars = NO;  
		_hasHorizontalScroller = [aCoder decodeBoolForKey:CPScrollViewHasHorizontalScrollerKey];
		_hasVerticalScroller = [aCoder decodeBoolForKey:CPScrollViewHasVerticalScrollerKey];

		[self setDocumentView:[aCoder decodeObjectForKey:CPScrollViewDocumentViewKey]];

		[self _init];

	}

	return self ; 

}

-(void) encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeBool:_hasHorizontalScroller forKey:CPScrollViewHasHorizontalScrollerKey];
	[aCoder encodeBool:_hasVerticalScroller forKey:CPScrollViewHasVerticalScrollerKey];
	[aCoder encodeObject:_documentView forKey:CPScrollViewDocumentViewKey];
}


@end