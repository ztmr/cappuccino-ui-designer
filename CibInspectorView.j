

@import <AppKit/CPSplitView.j>

@import "InspectorView.j"
@import "WidgetsView.j"

@implementation CibInspectorView : CPSplitView
{

    
}

-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if( self )
	{
		[self setOrientation:CPSplitViewVertical];

		[self setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable];

		var widgetsView = [[WidgetsView alloc] initWithFrame:CGRectMake(0,0, 300, CGRectGetHeight(aFrame)/2.0)];
	    [widgetsView setAutoresizingMask:CPViewHeightSizable];
	    var inspectorView = [[InspectorView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(aFrame)/2.0, 300, CGRectGetHeight(aFrame)/2.0)];
	    [inspectorView setAutoresizingMask:CPViewHeightSizable];

    	[self addSubview:widgetsView];
    	[self addSubview:inspectorView];
	}


	return self; 


}

@end