@import "CPControl.j"
@import "CPImageView.j"
@import "CPTextField.j"

#define CPTOOLBARITEM_WIDTH 56.0
#define CPTOOLBARITEM_HEIGHT 58.0


var CPToolbarSeparatorItemIdentifier        = @"CPToolbarSeparatorItem",
	CPToolbarFlexibleSpaceItemIdentifier    = @"CPToolbarFlexibleSpaceItem";
	


@implementation CPToolbarItem : CPObject
{
	CPToolbarItemView 			_toolbarItemView @accessors(getter=itemView);
	CPView 						_containView; 
	CPImageView 				_imageView;
	
	CPView 						_view @accessors(getter=view); 

	CPImage 					_image @accessors(getter=image);
	CPImage 					_alternateImage @accessors(getter=alternateImage); 

	id 							_target @accessors(property=target);
	SEL 						_action @accessors(property=action); 

	CPTextField					_label @accessors(getter=label);

	int 						_tag @accessors(property=tag);

	CPString 					_identifier @accessors(getter=itemIdentifier); 

	CPToolbar  					_toolbar @accessors(property=toolbar);


}

-(id) init 
{
	return [[self alloc] initWithItemIdentifier:@""];
}

-(id) initWithItemIdentifier:(CPString)iden 
{
	self = [super init];

	if(self)
	{	

		_toolbarItemView = [[CPToolbarItemView alloc] initWithFrame:CGRectMake(0,0,CPTOOLBARITEM_WIDTH,CPTOOLBARITEM_HEIGHT)];
		[_toolbarItemView setToolbarItem:self];

		_containView = [[CPView alloc] initWithFrame:CGRectMake((CPTOOLBARITEM_WIDTH-32)/2.0, (CPTOOLBARITEM_HEIGHT - 32)/2.0 - 6, 32,32)];
		[_containView setAutoresizingMask:CPViewWidthSizable];

		[_toolbarItemView addSubview:_containView];

		_imageView = nil;
		_label = nil;
		_view = nil; 
		_target = nil;
		_action = nil; 
		_image = nil;
		_alternateImage = nil; 

		[self _setIdentifier:iden];

		[self _setStateSelected:NO];

	}

	return self; 
}


-(void) _setIdentifier:(CPString)anIdentifier
{
	_identifier = anIdentifier;

	if(_toolbarItemView)
	{
		_toolbarItemView._DOMElement.removeClass("cptoolbaritem-flexible-space");
		_toolbarItemView._DOMElement.removeClass("cptoolbaritem-separator");

		if(_identifier === CPToolbarFlexibleSpaceItemIdentifier)
			_toolbarItemView._DOMElement.addClass("cptoolbaritem-flexible-space");
		else if(_identifier === CPToolbarSeparatorItemIdentifier)
			_toolbarItemView._DOMElement.addClass("cptoolbaritem-separator");
	}

}

-(CPString) label
{
	return [_label stringValue];
}

-(void) setLabel:(CPString)aLabel
{
	if(!_label)
	{
		_label = [CPTextField labelWithString:aLabel];
		_label._DOMElement.addClass("cptoolbaritem-label");
		[_label setAlternativeTextColor:[CPColor blackColor]];
		[_label setAlternativeTextShadowColor:[CPColor colorWithHexString:@"555"]];
		[_label setFont:[CPFont systemFontOfSize:12.0]];


		[_toolbarItemView addSubview:_label];
	}

	[_label setStringValue:aLabel];
	[_label sizeToFit];

	var tbiframe = [_toolbarItemView frame],
		labelframe = [_label frame];

	[_toolbarItemView setFrameSize:CGSizeMake(MAX(CGRectGetWidth(tbiframe), CGRectGetWidth(labelframe) +10), 
												CPTOOLBARITEM_HEIGHT)];

	var p = CGPointMake((CGRectGetWidth(tbiframe) - CGRectGetWidth(labelframe))/2.0, 
						CGRectGetHeight(tbiframe) - CGRectGetHeight(labelframe) -4);

	[_label setFrameOrigin:p];

	if(_imageView)
	{
		var x = MAX(0, (CGRectGetWidth(_containView._frame) - CGRectGetWidth(_imageView._frame))/2.0)   

		[_imageView setFrameOrigin:CGPointMake(x, 0)]; 
	}
	 
}


-(void) setImage:(CPImage)anImage 
{
	_image = [anImage copy];

	 if(!_imageView)
	{ 
		_imageView = [[CPImageView alloc] initWithFrame:CGRectMake(x,0, 28,28)];
		[_imageView setImageScaling:CPScaleProportionally];


		[_containView addSubview:_imageView];
	}

	[_imageView setImage:_image];

	if(_imageView)
	{
		var x = MAX(0, (CGRectGetWidth(_containView._frame) - CGRectGetWidth(_imageView._frame))/2.0) ;   

		[_imageView setFrameOrigin:CGPointMake(x, 0)]; 
	}
}

-(void) setEnabled:(BOOL)aFlag
{	
	[_toolbarItemView setEnabled:aFlag];

	if(aFlag)
	{
		[_label setTextColor:[CPColor blackColor]];
		[_imageView setAlphaValue:1.0];
	}
	else
	{
		[_label setTextColor:[CPColor grayColor]];
		[_imageView setAlphaValue:0.7];
	}

}


-(BOOL) isEnabled
{
	return [_toolbarItemView isEnabled];
}


-(BOOL) triggerAction 
{	
	if(!_view)
	{
		if(_action && _target)
		{	
			return [CPApp sendAction:_action to:_target from:self];
		} 

	}
	
	return NO; 
} 


-(void) setView:(CPView)aView 
{	
	if([_view isEqual:aView])
		return; 


	[_view removeFromSuperview];

	_view = aView; 

	if(_view)
	{
		var frame = [_view frame];

		[_toolbarItemView setFrameSize:CGSizeMake(MAX(CGRectGetWidth([_toolbarItemView frame]), CGRectGetWidth(frame) + CPTOOLBARITEM_WIDTH-32), CPTOOLBARITEM_HEIGHT)];
		[_containView setFrameOrigin:CGPointMake((CGRectGetWidth([_toolbarItemView frame]) - CGRectGetWidth([_containView frame]))/2.0, 
												  (CPTOOLBARITEM_HEIGHT - 32)/2.0 - 3)];

		[_containView addSubview:_view];

		if(_imageView)
		{
			var x = MAX(0, (CGRectGetWidth(_containView._frame) - CGRectGetWidth(_imageView._frame))/2.0) ;  

			[_imageView setFrameOrigin:CGPointMake(x, 0)]; 
		}
	}
}


-(void) layout 
{
	var labFrame = CGRectMakeZero(); 

	var tbiframe = [_toolbarItemView frame];



	if(_label)
	{	
		[_label sizeToFit];
		
		var labelframe = [_label frame];

		var p = CGPointMake((CGRectGetWidth(tbiframe) - CGRectGetWidth(labelframe))/2.0, 
						CGRectGetHeight(tbiframe) - CGRectGetHeight(labelframe) - 4); 


		[_label setFrameOrigin:p];

		if(_imageView)
		{
			var x = MAX(0, (CGRectGetWidth(_containView._frame) - CGRectGetWidth(_imageView._frame))/2.0); 

			[_imageView setFrameOrigin:CGPointMake(x, 0)]; 
		}
	}	

}

-(void) setAlternateImage:(CPImage)anImage
{
	_alternateImage = [anImage copy];
}


-(void) _setStateSelected:(BOOL)aFlag
{
	if(_identifier === CPToolbarFlexibleSpaceItemIdentifier || _identifier === CPToolbarSeparatorItemIdentifier)
			return; 

	if(![self isEnabled])
		return; 

	if(_view)
		return; 

	if(aFlag)
	{ 	
		if(_alternateImage)
		{
			[_imageView setImage:_alternateImage];
		}
	 	
	 	[_label setThemeState:@"selected"];
	}
	else
	{
		[_label unsetThemeState:@"selected"];
		if(_image)
			[_imageView setImage:_image];
	}

}

@end


var CPToolbarItemIdentifierKey					= @"CPToolbarItemIdentifierKey",
	CPToolbarItemLabelKey 						= @"CPToolbarItemLabelKey",
	CPToolbarItemImageKey						= @"CPToolbarItemImageKey",
	CPToolbarItemAlternateImageKey				= @"CPToolbarItemAlternateImageKey",
	CPToolbarItemTagKey 						= @"CPToolbarItemTagKey",
	CPToolbarItemViewKey						= @"CPToolbarItemViewKey",
	CPToolbarItemActionKey						= @"CPToolbarItemActionKey",
	CPToolbarItemTargetKey						= @"CPToolbarItemTargetKey";

 
@implementation CPToolbarItem (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];

	if(self)
	{
		_toolbarItemView = [[CPToolbarItemView alloc] initWithFrame:CGRectMake(0,0,CPTOOLBARITEM_WIDTH,CPTOOLBARITEM_HEIGHT)];
		[_toolbarItemView setToolbarItem:self];


		_containView = [[CPView alloc] initWithFrame:CGRectMake((CPTOOLBARITEM_WIDTH-32)/2.0, (CPTOOLBARITEM_HEIGHT - 32)/2.0 - 6, 32,32)];
		[_containView setAutoresizingMask:CPViewWidthSizable];

		[_toolbarItemView addSubview:_containView];

		_imageView = nil;
		 
		[self _setIdentifier:[aCoder decodeObjectForKey:CPToolbarItemIdentifierKey]];
		[self setLabel:[aCoder decodeObjectForKey:CPToolbarItemLabelKey]];
		[self setImage:[aCoder decodeObjectForKey:CPToolbarItemImageKey]];
		[self setAlternateImage:[aCoder decodeObjectForKey:CPToolbarItemAlternateImageKey]];
		[self setTarget:[aCoder decodeObjectForKey:CPToolbarItemTargetKey]];
		[self setAction:[aCoder decodeObjectForKey:CPToolbarItemActionKey]];

		_tag = [aCoder decodeIntForKey:CPToolbarItemTagKey];

		[self _setStateSelected:NO];
	}

	return self; 

}


-(void) encodeWithCoder:(CPCoder)aCoder
{

	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:_image forKey:CPToolbarItemImageKey];
	[aCoder encodeObject:_alternateImage forKey:CPToolbarItemAlternateImageKey];
	[aCoder encodeConditionalObject:_target forKey:CPToolbarItemTargetKey];
	[aCoder encodeObject:_action forKey:CPToolbarItemActionKey];
	[aCoder encodeObject:_identifier forKey:CPToolbarItemIdentifierKey];
	[aCoder encodeObject:_view forKey:CPToolbarItemViewKey];
	[aCoder encodeObject:[self label] forKey:CPToolbarItemLabelKey];
	[aCoder encodeInt:_tag forKey:CPToolbarItemTagKey];


}


@end



@implementation CPToolbarItemView : CPControl
{

	CPToolbarItem 					_toolbarItem @accessors(property=toolbarItem); 

}


-(id) initWithFrame:(CGRect)aRect 
{
	self = [super initWithFrame:aRect];

	if( self )
	{
		_DOMElement.addClass("cptoolbaritem");
		_DOMElement.attr("role", "button");
	}

	return self; 
}

 

-(void) mouseUp:(CPEvent)theEvent
{
	if(![self isEnabled] || _toolbarItem._view || _toolbarItem._identifier === CPToolbarSeparatorItemIdentifier
				|| _toolbarItem._identifier === CPToolbarFlexibleSpaceItemIdentifier)
	{
		 return;
	}

	[super mouseUp:theEvent];


	var mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];



	if(CGRectContainsPoint([self bounds], mouseLocation))
		[_toolbarItem triggerAction];
}

-(void) keyDown:(CPEvent)theEvent
{	
	if(![_toolbarItem isEnabled] || _toolbarItem._view || _toolbarItem._identifier === CPToolbarSeparatorItemIdentifier
				|| _toolbarItem._identifier === CPToolbarFlexibleSpaceItemIdentifier)
	{
		 return;
	}

	var KC = [theEvent keyCode];
	if(KC === CPSpaceKeyCode || KC === CPReturnKeyCode)
		[_toolbarItem triggerAction];

}

-(void) setHighlighted:(BOOL)aFlag
{
	[_toolbarItem _setStateSelected:aFlag];
}


@end