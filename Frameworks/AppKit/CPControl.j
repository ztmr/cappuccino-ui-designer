@import <Foundation/CPString.j>
@import <Foundation/CPNumberFormatter.j>
@import <Foundation/CPDateFormatter.j>

@import "CPFont.j"
@import "CPView.j"


var CPImageLeft 	= 0,
	CPImageRight 	= 1,
	CPImageAbove 	= 2,
	CPImageBelow 	= 3,
	CPImageOnly 	= 4,
	CPNoImage 		= 5; 

var CPRoundRectBezelStyle = 0,
	CPRegularSquareBezelStyle = 1,
	CPHUDBezelStyle = 2,
	CPTexturedRoundedBezelStyle = 3,
	CPRoundedBezelStyle = 4;


var CPControlSelectedState = 1,
	CPControlNormalState = 0,
	CPControlMixedState = -1;

var CPLeftTextAlignment = @"left",
	CPRightTextAlignment = @"right",
	CPCenterTextAlignment = @"center"; 

var CPLineBreakByWordWrapping = @"normal",
	CPLineBreakByClipping = @"nowrap"; 
	
@implementation CPControl : CPView
{
	
	BOOL							_continuous @accessors(property=continuous);
	BOOL							_enabled; 
	
	CPFormatter						_formatter @accessors(property=formatter); 
	
	id								_target @accessors(property=target);
	SEL								_action @accessors(property=action);
	
	id								_value;
	 


	
}


-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];
	
	if( self )
	{
		_target = nil;
		_action = nil;
		
		_continuous = NO;
		_enabled = YES;
		
		_value = nil; 
		_formatter = nil; 
	}
	
	return self; 
	
}

-(BOOL)acceptsFirstResponder
{
	return YES; 
}

-(void) setHighlighted:(BOOL)aFlag
{	
	if(aFlag)
	{
		if([self isEnabled])
			[self setThemeState:@"highlighted"];
	}else
	{
		[self unsetThemeState:@"highlighted"];
	}
}

-(BOOL) highlighted
{
	return [self hasThemeState:@"highlighted"];
}


-(void) setEnabled:(BOOL)enabled
{
	_enabled = enabled;
	if(_enabled)
		[self unsetThemeState:@"disabled"];
	else
		[self setThemeState:@"disabled"];
}

-(BOOL) isEnabled
{
	return _enabled; 
}

-(void) setObjectValue:(id)aValue
{
	_value = aValue; 
}

-(id) objectValue
{
	return _value;
}

-(void) setDoubleValue:(double)val
{
	[self setObjectValue:val];
}

-(double) doubleValue
{
	var dv = parseFloat([self objectValue]);
	return isNaN(dv) ? 0.0 : dv; 
}

-(void) setIntValue:(int)val
{
	[self setObjectValue:val];
}

-(int) intValue
{
	var intval = parseInt([self objectValue], 10);
	return isNaN(intval) ? 0 : intval; 
}

-(void) setStringValue:(CPString)sval
{
	[self setObjectValue:sval];
}

-(CPString)stringValue
{
	var val = [self objectValue];
	
	if(typeof val === "number" && _formatter)
		val = [_formatter stringFromNumber:val];
	else if(val instanceof Date && _formatter)
		val = [_formatter stringFromDate:val];
	 
	return (val === undefined || val === null) ? "" : String(val);
}

-(void)takeDoubleValueFrom:(id)sender
{
	if([sender respondsToSelector:@selector(doubleValue)])
		[self setDoubleValue:[sender doubleValue]];
}

-(void)takeIntValueFrom:(id)sender
{
	if([sender respondsToSelector:@selector(intValue)])
		[self setIntValue:[sender intValue]];
}

-(void)takeObjectValueFrom:(id)sender
{
	if([sender respondsToSelector:@selector(objectValue)])
		[self setObjectValue:[sender objectValue]];
}

-(void)takeStringValueFrom:(id)sender
{
	if([sender respondsToSelector:@selector(stringValue)])
		[self setStringValue:[sender stringValue]];
}

-(void) keyDown:(CPEvent)theEvent
{
	if([theEvent keyCode] === CPReturnKeyCode)
		[self setHighlighted:YES];
	 
	[super keyDown:theEvent];
}

-(void) keyUp:(CPEvent)theEvent
{
	[self setHighlighted:NO];
	[super keyUp:theEvent];
}

-(void) mouseDown:(CPEvent)theEvent
{
	[self setHighlighted:YES];
	[super mouseDown:theEvent];
}

-(void) mouseUp:(CPEvent)theEvent
{
	[self setHighlighted:NO];
	[super mouseUp:theEvent];
}

-(void)mouseExited:(CPEvent)theEvent
{
	[self unsetThemeState:@"hovered"];
	[super mouseExited:theEvent];
}

-(void)mouseEntered:(CPEvent)theEvent
{
	[self setThemeState:@"hovered"];
	[super mouseEntered:theEvent];
}

-(BOOL) triggerAction 
{
	if(_action && _target)
	 	return [self sendAction:_action to:_target];
	  
	return NO; 
}

- (BOOL)sendAction:(SEL)anAction to:(id)anObject
{
    return [CPApp sendAction:anAction to:anObject from:self];
}

-(BOOL) becomeFirstResponder
{
	if([self isEnabled])
		[self setThemeState:@"focus"];
	
	return YES;
}

-(BOOL) resignFirstResponder
{
	[self unsetThemeState:@"focus"];
	
	return YES;
}

-(int) imagePosition
{
	return [self valueForThemeAttribute:@"image-position"];
}

-(void) setImagePosition:(int)imgPos 
{
	if([self imagePosition] === imgPos)
		return;

	[self setValue:imgPos forThemeAttribute:@"image-position"];
	 
}

-(CGSize) imageSize
{
	return [self valueForThemeAttribute:@"image-size"];
}

-(void) setImageSize:(CGSize)aSize
{
	if(CGSizeEqualToSize([self imageSize], aSize))
		return

	[self setValue:aSize forThemeAttribute:@"image-size"];
	 
}

-(CPFont)font
{	
	return [self valueForThemeAttribute:@"font"];
}

-(void) setFont:(CPFont)aFont
{
	if([[self font] isEqual:aFont])
		return; 

	[self setValue:aFont forThemeAttribute:@"font"];
 
}

-(CPColor) alternativeTextColor 
{
	return [self valueForThemeAttribute:@"alt-text-color"];
}

-(void) setAlternativeTextColor:(CPColor)aColor
{
	if([[self alternativeTextColor] isEqual:aColor])
		return;

	[self setValue:aColor forThemeAttribute:@"alt-text-color"];
 
}

-(CPColor) alternativeTextShadowColor 
{
	return [self valueForThemeAttribute:@"alt-text-shadow-color"];
}

-(void) setAlternativeTextShadowColor:(CPColor)aColor
{
	if([[self alternativeTextShadowColor] isEqual:aColor])
		return;

	[self setValue:aColor forThemeAttribute:@"alt-text-shadow-color"];
 
}

-(CPColor) textColor 
{	
	return [self valueForThemeAttribute:@"text-color"];
}

-(void)setTextColor:(CPColor)aColor
{	
	if([[self textColor] isEqual:aColor])
		return; 

	[self setValue:aColor forThemeAttribute:@"text-color"];
	 
}

-(CGSize) textShadowOffset
{
	return [self valueForThemeAttribute:@"text-shadow-offset"];
}

-(void) setTextShadowOffset:(CGSize)aSize
{
	if(CGSizeEqualToSize([self textShadowOffset], aSize))
		return;

	[self setValue:aSize forThemeAttribute:@"text-shadow-offset"];
}

-(CPColor) textShadowColor
{
	return [self valueForThemeAttribute:@"text-shadow-color"];

}

-(void) setTextShadowColor:(CPColor)aColor
{
	if([[self textShadowColor] isEqual:aColor])
		return;

	[self setValue:aColor forThemeAttribute:@"text-shadow-color"];
}

-(CPTextAlignment)textAlignment
{
	return [self valueForThemeAttribute:@"alignment"];
}

-(void) setTextAlignment:(CPTextAlignment)textAlignment
{	
	if([self textAlignment] === textAlignment)
		return;

	[self setValue:textAlignment forThemeAttribute:@"alignment"];
	 
}

-(CPLineBreakMode)lineBreakMode
{
	return [self valueForThemeAttribute:@"line-break-mode"];
}

-(void) setLineBreakMode:(CPLineBreakMode)lbm 
{	
	if([self lineBreakMode] === lbm)
		return;

	[self setValue:lbm forThemeAttribute:@"line-break-mode"];
	 
}

- (BOOL)canBecomeKeyView
{
    return [self acceptsFirstResponder] && ![self isHiddenOrHasHiddenAncestor] && [self isEnabled];
}


@end

var CPControlContinuousKey 			= @"CPControlContinuousKey",
	CPControlEnabledKey 			= @"CPControlEnabledKey",
	CPControlFormatterKey 			= @"CPControlFormatterKey",
	CPControlTargetKey				= @"CPControlTargetKey",
	CPControlActionKey 				= @"CPControlActionKey",
	CPControlValueKey 				= @"CPControlValueKey",
	CPControlFontKey  				= @"CPControlFontKey",
	CPControlTextColorKey 			= @"CPControlTextColorKey",
	CPControlTextAlignmentKey		= @"CPControlTextAlignmentKey",
	CPControlLineBreakModeKey		= @"CPControlLineBreakModeKey";


@implementation CPControl (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];
	if(self)
	{
		_continuous = [aCoder decodeBoolForKey:CPControlContinuousKey];
		
		_formatter = [aCoder decodeObjectForKey:CPControlFormatterKey];
		
		[self setTarget:[aCoder decodeObjectForKey:CPControlTargetKey]];
		
		_action = [aCoder decodeObjectForKey:CPControlActionKey];
		[self setEnabled:[aCoder decodeBoolForKey:CPControlEnabledKey]];
		[self setObjectValue:[aCoder decodeObjectForKey:CPControlValueKey]];
 
	}
	
	return self; 
}

-(void) encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];
	
	[aCoder encodeBool:_continuous forKey:CPControlContinuousKey];
	[aCoder encodeBool:_enabled forKey:CPControlEnabledKey];
	[aCoder encodeObject:_formatter forKey:CPControlFormatterKey];
	
	[aCoder encodeConditionalObject:_target forKey:CPControlTargetKey];
	
	[aCoder encodeObject:_action forKey:CPControlActionKey];
	
	[aCoder encodeObject:_value forKey:CPControlValueKey];
	 
	
	
}





@end

