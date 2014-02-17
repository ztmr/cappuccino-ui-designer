@import "CPControl.j"
@import "CPDOMEventDispatcher.j"
 

@implementation _CPSliderHandle : CPObject
{
	double 					_position @accessors(property=position);
	CPSlider 				_slider;

	double					_startValue;
	BOOL					_leftMouseDown; 

	DOMElement 				_DOMElement; 
}

-(id) init
{
	self = [super init];

	if(self)
	{
		_startValue = 0.0;

		_DOMElement = $("<div></div>").addClass("cpslider-handle");
		_DOMElement.append($("<div></div>").addClass("cpslider-handle-center"));

		_DOMElement.bind({
			mouseover : function(evt)
			{	
				$(this).addClass("hovered");
			},
			mouseout : function(evt)
			{	
				$(this).removeClass("hovered");
			},
			mousedown : function(evt)
			{	
				evt.preventDefault();
				evt.stopPropagation(); 
 
				if(evt.which < 2 && [_slider isEnabled])
				{	
					_startValue = [_slider doubleValue];
					_slider._leftMouseDown = YES; 
					_leftMouseDown = YES;
				 
					[self makeActive:YES];
				}

				[CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:_slider];
				 
			}
		});
	}

	return self; 
}

-(void) makeActive:(BOOL)aFlag
{
	if(aFlag)
	{
		if(_slider._activeHandle)
			[_slider._activeHandle makeActive:NO];

		_slider._activeHandle = self; 
 
		_DOMElement.addClass("selected");
		_DOMElement.css("zIndex", 10);
		 

		[_slider setDoubleValue:[_slider valueOfHandlePosition:_position]];
	}
	else
	{
		_DOMElement.removeClass("selected");
		_DOMElement.css("zIndex", 5);
	}

}

 

 
@end

var CPCircularSlider = 0,
	CPLinearSlider = 1,
	CPRangeSlider = 2;  


@implementation CPSlider : CPControl
{
	int 					_sliderType @accessors(getter=sliderType); 
	BOOL					_vertical @accessors(getter=vertical); 

	double 					_step @accessors(property=increment);
	double 					_minValue @accessors(getter=minValue);
	double 					_maxValue @accessors(getter=maxValue); 

	_CPSliderHandle			_activeHandle; 
	CPArray					_handles;   
	BOOL					_leftMouseDown; 
	double 					_secondValue; 
	 

}

-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];

	if(self)
	{
		_sliderType = CPLinearSlider;
		_vertical = NO; 

		_step = 1.0;
		_minValue = 0.0;
		_maxValue = 100.0; 
		_secondValue = 50.0; 

		//fix mousedown quirk
		_DOMElement.mousedown(function(evt){
			 evt.stopPropagation(); 
			[CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:self];
		});
		
	}

	return self; 

}


-(void) layoutSubviews
{
	_DOMElement.empty(); 

	if([self doubleValue] < _minValue)
		[self setDoubleValue:_minValue];

	if([self doubleValue] > _maxValue)
		[self setDoubleValue:_maxValue];

	if(_sliderType === CPCircularSlider)
	{
		_DOMElement.addClass("cpcircular-slider");
		_DOMElement.removeClass("cpslider");
		
		
		_activeHandle = Nil; 
		_handles = Nil; 

		_DOMElement.append($("<div></div>").addClass("cpcircular-knob"));

		var dim = [self valueForThemeAttribute:@"circular-dim"];

		[self setFrameSize:CGSizeMake(dim,dim)];
		[self setDoubleValue:[self doubleValue]];

		[self setBorderWidth:1.0];
	}
	else
	{
		_DOMElement.removeClass("cpcircular-slider");
		_DOMElement.addClass("cpslider");

		_handles = []; 
		_activeHandle = [[_CPSliderHandle alloc] init];
		_activeHandle._slider = self; 
		_activeHandle._window = _window;
		_activeHandle._nextResponder = self; 
		[_activeHandle setPosition:[self _handleLinearPositionForValue:_value]];
		
		[self _addHandle:_activeHandle];

		if(_vertical)
		{	 
			_DOMElement.removeClass("cpslider-horizontal");
			_DOMElement.addClass("cpslider-vertical");
		}
		else
		{
			_DOMElement.removeClass("cpslider-vertical");
			_DOMElement.addClass("cpslider-horizontal");
		}

		if(_sliderType === CPRangeSlider)
		{	
			_activeHandle = [[_CPSliderHandle alloc] init];
			_activeHandle._slider = self;
			_activeHandle._window = _window;
			_activeHandle._nextResponder = self;
			[_activeHandle setPosition:[self _handleLinearPositionForValue:_secondValue]];

			[self _addHandle:_activeHandle];
			 
			 _DOMElement.prepend($("<div></div>").addClass("cpslider-range"));

			 [self setDoubleValues:[self doubleValue] second:_secondValue];
		}
		else
			[self setDoubleValue:[self doubleValue]];

		[self _positionHandle];

	}
}

-(void) stepToNearestAllowedValue:(double)dv
{
	var m = ROUND(dv/_step);

	return MIN(_maxValue, MAX(_minValue, m*_step)); 
}

-(void) mouseUp:(CPEvent)theEvent
{
	if(_leftMouseDown && ![self continuous])
		[self triggerAction];

	document.onselectstart = function(){return true;};

	_leftMouseDown = NO; 
}

-(void) mouseDragged:(CPEvent)theEvent
{
	if(_leftMouseDown)
	{
		var oldValue = [self doubleValue];
		[self calcValue:theEvent];

		if([self continuous] && oldValue !== [self doubleValue])
		{
			[self triggerAction];
		}
	}

	[super mouseDragged:theEvent];
}

-(void) mouseDown:(CPEvent)theEvent
{
	if([theEvent buttonNumber] < 2 && [self isEnabled])
	{	
		 
		[[self window] makeFirstResponder:self]; 
		
		if(!_leftMouseDown)
		{
			[self calcValue:theEvent];
			[self triggerAction];
		}

		_leftMouseDown = YES;
	}

	[super mouseDown:theEvent];
}


-(void) _addHandle:(_CPSliderHandle)aHandle
{
	[_handles addObject:aHandle];
	_DOMElement.append(aHandle._DOMElement);
}

-(BOOL) becomeFirstResponder
{
	if(![self isEnabled])
		return NO; 

	 
	if(_activeHandle)
		_activeHandle._DOMElement.addClass("selected");


	return YES; 
}

-(BOOL) resignFirstResponder
{
	if(_activeHandle)
	{
		_activeHandle._DOMElement.removeClass("selected");
		_activeHandle._DOMElement.removeClass("focus");
		_activeHandle._DOMElement.removeClass("hover");
 
	}
	
	return YES; 
}


-(void) keyDown:(CPEvent)theEvent
{
	if(![self isEnabled])
			return;
		
	var KC = [theEvent keyCode];
	
	if(_sliderType === CPCircularSlider)
	{
		if(KC === CPRightArrowKeyCode || KC === CPLeftArrowKeyCode)
		{
			var dv = [self doubleValue] + _step; 
			if(KC === CPLeftArrowKeyCode)
			 	dv = [self doubleValue] - _step; 
			
			dv = [self stepToNearestAllowedValue:dv];
			[self setDoubleValue:dv];
			[self triggerAction]; 
		}
	}
	else
	{	 
		if(_vertical)
		{
			if(KC === CPUpArrowKeyCode|| KC === CPDownArrowKeyCode)
			{

					var dv = [self doubleValue] + _step; 
					
					if(KC === CPDownArrowKeyCode)
				 		dv = [self doubleValue] - _step; 
					
					dv = [self stepToNearestAllowedValue:dv];
					[self setDoubleValue:dv];
					[self triggerAction]; 
			}
		}
		else
		{
			if(KC === CPRightArrowKeyCode || KC === CPLeftArrowKeyCode)
			{

					var dv = [self doubleValue] + _step;
					
					if(KC === CPLeftArrowKeyCode)
					 	dv = [self doubleValue] - _step;
					
					dv = [self stepToNearestAllowedValue:dv];
					[self setDoubleValue:dv];
					[self triggerAction];

			}
		}
		
	}
}

-(void) calcValue:(CPEvent)anEvent
{			
	var offset = [self convertPoint:[anEvent locationInWindow] fromView:nil];
	 
	if(_sliderType === CPCircularSlider)
	{
		
		var x = -offset.x + 14,
			y = offset.y - 14.0,
			angle = Math.atan2(y,x) - PI/2.0;
		
		var dv = [self valueOfHandlePosition:angle];  
		
		[self setDoubleValue:dv];
	}
	else
	{	
		var dv = 0; 
		if(_vertical)
			dv = [self valueOfHandlePosition:offset.y]; 
		else
			dv = [self valueOfHandlePosition:offset.x]; 
			
		[self setDoubleValue:dv]; 
	}
}

-(CPArray) doubleValues 
{
	if(_sliderType === CPRangeSlider)
	{
		if(_handles.length > 0)
		{
			var dvs = [],
				s1 =  _handles[0];
			
			dvs.push([self valueOfHandlePosition:[s1 position]]);
			
			if(_handles.length > 1)
			{
				var s2 = _handles[1];
				dvs.push([self valueOfHandlePosition:[s2 position]]);
				
			}else
			{
				dvs.push([CPNull null]);
			}
		}
	}
	
	return nil; 
}

-(void) _positionHandle
{	
 
	var p = 1 - (_maxValue - [self doubleValue]) /(_maxValue - _minValue);
	
	if(_sliderType === CPCircularSlider)
	{
		var angle = (1.0 - p) * 2.0 * PI +  PI/2.0;
		[self _positionHandleAtAngle:angle];
	}
	else
	{
		if(_activeHandle)
		{
			var pos = [self _handleLinearPositionForValue:[self doubleValue]];
			[_activeHandle setPosition:pos]; 

			if(_vertical)
			{	
				_activeHandle._DOMElement.css("top", pos );
				
				if(_DOMElement.children(".cpslider-range") && _handles.length > 1)
				{
					var top = _handles[0];
					var bottom = _handles[1];
 
					_DOMElement.children(".cpslider-range").css({
						top : [bottom position],
						bottom : [top position],
						height : ([top position] - [bottom position]),
						width : _frame.size.width
					});
				} 
			}
			else 
			{ 
				_activeHandle._DOMElement.css("left", pos );
				if(_DOMElement.children(".cpslider-range") && _handles.length > 1)
				{
					var left =  _handles[0];
					var right = _handles[1];

					_DOMElement.children(".cpslider-range").css({
						left : [left position],
						right : [right position],
						width : ([right position] - [left position]),
						height : _frame.size.height
					});
				}
			}
		 }
	   }	
}

-(void) _positionHandleAtAngle:(double)angle
{
		var shift = 10.0;
        
        var x = 10.0 * COS(angle) + shift;
        var y = 10.0 * SIN(angle) + shift;

		if(_DOMElement.children(".cpcircular-knob"))
		{	
			_DOMElement.children(".cpcircular-knob").css({
				left : x,
				top : y
			 });
			
		}
}

-(void) setDoubleValues:(double)v1 second:(double)v2
{	
	_rangeSlider = YES; 

	if(v2 < v1)
	{
		var temp = v1;
		v1 = v2;
		v2 = temp; 
	}

	[self setDoubleValue:v1]; 

	_secondValue = v2; 

	if(_handles)
	{
		if(_handles.length > 1 && _sliderType === CPRangeSlider)
		{
 			_activeHandle = _handles[1]; 
		 
			[self setDoubleValue:_secondValue];
			 
			 _activeHandle = _handles[0];
		}
	}

	[self setDoubleValue:v1]; 
	 
}

-(void) setIntValue:(id)value
{
	[self setDoubleValue:ROUND(value)];
}

-(void) setDoubleValue:(id)value 
{	
	 
	if(_activeHandle && _handles.length > 1)
	{
		if(_activeHandle === _handles[0])
		{
			if(value > [self valueOfHandlePosition:[_handles[1] position]])
			 	return;
			 
		}
		else if(_activeHandle === _handles[1])
		{	
			if(value < [self valueOfHandlePosition:[_handles[0] position]])
			 	return;
			 
		}
	}

	var dv = parseFloat("" + value); 

	dv = [self stepToNearestAllowedValue:dv];
	
	[super setObjectValue:dv];
 	 
	[self _positionHandle];
}

-(double) _handleLinearPositionForValue:(double)value
{
	var p = 1 - (_maxValue - value) /(_maxValue - _minValue);

	if(_sliderType === CPLinearSlider || _sliderType == CPRangeSlider)
	{
		 if(_vertical)
		 {
			var yshift = ROUND((1-p) * (_frame.size.height - 20 ));
			return yshift + 10; 
		 }
		 else
		 {
		 	var xshift = ROUND(p*(_frame.size.width - 20));
		 	return xshift+10; 
		 } 
	}

	return 0; 

}

-(void) valueOfHandlePosition:(double)pos 
{
	if(_sliderType === CPCircularSlider)
	{
			var p = 0.0;

			if (pos >= 0) {
			      p = pos / (2.0 *  PI);
			} else {
			    p = (2.0 * PI + pos) / (2.0 * PI);
		    }

		    var dv = p * (_maxValue - _minValue) + _minValue;
		    dv = [self stepToNearestAllowedValue:dv];

			return dv;
	}
	else
	{
		var p = 0.0;
		if(_vertical)
		{
			var h = _frame.size.height - 20 ;
			p = MAX(0.0, MIN(1.0,  (h - (pos - 10))/ h));
		}else
		{
			p = MAX(0.0, MIN(1.0, (pos - 10)/(_frame.size.width - 20)));
		}
		 
		var dv = p*(_maxValue - _minValue) + _minValue;
		dv = [self stepToNearestAllowedValue:dv];

		return dv;
	}
}

-(void) setFrameSize:(CGSize)aSize
{	
	if(_sliderType === CPCircularSlider)
	{	
		var dim = [self valueForThemeAttribute:@"circular-dim"];

		[super setFrameSize:CGSizeMake(dim,dim)];
	 }
		
	[self setDoubleValue:[self doubleValue]];
}

-(void) setMaxValue:(double)aVal
{
	_maxValue = aVal;

	if([self doubleValue] > _maxValue)
		[self setDoubleValue:_maxValue];
}

-(void)setMinValue:(double)aVal
{
	_minValue = aVal;

	if([self doubleValue] < _minValue)
		[self setDoubleValue:_minValue];
}

-(void) setSliderType:(int)sliderType
{
	_sliderType = sliderType;

	[self setNeedsLayout];
}

-(void) setVertical:(BOOL)aFlag
{
	_vertical = aFlag;

	[self setNeedsLayout];
}

@end

var CPSliderTypeKey					= @"CPSliderTypeKey",
	CPSliderVerticalKey				= @"CPSliderVerticalKey",
	CPSliderStepKey					= @"CPSliderStepKey",
	CPSliderMinValueKey				= @"CPSliderMinValueKey",
	CPSliderMaxValueKey				= @"CPSliderMaxValueKey",
	CPSliderSecondValueKey			= @"CPSliderSecondValueKey";

@implementation CPSlider (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];
	if( self )
	{	
		_sliderType = [aCoder decodeIntForKey:CPSliderTypeKey];
		_vertical = [aCoder decodeBoolForKey:CPSliderVerticalKey];
		_step = [aCoder decodeDoubleForKey:CPSliderStepKey];
		_minValue = [aCoder decodeDoubleForKey:CPSliderMinValueKey];
		_maxValue = [aCoder decodeDoubleForKey:CPSliderMaxValueKey]; 
		_secondValue = [aCoder decodeDoubleForKey:CPSliderSecondValueKey];
 
		[self setDoubleValue:_value];

		//fix mousedown quirk
		_DOMElement.mousedown(function(evt){
			 evt.stopPropagation(); 
			[CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:self];
		});
		
	}

	return self; 
}


-(void) encodeWithCoder:(aCoder)aCoder 
{
	[super encodeWithCoder:aCoder];
 
	[aCoder encodeInt:_sliderType forKey:CPSliderTypeKey];
	[aCoder encodeBool:_vertical forKey:CPSliderVerticalKey];
	[aCoder encodeDouble:_step forKey:CPSliderStepKey];
	[aCoder encodeDouble:_minValue forKey:CPSliderMinValueKey];
	[aCoder encodeDouble:_maxValue forKey:CPSliderMaxValueKey];
	[aCoder encodeDouble:_secondValue forKey:CPSliderSecondValueKey];


}

@end