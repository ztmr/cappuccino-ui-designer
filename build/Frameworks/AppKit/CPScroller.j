@import "CPControl.j"
@import "CPDOMEventDispatcher.j"

var CPScrollerVertical = 0,
	CPScrollerHorizontal = 1; 

@implementation _CPScrollerKnob : CPObject 
{
	CPScroller    			_scroller; 
	int 					_position @accessors(getter=position);


	DOMElement 				_DOMElement; 
}


-(id) initWithScroller:(CPScroller)aScroller
{

	self = [super init];

	if(self)
	{	
		_DOMElement = $("<div></div>");
		_scroller = aScroller;

		if([_scroller orientation] === CPScrollerVertical)
		{
			_DOMElement.addClass("cpscrollview-vscrollthumb");
			_DOMElement.append($("<div></div>").addClass("cpscrollview-vthumb-top"));
		 	_DOMElement.append($("<div></div>").addClass("cpscrollview-vthumb-center"));
		 	_DOMElement.append($("<div></div>").addClass("cpscrollview-vthumb-bottom"));
		}
		else
		{
			_DOMElement.addClass("cpscrollview-hscrollthumb"); 
 	 		_DOMElement.append($("<div></div>").addClass("cpscrollview-hthumb-left"));
 			_DOMElement.append($("<div></div>").addClass("cpscrollview-hthumb-center"));
 	 		_DOMElement.append($("<div></div>").addClass("cpscrollview-hthumb-right"));
		}

		_DOMElement.bind({
			mousedown : function(evt)
			{
				if(evt.which === 1)
				{
					[self setActive:YES];

					if([_scroller orientation] === CPScrollerVertical)
					 	_scroller._mouseThumbDown = evt.pageY - _DOMElement.offset().top; 
					else
				 		_scroller._mouseThumbDown = evt.pageX - _DOMElement.offset().left; 
				}

				[CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:_scroller];
			}
		});

	}

	return self; 

}

 

-(void) setActive:(BOOL)aFlag
{
	if([_scroller orientation] === CPScrollerVertical)
	{	
		if(aFlag)
			_DOMElement.children(".cpscrollview-vthumb-center").addClass("active");
		else
			_DOMElement.children(".cpscrollview-vthumb-center").removeClass("active"); 
	}
	else
	{	
		if(aFlag)
			_DOMElement.children(".cpscrollview-hthumb-center").addClass("active");
		else
			_DOMElement.children(".cpscrollview-hthumb-center").removeClass("active");
	}
}

-(void) setPosition:(double)aPosition
{
	_position = aPosition; 

	var s = [_scroller valueForThemeAttribute:@"scroller-buttons-height"];

	if([_scroller orientation] === CPScrollerVertical)
		_DOMElement.css("top", (_position + s));
	else
		_DOMElement.css("left", (_position + s));


}


@end


@implementation CPScroller : CPControl
{
	DOMElement   			_scrollButton1;
	DOMElement 				_scrollButton2;

	JSTimer					_scrollInterval;


	int 					_mouseThumbDown;
	int  					_scrollLength; 
	double					_pointsPerScroll @accessors(getter=pointsPerScroll); 

	_CPScrollerKnob 		_knob; 


	int 					_orientation @accessors(getter=orientation); 

}


-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if(self)
	{	
		_mouseThumbDown = -1;
		_scrollLength = -1;
		_orientation = CPScrollerVertical; 

		
		_scrollButton1 = $("<div></div>");
		_scrollButton2 = $("<div></div>");
		_scrollInterval = null;

	}

	return self; 
}

 

-(void) setOrientation:(int)orientation
{	

	_orientation = orientation

	_DOMElement.empty();

	if(_orientation === CPScrollerVertical)
	{
		_DOMElement.removeClass("cpscrollview-hscrollarea");
		_DOMElement.addClass("cpscrollview-vscrollarea");
		_scrollButton1.removeClass("cpscrollview-hscrollleft");
		_scrollButton1.addClass("cpscrollview-vscrollup");
		_scrollButton2.removeClass("cpscrollview-hscrollright");
		_scrollButton2.addClass("cpscrollview-vscrolldown");

		_DOMElement.css({
		 	"tabindex" : "1",
		 	"role" : "scrollbar",
		 	"aria-orientation" : "1",
		 	"aria-valuemin" : "0",
		 	"aria-valuemax" : "100",
		 	"aria-valuenow" : "0",
		 	"aria-label" : "vertical scroll bar"
 		});
	}
	else
	{
		_DOMElement.removeClass("cpscrollview-vscrollarea");
		_DOMElement.addClass("cpscrollview-hscrollarea");
		_scrollButton1.addClass("cpscrollview-hscrollleft");
		_scrollButton1.removeClass("cpscrollview-vscrollup");
		_scrollButton2.addClass("cpscrollview-hscrollright");
		_scrollButton2.removeClass("cpscrollview-vscrolldown");

		_DOMElement.css({
				"role" : "scrollbar",
				"aria-orientation" : "horizontal",
				"aria-valuemin" : "0",
				"aria-valuemax" : "100",
				"aria-valuenow" : "0",
				"aria-label" : "horizontal scroll bar"
 			});
	}

	_DOMElement.append(_scrollButton1);
	_DOMElement.append(_scrollButton2); 

	
	_knob = [[_CPScrollerKnob alloc] initWithScroller:self];
	[self setKnobPosition:0];

	_DOMElement.append(_knob._DOMElement);

	[self computeKnobProportion];  
}

-(void) setScrollLength:(double)sl 
{
	_scrollLength = sl;

	[self computeKnobProportion];
}
 

-(double) knobProportion 
{
	if(_knob)
		return _knob._DOMElement.height()/_frame.size.height;

	return 0; 
}

-(void) setKnobProportion:(double)aProportion
{
	if(_knob)
	{
		if([self orientation] === CPScrollerVertical)
		{
			var h = aProportion*_frame.size.height; 
			_knob._DOMElement.css("height", h);
		}
		else
		{
			var w = aProportion*_frame.size.width;
			_knob._DOMElement.css("width", w);
		}
	}
}

-(double) knobPosition
{
	if(_knob)
		return [_knob position];

	return 0; 
}

-(void) setKnobPosition:(double)aPosition
{
	if(_knob)
	{
		var s = [self valueForThemeAttribute:@"scroller-buttons-height"];

		if([self orientation] === CPScrollerVertical)
			[_knob setPosition:MAX(0, MIN(aPosition, _frame.size.height - 2*s - _knob._DOMElement.height()))];
		else
			[_knob setPosition:MAX(0, MIN(aPosition, _frame.size.width - 2*s - _knob._DOMElement.width()))];
	}
}

-(void) computeKnobProportion
{	

	var minknobsize = [self valueForThemeAttribute:@"minimum-scroller-knob-size"],
	 	dpps = [self valueForThemeAttribute:@"default-points-per-scroll"],
	 	s = [self valueForThemeAttribute:@"scroller-buttons-height"]; 

	if([self orientation] === CPScrollerVertical)
	{
		var dy = _scrollLength - _frame.size.height;
 		var thumbHeight = MAX(minknobsize, _frame.size.height - FLOOR(dy/dpps) - 2*s);
		var proportion = thumbHeight/_frame.size.height;
		
		[self setKnobProportion:proportion]; 

		var oldPPS = _pointsPerScroll;

		_pointsPerScroll = MAX(dpps, dy/MAX(0.01, _frame.size.height - thumbHeight - 2*s));

		var vp = [_knob position]; 
		if(vp + thumbHeight > _frame.size.height - 2*s)
		{
			vp = (_frame.size.height - 2*s - thumbHeight);
		}

		[self setKnobPosition:vp]; 
	}
	else
	{

		var dx =  _scrollLength - _frame.size.width;

		var thumbWidth = MAX(minknobsize, _frame.size.width - FLOOR(dx/dpps) - 2*s);
		var proportion = thumbWidth/_frame.size.width; 
		
		[self setKnobProportion:proportion]; 
	 
		var oldPPS = _pointsPerScroll; 

		_pointsPerScroll = MAX(dpps, dx/MAX(0.01, _frame.size.width - thumbWidth - 2*s));

		var hp = [_knob position];  

		if(hp + thumbWidth > _frame.size.width - 2*s)
		{
			hp = (_frame.size.width - 2*s - thumbWidth);
			 
		}

		[self setKnobPosition:hp];
		 
	}
}


-(void) mouseDragged:(CPEvent)theEvent
{
	if(_mouseThumbDown !== -1)
	{	
		var s = [self valueForThemeAttribute:@"scroller-buttons-height"], 
 			p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		 
		if([self orientation] === CPScrollerVertical)
			[self setKnobPosition:(p.y - _mouseThumbDown - s)]; 
		else
			[self setKnobPosition:(p.x - _mouseThumbDown - s)]; 

	 	[self triggerAction];
	}
}


-(void) mouseUp:(CPEvent)theEvent
{
 	_mouseThumbDown = -1; 

	_scrollButton1.removeClass("active");
	_scrollButton2.removeClass("active");

	if(_scrollInterval)
		clearInterval(_scrollInterval);

	[_knob setActive:NO];

	[super mouseUp:theEvent];
}


-(void) mouseDown:(CPEvent)theEvent
{
	var p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
	if([theEvent buttonNumber] < 2)
	{ 
		var minknobsize = [self valueForThemeAttribute:@"minimum-scroller-knob-size"],
	 		dpps = [self valueForThemeAttribute:@"default-points-per-scroll"],
	 		h = [self valueForThemeAttribute:@"scroller-buttons-height"],
	 		w = [self valueForThemeAttribute:@"scroller-buttons-width"];

		if(_mouseThumbDown === -1)
		{
			if([self orientation] === CPScrollerVertical)
			{	
				if(CGRectContainsPoint(CPMakeRect(0,0, w,h), p))
				{
					_scrollButton1.addClass("active");
					_scrollInterval = setInterval(function(){
						var p = [self knobPosition];
						[self setKnobPosition:p-1];
						[self triggerAction]; 
						[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

					}, 30);
				}
				else if(CGRectContainsPoint(CPMakeRect(0, _frame.size.height - h, w, h), p))
				{
					_scrollButton2.addClass("active");	
					_scrollInterval = setInterval(function(){
						var p = [self knobPosition];
						[self setKnobPosition:p+1];
						[self triggerAction]; 
						[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
					}, 30);
				}
				else
				{
					[self setKnobPosition:(p.y - _knob._DOMElement.height()/2.0)]; 
				} 
			}
			else
			{	
				if(CGRectContainsPoint(CPMakeRect(0, 0, h, w), p))
				{
					_scrollButton1.addClass("active");
					_scrollInterval = setInterval(function(){
						 var p = [self knobPosition];
						[self setKnobPosition:p-1];
						[self triggerAction];  
						[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
					}, 30);
				}
				else if(CGRectContainsPoint(CPMakeRect(_frame.size.width - h, 0, h, w), p))
				{
					_scrollButton2.addClass("active");
					_scrollInterval = setInterval(function(){
					 	var p = [self knobPosition];
						[self setKnobPosition:p+1];
						[self triggerAction]; 
						[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode]; 

					}, 30);
				}
				else
				{
					[self setKnobPosition:(p.x - _knob._DOMElement.width()/2.0)]; 
				}
			}

			[self triggerAction];	
		}
	}
}


-(void) setFrameSize:(CGSize)aSize
{
	var oldSize = CGSizeCreateCopy(_frame.size);
	var oldPos = [self knobPosition]*_pointsPerScroll; 

	[super setFrameSize:aSize];

	[self computeKnobProportion];

	var newPos = oldPos/_pointsPerScroll;

	[self setKnobPosition:newPos];

	[self triggerAction]; 
}









@end