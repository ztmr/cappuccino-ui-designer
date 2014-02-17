@import <Foundation/CPObject.j>

@import "_CPDisplayServer.j"


var CPLeftMouseDown                         	= 1,
	CPLeftMouseUp                           	= 2,
	CPRightMouseDown                        	= 3,
	CPRightMouseUp                          	= 4,
	CPMouseMoved                            	= 5,
	CPLeftMouseDragged                      	= 6,
	CPRightMouseDragged                     	= 7,
	CPMouseEntered                          	= 8,
	CPMouseExited                           	= 9,
	CPKeyDown                              	 	= 10,
	CPKeyUp                                 	= 11, 
	CPScrollWheel                           	= 12,
	CPOtherMouseDown                        	= 13,
	CPOtherMouseUp                          	= 14,
	CPOtherMouseDragged                     	= 15,
	CPMouseClicked								= 16;  


var mpt = null;  

@implementation CPEvent : CPObject
{
	JSObject		_domEvent; 
	int 			_type @accessors(property=type);
	
}

+(void) initialize
{	
	$(document).mousemove(function(evt) {
	     mpt = CGPointMake(evt.pageX, evt.pageY);
	});

}


+(CGPoint)mouseLocation
{
	return mpt; 
}

+(id)event:(JSObject)evt
{
	return [[self alloc] initWithNativeEvent:evt];
}

-(id) initWithNativeEvent:(JSObject)evt
{
	self = [super init];
	if(self)
	{
		_domEvent = evt; 
		
	}
	
	return self; 
}

-(CGPoint) mouseLocation
{
	return CGPointMake(_domEvent.clientX, _domEvent.clientY);
}


-(CGPoint) locationInWindow
{	
	var cframe = null; 
	if(!_domEvent._window._DOMWindowContentDiv)
		cframe = $("#CPWindowToolbarAndContent").offset();
	else
		cframe = _domEvent._window._DOMWindowContentDiv.offset();   
	
	 
	return CGPointMake(_domEvent.clientX - cframe.left, _domEvent.clientY - cframe.top);
}

-(CPInteger) buttonNumber
{
	return _domEvent.which; 
}

-(CPInteger) keyCode
{
	return _domEvent.which; 
}

-(double) deltaX
{
	if(_domEvent.deltaX)
		return _domEvent.deltaX;

	return 0.0; 
}

-(double) deltaY
{
	if(_domEvent.deltaY)
		return _domEvent.deltaY;

	return 0.0; 
}
-(BOOL) shiftKey
{
	return _domEvent.shiftKey; 
}

-(void) _setWindow:(CPWindow)aWindow
{
	_domEvent._window = aWindow; 
}

-(CPWindow) window 
{
	return _domEvent._window; 
}

-(int) windowNumber
{
	return [_domEvent._window]
}


@end