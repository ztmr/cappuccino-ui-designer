@import "CPTextField.j"



@implementation CPSecureTextField : CPTextField
{

}


-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if( self )
	{
		[self setBezeled:YES];
		[self setEditable:YES];


		_input.attr("type", "password");
	}

	return self; 
}

@end


@implementation CPSecureTextField (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];
	if(self)
	{
		_input.attr("type", "password");
	}

	return self; 
}

@end