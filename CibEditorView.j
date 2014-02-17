@import <AppKit/CPSplitView.j>


@implementation CibEditorView : CPSplitView
{
	CPView 				_canvasView;
	CPView 				_objectsView;

}

-(id) initWithFrame:(CGRect)aFrame 
{
	self  = [super initWithFrame:aFrame];

	if( self )
	{
			[self setOrientation:CPSplitViewVertical];
    		[self setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];	

    		_canvasView = [[CPView alloc] initWithFrame:CGRectMake(0,0, CGRectGetWidth(aFrame)-600, CGRectGetHeight(aFrame)*0.7)];
    		[_canvasView setAutoresizingMask:CPViewHeightSizable];
    		[_canvasView addCSSStyle:@"canvas"];
    		_objectsView = [[CPView alloc] initWithFrame:CGRectMake(0, 500, CGRectGetWidth(aFrame), CGRectGetHeight(aFrame)*0.3)];
    		[_objectsView setBackgroundColor:[CPColor whiteColor]];

    		[self addSubview:_canvasView];
    		[self addSubview:_objectsView];

	}

	return self; 
}

@end