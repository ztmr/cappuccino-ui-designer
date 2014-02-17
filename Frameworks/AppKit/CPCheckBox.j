@import "CPButton.j"




@implementation CPCheckBox : CPButton
{
}

 

-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];

	if(self)
	{
		
		_DOMElement.attr("role", "checkbox"); 
		_DOMElement.addClass("cpcheckbox");

		var dim = [self valueForThemeAttribute:@"image-size"]; 
		_imageView = [[CPView alloc] initWithFrame:CGRectMake(0,0,dim.width, dim.height)];
		_imageView._DOMElement.addClass("cpbutton-image-view");
		_imageView._DOMElement.addClass("checkbox");
		_imageView._DOMElement.append($("<div></div>").addClass("cpbutton-image").addClass("checkbox")); 

		[self setButtonType:CPPushOnPushOffButton]; 
	}


	return self;
}

-(void) setImage:(CPImage)anImage
{
	//no standard image for checkbox
}

@end


@implementation CPCheckBox (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];

	if( self )
	{
		_DOMElement.attr("role", "checkbox"); 
		_DOMElement.addClass("cpcheckbox");
		
		var dim = [self valueForThemeAttribute:@"image-size"];
		_imageView = [[CPView alloc] initWithFrame:CGRectMake(0,0,dim.width, dim.height)];
		_imageView._DOMElement.addClass("cpbutton-image-view");
		_imageView._DOMElement.addClass("checkbox");
		_imageView._DOMElement.append($("<div></div>").addClass("cpbutton-image").addClass("checkbox")); 

		[self setButtonType:CPPushOnPushOffButton];


	}

	return self; 
}

@end