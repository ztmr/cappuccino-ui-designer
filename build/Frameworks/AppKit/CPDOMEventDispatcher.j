@import <Foundation/CPObject.j>
@import <Foundation/CPRunLoop.j>

@import "Interactions.j"
@import "CPEvent.j"

var _CPResponderLastMouseDown = null,  
	_CPWindowIsResizing = NO,
	_CPWindowIsMoving = NO,
	_CPWindowResizeDelayTimer = null; 


@implementation CPDOMEventDispatcher : CPObject
{
}

+(void) addEventDispatchersForWindow:(CPWindow)aWindow 
{	
	var WindowDOM = aWindow._DOMWindowContentDiv; 
	 
	if(aWindow === [CPApp mainWindow]) //browswer window
	{	
		$(window).resize(function(){ 
 			[aWindow _adjustContentViewSize];
			
			if(_CPWindowResizeDelayTimer)
			{
				clearTimeout(_CPWindowResizeDelayTimer);
				_CPWindowResizeDelayTimer = null; 
			}		

			_CPWindowResizeDelayTimer = setTimeout(function(){
				[aWindow._toolbar layout];
			}, 100); 

			[[CPApp mainWindow] makeKeyWindow];
			
			[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

			
		}); 

		$(window).blur(function(evt){
			$(document.activeElement).blur(); 
			[CPApp._keyWindow resignKeyWindow];
			
		});



		$(window).bind("click mousedown mouseup mousemove keydown keyup", function(evt)
		{		
				[CPDOMEventDispatcher dispatchDOMEvent:evt inWindow:aWindow];
		}); 

		WindowDOM = aWindow.contentView._DOMElement; 
	}
	else
	{ 
		WindowDOM.bind("mousedown click mousemove keydown keyup", function(evt){
			[CPDOMEventDispatcher dispatchDOMEvent:evt inWindow:aWindow];
		}); 
	}

	/* mouse wheel */ 

	WindowDOM.on('mousewheel', function(evt){
		[CPDOMEventDispatcher dispatchDOMEvent:evt inWindow:aWindow];

	}); 

}
 
+(void) dispatchDOMEvent:(JSObject)evt inWindow:(CPWindow)aWindow
{
	if(!_CPWindowIsResizing && !_CPWindowIsMoving)
	{
		evt._window = aWindow; 
		 
		var theEvent = [CPEvent event:evt];
		var firstResponder = [aWindow firstResponder] ? [aWindow firstResponder] : aWindow;
		var isKey = [aWindow isKeyWindow];
 
		if(evt.type === "keydown")
		{	 
			if(isKey)
			{
				evt.stopPropagation();
				[theEvent setType:CPKeyDown];

				[firstResponder keyDown:theEvent];

				if(evt.which === CPTabKeyCode)
				{
					evt.preventDefault(); 
					[aWindow selectNextKeyView:aWindow];
				}
							
				[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
			}
		}
		else if(evt.type === "keyup")
		{
			if(isKey)
			{
				evt.stopPropagation();
				[theEvent setType:CPKeyUp];
				[firstResponder keyUp:theEvent];
				[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
			}
		}
		else //mouse event
		{

		 	var view = [aWindow hitTest:[theEvent locationInWindow]];
	 	
	 		if(!view)
	 			view = [[CPApp mainWindow] contentView];


 			[CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:view];

		}
	}
}


+(void) dispatchDOMMouseEvent:(JSObject)evt toView:(CPView)view
{
	if(_CPWindowIsResizing || _CPWindowIsMoving)
		return; 
	
	evt.stopPropagation();

	evt._window = [view window];


	var theEvent = [CPEvent event:evt];
 	
 	if(evt.type === "click")
	{		
		if(evt.which === 1)
		{	
			evt.preventDefault(); 
			[theEvent setType:CPMouseClicked]; 
			[view mouseClicked:theEvent];	
			[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];	
		} 
	}
	else if(evt.type === "mousewheel" || evt.type === "DOMMouseScroll")
	{	 
		[view scrollWheel:theEvent];	
		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
	}
	else if(evt.type === "mousedown" )
	{

		if(!evt._cancelPreventDefault)
			evt.preventDefault();

	 	if(evt.which === 1)
		{
			[theEvent setType:CPLeftMouseDown];
			[view mouseDown:theEvent];
		}
		else if(evt.which === 3)
		{	[theEvent setType:CPRightMouseDown];
			[view rightMouseDown:theEvent];
		}

		_CPResponderLastMouseDown = view; 
		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
	}
	else if(evt.type === "mouseup")
	{	 

		if(_CPResponderLastMouseDown)
		{	
			[theEvent _setWindow:[_CPResponderLastMouseDown window]];

			if(evt.which === 1)
			{		
				[theEvent setType:CPLeftMouseUp];
		 		[_CPResponderLastMouseDown mouseUp:theEvent];
			}
			else if(evt.which === 3)
			{	
				
				[theEvent setType:CPRightMouseUp];
				[_CPResponderLastMouseDown rightMouseUp:theEvent];
			}
 			
 			_CPResponderLastMouseDown = null; 
 			[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

		}
	}
	else if(evt.type === "mousemove")
	{
		
		if(_CPResponderLastMouseDown) //mouse drag
		{ 	
		 	[theEvent _setWindow:[_CPResponderLastMouseDown window]];  
			[theEvent setType:CPLeftMouseDragged];
			[_CPResponderLastMouseDown mouseDragged:theEvent];

			[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
		}	
		else
		{ 	
			 
			 [theEvent setType:CPMouseMoved];
			 [view mouseMoved:theEvent];
		}
	}
	else if(evt.type === "mouseout")
	{
		[theEvent setType:CPMouseExited];
		[view mouseExited:theEvent];
	}
	else if(evt.type === "mouseover")
	{
		[theEvent setType:CPMouseEntered];
		[view mouseEntered:theEvent];
 
	} 
}

+(void) DOMFocusKeyWindow:(BOOL)bool
{
	if(CPApp._keyWindow)
	{	
		if(bool)
		{	
			if(CPApp._keyWindow._DOMWindowContentDiv)
			{ 	
				CPApp._keyWindow._DOMWindowContentDiv.makeKey(); 
			}else
			{
				CPApp._keyWindow.contentView._DOMElement.makeKey();
			}
		}
		else
		{
			if(CPApp._keyWindow._DOMWindowContentDiv)
				CPApp._keyWindow._DOMWindowContentDiv.blur(); 
			else
				CPApp._keyWindow.contentView._DOMElement.blur();
		}
	}
    	
}

	 		



@end