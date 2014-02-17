@import <Foundation/CPString.j>

@import "CPControl.j"
@import "CPColor.j"
@import "CPColorPanel.j"



@implementation CPColorWell : CPControl 
{
		CPView 				_colorView;
		CPColor 			_color @accessors(getter=color); 

}


-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if( self )
	{
		_DOMElement.addClass("cpcolorwell");

		_colorView = [[CPView alloc] initWithFrame:CPMakeRect(5,5, _frame.size.width - 10, _frame.size.height - 10)];
		[_colorView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
 
		[_ephemeralSubviews addObject:_colorView];
		[self addSubview:_colorView];

		[self setColor:[CPColor blackColor]];
	}

	return self; 
}


-(void) setColor:(CPColor)aColor 
{
	_color = aColor;
	[_colorView setBackgroundColor:_color];
}

 

-(void) mouseClicked:(CPEvent)theEvent
{
	var colorPanel = [CPColorPanel sharedColorPanel];

	[colorPanel setDelegate:nil];
	[colorPanel setColor:_color];
	[colorPanel setDelegate:self];

	[colorPanel orderFront:nil];


	[super mouseClicked:theEvent];

}

-(void) changeColor:(CPNotification)aNotification 
{
	var colorPanel = [aNotification object];

	[self setColor:[colorPanel color]];

	[self triggerAction];
}


@end




@implementation CPColorWell (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder 
{
	self = [super initWithCoder:aCoder];


	if( self )
	{
		_DOMElement.addClass("cpcolorwell");

		_colorView = [[CPView alloc] initWithFrame:CPMakeRect(5,5, _frame.size.width - 10, _frame.size.height - 10)];
		[_colorView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
 
		[_ephemeralSubviews addObject:_colorView];
		[self addSubview:_colorView];

		[self setColor:[aCoder decodeObjectForKey:@"CPColorWellColorKey"]];


	}


	return self; 
}


-(void) encodeWithCoder:(CPCoder)aCoder 
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:_color forKey:@"CPColorWellColorKey"];


}


@end