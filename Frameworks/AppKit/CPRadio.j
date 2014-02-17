@import "CPButton.j"


@implementation CPRadio : CPButton
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
		_imageView._DOMElement.addClass("radio");
		_imageView._DOMElement.append($("<div></div>").addClass("cpbutton-image").addClass("radio")); 
 
		[self setButtonType:CPPushOnPushOffButton];
	}


	return self;
}

-(void) setImage:(CPImage)anImage
{
	//no standard image for checkbox
}


-(int) nextState
{
	return CPControlSelectedState; 
}
 
 
@end


@implementation CPRadio (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];

	if(self)
	{
		_DOMElement.attr("role", "checkbox"); 
		_DOMElement.addClass("cpcheckbox");

		var dim = [self valueForThemeAttribute:@"image-size"]; 
		_imageView = [[CPView alloc] initWithFrame:CGRectMake(0,0,dim.width,dim.height)];
		_imageView._DOMElement.addClass("cpbutton-image-view");
		_imageView._DOMElement.addClass("radio");
		_imageView._DOMElement.append($("<div></div>").addClass("cpbutton-image").addClass("radio")); 


		[self setButtonType:CPPushOnPushOffButton];
	}

	return self; 
}

@end