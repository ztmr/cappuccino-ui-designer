@import <AppKit/CPSegmentedControl.j>




@implementation InspectorView : CPView 
{

	CPSegmentedControl					_tabControl; 


	CPView 								_attributesView;
	CPView 								_sizeView;
	CPView 								_connectionsView;
	CPView 								_classView; 


}

-(id) initWithFrame:(CGRect)aFrame 
{

	self = [super initWithFrame:aFrame];


	if( self )
	{
		_tabControl = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0,1, aFrame.size.width+1, 28)];
		[_tabControl setSegmentCount:4];
		[_tabControl setSegmentStyle:CPSegmentStyleSquare];
		[_tabControl setLabel:@"Attributes" forSegment:0];
		[_tabControl setWidth:80 forSegment:0];
		[_tabControl setLabel:@"Size" forSegment:1];
		[_tabControl setWidth:50 forSegment:1];
		[_tabControl setLabel:@"Connections" forSegment:2];
		[_tabControl setWidth:aFrame.size.width-200 forSegment:2];
		[_tabControl setLabel:@"Class" forSegment:3]; 

		[_tabControl setSelected:YES forSegment:0];

		[_tabControl setTarget:self];
		[_tabControl setAction:@selector(onTabChange:)];

		[self addSubview:_tabControl];

		var frame = CGRectMake(0, 28, aFrame.size.width, aFrame.size.height-28),
			mask = CPViewWidthSizable|CPViewHeightSizable;
		_attributesView = [[CPView alloc] initWithFrame:frame];
		[_attributesView setAutoresizingMask:mask];

	


		_sizeView = [[CPView alloc] initWithFrame:frame];
		[_sizeView setAutoresizingMask:mask];

		
		[self addSubview:_sizeView];

		_connectionsView = [[CPView alloc] initWithFrame:frame];
		[_connectionsView setAutoresizingMask:mask];


		[self addSubview:_connectionsView];

		_classView = [[CPView alloc] initWithFrame:frame];
		[_classView setAutoresizingMask:mask];

		

		[self addSubview:_classView];

		[self addSubview:_attributesView];

		[self setBackgroundColor:[CPColor colorWithHexString:@"dfedfa"]];

	}

	return self; 
}

-(void) onTabChange:(id)sender
{
	var selectedTab = [[sender selectedSegments] firstIndex];

	[_attributesView setHidden:YES];
	[_sizeView setHidden:YES];
	[_connectionsView setHidden:YES];
	[_classView setHidden:YES];

	switch(selectedTab)
	{
		case 0 :
			[_attributesView setHidden:NO];
			break;
		case 1:
			[_sizeView setHidden:NO];
			break;
		case 2:
			[_connectionsView setHidden:NO];
			break;
		case 3:
			[_classView setHidden:NO];
			break; 
	}
}









@end