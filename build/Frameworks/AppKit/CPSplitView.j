
@import "CPView.j"
@import "CPDOMEventDispatcher.j"

#define CPSplitViewHorizontal 0
#define CPSplitViewVertical 1


@implementation _CPSplitViewDivider : CPObject
{
	int  					_orientation @accessors(getter=orientation);
	double					_thickness @accessors(getter=thickness);
	int 					_index @accessors(property=index);
	double					_position @accessors(getter=position);

	double					_minPosition @accessors(property=minPosition);
	double					_maxPosition @accessors(property=maxPosition);

	CPSplitView 			_splitView;

	BOOL 					_fixed @accessors(getter=fixed);

	DOMElement 				_DOMElement; 
}


-(id) init
{
	self = [super init];

	if(self)
	{	
		 _DOMElement = $("<div></div>").addClass("view-divider");
		 _DOMElement.attr("role", "separator");

		 _DOMElement.bind("mousedown click", function(evt){

		 	evt.stopPropagation();
		 	evt.preventDefault(); 
			
			if(!_fixed)
			{
				if(evt.which < 2 && evt.type === "mousedown")
			 	 	_splitView._selectedDivider = self; 

					
				[CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:_splitView];
			}

		 });

		 [self setThickness:9.0];
		 [self setOrientation:CPSplitViewHorizontal];
		 [self setFixed:NO];
		 [self setPosition:0];
	}

	return self; 

}

-(void) setOrientation:(int)orientation
{
	_orientation = orientation;
	_DOMElement.removeClass("horizontal");
	_DOMElement.removeClass("vertical");

	if(_orientation === CPSplitViewHorizontal)
	{
		_DOMElement.attr("aria-orientation", "horizontal");
		_DOMElement.addClass("horizontal");
	}
	else
	{
		_DOMElement.attr("aria-orientation", "vertical");
		_DOMElement.addClass("vertical");
	}

}

-(void) setFixed:(BOOL)fixed
{
	_fixed = fixed;

	if(_fixed)
		_DOMElement.addClass("fixed");
	else
		_DOMElement.removeClass("fixed");
}

-(void)setPosition:(double)pos
{
	_position = pos; 

	if(_orientation === CPSplitViewHorizontal)
	{
		_DOMElement.css({
			top : 0,
			left : _position
		});
	}
	else
	{
		_DOMElement.css({
			top : _position,
			left : 0
		});
	}
}

-(void) setThickness:(double)thickness
{
	_thickness = thickness;

	_DOMElement.removeClass("no-thick");

	if(_thickness === 0)
		_DOMElement.addClass("no-thick");

	if(_orientation === CPSplitViewHorizontal)
	{
		_DOMElement.css({
			height : "100%",
			width : _thickness
		});
	}
	else
	{
		_DOMElement.css({
			width : "100%",
			height : _thickness
		});
	}
} 



@end

@implementation CPSplitView : CPView
{
	double						_dividerThickness @accessors(property=dividerThickness);
	int 						_orientation @accessors(property=orientation); 



	JSObject					_minPositions;
	JSObject					_maxPositions;
	CPArray						_dividers;
	JSObject					_fixedDividers;

	_CPSplitViewDivider			_selectedDivider; 



}

-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];

	if( self )
	{
		_minPositions = {};
		_maxPositions = {};
		_dividers = [];
		_fixedDividers = {};
		_selectedDivider = null;
		_orientation = CPSplitViewHorizontal; 
		_dividerThickness = 9.0; 
		
		_DOMElement.addClass("cpsplitview");
	}


	return self; 
}

-(void) setMaxPosition:(double)pos forDividerAtIndex:(int)index
{
	_maxPositions[index] = pos; 

	if(index > -1 && index < _dividers.length)
	{
		[_dividers[index] setMaxPosition:pos];
	}
}

-(void) setMinPosition:(double)pos forDividerAtIndex:(int)index
{
	_minPositions[index] = pos; 

	if(index > -1 && index < _dividers.length)
	{
		[_dividers[index] setMinPosition:pos];
	}
}

-(void) fixDivider:(BOOL)aFlag atIndex:(int)index
{
	if(aFlag)
	{
		_fixedDividers[index] = 1;
	}else
	{ 
		 if(_fixedDividers.hasOwnProperty(index))
		 {
		 	delete _fixedDividers[index];
		 }
	}

	if(index > -1 && index < _dividers.length)
	{
		[_dividers[index] setFixed:aFlag];
	}

}


-(void) layoutSubviews 
{
	var count = _dividers.length,
		index = 0;

	for(; index < count; index++)
	{
		_dividers[index]._DOMElement.remove(); 
	}

	_dividers = [];

	if(_orientation === CPSplitViewHorizontal)
		[self layoutHorizontal];
	else
		[self layoutVertical];
}

-(void)_createDividerAtIndex:(int)dividerIndex withPosition:(double)startPos
{
	var minPos = -1,
		maxPos = Number.MAX_VALUE;

	if(_minPositions[dividerIndex] != undefined)
		minPos = _minPositions[dividerIndex];

	if(_maxPositions[dividerIndex] != undefined)
		maxPos = _maxPositions[dividerIndex];
		
	var divider = [[_CPSplitViewDivider alloc] init];
	[divider setMaxPosition:maxPos];
	[divider setMinPosition:minPos];
	[divider setOrientation:_orientation];
	[divider setThickness:_dividerThickness];
	[divider setFixed:_fixedDividers.hasOwnProperty(dividerIndex)]
	[divider setIndex:dividerIndex];
	[divider setPosition:startPos];
	divider._splitView = self;  
  	
 	_DOMElement.append(divider._DOMElement);
 	
 	[_dividers addObject:divider]; 

}

-(void) setFrameSize:(CGSize)aSize
{
	var size = _frame.size; 
		
	if(!aSize || CGSizeEqualToSize(size, aSize))
		return;
		
	var oldSize = CGSizeCreateCopy(_frame.size);
	
	var dx = aSize.width - oldSize.width,
		dy = aSize.height - oldSize.height;
		
	size.width = aSize.width;
	size.height = aSize.height; 
	
	_DOMElement.css({
		width : size.width,
		height : size.height
	});
	
	var count = _subviews.length;

	if(_orientation === CPSplitViewHorizontal)
	{
		var viewWidthExp = 0;

		for(var i = 0; i < count; i++)
		{
			var aView = _subviews[i];
			var mask = [aView autoresizingMask];

			if(mask & CPViewWidthSizable)
				viewWidthExp++;
		}

		var dxPerView = dx; 

		if(viewWidthExp > 0)
			dxPerView = dx/viewWidthExp; 

		for(var i = 0; i < count; i++)
		{
			var aView = _subviews[i];
			var mask = [aView autoresizingMask];
			var newFrame = [aView frame]; 

			if(mask & CPViewHeightSizable)
			{
				var dy = size.height - oldSize.height;
				newFrame.size.height+=dy;
			}

			if(mask & CPViewWidthSizable)
			{
				newFrame.size.width+=dxPerView;
			}

			[aView setFrame:newFrame];
		}
	}
	else
	{
		var viewHeightExp = 0;

		for(var i = 0; i < count; i++)
		{
			var aView = _subviews[i];
			var mask = [aView autoresizingMask];

			if(mask & CPViewHeightSizable)
				viewHeightExp++;
		}

		var dyPerView = dy;

		if(viewHeightExp > 0)
			dyPerView = dy/viewHeightExp;

		for(var i = 0; i < count; i++)
		{
			var aView = _subviews[i];
			var mask = [aView autoresizingMask];
			var newFrame = [aView frame]; 

			if(mask & CPViewWidthSizable)
			{
				var dx = size.width - oldSize.width;
				newFrame.size.width+=dx; 
			}

			if(mask & CPViewHeightSizable)
			{
				newFrame.size.height+=dyPerView;
			}

			[aView setFrame:newFrame];
		} 
	}

	[self setNeedsLayout];
}

-(void) layoutVertical
{
	var divIndex = 0,
		count = _subviews.length,
		index = 0;

	for(; index < count; index++)
	{
		var aView = _subviews[index],
			startPos = 0;

		if(index > 0)
		{
			var prevFrame = [_subviews[index - 1] frame];
			startPos = CGRectGetMaxY(prevFrame) + _dividerThickness;
		}

		if(index === count - 1)
		{
			var h = _frame.size.height - startPos;
			[aView setFrame:CGRectMake(0, startPos, _frame.size.width, h)];
		}
		else
		{
			var minPos = 0,
				maxPos = Number.MAX_VALUE;

			if(_minPositions[index] != undefined)
			{
				minPos = _minPositions[index];
			}

			if(_maxPositions[index] != undefined)
			{
				maxPos = _maxPositions[index];
			}

			var h = Math.min(maxPos, Math.max(CGRectGetHeight([aView frame]), minPos));
			[aView setFrame:CGRectMake(0, startPos, _frame.size.width, h)];	 
			[self _createDividerAtIndex:divIndex withPosition:(startPos+h)]; 
			divIndex++;
		}

		var mask = [aView autoresizingMask];
		[aView setAutoresizingMask:(mask | CPViewWidthSizable)]; 
	}
}

-(void) layoutHorizontal
{
	var divIndex = 0,
		count = _subviews.length,
		index = 0;

	for(; index < count; index++)
	{
		var aView = _subviews[index],
			startPos = 0;

		if(index > 0)
		{
			var prevFrame = [_subviews[index - 1] frame];
			startPos = CGRectGetMaxX(prevFrame) + _dividerThickness;
		}

		if(index === count - 1)
		{
			var w = _frame.size.width - startPos;
			[aView setFrame:CGRectMake(startPos,0,w,_frame.size.height)]; 

		}
		else
		{
			var minPos = 0,
				maxPos = Number.MAX_VALUE;

			if(_minPositions[index] != undefined)
			{
				minPos = _minPositions[index];
			}

			if(_maxPositions[index] != undefined)
			{
				maxPos = _maxPositions[index];
			}

			var w = Math.min(maxPos, Math.max(CGRectGetWidth([aView frame]), minPos));
			[aView setFrame:CGRectMake(startPos,0,w,_frame.size.height)];
			[self _createDividerAtIndex:divIndex withPosition:(startPos+w)]; 
			divIndex++;

		}

		var mask = [aView autoresizingMask];
		[aView setAutoresizingMask:(mask|CPViewHeightSizable)]; 

	}
}

-(double) positionOfDividerAtIndex:(int)dividerIndex
{
	if(dividerIndex > -1 && dividerIndex < _dividers.length)
	{
		return [_dividers[dividerIndex] position]; 
	}

	return -1;
}

-(void) setPosition:(double)position ofDividerAtIndex:(int)dividerIndex
{
	if(dividerIndex > -1 && dividerIndex < _dividers.length)
	{
		var divider = _dividers[dividerIndex];
		var pos = position;

		if(_orientation === CPSplitViewHorizontal)
		{	
			var leftView = _subviews[dividerIndex];
			var rightView = _subviews[dividerIndex + 1];

			var leftFrame = [leftView frame]; 
			var rightFrame = [rightView frame];

			pos = MIN(MIN([divider maxPosition], CGRectGetMaxX(rightFrame) - _dividerThickness),
							   MAX([divider minPosition], MAX(leftFrame.origin.x, pos)));

			[divider setPosition:pos]; 

			var dX = pos - CGRectGetMaxX(leftFrame);

			leftFrame.size.width = MAX(0, leftFrame.size.width + dX);
			[leftView setFrameSize:leftFrame.size]; 

			rightFrame.origin.x = MAX(0, rightFrame.origin.x + dX);
			rightFrame.size.width = MAX(0, rightFrame.size.width - dX);
			
			[rightView setFrame:rightFrame];
		}
		else
		{
			var topView = _subviews[dividerIndex];
			var bottomView = _subviews[dividerIndex + 1];
			var topFrame = [topView frame]; 
			var bottomFrame = [bottomView frame]; 

			pos = MIN(MIN([divider maxPosition], CGRectGetMaxY(bottomFrame) - _dividerThickness),
							   MAX([divider minPosition], MAX(topFrame.origin.y, pos))); 

			[divider setPosition:pos];
	 
			var dY = pos - CGRectGetMaxY(topFrame);
			topFrame.size.height = MAX(0, topFrame.size.height + dY);
			
			[topView setFrameSize:topFrame.size]; 

			bottomFrame.origin.y = MAX(0, bottomFrame.origin.y + dY)  ;
		    bottomFrame.size.height = MAX(0, bottomFrame.size.height - dY);

		    [bottomView setFrame:bottomFrame]; 

		}
	}
	
}

-(void) mouseUp:(CPEvent)theEvent
{	
	 
	_selectedDivider = Nil;
	_DOMElement.css("cursor", "inherit");

	[super mouseUp:theEvent];
}

-(void) mouseDragged:(CPEvent)theEvent
{
	[self _dragDividerWithMouseEvent:theEvent];
	[super mouseDragged:theEvent];
}

-(void) _dragDividerWithMouseEvent:(CPEvent)theEvent
{		
	 
	if(_selectedDivider)
	{	
		if(![_selectedDivider fixed])
		{	
			 
			var pospt = [self convertPoint:[theEvent locationInWindow] fromView:nil]; 
			var pos = 0; 
			
			if(_orientation === CPSplitViewHorizontal)
			{
				_DOMElement.css("cursor", "col-resize");
				pos = pospt.x - _dividerThickness; 
			}
			else
			{
				_DOMElement.css("cursor", "row-resize");
				pos = pospt.y - _dividerThickness;
			}
			
			[self setPosition:pos ofDividerAtIndex:[_selectedDivider index]]; 

		} 
	}
}

@end

var CPSplitViewDividerThicknessKey			= @"CPSplitViewDividerThicknessKey",
	CPSplitViewOrientationKey				= @"CPSplitViewOrientationKey";


@implementation CPSplitView (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];

	if( self )
	{
		_minPositions = {};
		_maxPositions = {};
		_dividers = [];
		_fixedDividers = [];
		_selectedDivider = null;
		 
		_DOMElement.addClass("cpsplitview");

		[self setDividerThickness:[aCoder decodeFloatForKey:CPSplitViewDividerThicknessKey]];
		[self setOrientation:[aCoder decodeIntForKey:CPSplitViewOrientationKey]];

	}

	return self; 
}

-(void) encodeWithCoder:(CPCoder)aCoder
{	
	[super encodeWithCoder:aCoder];

	[aCoder encodeFloat:_dividerThickness forKey:CPSplitViewDividerThicknessKey];
	[aCoder encodeInt:_orientation forKey:CPSplitViewOrientationKey];

}

@end