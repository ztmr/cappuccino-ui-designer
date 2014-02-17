@import "CPView.j"
@import "CPButton.j"
@import "CPPopUpButton.j"


@implementation CPButtonBar : CPView
{
	 
}

+(CPButton) plusButton
{
	var imgData = [[CPApp theme] themeAttribute:@"plus-image" forClass:[CPButtonBar class]];

	var pb = [[CPButton alloc] initWithFrame:CGRectMake(0,0, 34, 27)];
	pb._DOMElement.addClass("cpbuttonbar-button");
	[pb setBezelStyle:CPRegularSquareBezelStyle]; 
	[pb setImageSize:CGSizeMake(11,12)];
	[pb setImagePosition:CPImageOnly];
	[pb setImage:[CPImage initWithData:[CPData dataWithBase64:imgData]]];


	return pb; 
}

+(CPButton) minusButton
{
	var imgData = [[CPApp theme] themeAttribute:@"minus-image" forClass:[CPButtonBar class]];

	var mb = [[CPButton alloc] initWithFrame:CGRectMake(0,0, 34, 27)];
	mb._DOMElement.addClass("cpbuttonbar-button");
	[mb setBezelStyle:CPRegularSquareBezelStyle]; 
	[mb setImageSize:CGSizeMake(12,4)];
	[mb setImagePosition:CPImageOnly];
	[mb setImage:[CPImage initWithData:[CPData dataWithBase64:imgData]]];


	return mb; 
}

+(CPPopUpButton) actionButton 
{
	var imgData = [[CPApp theme] themeAttribute:@"action-image" forClass:[CPButtonBar class]];

	var ab = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0,0, 34, 27) pullsdown:YES];
	ab._DOMElement.addClass("cpbuttonbar-button");
	[ab setBezelStyle:CPDisclosureBezelStyle]; 
	[ab setImageSize:CGSizeMake(22,14)];
	[ab setImagePosition:CPImageOnly];
	[ab setImage:[CPImage initWithData:[CPData dataWithBase64:imgData]]];

	return ab; 
}


-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if(self )
	{
		_DOMElement.addClass("cpbuttonbar");

	}

	return self;
}


-(void) addButton:(CPButton)aButton 
{
	var lastButton = _subviews[_subviews.length - 1];

	if(![_subviews containsObject:aButton])
	{
		if(lastButton)
		{
			var x = CGRectGetMaxX(lastButton._frame);
			[aButton setFrameOrigin:CGPointMake(x,0)];
		}
		else
		{
			[aButton setFrameOrigin:CGPointMake(0,0)];
		}

		[self addSubview:aButton];
	}
}




@end