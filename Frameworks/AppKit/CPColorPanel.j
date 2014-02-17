@import <Foundation/CPArray.j>

@import "_CPColorWheel.j"
@import "CPWindow.j"
@import "CPTextField.j"
@import "CPSlider.j"
@import "CPToolbarItem.j"

#define COLORPANEL_WIDTH 220.0
#define COLORPANEL_HEIGHT 370.0


var _CPSharedColorPanel = null; 

var CPColorPanelColorDidChangeNotification = @"CPColorPanelColorDidChangeNotification";


@implementation _CPColorSliderView : CPView 
{

	CPColorPanel 				_colorPanel @accessors(property=colorPanel); 


	CPArray 					_rgbSliders; 
	CPArray						_rgbFields; 
	CPArray 					_hsbSliders;
	CPArray 					_hsbFields; 

	CPTextField 				_hexField; 

}	


-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];
	if(self)
	{	

		var rgbLabels = ["R", "G", "B"];

		_rgbSliders = [];
		_rgbFields = []; 


		var rgbLabel = [CPTextField labelWithString:@"Red, Green, Blue"];
		[rgbLabel setFrameOrigin:CGPointMake(10,0)];

		[self addSubview:rgbLabel];

		var ypos = 28.0; 

		for(var i = 0; i < 3; i++)
		{	
			var lab = [CPTextField labelWithString:rgbLabels[i]];
			[lab setFrameOrigin:CGPointMake(10, ypos)];
			[self addSubview:lab];

			var rgbSlider = [[CPSlider alloc] initWithFrame:CGRectMake(30, ypos+4, 130.0, 6.0)];
			[rgbSlider setMaxValue:255];
			[rgbSlider setMinValue:0.0]; 
			[rgbSlider setTarget:self];
			[rgbSlider setContinuous:YES];
			[rgbSlider setAction:@selector(sliderChanged:)];


			[self addSubview:rgbSlider];
			[_rgbSliders addObject:rgbSlider];

			var rgbField = [[CPTextField alloc] initWithFrame:CGRectMake(170.0, ypos-4, 40, 22)];
			[rgbField setBezeled:YES];
			[rgbField setDelegate:self];

			[self addSubview:rgbField];

			[_rgbFields addObject:rgbField];

			ypos+=27.0;
		}
		
		var hsbLabels = ["H", "S", "B"];

		_hsbSliders = [];
		_hsbFields = []; 

		var hsbLabel = [CPTextField labelWithString:@"Hue, Saturation, Brightness"];
		[hsbLabel setFrameOrigin:CGPointMake(10, ypos)];

		[self addSubview:hsbLabel];

		ypos+=28.0; 

		for(var i = 0; i < 3; i++)
		{	
			var lab = [CPTextField labelWithString:hsbLabels[i]];
			[lab setFrameOrigin:CGPointMake(10, ypos)];
			[self addSubview:lab];

			var hsbSlider = [[CPSlider alloc] initWithFrame:CGRectMake(30, ypos+4, 130.0, 6.0)];
			[hsbSlider setContinuous:YES];
			[hsbSlider setMinValue:0.0];
			[hsbSlider setMaxValue:100]; 
			[hsbSlider setTarget:self];
			[hsbSlider setAction:@selector(sliderChanged:)];


			[self addSubview:hsbSlider];
			[_hsbSliders addObject:hsbSlider];

			var hsbField = [[CPTextField alloc] initWithFrame:CGRectMake(170.0, ypos-4, 40, 22)];
			[hsbField setBezeled:YES];
			[hsbField setDelegate:self];

			[self addSubview:hsbField];

			[_hsbFields addObject:hsbField];

			ypos+=27.0;
		}

		[_hsbSliders[0] setMaxValue:359.0];
 
		var hexLabel = [CPTextField labelWithString:@"Hex"];
		[hexLabel setFrameOrigin:CGPointMake(10, ypos+10)];

		[self addSubview:hexLabel];

		_hexField = [[CPTextField alloc] initWithFrame:CGRectMake(40,ypos+7,70,22)];
		[_hexField setBezeled:YES];
		[_hexField setDelegate:self];

		[self addSubview:_hexField];


	}

	return self; 
}



-(void) controlTextDidEndEditing:(CPNotification)aNotification
{

	var field = [aNotification object],
		value = [[field stringValue] stringByTrimmingWhitespace];  
	
		if(field === _hsbFields[0] && [_hsbSliders[1] doubleValue] === 0)
	    {
	   		setTimeout(function(){
	   			[_hsbFields[0] setIntValue:0]; 
	   		}, 50); 

	   		return; 
	    }

		if (field === _hexField)
	    {
	        var newColor = [CPColor colorWithHexString:value];
			
			if (newColor)
	        {	
	        	[self setColor:newColor];
	        	[_colorPanel setColor:newColor];
	        }
	    }
	    else
	    {	
	    	value = [value doubleValue];
	        
	        switch (field)
	        {
	            case _rgbFields[0]:  [_rgbSliders[0] setDoubleValue:MAX(MIN(ROUND(value), 255) , 0)];
	                                   	  [self sliderChanged:_rgbSliders[0]]; 
	                                   	  break;
	            case _rgbFields[1]:  [_rgbSliders[1] setDoubleValue:MAX(MIN(ROUND(value), 255)  , 0)];
					                      [self sliderChanged:_rgbSliders[1]]; 
					                      break;
	            case _rgbFields[2]:  [_rgbSliders[2] setDoubleValue:MAX(MIN(ROUND(value), 255)   , 0)];
	                                   	  [self sliderChanged:_rgbSliders[2]];
	                                   	  break;

	            case _hsbFields[0]:  [_hsbSliders[0] setDoubleValue:MAX(MIN(ROUND(value), 359.0) , 0)];
	                                   	  [self sliderChanged:_hsbSliders[0]];
	                                      break;
	            case _hsbFields[1]: [_hsbSliders[1] setDoubleValue:MAX(MIN(ROUND(value), 100) , 0)];
							             [self sliderChanged:_hsbSliders[1]];
							             break;
	            case _hsbFields[2]: [_hsbSliders[2] setDoubleValue:MAX(MIN(ROUND(value), 100) , 0)];
	                                   	 [self sliderChanged:_hsbSliders[2]];
	                                     break;
	        }
	    }
}


-(void) sliderChanged:(id)sender 
{
	var newColor,
		alpha = [_colorPanel opacity];
		 	
		switch (sender)
		{
	        case    _hsbSliders[0]:
	        case    _hsbSliders[1]:     
	        case    _hsbSliders[2]:    newColor = [CPColor colorWithHue:[_hsbSliders[0] doubleValue]/360.0 
				        								   saturation:[_hsbSliders[1] doubleValue]/100.0 
				        								   brightness:[_hsbSliders[2] doubleValue]/100.0 
				        								   alpha:alpha];
											[self updateRGBSliders:newColor];
										    break;

	        case    _rgbSliders[0]:
	        case    _rgbSliders[1]:
	        case    _rgbSliders[2]:    newColor = [CPColor colorWithRed:[_rgbSliders[0] doubleValue] / 255.0
	        											   green:[_rgbSliders[1] doubleValue] / 255.0
	        											   blue: [_rgbSliders[2] doubleValue] / 255.0
	        											   alpha: alpha];
	        		 						[self updateHSBSliders:newColor]; 
	                                        break;
	    }

	    
	    [self updateLabels];
	    [self updateHex:newColor];
	    [_colorPanel setColor:newColor];
	    
	 
}

-(void) updateHSBSliders:(CPColor)aColor
{
	var hsb = [aColor hsbComponents];
	[_hsbSliders[0] setDoubleValue:ROUND(hsb[0]*360.0)]; 
	[_hsbSliders[1] setDoubleValue:ROUND(hsb[1]*100.0)];
	[_hsbSliders[2] setDoubleValue:ROUND(hsb[2]*100.0)]; 
}


-(void) updateRGBSliders:(CPColor)aColor 
{
	var rgb = [aColor components];
	[_rgbSliders[0] setDoubleValue:ROUND(rgb[0]*255.0)]; 
	[_rgbSliders[1] setDoubleValue:ROUND(rgb[1]*255.0)];
	[_rgbSliders[2] setDoubleValue:ROUND(rgb[2]*255.0)];

}

-(void) updateHex:(CPColor)aColor 
{	
	[_hexField setStringValue:[aColor hexString]];
}

-(void) updateLabels
{
	[_hsbFields[0] setStringValue:[_hsbSliders[0] doubleValue]];
	[_hsbFields[1] setStringValue:[_hsbSliders[1] doubleValue]];
	[_hsbFields[2] setStringValue:[_hsbSliders[2] doubleValue]];
		
	for(var i = 0; i < 3; i++)
		[_rgbFields[i] setStringValue:[_rgbSliders[i] doubleValue]];
}


-(void) setColor:(CPColor)aColor 
{
	[self updateHSBSliders:aColor];
	[self updateRGBSliders:aColor];
	[self updateHex:aColor];
	[self updateLabels];
}

@end



@implementation CPColorPanel : CPWindow 
{

	CPColor 					_color @accessors(getter=color);
	double 						_opacity @accessors(getter=opacity);

	CPView 						_previewColorView;
	_CPColorSliderView 			_colorSliderView; 
	
	CPView 						_colorWheelView;
	_CPColorWheel 				_colorWheel; 

	CPSlider 					_opacitySlider; 
	CPSlider 					_brightnessSlider; 
 

}


+(CPColorPanel) sharedColorPanel
{
	if(!_CPSharedColorPanel)
		_CPSharedColorPanel = [[CPColorPanel alloc] initWithContentRect:CGRectMake(50,50, COLORPANEL_WIDTH, COLORPANEL_HEIGHT) styleMask:CPClosableWindowMask];

	return _CPSharedColorPanel; 
}

-(id) initWithContentRect:(CGRect)aFrame styleMask:(int)styleMask
{
	self = [super initWithContentRect:aFrame styleMask:styleMask];

	if(self)
	{	

		_opacity = 1.0;
		_color = [CPColor whiteColor];

		[self setTitle:@"Color Panel"];

		var background = [CPColor colorWithWhite:0.9 alpha:1.0];

		var tbarView = [[CPView alloc] initWithFrame:CGRectMake(0,0, COLORPANEL_WIDTH, 40.0)];
		[tbarView setBackgroundColor:background];
		[tbarView setAutoresizingMask:CPViewWidthSizable|CPViewMaxXMargin];


		var colorbtnWheel = [[CPToolbarItem alloc] initWithItemIdentifier:@"colorWheelBtn"];
		[colorbtnWheel setTarget:self];
		[colorbtnWheel setAction:@selector(selectColorWheel:)];

		var imgData = [[CPApp theme] themeAttribute:@"colorwheel-toolbar-image" forClass:[CPColorPanel class]]; 

		[colorbtnWheel setImage:[[CPImage alloc] initWithData:[CPData dataWithBase64:imgData]]];
		imgData = [[CPApp theme] themeAttribute:@"colorwheel-toolbar-image-highlight" forClass:[CPColorPanel class]];
		[colorbtnWheel setImage:[[CPImage alloc] initWithData:[CPData dataWithBase64:imgData]]
					forState:CPControlSelectedState];

		var f = [colorbtnWheel._toolbarItemView frame];

		[colorbtnWheel._toolbarItemView setFrameOrigin:CGPointMake((COLORPANEL_WIDTH - 2*f.size.width)/2.0,0)];

		[tbarView addSubview:colorbtnWheel._toolbarItemView];

		var sliderbtn = [[CPToolbarItem alloc] initWithItemIdentifier:@"sliderBtn"];
		[sliderbtn setTarget:self];
		[sliderbtn setAction:@selector(selectColorSlider:)];

		imgData = [[CPApp theme] themeAttribute:@"slider-toolbar-image" forClass:[CPColorPanel class]]

		[sliderbtn setImage:[[CPImage alloc] initWithData:[CPData dataWithBase64:imgData]]];
		imgData = [[CPApp theme] themeAttribute:@"slider-toolbar-image-highlight" forClass:[CPColorPanel class]];
		[sliderbtn setImage:[[CPImage alloc] initWithData:[CPData dataWithBase64:imgData]]
						forState:CPControlSelectedState];
		[sliderbtn._toolbarItemView setFrameOrigin:CGPointMake(CGRectGetMaxX(colorbtnWheel._toolbarItemView._frame),0)];

		[tbarView addSubview:sliderbtn._toolbarItemView];

		[contentView addSubview:tbarView];


		var midView = [[CPView alloc] initWithFrame:CGRectMake(0,40,COLORPANEL_WIDTH,70)];
		[midView setBackgroundColor:background];
		[midView setAutoresizingMask:CPViewWidthSizable|CPViewMaxXMargin];

		var previewLabel = [CPTextField labelWithString:@"Preview:"];

		_previewColorView = [[CPView alloc] initWithFrame:CGRectMake(0,10,120,18)];
		[_previewColorView setBackgroundColor:[CPColor blueColor]];

		_previewColorView._DOMElement.addClass("cpcolorpanel-colorpreview");

		var startx = (220 - (CGRectGetWidth(previewLabel._frame) + 130.0))/2.0;

		[previewLabel setFrameOrigin:CGPointMake(startx-5, 12)];

		[_previewColorView setFrameOrigin:CGPointMake(startx + CGRectGetWidth(previewLabel._frame)+5, 10)];


		[midView addSubview:previewLabel];
		[midView addSubview:_previewColorView];

		var opacityLabel = [CPTextField labelWithString:@"Opacity:"];
		_opacitySlider =  [[CPSlider alloc] initWithFrame:CGRectMake(0,40,120,6)];
		[_opacitySlider setMaxValue:1.0];
		[_opacitySlider setIncrement:0.01];
		[_opacitySlider setContinuous:YES];
		[_opacitySlider setTarget:self];
		[_opacitySlider setAction:@selector(opacitySliderDidChange:)];

		[_opacitySlider setDoubleValue:1.0];

		[opacityLabel setFrameOrigin:CGPointMake(startx-5,40)];
		[_opacitySlider setFrameOrigin:CGPointMake(startx+CGRectGetWidth(opacityLabel._frame) +5, 46)];

		[midView addSubview:opacityLabel];
		[midView addSubview:_opacitySlider];

		[contentView addSubview:midView];

		_colorWheelView = [[CPView alloc] initWithFrame:CGRectMake(0,110, COLORPANEL_WIDTH, 260)];
		[_colorWheelView setBackgroundColor:background];
		[_colorWheelView setAutoresizingMask:CPViewWidthSizable|CPViewMaxXMargin];

		_colorWheel =  [[_CPColorWheel alloc] init];
		[_colorWheel setDelegate:self];

		[_colorWheelView addSubview:_colorWheel];

		_brightnessSlider = [[CPSlider alloc] initWithFrame:CGRectMake(15,225,COLORPANEL_WIDTH - 30,16)];
		[_brightnessSlider setContinuous:YES]; 
		[_brightnessSlider setTarget:self];
		[_brightnessSlider setMinValue:1];
		[_brightnessSlider setAction:@selector(brightnessSliderDidChange:)];

		[_brightnessSlider setIntValue:100];
		_brightnessSlider._DOMElement.addClass("cpcolorpanel-brightness-slider");

		[_colorWheelView addSubview:_brightnessSlider];

		[contentView addSubview:_colorWheelView];

		_colorSliderView = [[_CPColorSliderView alloc] initWithFrame:CGRectMake(0,110,COLORPANEL_WIDTH,260)];
		[_colorSliderView setBackgroundColor:background];
		[_colorSliderView setColorPanel:self];

		[_colorSliderView setHidden:YES];

		[contentView addSubview:_colorSliderView];

		[self updateColor]; 

	}

	return self; 
} 


-(void) setDelegate:(id) delegate 
{
	if( _delegate )
	 	[[CPNotificationCenter defaultCenter] removeObserver:_delegate name:CPColorPanelColorDidChangeNotification object:self];
	 

	_delegate = delegate;


	[[CPNotificationCenter defaultCenter] addObserver:_delegate 
											 selector:@selector(changeColor:) 
										 		name:CPColorPanelColorDidChangeNotification
											   object:self];
}

-(void) setColor:(CPColor)aColor
{
	 [self _setColor:aColor updateColorWheel:YES updateSliders:YES]; 	
}

- (void)_setColor:(CPColor)aColor updateColorWheel:(BOOL)ucw updateSliders:(BOOL)us
{
    _color = aColor; 

	[_previewColorView setBackgroundColor:_color];

	var hsb = [_color hsbComponents];

	[_brightnessSlider setBackgroundColor:[CPColor colorWithHue:hsb[0].toPrecision(3) saturation:hsb[1].toPrecision(3) brightness:1.0 alpha:1.0]];
	 
	[_brightnessSlider setDoubleValue:ROUND(hsb[2].toPrecision(3)*100)];
	
	[_colorWheel setWheelBrightness:hsb[2].toPrecision(3)];
	[_opacitySlider setDoubleValue:[_color alphaComponent]];

    if (ucw)
        [_colorWheel setPositionToColor:aColor];

    if(us)
    	[_colorSliderView setColor:_color]

    [[CPNotificationCenter defaultCenter] postNotificationName:CPColorPanelColorDidChangeNotification object:self];
}

-(void) setOpacity:(double)opacity 
{
	_opacity = opacity;

	[self updateColor];
}

-(void) opacitySliderDidChange:(id)sender
{
	[self setOpacity:[sender doubleValue]];
}

-(void) brightnessSliderDidChange:(id)sender
{
	[_colorWheel setWheelBrightness:[sender doubleValue]];
 	[self updateColor];
}

-(void) colorWheelDidChange:(_CPColorWheel)aColorWheel
{
	[self updateColor];
}

-(void) selectColorSlider:(id)sender
{
	[_colorWheelView setHidden:YES];
	[_colorSliderView setHidden:NO];

	[self setColor:_color]; 
}


-(void) selectColorWheel:(id)sender
{
	[_colorWheelView setHidden:NO];
	[_colorSliderView setHidden:YES];

	[self setColor:_color]; 
}

-(void) updateColor
{
	var hue = [_colorWheel angle]/360.0,
		sat = [_colorWheel distance]/100.0,
		bri = [_brightnessSlider intValue]/100.0;

	[self _setColor:[CPColor colorWithHue:hue saturation:sat brightness:bri alpha:_opacity] updateColorWheel:NO updateSliders:NO]; 
}


@end