@import <AppKit/CPCollectionView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPImageView.j>

@implementation WidgetItem : CPCollectionViewItem
{

	CPTextField 				_label; 
	CPTextField 				_description; 
	CPImageView 				_image; 


	id 							_prototype; 
}

-(void) setRepresentedObject:(JSObject)data 
{
	if (!_label)
    {	
    	[_view addCSSStyle:@"widgetItem"]

        _label = [CPTextField labelWithString:@""];
      	[_label setFont:[CPFont boldSystemFontOfSize:13.0]];

         [_view addSubview:_label];
    }

    if(!_description)
    {
    	_description = [CPTextField labelWithString:@""];
    	[_description setFont:[CPFont fontWithName:@"Arial,sans-serif" size:12.0 italic:YES]];
    	[_description setTextColor:[CPColor colorWithWhite:0.46 alpha:1.0]];
    	[_description setLineBreakMode:CPLineBreakByWordWrapping];
    	[_view addSubview:_description];
    }

    if(!_image)
    {
    	_image = [[CPImageView alloc] init];

    	[_view addSubview:_image];

    }

    _prototype = data["itemPrototype"];
    
    [_image setImage:data["image"]];
    [_image setFrame:data["imageFrame"]];
    
 
    [_label setStringValue:data["label"]];
    [_label sizeToFit];

    [_label setFrameOrigin:CGPointMake(80, 8)];

    [_description setStringValue:data["description"]];
    [_description sizeToFitInWidth:200];

    [_description setFrameOrigin:CGPointMake(80, CGRectGetMaxY(_label._frame)+3)];
}


@end



@implementation WidgetsView : CPView
{
	CPCollectionView				_widgetList;
	
	CPView 							_searchBar; 
	CPSearchField 					_searchField;

}
 



-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if( self )
	{
		_searchBar = [[CPView alloc] initWithFrame:CGRectMake(0,0, aFrame.size.width, 50)];
		
		[_searchBar addCSSStyle:@"widgetSearchBar"];
		
		_searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(12,12, aFrame.size.width - 24, 26)];
		[_searchField setPlaceholder:@"Search Components"];
		[_searchField setFont:[CPFont systemFontOfSize:14.0]];
		 
		[_searchBar addSubview:_searchField];

		_widgetList = [[CPCollectionView alloc] initWithFrame:CGRectMake(0, 50, aFrame.size.width, aFrame.size.height-50)];
		[_widgetList setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];	
		[_widgetList setMaximumNumberOfColumns:1]; 
		[_widgetList setVerticalMargin:0];
		[_widgetList setHorizontalMargin:0];
		[_widgetList setMinItemSize:CGSizeMake(aFrame.size.width, 60)];

		var widgetItem = [[WidgetItem alloc] init]; 
		[widgetItem setView:[[CPView alloc] initWithFrame:CGRectMake(0,0,aFrame.size.width, 60)]];

		[_widgetList setItemPrototype:widgetItem];

		[_widgetList setContent:[
			{

				label : @"Push Button",
				description : "Executes an action when clicked.",
				itemPrototype : [CPButton buttonWithTitle:@"Button"],
				imageFrame : CGRectMake(3,8, 70, 38),
				image : [CPImage imageNamed:@"buttonWidget.png"]

			}
		]];
			

		[self addSubview:_searchBar];
		[self addSubview:_widgetList]; 


	}

	return self; 
}




@end
