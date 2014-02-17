@import "CPControl.j"


@implementation CPProgressIndicator : CPControl
{
	BOOL						_indeterminate @accessors(getter=indeterminate);

	double						_minValue @accessors(property=minimumValue);
	double						_maxValue @accessors(property=maximumValue); 


	DOMElement 					_progressDiv;
	DOMElement					_innerDiv;

}


-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if(self )
	{
		_indeterminate = NO;
		_minValue = 0;
		_maxValue = 100; 

		[self _init];

	}

	return self;
}

-(void) _init 
{
	_progressDiv = $("<div></div>").addClass("cpprogressindicator-progress");
	_progressDiv.css("height", _frame.size.height  );

	_innerDiv = $("<div></div>").addClass("cpprogressindicator-inner");
	_innerDiv.css("height", _frame.size.height );
		
	_DOMElement.append(_innerDiv);
	_DOMElement.append(_progressDiv);
 	_DOMElement.addClass("cpprogressindicator");
}

-(BOOL)acceptsFirstResponder
{
	return NO; 
}

-(void) layoutSubviews
{
	if(_indeterminate)
	{
		_DOMElement.addClass("indeterminate");
		[self setDoubleValue:_maxValue];
	}
	else
		_DOMElement.removeClass("indeterminate");


	[self setDoubleValue:[self doubleValue]];
}


-(void) setIndeterminate:(BOOL)aFlag
{
	_indeterminate = aFlag;
	[self setNeedsLayout];
}


-(void) setObjectValue:(id)anObject
{
	var v = MIN(_maxValue, MAX(_minValue, anObject));

	[super setObjectValue:v];

	var p =  [self doubleValue]/(_maxValue - _minValue) ;
	if(_progressDiv)
		_progressDiv.css("width", ROUND(p*100.0) + "%");

	if(p === 1.0)
	{
		if(_innerDiv)
			_innerDiv.addClass("full")
		[self triggerAction];
	}
	else
	{
		if(_innerDiv)
	 		_innerDiv.removeClass("full");
 	}
}



@end


@implementation CPProgressIndicator (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];

	if(self)
	{	
		_indeterminate = [aCoder decodeBoolForKey:CPProgressIndicatorIndeterminateKey];
		_minValue = [aCoder decodeNumberForKey:CPProgressIndicatorMinValueKey];
		_maxValue = [aCoder decodeNumberForKey:CPProgressIndicatorMaxValueKey];

		[self _init];
	}

	return self; 

}

-(void) encodeWithCoder:(CPCoder)aCoder
{	
	[super encodeWithCoder:aCoder];
	[aCoder encodeBool:_indeterminate forKey:CPProgressIndicatorIndeterminateKey];
	[aCoder encodeNumber:_minValue forKey:CPProgressIndicatorMinValueKey];
	[aCoder encodeNumber:_maxValue forKey:CPProgressIndicatorMaxValueKey];

}

@end