@import "CPButton.j"
@import "CPMenu.j"

var CPDisclosureBezelStyle = 10;

@implementation CPPopUpButton : CPButton
{

	BOOL					_pullsdown @accessors(getter=pullsdown); 
	CPMenu					_menu @accessors(getter=menu); 

	BOOL 					_setMenuWidth; 

}

-(id) initWithFrame:(CGRect)aFrame
{
	return [self initWithFrame:aFrame pullsdown:NO];
}

-(id) initWithFrame:(CGRect)aFrame pullsdown:(BOOL)aFlag
{

	self = [super initWithFrame:aFrame];

	if( self )
	{
		_setMenuWidth = NO; 
		var h = [self valueForThemeAttribute:@"optimal-height"];

		[self setFrameSize:CGSizeMake(aFrame.size.width, h)];

	
		_DOMElement.addClass("cppopupbutton");

		[self setBezelStyle:CPRoundRectBezelStyle];
		
		_menu = [[CPMenu alloc] init];
		_menu._delegate = self; 

		[self setPullsDown:aFlag];
	}


	return self; 
}

-(void) setPullsDown:(BOOL)aFlag
{
	_pullsdown = aFlag;

	[_menu setIsRadio:!_pullsdown];


	if(_pullsdown)
	{	 
	 	_DOMElement.addClass("pullsdown");
		[self setButtonType:CPPushOnPushOffButton];
	}
	else
	{
		 if([_menu numberOfItems] > 0)
		 	[self setTitle:[[_menu itemAtIndex:0] title]]
		 	
		 _DOMElement.removeClass("pullsdown");
		 [self setButtonType:CPMomentaryPushButton];

	 }
}


-(void) setBezelStyle:(int)bs 
{
	[super setBezelStyle:bs];

	_DOMElement.children(".cppopupbutton-buttonview").remove();
	_DOMElement.children(".cppopupbutton-trigger").remove(); 

	if(_bezelStyle !== CPDisclosureBezelStyle)
	{	
		var w = [self valueForThemeAttribute:@"trigger-width"];
		_DOMElement.append($("<div></div>").addClass("cppopupbutton-buttonview").css("width", _frame.size.width-w));
		_DOMElement.append($("<div></div>").addClass("cppopupbutton-trigger"));
	}
	 
	 
}



-(void) setFrameSize:(CGSize)aSize
{
	[super setFrameSize:aSize];
 
	_DOMElement.children(".cppopupbutton-buttonview").css("width", aSize.width-[self valueForThemeAttribute:@"trigger-width"]);

	if(_bezelStyle !== CPDisclosureBezelStyle)
		[_menu setWidth:_frame.size.width];

}

-(void) layoutSubviews
{	
	if(_bezelStyle === CPDisclosureBezelStyle)
	{
		[super layoutSubviews];
	}
	else
	{
		[self setState:_value];

		var w = [self valueForThemeAttribute:@"trigger-width"]; 

		[_titleView setThemeAttributes:_themeAttributes];
		[_titleView sizeToFit]; 
	  	[_titleView setCenter:[self convertPoint:[self center] fromView:_superview]];
	  	
		var f = [_titleView frame];
		f.origin.x = (_frame.size.width - w - CGRectGetWidth(_titleView._frame))/2.0;

		[_titleView setFrame:f];
	} 

}

-(void) becomeFirstResponder
{
	if([_menu isVisible])
		_menu._DOMElement.makeKey(); 

	return [super becomeFirstResponder];
}

-(void) addItemWithTitle:(CPString)aTitle
{	
	
	[_menu addItem:[CPMenuItem menuItemWithTitle:aTitle]];

	if([_menu numberOfItems] === 1 && !_pullsdown)
	{
		[_menu selectItemAtIndex:0];
		[self setTitle:aTitle];
	}


}

-(void) menuDidClose:(CPMenu)menu
{
	if(!_pullsdown)
	{
		var selItem = [menu selectedItem];
	 
		[self setTitle:[selItem title]];
		[self setNeedsLayout];
	}

	[self setState:CPControlNormalState];
	

}
 
-(void) mouseUp:(CPEvent)theEvent
{
	var mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	if(!CGRectContainsPoint([self bounds], mouseLocation)) //ignore if mouse is over view
		[super mouseUp:theEvent];
}

-(void) mouseDown:(CPEvent)theEvent
{	

	if(![self isEnabled])
		return;

	
	if([theEvent buttonNumber] === 1)
	{	

		[[self window] makeFirstResponder:self];

		if(_pullsdown)
		{	
			if([self state] === CPControlSelectedState)
			{
				[_menu close:self];
				[self setState:CPControlNormalState];
			}
			else
			{	
				[self _showPulldownMenu];
				[self setState:CPControlSelectedState];

			}  
		}
		else
		{
		  [self setHighlighted:YES];
		  [self _showPopupMenu];
		} 
			 
	} 
	  
}

-(void) keyDown:(CPEvent)theEvent
{	
	if(![self isEnabled])
		return;

	if([theEvent keyCode] === CPReturnKeyCode)
	{
		if(_pullsdown)
		{	
			if([_menu isVisible])
			{
				[_menu close:self];
				[self setState:CPControlNormalState];
			}
			else
			{	
				[self _showPulldownMenu];
				[self setState:CPControlSelectedState];
			}  
		}
		else
		{	
			[self setHighlighted:YES];
			[self _showPopupMenu];
		}
	}
}

-(void) _showPulldownMenu
{
	var offset = _DOMElement.offset(); 
		
	var h = [self valueForThemeAttribute:@"optimal-height"];

	var mh = $(window).height() - offset.top - h;

	if(!_setMenuWidth)
	{
		[_menu setWidth:_frame.size.width];
		_setMenuWidth = YES; 
	}
			 
	if(mh < 120)
		[_menu setPosition:CGPointMake(offset.left, MAX(0, offset.top - [_menu menuHeight]))];
	else
		[_menu setPosition:CGPointMake(offset.left, offset.top + h)];
	
	[_menu fadeIn:0 sender:self];
	 
}

-(void) _showPopupMenu
{	
	var offset = _DOMElement.offset(); 

	var yshift = 0; 
	var selItem = [_menu selectedItem];

	if(!selItem)
	{
		[_menu selectItemAtIndex:0];
		selItem = [_menu selectedItem];
	}

	var count = [_menu numberOfItems],
		i = 0;

	for(; i < count; i++)
	{
		var mi = [_menu itemAtIndex:i];
		if(![mi isEqual:selItem])
			yshift+=25.0;
		else
		{
			selItem = mi;
			break; 
		} 
	}

	if(!_setMenuWidth && _bezelStyle !== CPDisclosureBezelStyle)
	{
		[_menu setWidth:_frame.size.width];
		_setMenuWidth = YES; 
	}

	var mh = $(window).height() - MAX(0,offset.top - yshift);
	if(mh < 120)
		[_menu setPosition:CGPointMake(offset.left, MAX(0, $(window).height() - [_menu menuHeight]))];
	else
		[_menu setPosition:CGPointMake(offset.left, MAX(0,offset.top - yshift))];
	
	[_menu fadeIn:0 sender:self];

	if(selItem)
		[_menu setHighlightedMenuItem:selItem];
	else
		[_menu selectItemAtIndex:0];
}


-(void) sizeToFit
{
	var count = [_menu numberOfItems],
		i = 0;

	var maxW = 0; 


	for(; i < count; i++)
	{	
		var mi = [_menu itemAtIndex:i];
		var sz = [[mi title] sizeWithFont:[self font]];

		if(sz.width > maxW)
			maxW = sz.width; 
	}

	if(_bezelStyle !== CPDisclosureBezelStyle)
 		[self setFrameSize:CGSizeMake(maxW+2*[self valueForThemeAttribute:@"trigger-width"], [self valueForThemeAttribute:@"optimal-height"])];
 	else
 	{
 		[_menu setWidth:maxW+60];
 		_setMenuWidth = YES; 
 	}
}


@end


var CPPopUpButtonMenuKey 				= @"CPPopUpButtonMenuKey",
	CPPopUpButtonPullsDownKey			= @"CPPopUpButtonPullsDownKey";


@implementation CPPopUpButton (CPCoding)


-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];

	if( self )
	{	
		_setMenuWidth = NO; 
		var h = [self valueForThemeAttribute:@"optimal-height"];
		_DOMElement.addClass("cppopupbutton");
	 	
		_menu = [aCoder decodeObjectForKey:CPPopUpButtonMenuKey];
		_menu._delegate = self; 

		[self setPullsDown:[aCoder decodeBoolForKey:CPPopUpButtonPullsDownKey]];

	}


	return self; 
}


-(void)encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:_menu forKey:CPPopUpButtonMenuKey];
	[aCoder encodeBool:_pullsdown forKey:CPPopUpButtonPullsDownKey];

}


@end

