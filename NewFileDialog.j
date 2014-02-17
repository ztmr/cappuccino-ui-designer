@import <AppKit/CPWindow.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPCollectionView.j>
 

@implementation NewFileDialog : CPWindow 
{
	CPTextField 				_fileNameField; 
	CPCollectionView 			collectionView; 
}


-(id) init 
{
	self = [super initWithContentRect:CGRectMake(0,0, 470,400) styleMask:CPClosableWindowMask];

	if(self )
	{	
		[self setTitle:@"New File"];

		var cv = [self contentView];

		var okButton = [[CPButton alloc] initWithFrame:CGRectMake(375, 360, 80, 25)];
		[okButton setTitle:@"OK"];
		[okButton setAutoresizingMask:CPViewMinXMargin|CPViewMinYMargin];
		[okButton setTarget:self];
		[okButton setAction:@selector(onConfirm:)];

		[cv addSubview:okButton];

		var cancelButton = [[CPButton alloc] initWithFrame:CGRectMake(290, 360, 80, 25)];
		[cancelButton setTitle:@"Cancel"];
		[cancelButton setAutoresizingMask:CPViewMinXMargin|CPViewMinYMargin];
		[cancelButton setTarget:self];
		[cancelButton setAction:@selector(orderOut:)];

		[cv addSubview:cancelButton];

		var fileTemplateLabel = [CPTextField labelWithString:@"File Template:"];
		[fileTemplateLabel setFrameOrigin:CGPointMake(15, 15)];

		[cv addSubview:fileTemplateLabel];

		collectionView = [[CPCollectionView alloc] initWithFrame:CGRectMake(15,35, 440, 230)];
		[collectionView setAutoresizingMask:CPViewWidthSizable];
		[collectionView setBackgroundColor:[CPColor whiteColor]];
		[collectionView setBorderWidth:1.0];
		[collectionView setBorderColor:[CPColor colorWithHexString:@"9d9d9d"]];
		[collectionView setHorizontalMargin:10];
		[collectionView setVerticalMargin:10];

		[collectionView setMinItemSize:CGSizeMake(96,96)];
		[collectionView setMaxItemSize:CGSizeMake(96,96)];

		var newItem = [[NewItem alloc] init]; 
		[newItem setView:[[CPView alloc] initWithFrame:CGRectMake(0,0,96,96)]];

		[collectionView setItemPrototype:newItem];

		[collectionView setContent:[{
			label : @"Window",
			image : [CPImage imageNamed:@"window.png"]
		  },
		  {
		  	label : @"View",
		  	image : [CPImage imageNamed:@"view.png"]
		  }

		]];

		[cv addSubview:collectionView];
		
		var newFileLabel = [CPTextField labelWithString:@"Filename:"];
		[newFileLabel setFrameOrigin:CGPointMake(15, 275)];

		[cv addSubview:newFileLabel];

		_fileNameField = [[CPTextField alloc] initWithFrame:CGRectMake(15, 295, 440, 28)];
		[_fileNameField setBezeled:YES];
		[_fileNameField setAutoresizingMask:CPViewWidthSizable];

		[cv addSubview:_fileNameField];  



	}

	return self; 
}

-(void) reset 
{	
	[collectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:0]];
	[_fileNameField setStringValue:@""]; 
	[self makeFirstResponder:collectionView];
}

-(void) onConfirm:(id)sender 
{
	
}


@end



@implementation NewItem : CPCollectionViewItem 
{
	CPTextField 		_label;
	CPImageView 		_imageView; 
}

-(void) setRepresentedObject:(JSObject)data 
{
     if(!_imageView)
     {
     	_imageView = [[CPImageView alloc] initWithFrame:CGRectMake(16,5,64,64)];
     	[_imageView setImageScaling:CPScaleProportionally];
     	[_view addSubview:_imageView];
     }

	 if(!_label)
	 {
	 	_label = [CPTextField labelWithString:data.label];
	 	[_label setTextShadowOffset:CGSizeMake(0,0)];
	 	[_view addSubview:_label];

	 }

	 [_imageView setImage:data.image];
	 [_label setStringValue:data.label];

	 [_label sizeToFit];
	 [_label setFrameOrigin:CGPointMake((96-CGRectGetWidth([_label frame]))/2.0, 72)];
}

-(void) setSelected:(BOOL)aBOOL 
{
	[super setSelected:aBOOL];

	if(aBOOL)
	{	
		[_view setBackgroundColor:[CPColor colorWithHexString:@"99C2FF"]];
	}else
	{
	    [_view setBackgroundColor:[CPColor whiteColor]];
	}
}

@end