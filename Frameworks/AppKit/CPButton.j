@import "CPControl.j"
@import "CPImageView.j"

@import "CPTextField.j"

var CPPushOnPushOffButton = 0,
	CPMomentaryPushButton = 1; 


@implementation CPButton : CPControl
{
	CPBezelStyle	_bezelStyle @accessors(getter=bezelStyle);
	CPButtonType	_buttonType @accessors(property=buttonType);
	BOOL 			_border @accessors(getter=isBordered); 
	
 	 
 	CPDictionary 		_imageStateMap;
 	CPDictionary		_titleStateMap;

	CPImageView		_imageView;  
	
	BOOL			_allowsMixedState @accessors(property=allowsMixedState);
	
	CPTextField		_titleView; 

	JSTimer			_continuousTimer;  
}
 
 
+(id) buttonWithTitle:(CPString)aTitle
{
	var b = [[CPButton alloc] initWithFrame:CGRectMakeZero()];
	[b setTitle:aTitle];
	[b sizeToFit];

	return b; 
}


-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];
	if( self )
	{
		_allowsMixedState = NO; 
		_titleStateMap = @{};  
		_imageStateMap = @{}; 
		_bezelStyle = CPRoundRectBezelStyle; 
		_imageView = Nil;  
		
		_border = YES; 
		_buttonType = CPMomentaryPushButton; 
		
		_DOMElement.addClass("cpbutton");
		
		_titleView = [CPTextField labelWithString:@""];
		
		_imageView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
	 	_imageView._DOMElement.addClass("cpbutton-image");
	 
	 	[_imageView setImageScaling:CPScaleProportionally];
	 	[self addSubview:_imageView];
	 	[_ephemeralSubviews addObject:_imageView];

		[_ephemeralSubviews addObject:_titleView];
		[self addSubview:_titleView];
 
		_titleView._text.addClass("cpbutton-title"); 
		_DOMElement.addClass("cpbutton");

	


	}
	
	return self; 
}


-(void) setBezelStyle:(CPBezelStyle)bezelStyle 
{

	_bezelStyle = bezelStyle;

	_DOMElement.removeClass("rounded");
	_DOMElement.removeClass("square");
	_DOMElement.removeClass("hud");
	_DOMElement.removeClass("textured");

	if(_bezelStyle === CPHUDBezelStyle)
	 	_DOMElement.addClass("hud");
	else if(_bezelStyle === CPRoundedBezelStyle)
	 	_DOMElement.addClass("rounded");
	else if(_bezelStyle === CPTexturedRoundedBezelStyle)
	 	_DOMElement.addClass("textured");
	else if(_bezelStyle === CPRegularSquareBezelStyle)
	 	_DOMElement.addClass("square");
	
}

-(void) setImage:(CPImage)anImage 
{
	[self setImage:anImage forState:CPControlNormalState];
}

-(void) setImage:(CPImage)anImage forState:(int)state 
{
	 [_imageStateMap setObject:[anImage copy] forKey:state];
	 [self setNeedsLayout];

}

-(void) setObjectValue:(id)value
{	
	 
	if(!value || value === "" || value === 0)
		value = CPControlNormalState;
	else if(typeof value !== "number")
	{
		value = CPControlSelectedState;
	}
	else if(value >= CPControlSelectedState)
		value = CPControlSelectedState;
	else if(value < CPControlNormalState)
	{
		if(_allowsMixedState)
			value = CPControlMixedState;
		else
			value = CPControlSelectedState; 
	}
	
	[super setObjectValue:value];

	if([_imageStateMap objectForKey:CPControlNormalState])
	 	[_imageView setImage:[_imageStateMap objectForKey:CPControlNormalState]];
	
	if([_titleStateMap objectForKey:CPControlNormalState])
		[_titleView setStringValue:[_titleStateMap objectForKey:CPControlNormalState]];
	
	switch(value)
	{
		case CPControlMixedState: 
		{
			[self unsetThemeState:@"selected"];
			[self unsetThemeState:@"highlighted"];
			[self setThemeState:@"mixed"];

			if([_imageStateMap objectForKey:CPControlMixedState])
			 	[_imageView setImage:[_imageStateMap objectForKey:CPControlMixedState]];
			
			if([_titleStateMap objectForKey:CPControlMixedState])
				[_titleView setStringValue:[_titleStateMap objectForKey:CPControlMixedState]];

		}break;
		case CPControlSelectedState:
		{	
			[self setThemeState:@"selected"];
			[self unsetThemeState:@"mixed"];

			if([_imageStateMap objectForKey:CPControlSelectedState])
	 			[_imageView setImage:[_imageStateMap objectForKey:CPControlSelectedState]];
	
			
			if([_titleStateMap objectForKey:CPControlSelectedState])
				[_titleView setStringValue:[_titleStateMap objectForKey:CPControlSelectedState]];
	

		}break;
		case CPControlNormalState:
		{	
			[self unsetThemeState:@"selected"];
			[self unsetThemeState:@"highlighted"];
			[self unsetThemeState:@"mixed"];

		}break;
		
	}
	

}

-(int) nextState
{
	if(_allowsMixedState)
	{
		var value = [self state];
		return value - ((value === -1) ? -2 : 1);
	}
	
	return 1 - [self state];
}

-(void) setNextState
{
	[self setState:[self nextState]];
}

-(void) setState:(int)aState
{
	[self setIntValue:aState];
}

-(int) state
{
	return [self intValue];
}

-(void) setTitle:(CPString)aTitle 
{
	[self setTitle:aTitle forState:CPControlNormalState];
}

-(void) setTitle:(CPString)aTitle forState:(int)state 
{
	[_titleStateMap setObject:aTitle forKey:state];
	[self setNeedsLayout];
}


-(void) setWidth:(double)awidth 
{
	[self setFrameSize:CGSizeMake(awidth, _frame.size.height)];
}

-(void)mouseDown:(CPEvent)theEvent
{	 
	if([theEvent buttonNumber] === 1 && [self isEnabled])
	{	
		////[[self window] makeFirstResponder:self];

		if(!self._conttimeout)
			self._conttimeout = 250; 

		if([self continuous])
		{	
			var fireTrigger = function()
			{
				[self triggerAction];
				self._conttimeout = MAX(50, self._conttimeout-20);
				_continuousTimer = setTimeout(fireTrigger, self._conttimeout);
			}

			_continuousTimer = setTimeout(fireTrigger, self._conttimeout);
		}
	}

	[super mouseDown:theEvent];
}


-(void) mouseClicked:(CPEvent)theEvent
{
	if(![self isEnabled]) 
		return; 
	
	[self triggerAction];
		
	if(_buttonType === CPPushOnPushOffButton)
		[self setNextState];

	[super mouseClicked:theEvent];
}

-(void) mouseUp:(CPEvent)theEvent
{
	 clearInterval(_continuousTimer);
	 _continuousTimer = null;
	 self._conttimeout = null; 
 

	[super mouseUp:theEvent];
}

-(void) keyDown:(CPEvent)theEvent
{
	if([self continuous] && [theEvent keyCode] === CPReturnKeyCode)
		[self triggerAction];

	[super keyDown:theEvent];
}

-(void) keyUp:(CPEvent)theEvent
{	 	
	if([theEvent keyCode] === CPReturnKeyCode)
	{	
		if(![self continuous])
		{
			[self triggerAction];
			if(_buttonType === CPPushOnPushOffButton)
				[self setNextState];
		}
	}

	[super keyUp:theEvent];
}

 
-(void) sizeToFit
{
	[self setState:_value];
	[_titleView setThemeAttributes:_themeAttributes];
	[_titleView sizeToFit]; 

	var txtSz = CGSizeMake(_titleView._frame.size.width+20, _titleView._frame.size.height+10); 
 
	if(_imageView)
	{	
		var imageSize = [self imageSize]; 
		var imagePosition = [self imagePosition];

		if(imagePosition === CPImageOnly)
		{
			[self setFrameSize:CGSizeMake(imageSize.width+8,imageSize.height+12)];
		}
		else if(imagePosition === CPImageLeft || imagePosition === CPImageRight)
		{	
			 [self setFrameSize:CGSizeMake(imageSize.width + txtSz.width, txtSz.height)];
		}
		else if(imagePosition === CPImageAbove || imagePosition === CPImageBelow)
		{
			 [self setFrameSize:CGSizeMake(txtSz.width, txtSz.height + imageSize.height+5)];
		}
		else
			[self setFrameSize:txtSz];

	}
	else
		[self setFrameSize:txtSz];
}

-(void) layoutSubviews
{  	 
	 
	[self setState:_value];

 	[_titleView setThemeAttributes:_themeAttributes];
	[_titleView sizeToFit]; 
  	[_titleView setCenter:[self convertPoint:[self center] fromView:_superview]];

  	var imagePosition = [self imagePosition];
  	
  	if(imagePosition == CPNoImage)
  	{
	  	[_imageView setHidden:YES];
 
	}else 
	{
		[_titleView setHidden:NO];

  		var imageSize = [self imageSize],
  			iw = imageSize.width,
  			ih = imageSize.height; 

  		if(imagePosition === CPImageOnly)
  		{
  			[_imageView setFrameSize:imageSize];
  			[_imageView setFrameOrigin:CGPointMake((_frame.size.width-iw)/2.0, (_frame.size.height-ih)/2.0 - 1)]; 
  			[_titleView setHidden:YES];

  		}
  		else if(imagePosition === CPImageBelow)
  		{
  			 
  			[_imageView setFrame:CGRectMake((_frame.size.width  - iw)/2.0, 
  										_frame.size.height - ih - 3,
  											iw, ih)];

  			[_titleView setFrameOrigin:CGPointMake(_titleView._frame.origin.x, MIN(_titleView._frame.origin.y,
  															CGRectGetMinY(_imageView._frame) - CGRectGetHeight(_titleView._frame)- 4))];
  			 
  		}
  		else if(imagePosition === CPImageAbove)
  		{
  			 
  			[_imageView setFrame:CGRectMake((_frame.size.width  - iw)/2.0, 
  										 3,
  											iw,ih)];

  			[_titleView setFrameOrigin:CGPointMake(_titleView._frame.origin.x, MAX(_titleView._frame.origin.y,
  															CGRectGetMaxY(_imageView._frame) + 4))];
  		}
  		else if(imagePosition === CPImageRight)
  		{
  			 
  			[_imageView setFrame:CGRectMake(_frame.size.width - iw - 3, 
  										(_frame.size.height - ih)/2.0,
  											iw,ih)];

  			[_titleView setFrameOrigin:CGPointMake(MIN(_titleView._frame.origin.x, 
  														CGRectGetMinX(_imageView._frame) - CGRectGetWidth(_titleView._frame)- 6), 
  														_titleView._frame.origin.y)];


  		}
  		else if(imagePosition === CPImageLeft)
  		{
  			  
  			[_imageView setFrame:CGRectMake(3, 
  										(_frame.size.height - ih)/2.0,
  											iw,ih)];
  			[_titleView setFrameOrigin:CGPointMake(MAX(_titleView._frame.origin.x, CGRectGetMaxX(_imageView._frame)+6), 
  														_titleView._frame.origin.y)];
  		} 

  		if([_imageView superview] !== self)
	  		[self addSubview:_imageView];


	  	

	}

  	 

}

-(void) setBordered:(BOOL)aFlag
{	
	_border = aFlag; 
	if(aFlag)
	{	_DOMElement.removeClass("no-border");
		[self setBorderWidth:1.0];
	}else
	{	_DOMElement.addClass("no-border");
		[self setBorderWidth:0.0];
	}
}

-(void) setThemeState:(CPString)state
{
	[super setThemeState:state];
	[_titleView setThemeState:state];

}

-(void) unsetThemeState:(CPString)state
{
	[super unsetThemeState:state];
	[_titleView unsetThemeState:state];

}
 

@end


var CPButtonTitleKey 					= @"CPButtonTitleKey",
	CPButtonBezelStyleKey 				= @"CPButtonBezelStyleKey",
	CPButtonAllowsMixedStateKey 		= @"CPButtonAllowsMixedStateKey",
	CPButtonTitleViewKey				= @"CPButtonTitleViewKey",
	CPButtonImageKey					= @"CPButtonImageKey",
	CPButtonAlternateImageKey 			= @"CPButtonAlternateImageKey",
	CPButtonImagePositionKey			= @"CPButtonImagePositionKey",
	CPButtonBorderKey					= @"CPButtonBorderKey",
	CPButtonTypeKey						= @"CPButtonTypeKey";


@implementation CPButton (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];
	if(self)
	{
		
		_allowsMixedState = [aCoder decodeBoolForKey:CPButtonAllowsMixedStateKey];
		
		_DOMElement.addClass("cpbutton");
		
		_titleView = [CPTextField labelWithString:@""];

		[_ephemeralSubviews addObject:_titleView];
		[self addSubview:_titleView];
 
		_titleView._text.addClass("cpbutton-title"); 
		_DOMElement.addClass("cpbutton"); 

		_imageView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
	 	_imageView._DOMElement.addClass("cpbutton-image");
	 
	 	[_imageView setImageScaling:CPScaleProportionally];
	 	[self addSubview:_imageView];
	 	[_ephemeralSubviews addObject:_imageView];

		[self setBezelStyle:[aCoder decodeIntForKey:CPButtonBezelStyleKey]];
 		
		_imageStateMap = [aCoder decodeObjectForKey:CPButtonImageKey];
		_imageTitleMap = [aCoder decodeObjectForKey:CPButtonTitleKey];
 
		[self setButtonType:[aCoder decodeIntForKey:CPButtonTypeKey]];
		[self setBordered:[aCoder decodeBoolForKey:CPButtonBorderKey]];


	
	}
	
	return self; 
}

-(void) encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:_imageStateMap forKey:CPButtonImageKey];
	[aCoder encodeObject:_titleStateMap forKey:CPButtonTitleKey];
	[aCoder encodeInt:_bezelStyle forKey:CPButtonBezelStyleKey];
	[aCoder encodeBool:_allowsMixedState forKey:CPButtonAllowsMixedStateKey];
	[aCoder encodeInt:_buttonType forKey:CPButtonTypeKey];
	[aCoder encodeBool:_border forKey:CPButtonBorderKey];
	
	 
	
}

@end