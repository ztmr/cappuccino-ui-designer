
@import "CPResponder.j"
@import "CPScreen.j" 
@import "CPDOMEventDispatcher.j"
@import "Interactions.j"
@import "CPMenu.j"

var CPWindowDOMElementPrototype = nil;  

//return codes
var CPCancelButton = 0,
	CPOKButton = 1;

function __CPBrowserSize()
{
	  var e = window, a = 'inner';
	  if ( !( 'innerWidth' in window ) )
	  {
	        a = 'client';
	        e = document.documentElement || document.body;
	  }
 	
      return CPMakeSize(e[ a+'Width' ], e[ a+'Height' ]); 
}


var CPBorderlessWindowMask          	= 1 << 0,
	CPStaticWindowMask					= 1 << 1,
	CPClosableWindowMask 				= 1 << 2,
	CPResizableWindowMask           	= 1 << 3,
	CPTexturedBackgroundWindowMask 		= 1 << 4,
	CPBorderlessBridgeWindowMask		= 1 << 5,
	CPHUDBackgroundWindowMask 			= 1 << 6;	

var CPWindowWillCloseNotification       = @"CPWindowWillCloseNotification",
 	CPWindowDidBecomeKeyNotification    = @"CPWindowDidBecomeKeyNotification",
	CPWindowDidResignKeyNotification    = @"CPWindowDidResignKeyNotification", 
	CPWindowWillBeginSheetNotification	= @"CPWindowWillBeginSheetNotification",
	CPWindowDidEndSheetNotification		= @"CPWindowDidEndSheetNotification",
	CPWindowDidResizeNotification       = @"CPWindowDidResizeNotification",
	CPWindowDidMoveNotification         = @"CPWindowDidMoveNotification";
 


/*!
    @class CPWindow
    @ingroup appkit
    @brief Floating panel widget that contains a view.

    A CPWindow class
*/
  
@implementation CPWindow : CPResponder
{

		int					_windowNumber @accessors(getter=windowNumber);
		int					_level; 

		unsigned			_styleMask @accessors(getter=styleMask); 
		CPString			_title @accessors(getter=title);

		BOOL				_isVisible @accessors(getter=isVisible);
		BOOL				_isMovable @accessors(getter=isMovable);
		BOOL				_isResizable @accessors(getter=isResizable);
		BOOL				_isClosable @accessors(getter=isClosable);
		BOOL 				_isSheet @accessors(property=isSheet);


		CPView 				contentView @accessors(getter=contentView);
		CPResponder 		_initialFirstResponder;

		CPToolbar			_toolbar @accessors(getter=toolbar); 

		CGRect  			_frame; 
		CPRect				_initFrame; 

		CPSize				_minSize @accessors(getter=minSize);
		CPSize				_maxSize @accessors(getter=maxSize);

		BOOL 				_isModal @accessors(property=modal);
		
		DOMElement			_DOMElement; 
		DOMElement  		_DOMWindowContentDiv;  
		DOMElement 			_DOMWindowTitleBar;
		DOMElement 			_DOMWindowTitle;
		DOMElement 			_DOMWindowCloseBtn; 
		DOMElement 			_DOMWindowModalOverlay; 
		

		JSObject			_sheetContext; 
		BOOL 				_sheetAttached;  
		BOOL 				_autorecalculatesKeyViewLoop; 
		BOOL 				_keyViewLoopIsDirty; 

		
		CPResponder			_firstResponder @accessors(getter=firstResponder); 
		id 					_delegate @accessors(getter=delegate);


}

 
+(void) initialize
{
	CPWindowDOMElementPrototype = $("<div></div>").addClass("cpwindow");
	CPWindowDOMElementPrototype.css({
		position : "absolute",
		zIndex : 10000
	});
} 


-(BOOL) _init
{
		_isModal = NO; 
		_isMovable = YES; 
		_isVisible = NO;
		_isClosable = YES;
		_sheetAttached = NO;  
		_keyViewLoopIsDirty = YES; 
		_initialFirstResponder = nil;
		_nextResponder = nil; 
		_autorecalculatesKeyViewLoop = YES;
		_firstResponder = self; 

		_DOMWindowModalOverlay = $("<div></div>").addClass("cpmodal-overlay");
		_DOMWindowModalOverlay.bind("mousedown click mouseout mouseover mousemove", function(evt){
			evt.stopPropagation();
			evt.preventDefault(); 
		});

		_toolbarOverlay = nil;
		
		// Set up our window number.
        _windowNumber = [CPApp._windows count];
        CPApp._windows[_windowNumber] = self;
 
		if (_styleMask & CPBorderlessBridgeWindowMask) // this is the Browser window  
		{ 	
			 
			if(CPApp._mainWindow) //main browser window already defined elsewhere
			 	return NO; 
			 
			CPApp._mainWindow = self; 
			CPApp._keyWindow = self; 
			
			_isVisible = YES;
			contentView._DOMElement.attr("role", "application"); 
			contentView._DOMElement.attr("id", "rootView"); 
			contentView._DOMElement.attr("tabIndex", "0");

			var CPWindowToolbarAndContentDiv = $("<div></div>").attr("id", "CPWindowToolbarAndContent");
			 
			$("body").append(CPWindowToolbarAndContentDiv);

			[self _adjustContentViewSize];
			
		}else
		{
			_minSize = CPMakeSize(60.0, 60.0);
	        _maxSize = CPMakeSize(Number.MAX_VALUE, Number.MAX_VALUE);

			_DOMElement = CPWindowDOMElementPrototype.clone(false);
 
			_DOMElement.css({
				left : _initFrame.origin.x,
				top : _initFrame.origin.y,
				width : _initFrame.size.width,
				height : _initFrame.size.height 
			}); 

			_frame = _initFrame; 

			_DOMElement.bind("click mousedown", function(evt){
				 evt.stopPropagation(); 
				 evt.preventDefault(); 
				
				 if(evt.type === "mousedown")
				 	[self makeKeyAndOrderFront:nil];
				 
			});
			
			
			_DOMWindowTitleBar = $("<div></div>").addClass("cpwindow-titlebar");	
			_DOMWindowTitle = $("<div></div>").addClass("cpwindow-title");

			_DOMWindowCloseBtn = $("<div></div>").addClass("cpwindow-titlebar-close");
			_DOMWindowCloseBtn.attr({
					tabIndex : 0,
					role	   : "button",
					"aria-label" : "window close"
			});

			_DOMWindowCloseBtn.bind({
				mousedown : function(evt)
				{
					evt.stopPropagation();
					evt.preventDefault(); 
				},
				click : function(evt)
				{	
					evt.stopPropagation();
					evt.preventDefault(); 

					if(_isClosable && !_sheetAttached)
						[self orderOut:self];
					
				},
				keydown : function(evt)
				{
					if(evt.which === CPReturnKeyCode && !_sheetAttached)
					 	[self orderOut:self];
				} 
			});

			_DOMWindowTitleBar.append(_DOMWindowTitle);
			_DOMWindowTitleBar.append(_DOMWindowCloseBtn);
			 
			_DOMWindowContentDiv = $("<div></div>").css({
				position : "absolute",
			}).addClass("cpwindow-content");
			
			_DOMWindowContentDiv.append(contentView._DOMElement);
			_DOMWindowContentDiv.attr("tabindex", 0);	

			_DOMElement.append(_DOMWindowContentDiv); 

			$("#CPWindowToolbarAndContent").append(_DOMElement);
			
			[self _adjustContentViewSize];
			
			[contentView setBackgroundColor:[CPColor colorWithWhite:0.9 alpha:1.0]];

			[self setVisible:NO];
			[self setStyleMask:_styleMask]; 

		} 

		[CPDOMEventDispatcher addEventDispatchersForWindow:self];

		return YES; 
}

-(void) setDelegate:(id)aDelegate 
{
   var defaultCenter = [CPNotificationCenter defaultCenter];
 	
   [defaultCenter removeObserver:_delegate name:CPWindowWillCloseNotification object:self];	
   [defaultCenter removeObserver:_delegate name:CPWindowDidResignKeyNotification object:self];
   [defaultCenter removeObserver:_delegate name:CPWindowDidBecomeKeyNotification object:self]; 
   [defaultCenter removeObserver:_delegate name:CPWindowDidMoveNotification object:self];
   [defaultCenter removeObserver:_delegate name:CPWindowDidResizeNotification object:self];
   [defaultCenter removeObserver:_delegate name:CPWindowWillBeginSheetNotification object:self];
   [defaultCenter removeObserver:_delegate name:CPWindowDidEndSheetNotification object:self];

   _delegate = aDelegate;

   if ([_delegate respondsToSelector:@selector(windowWillClose:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowWillClose:)
                   name:CPWindowWillCloseNotification
                 object:self];

   if ([_delegate respondsToSelector:@selector(windowDidResignKey:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidResignKey:)
                   name:CPWindowDidResignKeyNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(windowDidBecomeKey:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidBecomeKey:)
                   name:CPWindowDidBecomeKeyNotification
                 object:self];

    
    if ([_delegate respondsToSelector:@selector(windowDidMove:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidMove:)
                   name:CPWindowDidMoveNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(windowDidResize:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidResize:)
                   name:CPWindowDidResizeNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(windowWillBeginSheet:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowWillBeginSheet:)
                   name:CPWindowWillBeginSheetNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(windowDidEndSheet:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(windowDidEndSheet:)
                   name:CPWindowDidEndSheetNotification
                 object:self];

}

-(id) initWithContentRect:(CPRect)aRect styleMask:(int)aStyleMask
{

	self = [super init];

	if(self)
	{	 
		_styleMask = aStyleMask;
		
		_initFrame = [self _frameRectForContentRect:aRect];
		contentView = [[CPView alloc] initWithFrame:aRect];
		[contentView _setWindow:self]; 
		[contentView setNextResponder:self];
		
		//[self setNextResponder:CPApp];
	 	
		[self _init];
	}

	return self; 

}


-(void) setContentView:(CPView)aView 
{
	if(aView === contentView)
		return;

	if(contentView)
		contentView._DOMElement.detach();

	contentView = aView;

	[contentView setNextResponder:self];

	if(CPApp._mainWindow === self)
	{
		$("#CPWindowToolbarAndContent").append(contentView._DOMElement);

	}
	else
	{
		if(contentView)
			_DOMWindowContentDiv.append(contentView._DOMElement);
	}

	[self _adjustContentViewSize];
}



-(void) setStyleMask:(unsigned)styleMask
{
	_styleMask = styleMask;
	
	[self setResizable:_styleMask & CPResizableWindowMask]; 
	[self setClosable:_styleMask & CPClosableWindowMask];
	[self setMovable:!(_styleMask & CPStaticWindowMask)];

	if(_styleMask & CPHUDBackgroundWindowMask)
	{
		_DOMElement.addClass("hud");
		contentView._DOMElement.css("background", "transparent");
		contentView._DOMElement.css("background-color", "none"); 
	}
	else
	{
		_DOMElement.removeClass("hud");
		[contentView setBackgroundColor:[contentView backgroundColor]];

	}
	
	if(_styleMask & CPBorderlessWindowMask)
	{
		_DOMWindowTitleBar.detach(); 
		[self setFrame:[self _frameRectForContentRect:[contentView frame]]]
	}
	else
	{
		_DOMElement.append(_DOMWindowTitleBar);
		[self setFrame:[self _frameRectForContentRect:[contentView frame]]]
	}
	
	[self _adjustContentViewSize];

}
 

-(void) setMinSize:(CPSize)aSize
{
	_minSize = CPMakeSize(aSize.width, aSize.height + [self titleBarHeight]);;
	[self setResizable:[self isResizable]];
}

-(void) setMaxSize:(CPSize)aSize
{
	_maxSize = CPMakeSize(aSize.width, aSize.height + [self titleBarHeight]);
	[self setResizable:[self isResizable]];
}
 

-(void) setVisible:(BOOL)visible
{
	if(visible == _isVisible)
		return; 

	_isVisible = visible;
	
	if(_isVisible)
	{
 		_DOMElement.show();  
	}else
	{
		_DOMElement.hide(); 
	}
		
}
 
-(void) setClosable:(BOOL)closable
{
	_isClosable = closable;
	
	if(_DOMWindowCloseBtn)
	{	 
		if(_isClosable)
			_DOMWindowCloseBtn.show(); 
		else
			_DOMWindowCloseBtn.hide(); 	
	}
}

 

- (void)setResizable:(BOOL)isResizable
{
	_isResizable = isResizable;

	_DOMElement.resizable();
	 

	if(_isResizable)
	{
		_DOMElement.resizable({
			maxHeight : _maxSize.height,
			minHeight : _minSize.height,
			maxWidth : _maxSize.width,
			minWidth : _minSize.width,
			resize : function()
			{
				[self setFrameSize:CGSizeMake(_DOMElement.width(), _DOMElement.height())]; 
				_CPWindowIsResizing = YES; 
				 
				
			},
			stop : function()
			{
				
				[self setFrameSize:CGSizeMake(_DOMElement.width(), _DOMElement.height())]; 
				 
				
				[_toolbar layout];

				[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
				_CPWindowIsResizing = NO; 
				 
			}
		}); 
	}
	else
	{
		_DOMElement.resizable("destroy");
	}
	 
}
 
-(void)setMovable:(BOOL)movable
{
	_isMovable = movable; 

	_DOMElement.draggable(); 
	
	if(_isMovable)
	{
		_DOMElement.draggable({
		 	containment : "parent",
			handle : _DOMWindowTitle,
			drag : function()
			{	
				var offset = _DOMElement.offset();
				[self setFrameOrigin:CGPointMake(offset.left, offset.top)];
				_CPWindowIsMoving = YES; 
			},
			stop : function()
			{
				var offset = _DOMElement.offset();
				[self setFrameOrigin:CGPointMake(offset.left, offset.top)];
				_CPWindowIsMoving = NO; 
				 
			}
		});
		
	}
	else
	{
		_DOMElement.draggable("destroy");
	}
	  
}
 

- (CPView)initialFirstResponder
{
    return _initialFirstResponder;
}

- (void)setInitialFirstResponder:(CPView)aView
{
    _initialFirstResponder = aView;
}

 

/*!
    Attempts to make the \c aResponder the first responder. Before trying
    to make it the first responder, the receiver will ask the current first responder
    to resign its first responder status. If it resigns, it will ask
    \c aResponder accept first responder, then finally tell it to become first responder.
    @return \c YES if the attempt was successful. \c NO otherwise.
*/
- (BOOL)makeFirstResponder:(CPResponder)aResponder
{
    if (_firstResponder === aResponder)
        return YES;

    if (![_firstResponder resignFirstResponder])
        return NO;

    if (!aResponder || ![aResponder acceptsFirstResponder] || ![aResponder becomeFirstResponder])
    {
        _firstResponder = self;

        return NO;
    }

    _firstResponder = aResponder;

  
    return YES;
}

- (void)setToolbar:(CPToolbar)aToolbar
{
    if (_toolbar === aToolbar)
        return;

    // If this has an owner, dump it!
    [[aToolbar window] setToolbar:nil];
 
    // This is no longer out toolbar.
    [_toolbar setWindow:nil];

    _toolbar = aToolbar;

    // THIS is our toolbar.
    [_toolbar setWindow:self];

    [self _noteToolbarChanged];
}


- (void) _noteToolbarChanged
{
    var toolbar = [self toolbar]; 
    if (toolbar !== nil)
    { 

		if (self === CPApp._mainWindow) // this is the Browser window 
			$("#CPWindowToolbarAndContent").append(toolbar._itemsView._DOMElement);
		else
		{
			_DOMWindowContentDiv.append(toolbar._itemsView._DOMElement);
			if(_DOMWindowTitleBar)
				_DOMWindowTitleBar.addClass("unified");
		}
		 
		[self _adjustContentViewSize]; 
		[toolbar layout]; 	

    }  
    else
    {	
    	if(_DOMWindowTitleBar)
    		_DOMWindowTitleBar.removeClass("unified");
    }
}

- (void)toggleToolbarShown:(id)aSender
{
    var toolbar = [self toolbar];

    [toolbar setVisible:![toolbar isVisible]];
	
	[self _adjustContentViewSize];
}



-(CGRect) _frameRectForContentRect:(CPRect)aContentRect
{
	var frameRect = CGRectMakeCopy(aContentRect),
	 	titleBarHeight = [self titleBarHeight]; 
	var toolBarHeight = 0; 
	if(_toolbar && [_toolbar isVisible])
	{ 
		toolBarHeight = [_toolbar height] ;
	}
	
	frameRect.origin.y = Math.max(0, frameRect.origin.y - (titleBarHeight + toolBarHeight));
	frameRect.size.height+=(titleBarHeight + toolBarHeight  ); 
	
	return frameRect;  
}

 
-(CGRect) _contentRectForFrameRect:(CPRect)aFrame
{
	 var toolBarHeight = 0; 

	if(_toolbar && [_toolbar isVisible])
	 	toolBarHeight = [_toolbar height]  ;
	  

	var h = aFrame.size.height - toolBarHeight - [self titleBarHeight]; 

	return CGRectMake(0, toolBarHeight, aFrame.size.width, h );  
	 
}
 
-(void) titleBarHeight
{
	if(self === CPApp._mainWindow 
		|| (_styleMask & CPBorderlessWindowMask))
	{
		return 0;
	}
	return 27.0;  
}



-(void)_adjustContentViewSize
{
	if (self === CPApp._mainWindow) // this is the Browser window  
	{ 
		var menuBarHeight = 0; 
		var toolBarHeight = -1; 
		
		if(_toolbar && [_toolbar isVisible])
		{ 
			toolBarHeight = [_toolbar height];
		} 
		
		if([CPMenu menuBarVisible])
			menuBarHeight = [CPMenu menuBarHeight]; 
		
		var sz = __CPBrowserSize(); 

		$("#CPWindowToolbarAndContent").css({
			"position" : "absolute",
			"top" : menuBarHeight,
			"left" : 0,
			"width" : sz.width,
			"height" : sz.height - menuBarHeight
		});


		var w = sz.width;
		var h = sz.height - toolBarHeight - menuBarHeight;  
		[contentView setFrame:CPMakeRect(0, toolBarHeight, w, h)]; 
		// adjust toolbar starting y  
		if(_toolbar)
			[_toolbar._itemsView setFrame:CPMakeRect(0, 0, w, toolBarHeight)];
	
	}
	else
	{
		if(_toolbar)
		 	[_toolbar._itemsView setFrame:CPMakeRect(0, 0, _frame.size.width, [_toolbar height])];
 
		_DOMWindowContentDiv.css({
			top : [self titleBarHeight],
			left : 0,
			width : _frame.size.width,
			height : _frame.size.height - [self titleBarHeight] 
		});
		
		 
		[contentView setFrame:[self _contentRectForFrameRect:_frame]]; 
		
	} 
	
}


-(void)setFrameSize:(CPSize)aSize
{	
	if(_DOMElement)
	{
		_DOMElement.css({
			width : aSize.width,
			height : aSize.height
		}); 
		
		_frame.size = CGSizeCreateCopy(aSize);


		[self _adjustContentViewSize];

		[[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidResizeNotification object:self];
	}
	
}

-(void)setFrameOrigin:(CPPoint)aPoint
{
	if(_DOMElement)
	{
		_DOMElement.css({
			"top" : aPoint.y - [self titleBarHeight]  - 1,
			"left" : aPoint.x 
		}); 

		_frame.origin = CGPointCreateCopy(aPoint);

		[[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidMoveNotification object:self];
	}

}

-(void)setFrame:(CPRect)aFrame
{
	[self setFrameSize:aFrame.size];
	[self setFrameOrigin:aFrame.origin];
}

-(CPRect)frame
{
	if (self === CPApp._mainWindow) // this is the Browser window  
	{
		var sz = __CPBrowserSize();
		return CGRectMake(0,0, sz.width, sz.height);
	}
	
	if(_DOMElement)
	 	return CGRectCreateCopy(_frame);
	 
	
	return CGRectMakeZero(); 
}

-(void)center
{
	var f = [self frame];

	[self setFrameOrigin:CPMakePoint(($(window).width() - f.size.width) / 2.0, ($(window).height() - f.size.height) / 2.0 - 50)];
}


-(void) setTitle:(CPString)title
{
	_title = title;
	if(_title)
	{
		_DOMWindowTitle.text(_title);
	}
}

-(void) setAlphaValue:(double)alphaValue
{
	[super setAlphaValue:alphaValue];

	[contentView setAlphaValue:alphaValue];
}

 
-(void) orderFront:(id)aSender
{
	if(self === CPApp._mainWindow)
	{ 
		if(!document.getElementById("rootView"))
			$('#CPWindowToolbarAndContent').append(contentView._DOMElement);
 		
 		return;
	}
	
	
	var appWindows = [CPApp windows];

	//send all open windows to the back
	for(var aWindowNumber in appWindows)
	{
		var aWindow = appWindows[aWindowNumber];
		if(aWindow._DOMElement)
			aWindow._DOMElement.css("zIndex", 999);
	}

	//send this window to the front
	_DOMElement.css("zIndex", 1000);
 
	if(_isModal)
		$('#CPWindowToolbarAndContent').append(_DOMWindowModalOverlay);		 
	

	[self setVisible:YES];
	
	[_toolbar layout]; 

	
	
}

-(BOOL) isKeyWindow
{
	return CPApp._keyWindow === self; 
}




/*!
    Called when the receiver should become the key window. It sends
    the \c -becomeKeyWindow message to the first responder if it responds,
    and posts \c CPWindowDidBecomeKeyNotification.
*/
- (void)becomeKeyWindow
{
    if(![self isKeyWindow])
    {
    	CPApp._keyWindow = self; 

    	[_firstResponder becomeFirstResponder];

	    [[CPNotificationCenter defaultCenter]
	        postNotificationName:CPWindowDidBecomeKeyNotification
	                      object:self];
    }

    if(![_firstResponder swallowsKey])
 		[CPDOMEventDispatcher DOMFocusKeyWindow:YES];

}

/*!
    Determines if the window can become the key window.
    @return \c YES means the window can become the key window.
*/
- (BOOL)canBecomeKeyWindow
{
     return YES; 
}

/*!
    Returns \c YES if the window is the key window.
*/
- (BOOL)isKeyWindow
{
    return [CPApp keyWindow] == self;
}

/*!
    Makes the window the key window and brings it to the front of the screen list.
    @param aSender the object requesting this
*/
- (void)makeKeyAndOrderFront:(id)aSender
{	

	[self orderFront:self];
	[self makeKeyWindow]; 
    

}

/*!
    Makes this window the key window.
*/
- (void)makeKeyWindow
{
	if(CPApp._keyWindow !== self)
		[[CPApp keyWindow] resignKeyWindow];
    
    [self becomeKeyWindow];
}

/*!
    Causes the window to resign it's key window status.
*/
- (void)resignKeyWindow
{
    if (CPApp._keyWindow === self)
    {		
    	[_firstResponder resignFirstResponder];	
    	[CPDOMEventDispatcher DOMFocusKeyWindow:NO];
		
		

    	CPApp._keyWindow = nil; 

    	[[CPNotificationCenter defaultCenter]
        	postNotificationName:CPWindowDidResignKeyNotification
                      object:self];

    }

    
    
}



-(void) mouseDown:(CPEvent)theEvent
{
	[self makeKeyAndOrderFront:nil];

	[super mouseDown:theEvent];
}

-(void) mouseUp:(CPEvent)theEvent
{
	[self makeKeyWindow];

	[super mouseUp:theEvent];
}


- (void)orderOut:(id)aSender
{
	if(self === CPApp._mainWindow)
	{
		return; 
	}
	
 	[[CPNotificationCenter defaultCenter] postNotificationName:CPWindowWillCloseNotification object:self];

 	
 	if(_DOMWindowModalOverlay)
		_DOMWindowModalOverlay.detach(); 
	if(_toolbarOverlay)
		_toolbarOverlay.detach(); 


	[self setVisible:NO];
	
	if(CPApp._keyWindow === self)
    	[CPApp._mainWindow makeKeyWindow];
 
}


-(void) _attachSheet:(CPWindow)aSheet modalDelegate:(id)modalDelegate didEndSelector:(SEL)aSelector contextInfo:(id)contextInfo
{
 	if(!_sheetAttached)
	{

		[[CPNotificationCenter defaultCenter] postNotificationName:CPWindowWillBeginSheetNotification object:self];

		aSheet._sheetContext = {};
		aSheet._sheetContext.initStyleMask = [aSheet styleMask];
		aSheet._sheetContext.didEndSelector = aSelector;
		aSheet._sheetContext.modalDelegate = modalDelegate; 
		aSheet._sheetContext.contextInfo = contextInfo;
		aSheet._sheetContext.window = self; 
		
		aSheet._isSheet = YES; 
		self._sheet = aSheet;
		
		_sheetAttached = YES; 

		[aSheet setStyleMask:CPBorderlessWindowMask|CPStaticWindowMask];
		
		aSheet._DOMElement.detach(); 
		
		
		
		aSheet._DOMElement.appendTo(contentView._DOMElement);
		
		var frame = [self frame],
			sframe = [aSheet frame];
			
		var cv = [aSheet contentView];
		
		[aSheet setFrameOrigin:CGPointMake((frame.size.width - sframe.size.width)/2, -sframe.size.height)]; 
		
		[aSheet orderFront:nil];
		
		contentView._DOMElement.append(aSheet._DOMWindowModalOverlay);
	 
		
		if(_toolbar)
			aSheet._toolbarOverlay = $("<div></div>").addClass("cpmodal-overlay");
			
		if(aSheet._toolbarOverlay)
			_toolbar._itemsView._DOMElement.append(aSheet._toolbarOverlay);

		cv._DOMElement.addClass("cpwindow-sheet");
		cv._DOMElement.append($("<div></div>").addClass("cpwindow-sheet-topshadow"));
		
		aSheet._DOMElement.animate({
			top : 0
		}, 250, function(){
			[aSheet setFrameOrigin:CGPointMake((frame.size.width - sframe.size.width)/2, 0)];
			aSheet._isVisible = YES;
			
			if(_DOMElement)
				_DOMElement.css("overflow", "visible");
			if(_DOMWindowContentDiv)
				_DOMWindowContentDiv.css("overflow", "visible");
				
			contentView._DOMElement.css("overflow", "visible");
			
			[aSheet makeKeyWindow];
		});  
		
		
	 
	}

}

-(void) _detachSheet
{
	if(_sheetContext && _sheetContext.window)
	{ 
	 	_sheetContext.window.contentView._DOMElement.css("overflow", "hidden");
		
		if(_sheetContext.window._DOMWindowContentDiv)
			_sheetContext.window._DOMWindowContentDiv.css("overflow", "hidden");
			
		if(_sheetContext.window._DOMElement)
			_sheetContext.window._DOMElement.css("overflow", "hidden");
		
		var cvframe = [contentView frame];
		
		_DOMElement.animate({
			top : -cvframe.size.height
		}, 250, function(){

			[self setFrameOrigin:CGPointMake(0, -cvframe.size.height)]; 
			[self orderOut:nil];
			[self setStyleMask:_sheetContext.initStyleMask];
			
			
			contentView._DOMElement.children(".cpwindow-sheet-topshadow").detach(); 
			_DOMElement.detach();
			$("#CPWindowToolbarAndContent").append(_DOMElement);
			
			
			_sheetContext.window._sheetAttached = NO;
			_sheetContext.window._sheet = nil; 
			_isSheet = NO; 

			var target = _sheetContext.modalDelegate;
			var action = _sheetContext.didEndSelector;
			var returnCode = _sheetContext.returnCode;
			var contextInfo = _sheetContext.contextInfo; 

			[[CPNotificationCenter defaultCenter] postNotificationName:CPWindowDidEndSheetNotification object:_sheetContext.window];
			
			if(action)
				[target performSelector:action withObjects:self, returnCode, contextInfo];
		 	
			[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
		 	
			_sheetContext = null; 

		});

		CPApp._keyWindow = CPApp._mainWindow; 
	}


} 


-(CPView) hitTest:(CGPoint)aPoint 
{
	var view = [contentView hitTest:aPoint];

 	if(!view && _toolbar) //hit test check toolbar
	 	view = [_toolbar._itemsView hitTest:aPoint]
  
	return view; 
}


- (void)_dirtyKeyViewLoop
{
    if (_autorecalculatesKeyViewLoop)
        _keyViewLoopIsDirty = YES;
}

/*
    Recursively traverse an array of views (depth last) until we find one that has a next or previous key view set. Return nil if none can be found.

    We don't use _viewsSortedByPosition here because it is wasteful to enumerate the entire view hierarchy when we will probably find a key view at the top level.
*/
- (BOOL)_hasKeyViewLoop:(CPArray)theViews
{
    var i,
        count = [theViews count];

    for (i = 0; i < count; ++i)
    {
        var view = theViews[i];

        if ([view nextKeyView] || [view previousKeyView])
            return YES;
    }

    for (i = 0; i < count; ++i)
    {
        var subviews = [theViews[i] subviews];

        if ([subviews count] && [self _hasKeyViewLoop:subviews])
            return YES;
    }

    return NO;
}

/*!
    Recalculates the key view loop, based on geometric position.
    Note that the Cocoa documentation says that this method only marks the loop
    as dirty, the recalculation is not done until the next or previous key view
    of the window is requested. In reality, Cocoa does recalculate the loop
    when this method is called.
*/
- (void)recalculateKeyViewLoop
{
    [self _doRecalculateKeyViewLoop];
}

- (CPArray)_viewsSortedByPosition
{
    var views = [CPArray arrayWithObject:contentView];

    views = views.concat([self _subviewsSortedByPosition:[contentView subviews]]);

    if(_toolbar)
    {
    	views = views.concat([self _subviewsSortedByPosition:[_toolbar._itemsView subviews]]);
    }

    return views;
}

- (CPArray)_subviewsSortedByPosition:(CPArray)theSubviews
{
    /*
        We first sort the subviews according to geometric order.
        Then we go through each subview, and if it has subviews,
        they are sorted and inserted after the superview. This
        is done recursively.
    */
    theSubviews = [theSubviews copy];
    [theSubviews sortUsingFunction:keyViewComparator context:nil];

    var sortedViews = [];

    for (var i = 0, count = [theSubviews count]; i < count; ++i)
    {
        var view = theSubviews[i],
            subviews = [view subviews];

        sortedViews.push(view);

        if ([subviews count])
            sortedViews = sortedViews.concat([self _subviewsSortedByPosition:subviews]);
    }

    return sortedViews;
}

- (void)_doRecalculateKeyViewLoop
{	

    var views = [self _viewsSortedByPosition];

    for (var index = 0, count = [views count]; index < count; ++index)
    	[views[index] setNextKeyView:views[(index + 1) % count]];
     
     
    _keyViewLoopIsDirty = NO;
}

- (void)setAutorecalculatesKeyViewLoop:(BOOL)shouldRecalculate
{
    if (_autorecalculatesKeyViewLoop === shouldRecalculate)
        return;

    _autorecalculatesKeyViewLoop = shouldRecalculate;
}

- (BOOL)autorecalculatesKeyViewLoop
{
    return _autorecalculatesKeyViewLoop;
}

- (void)selectNextKeyView:(id)sender
{
    if (_keyViewLoopIsDirty)
        [self _doRecalculateKeyViewLoop];

    var nextValidKeyView = nil;
    
    if ([_firstResponder isKindOfClass:[CPView class]])
        nextValidKeyView = [_firstResponder nextValidKeyView];
	
	 
	if (nextValidKeyView)
    	[self makeFirstResponder:nextValidKeyView];
}

- (void)selectPreviousKeyView:(id)sender
{
    if (_keyViewLoopIsDirty)
        [self _doRecalculateKeyViewLoop];

    var previousValidKeyView = nil;

    if ([_firstResponder isKindOfClass:[CPView class]])
        previousValidKeyView = [_firstResponder previousValidKeyView];

    if (!previousValidKeyView)
    {
        if ([_initialFirstResponder acceptsFirstResponder])
            previousValidKeyView = _initialFirstResponder;
        else
            previousValidKeyView = [_initialFirstResponder previousValidKeyView];
    }

    if (previousValidKeyView)
        [self makeFirstResponder:previousValidKeyView];
}

- (void)selectKeyViewFollowingView:(CPView)aView
{
    if (_keyViewLoopIsDirty)
        [self _doRecalculateKeyViewLoop];

    var nextValidKeyView = [aView nextValidKeyView];

    if ([nextValidKeyView isKindOfClass:[CPView class]])
        [self makeFirstResponder:nextValidKeyView];
}

- (void)selectKeyViewPrecedingView:(CPView)aView
{
    if (_keyViewLoopIsDirty)
        [self _doRecalculateKeyViewLoop];

    var previousValidKeyView = [aView previousValidKeyView];

    if ([previousValidKeyView isKindOfClass:[CPView class]])
        [self makeFirstResponder:previousValidKeyView];
}

@end


var CPWindowContentViewKey = 		@"CPWindowContentViewKey",
	CPWindowTitleKey	=			@"CPWindowTitleKey",
	CPWindowStyleMaskKey = 			@"CPWindowStyleMaskKey",
	CPWindowMinSizeKey	=			@"CPWindowMinSizeKey",
	CPWindowMaxSizeKey	=			@"CPWindowMaxSizeKey",
	CPWindowInitFrameKey	=		@"CPWindowInitFrameKey";


@implementation CPWindow (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
	
        _initFrame = [aCoder decodeRectForKey:CPWindowInitFrameKey];
		contentView = [aCoder decodeObjectForKey:CPWindowContentViewKey];
		[contentView _setWindow:self];
		[contentView setNextResponder:self];
		
		[self _init];
		
		_minSize = [aCoder decodeSizeForKey:CPWindowMinSizeKey];
		_maxSize = [aCoder decodeSizeForKey:CPWindowMaxSizeKey];
		
	 	[self setTitle:[aCoder decodeObjectForKey:CPWindowTitleKey]];
	
		[self setStyleMask:[aCoder decodeIntForKey:CPWindowStyleMaskKey]];
	 

    }

    return self;
}

/*
    Archives the control to the provided coder.

    @param aCoder the coder to which the control will be archived.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
 		[super encodeWithCoder:aCoder];
		
		[aCoder encodeObject:contentView forKey:CPWindowContentViewKey];
		[aCoder encodeObject:_title forKey:CPWindowTitleKey];
		[aCoder encodeInt:_styleMask forKey:CPWindowStyleMaskKey];
		[aCoder encodeSize:_minSize forKey:CPWindowMinSizeKey];
		[aCoder encodeSize:_maxSize forKey:CPWindowMaxSizeKey];
		[aCoder encodeRect:_initFrame forKey:CPWindowInitFrameKey];
 
}

 

@end 


var keyViewComparator = function(lhs, rhs, context)
{
    var lhsBounds = [lhs convertRect:[lhs bounds] toView:nil],
        rhsBounds = [rhs convertRect:[rhs bounds] toView:nil],
        lhsY = CGRectGetMinY(lhsBounds),
        rhsY = CGRectGetMinY(rhsBounds),
        lhsX = CGRectGetMinX(lhsBounds),
        rhsX = CGRectGetMinX(rhsBounds),
        intersectsVertically = MIN(CGRectGetMaxY(lhsBounds), CGRectGetMaxY(rhsBounds)) - MAX(lhsY, rhsY);

    // If two views are "on the same line" (intersect vertically), then rely on the x comparison.
    if (intersectsVertically > 0)
    {
        if (lhsX < rhsX)
            return CPOrderedAscending;

        if (lhsX === rhsX)
            return CPOrderedSame;

        return CPOrderedDescending;
    }

    if (lhsY < rhsY)
        return CPOrderedAscending;

    if (lhsY === rhsY)
        return CPOrderedSame;

    return CPOrderedDescending;
};