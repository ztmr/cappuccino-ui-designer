@import <Foundation/CPData.j>

@import "CPControl.j"
@import "CPButton.j"

@implementation CPStepper : CPControl
{
	double 					_step @accessors(property=increment);
	double					_minValue @accessors(property=minValue); 
	double					_maxValue @accessors(property=maxValue);
	BOOL 					_valueWraps @accessors(property=valueWraps);

	CPButton				_upTickButton;
	CPButton				_downTickButton; 
	int 					_bezelStyle @accessors(getter=bezelStyle);

}

-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];
	if(self)
	{
		_step = 1.0;
		_minValue = 0.0;
		_maxValue = 100.0; 
		_valueWraps = NO; 

		_DOMElement.css("overflow", "visible"); //this is need due to border clipping
	}

	return self;
}

-(void) layoutSubviews
{	
	_DOMElement.addClass("cpstepper");

	var mid = _frame.size.height/2.0;
	

	if(!_upTickButton)
	{
		_upTickButton = [[CPButton alloc] initWithFrame:CGRectMake(0,0, _frame.size.width, mid)];
		[_upTickButton setImagePosition:CPImageOnly];
		[_upTickButton setImageSize:CGSizeMake(6,5)];
		[_upTickButton setImage:[[CPImage alloc] initWithData:[CPData dataWithBase64:[self valueForThemeAttribute:@"up-image"]]]];
		 
		[_upTickButton setContinuous:[self continuous]];
		[_upTickButton setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable];
		[_upTickButton setTarget:self];
		[_upTickButton setAction:@selector(upTick:)];
		[_upTickButton setEnabled:[self isEnabled]];
		_upTickButton._DOMElement.addClass("cpstepper-uptick");

		[_ephemeralSubviews addObject:_upTickButton];
		[self addSubview:_upTickButton]; 
	}

	if(!_downTickButton)
	{
		_downTickButton = [[CPButton alloc] initWithFrame:CGRectMake(0, mid, _frame.size.width, mid)];
		[_downTickButton setImagePosition:CPImageOnly];
		[_downTickButton setImageSize:CGSizeMake(6,5)];
		[_downTickButton setImage:[[CPImage alloc] initWithData:[CPData dataWithBase64:[self valueForThemeAttribute:@"down-image"]]]];
		 
		[_downTickButton setContinuous:[self continuous]];
		[_downTickButton setTarget:self];
		[_downTickButton setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable];
		[_downTickButton setAction:@selector(downTick:)];
		[_downTickButton setEnabled:[self isEnabled]];
		_downTickButton._DOMElement.addClass("cpstepper-downtick");

		[_ephemeralSubviews addObject:_downTickButton];
		[self addSubview:_downTickButton];
	}


	[_upTickButton setBezelStyle:_bezelStyle];
	[_downTickButton setBezelStyle:_bezelStyle];

}

-(void) setEnabled:(BOOL)aFlag
{
	[super setEnabled:aFlag];
	[_upTickButton setEnabled:aFlag];
	[_downTickButton setEnabled:aFlag];
}

-(void) setContinuous:(BOOL)aFlag
{
	[super setContinuous:aFlag];
	[_upTickButton setContinuous:aFlag];
	[_downTickButton setContinuous:aFlag];
}

-(void) setBezelStyle:(int)bezelStyle 
{
	_bezelStyle = bezelStyle; 

	[self setNeedsLayout];
}


-(void) upTick:(id)sender
{
	var value = [self doubleValue];
	value = value + _step;
	if(value <= _maxValue)
	{
		[self setDoubleValue:value];
		[self triggerAction];
	}
	else
	{
		if(_valueWraps)
		{
			[self setDoubleValue:_minValue];
			[self triggerAction];
		}
	}

}

-(void) downTick:(id)sender
{
	var value = [self doubleValue];
	value = value - _step;
 
	if(value >= _minValue)
	{
		[self setDoubleValue:value];
		[self triggerAction];
	}
	else
	{
		if(_valueWraps)
		{
			[self setDoubleValue:_maxValue];
			[self triggerAction];
		}
	}

}

@end

var CPStepperStepKey					= @"CPStepperStepKey",
	CPStepperMinValueKey				= @"CPStepperMinValueKey",
	CPStepperMaxValueKey				= @"CPStepperMaxValueKey";

@implementation CPStepper (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];
	if(self )
	{
		_step = [aCoder decodeDoubleForKey:CPStepperStepKey];
		_minValue = [aCoder decodeDoubleForKey:CPStepperMinValueKey];
		_maxValue = [aCoder decodeDoubleForKey:CPStepperMaxValueKey];

		_DOMElement.css("overflow", "visible"); //this is need due to border clipping
	}

	return self; 

}

-(void) encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeDouble:_step forKey:CPStepperStepKey];
	[aCoder encodeDouble:_minValue forKey:CPStepperMinValueKey];
	[aCoder encodeDouble:_maxValue forKey:CPStepperMaxValueKey];
}

@end