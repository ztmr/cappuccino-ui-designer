@import "CPTextField.j"
@import "CPButton.j"


@implementation CPHyperlinkButton : CPButton
{
	  
}

+(id) linkWithTitle:(CPString)aString
{
	var link = [[CPHyperlinkButton alloc] init];
	[link setTitle:aString];
	[link sizeToFit];
	
	return link; 

}


-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];
	
	if( self )
	{
		[self setBackgroundColor:[CPColor clearColor]];
		[self setBordered:NO];
		[self setTextColor:[CPColor blueColor]];
		[self setTextShadowColor:[CPColor clearColor]];
		[self setTextAlignment:CPLeftTextAlignment];
		[self setFont:[CPFont systemFontOfSize:13.0]];
		
		_DOMElement.addClass("cphyperlink");
	
		
	}
	
	return self; 
	
}

-(void) layoutSubviews
{
	[super layoutSubviews];
	
	[_titleView setFrameOrigin:CGPointMake(0, 0)];

	
}

-(void) sizeToFit 
{
	[super sizeToFit];
	[self setFrameSize:_titleView._frame.size];
	
}

@end




