@import "CPImageView.j"


@implementation CPActivityIndicatorView : CPImageView
{
	
}

+(id) activityIndicatorView
{
	return [[self alloc] initWithFrame:CGRectMake(0,0,32,32)];
}


-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];
	
	if( self )
	{
		[self setImage:[[CPImage alloc] imageNamed:@"css/themes/activityIndicator.gif"]];
	}
	
	
	return self; 
	
	
}


@end