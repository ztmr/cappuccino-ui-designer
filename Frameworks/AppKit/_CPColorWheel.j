@import "CPView.j"
@import "CPColor.j"

@implementation _CPColorWheel : CPView
{

	id 						_delegate @accessors(property=delegate); 

	double 					_angle @accessors(property=angle); 
	double 					_distance @accessors(property=distance);


	DOMElement				_blackWheel;
	DOMElement 				_selectBox; 
 


}

-(id) init 
{
	return [self initWithFrame:CGRectMake(0,0,220,220)];
}


-(id) initWithFrame:(CGRect)aFrame 
{

	self = [super initWithFrame:CGRectMake(aFrame.origin.x, aFrame.origin.y, 220,220)];

	if(self)
	{
		_DOMElement.addClass("cpcolorpanel-colorwheel");

		_blackWheel = $("<div></div>").addClass("cpcolorpanel-blackwheel");

		_blackWheel.css({
			position : "absolute",
			top : 0,
			left : 0,
			width : 220,
			height : 220
		});

		_DOMElement.append(_blackWheel);

		_selectBox = $("<div></div>").addClass("cpcolorpanel-colorwheel-selectbox");

		_DOMElement.append(_selectBox);

		[self setWheelBrightness:1.0];
		[self setPositionToColor:[CPColor colorWithWhite:0.0 alpha:1.0]];

	}


	return self; 

}


-(void) reposition:(CPEvent)theEvent
{
	var bounds   =  [self bounds],
        location = [self convertPoint:[theEvent locationInWindow] fromView:nil],
        midX     = CGRectGetMidX(bounds),
        midY     = CGRectGetMidY(bounds),
        distance = ROUND(MIN(SQRT((location.x - midX) * (location.x - midX) + (location.y - midY) * (location.y - midY)), 105.0)),
        angleRad    = ATAN2(location.y - midY, location.x - midX);

   
	[self setAngle:angleRad distance:(distance/105.0)];
	 
	if(_delegate && [_delegate respondsToSelector:@selector(colorWheelDidChange:)])
		[_delegate colorWheelDidChange:self];
}

-(void) setPositionToColor:(CPColor)aColor
{	

		var hsb = [aColor hsbComponents],
		    angleRad    = [self degreesToRadians:hsb[0]*359.0],
		    distance = hsb[1];
		
		[self setAngle:angleRad distance:distance]; 
}

-(void) setAngle:(double)angleRad distance:(double)distance
{
	var bounds = [self bounds],
	    midX   = CGRectGetMidX(bounds),
        midY   = CGRectGetMidY(bounds);

    _angle     = [self radiansToDegrees:angleRad]; 
    _distance  = distance * 100.0;

    _selectBox.css({
    	left : COS(angleRad) * distance*105 + midX - 3.0,
    	top : SIN(angleRad) * distance*105 + midY - 3.0
    });
}

-(void) setWheelBrightness:(double)brightness 
{
		_blackWheel.css({
			opacity : 1.0 - brightness,
			filter : "alpha(opacity=" + (1.0 - brightness) * 100 + ")"
		});
}

-(double) degreesToRadians:(double)degrees
{
	return -((degrees - 360.0) / 180.0) * PI;
}

-(double) radiansToDegrees:(double)radians 
{
	return ((-radians / PI) * 180.0 + 360.0) % 360;
}


-(void) mouseDown:(CPEvent)theEvent
{
	[self reposition:theEvent];
}

-(void) mouseDragged:(CPEvent)theEvent
{
	[self reposition:theEvent];
}

@end