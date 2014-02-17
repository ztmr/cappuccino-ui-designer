@import <Foundation/CPArray.j>
@import <Foundation/CPObjJRuntime.j>
@import <Foundation/CPSet.j>
@import <Foundation/CPGeometry.j>

@import "CGAffineTransform.j"
@import "CGContext.j"
@import "CPColor.j"
@import "CPDOMEventDispatcher.j"



/*
    @global
    @group CPViewAutoresizingMasks
    The default resizingMask, the view will not resize or reposition itself.
*/
CPViewNotSizable    = 0;
/*
    @global
    @group CPViewAutoresizingMasks
    Allow for flexible space on the left hand side of the view.
*/
CPViewMinXMargin    = 1;
/*
    @global
    @group CPViewAutoresizingMasks
    The view should grow and shrink horizontally with its parent view.
*/
CPViewWidthSizable  = 2;
/*
    @global
    @group CPViewAutoresizingMasks
    Allow for flexible space to the right hand side of the view.
*/
CPViewMaxXMargin    = 4;
/*
    @global
    @group CPViewAutoresizingMasks
    Allow for flexible space above the view.
*/
CPViewMinYMargin    = 8;
/*
    @global
    @group CPViewAutoresizingMasks
    The view should grow and shrink vertically with its parent view.
*/
CPViewHeightSizable = 16;
/*
    @global
    @group CPViewAutoresizingMasks
    Allow for flexible space below the view.
*/
CPViewMaxYMargin    = 32;

CPViewBoundsDidChangeNotification   = @"CPViewBoundsDidChangeNotification";
CPViewFrameDidChangeNotification    = @"CPViewFrameDidChangeNotification";


var CPThemeStateNormal          = @"normal",
	CPThemeStateDisabled        = @"disabled",
	CPThemeStateHovered         = @"hovered",
	CPThemeStateHighlighted     = @"highlighted",
	CPThemeStateSelected		= @"selected";


var DOMElementPrototype         = nil;


@implementation CPView : CPResponder
{
  
    CPView                  _superview;
    CPArray                 _subviews;

    CPWindow                _window  

    CPGraphicsContext       _graphicsContext @accessors(getter=graphicsContext);
    DOMElement              _canvasElement;

    int                     _tag @accessors(property=tag);
    CPString                _identifier @accessors(property=identifier);

    CGRect                  _frame;
    CGRect                  _bounds;
    CGRect                  _dirtyRect; 
	CGAffineTransform       _boundsTransform;
    CGAffineTransform       _inverseBoundsTransform;
    
    BOOL                    _isHidden;
    BOOL                    _hitTests; 

    BOOL                    _postsFrameChangedNotifications; 
    BOOL                    _postsBoundsChangedNotifications;
	BOOL				    _inhibitFrameAndBoundsChangedNotifications;  
     
    float                   _opacity;
    CPColor                 _backgroundColor;

    BOOL                    _autoresizesSubviews;
    unsigned                _autoresizingMask;

    
    // Layout Support
    BOOL                    _needsLayout;
    
      
    // Key View Support : TODO
    CPView                    _nextKeyView @accessors(getter=nextKeyView);
    CPView                    _previousKeyView @accessors(getter=previousKeyView);

    // ToolTips
    CPString                _toolTip    @accessors(getter=toolTip);

	//theme
	CPDictionary			_themeAttributes @accessors(property=themeAttributes); 
	CPString				_themeState;

    CPSet                   _ephemeralSubviews;

    DOMElement              _DOMElement; 
     

}

+ (void)initialize
{
    if (self !== [CPView class])
        return;

 
    DOMElementPrototype = $("<div></div>").addClass("cpview");
 
    
}

- (id)init
{
    return [self initWithFrame:CGRectMakeZero()];
}
 
/*!
    Initializes the receiver for usage with the specified bounding rectangle
    @return the initialized view
*/
- (id)initWithFrame:(CGRect)aFrame
{
    self = [super init];

    if (self)
    {
        var width = CGRectGetWidth(aFrame),
            height = CGRectGetHeight(aFrame);

        _subviews = [];
        _ephemeralSubviews = [CPSet set];
         
        _tag = -1;

        _frame = CGRectMakeCopy(aFrame);
        _bounds = CGRectMake(0.0, 0.0, width, height);

        _autoresizingMask = CPViewNotSizable;
        _autoresizesSubviews = YES;
        _postsFrameChangedNotifications = YES;
        _postsBoundsChangedNotifications = YES; 
        _inhibitFrameAndBoundsChangedNotifications = NO; 
        
        _opacity = 1.0;
        _isHidden = NO;
        _hitTests = YES;

        _nextKeyView = nil; 
    
        _DOMElement = DOMElementPrototype.clone(false);

        _DOMElement.css({
			left : CGRectGetMinX(aFrame),
			top : CGRectGetMinY(aFrame),
			width : width,
			height : height
		}); 

        _DOMElement.bind("mouseout mouseover", function(evt){
            [CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:self];
        });

        _themeState = CPThemeStateNormal;

        [self _loadThemeAttributes];
     
    }

    return self;
}

-(void) setToolTip:(CPString)aToolTip
{
    _toolTip = aToolTip;

    if(_toolTip)
        _DOMElement.attr("title", _toolTip);
    else
        _DOMElement.removeAttr("title");
}

/*!
    Returns the container view of the receiver
    @return the receiver's containing view
*/
- (CPView)superview
{
    return _superview;
}

/*!
    Returns an array of all the views contained as direct children of the receiver
    @return an array of CPViews
*/
- (CPArray)subviews
{
    return [_subviews copy];
}

/*!
    Returns the window containing this receiver
*/
- (CPWindow)window
{   
    return _window;
}
 
 
-(void) _setWindow:(CPWindow)aWindow
{
	if (_window === aWindow)
        return;
  
    _window = aWindow;

    var count = [_subviews count];

    while (count--)
        [_subviews[count] _setWindow:aWindow];
}

/*!
    Makes the argument a subview of the receiver.
    @param aSubview the CPView to make a subview
*/
- (void)addSubview:(CPView)aSubview
{    
    [self _insertSubview:aSubview atIndex:CPNotFound];
}


/* @ignore */
- (void)_insertSubview:(CPView)aSubview atIndex:(int)anIndex
{    

    if (aSubview === self)
        [CPException raise:CPInvalidArgumentException reason:"can't add a view as a subview of itself"];
 
    if (!aSubview._superview && _subviews.indexOf(aSubview) !== CPNotFound)
        [CPException raise:CPInvalidArgumentException reason:"can't insert a subview in duplicate (probably partially decoded)"];

    // We will have to adjust the z-index of all views starting at this index.
    var count = _subviews.length;

    // Dirty the key view loop, in case the window wants to auto recalculate it
    //[[self window] _dirtyKeyViewLoop];

    [aSubview setNextResponder:self]; 
 
    // If this is already one of our subviews, remove it.
    if (aSubview._superview == self)
    {
        var index = [_subviews indexOfObjectIdenticalTo:aSubview];

        // FIXME: should this be anIndex >= count? (last one)
        if (index === anIndex || index === count - 1 && anIndex === count)
            return;

        [_subviews removeObjectAtIndex:index];

 		aSubview._DOMElement.detach(); 
   
        if (anIndex > index)
            --anIndex;

        //We've effectively made the subviews array shorter, so represent that.
        --count;
    }
    else
    {
        // Remove the view from its previous superview.
        [aSubview removeFromSuperview];

        // Set the subview's window to our own.
        [aSubview _setWindow:_window];

        // Notify the subview that it will be moving.
        [aSubview viewWillMoveToSuperview:self];

        // Set ourselves as the superview.
        aSubview._superview = self;
    }

    if (anIndex === CPNotFound || anIndex >= count)
    {
        _subviews.push(aSubview);

 		// Attach the actual node.
		_DOMElement.append(aSubview._DOMElement); 
  
    }
    else
    {
        _subviews.splice(anIndex, 0, aSubview);
        // Attach the actual node.
		aSubview._DOMElement.insertBefore(_subviews[anIndex + 1]._DOMElement);
    }

    var bw = [self borderWidth];  //this is a fix for the way browser positions items relative to border
 
    aSubview._DOMElement.css({
        left : aSubview._frame.origin.x - bw,
        top : aSubview._frame.origin.y - bw
    });



	[aSubview setNeedsLayout];
    [aSubview setNeedsDisplay:YES];
       
    [aSubview viewDidMoveToSuperview];
	
    [self didAddSubview:aSubview];
}

 

/*!
    Called when the receiver has added \c aSubview to it's child views.
    @param aSubview the view that was added
*/
- (void)didAddSubview:(CPView)aSubview
{
}

/*!
    Removes the receiver from it's container view and window.
    Does nothing if there's no container view.
*/
- (void)removeFromSuperview
{
    if (!_superview)
        return;

    // Dirty the key view loop, in case the window wants to auto recalculate it
    //[[self window] _dirtyKeyViewLoop];

    [_superview willRemoveSubview:self];

    [_superview._subviews removeObjectIdenticalTo:self];

	_DOMElement.detach();  
 
    _superview = nil;

    [self _setWindow:nil];
}

/*!
    Replaces the specified child view with another view
    @param aSubview the view to replace
    @param aView the replacement view
*/
- (void)replaceSubview:(CPView)aSubview with:(CPView)aView
{
    if (aSubview._superview !== self)
        return;

    var index = [_subviews indexOfObjectIdenticalTo:aSubview];

    [aSubview removeFromSuperview];

    [self _insertSubview:aView atIndex:index];
}


/*!
    Called when the receiver's superview has changed.
*/
- (void)viewDidMoveToSuperview
{
	if (_graphicsContext)
        [self setNeedsDisplay:YES];
}

/*!
    Called when the receiver has been moved to a new CPWindow.
*/
- (void)viewDidMoveToWindow
{
}

/*!
    Called when the receiver is about to be moved to a new view.
    @param aView the view to which the receiver will be moved
*/
- (void)viewWillMoveToSuperview:(CPView)aView
{
}

/*!
    Called when the receiver is about to be moved to a new window.
    @param aWindow the window to which the receiver will be moved.
*/
- (void)viewWillMoveToWindow:(CPWindow)aWindow
{
}

/*!
    Called when the receiver is about to remove one of its subviews.
    @param aView the view that will be removed
*/
- (void)willRemoveSubview:(CPView)aView
{
}


- (CPView)viewWithTag:(CPInteger)aTag
{
    if ([self tag] == aTag)
        return self;

    var index = 0,
        count = _subviews.length;

    for (; index < count; ++index)
    {
        var view = [_subviews[index] viewWithTag:aTag];

        if (view)
            return view;
    }

    return nil;
}


/*!
    Sets the frame size of the receiver to the dimensions and origin of the provided rectangle in the coordinate system
    of the superview. The method also posts a CPViewFrameDidChangeNotification to the notification
    center if the receiver is configured to do so. If the frame is the same as the current frame, the method simply
    returns (and no notification is posted).
    @param aFrame the rectangle specifying the new origin and size  of the receiver
*/
- (void)setFrame:(CGRect)aFrame
{
    if (CGRectEqualToRect(_frame, aFrame))
        return;

    _inhibitFrameAndBoundsChangedNotifications = YES;

    [self setFrameOrigin:aFrame.origin];
    [self setFrameSize:aFrame.size];

    _inhibitFrameAndBoundsChangedNotifications = NO;

    if (_postsFrameChangedNotifications)
        [[CPNotificationCenter defaultCenter] postNotificationName:CPViewFrameDidChangeNotification object:self];
}

/*!
    Returns the receiver's frame.
    @return a copy of the receiver's frame
*/
- (CGRect)frame
{
    return CGRectMakeCopy(_frame);
}

- (CGPoint)frameOrigin
{
    return CGPointMakeCopy(_frame.origin);
}

- (CGSize)frameSize
{
    return CGSizeMakeCopy(_frame.size);
}

/*!
    Moves the center of the receiver's frame to the provided point. The point is defined in the superview's coordinate system.
    The method posts a CPViewFrameDidChangeNotification to the default notification center if the receiver
    is configured to do so. If the specified origin is the same as the frame's current origin, the method will
    simply return (and no notification will be posted).
    @param aPoint the new origin point
*/
- (void)setCenter:(CGPoint)aPoint
{
    [self setFrameOrigin:CGPointMake(aPoint.x - _frame.size.width / 2.0, aPoint.y - _frame.size.height / 2.0)];
}

/*!
    Returns the center of the receiver's frame in the superview's coordinate system.
    @return CGPoint the center point of the receiver's frame
*/
- (CGPoint)center
{
    return CGPointMake(_frame.size.width / 2.0 + _frame.origin.x, _frame.size.height / 2.0 + _frame.origin.y);
}


/*!
    Sets the receiver's frame origin to the provided point. The point is defined in the superview's coordinate system.
    The method posts a CPViewFrameDidChangeNotification to the default notification center if the receiver
    is configured to do so. If the specified origin is the same as the frame's current origin, the method will
    simply return (and no notification will be posted).
    @param aPoint the new origin point
*/
- (void)setFrameOrigin:(CGPoint)aPoint
{
    var origin = _frame.origin;

    if (!aPoint || CGPointEqualToPoint(origin, aPoint))
        return;

    origin.x = aPoint.x;
    origin.y = aPoint.y;

    if (_postsFrameChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [[CPNotificationCenter defaultCenter] postNotificationName:CPViewFrameDidChangeNotification object:self];

 
    var transform = _superview ? _superview._boundsTransform : null;
	var p = CGPointApplyAffineTransform(origin, transform);

    var bw = _superview ? [_superview borderWidth] : 0;  //this is a fix for the way browser positions items relative to border

	_DOMElement.css({
		left : p.x - bw,
		top : p.y - bw 
	});
  
}

/*!
    Sets the receiver's frame size. If \c aSize is the same as the frame's current dimensions, this
    method simply returns. The method posts a CPViewFrameDidChangeNotification to the
    default notification center if the receiver is configured to do so.
    @param aSize the new size for the frame
*/
- (void)setFrameSize:(CGSize)aSize
{
    var size = _frame.size;

    if (!aSize || CGSizeEqualToSize(size, aSize))
        return;

    var oldSize = CGSizeMakeCopy(size);

    size.width = aSize.width;
    size.height = aSize.height;
    
    _bounds.size.width = aSize.width;
    _bounds.size.height = aSize.height; 

    if (_autoresizesSubviews)
        [self resizeSubviewsWithOldSize:oldSize];

    if(_graphicsContext)
    {  
        if(self._GCCreateTimer)
        {
            clearTimeout(self._GCCreateTimer);
            self._GCCreateTimer = null; 
        }

        self._GCCreateTimer = setTimeout(function(){
            [self _createGraphicsContext];
            [self display];
        }, 50);
    }

    [self setNeedsLayout];
    [self setNeedsDisplay:YES];
    
   
	_DOMElement.css({
		width : size.width,
		height : size.height
	});
 
    if (_postsFrameChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [[CPNotificationCenter defaultCenter] postNotificationName:CPViewFrameDidChangeNotification object:self];
}


/*!
    Sets the receiver's bounds. The bounds define the size and location of the receiver inside it's frame. Posts a
    CPViewBoundsDidChangeNotification to the default notification center if the receiver is configured to do so.
    @param bounds the new bounds
*/
- (void)setBounds:(CGRect)bounds
{
    if (CGRectEqualToRect(_bounds, bounds))
        return;

    _inhibitFrameAndBoundsChangedNotifications = YES;

    [self setBoundsOrigin:bounds.origin];
    [self setBoundsSize:bounds.size];

    _inhibitFrameAndBoundsChangedNotifications = NO;

    if (_postsBoundsChangedNotifications)
        [[CPNotificationCenter defaultCenter] postNotificationName:CPViewBoundsDidChangeNotification object:self];
}

/*!
    Returns the receiver's bounds. The bounds define the size
    and location of the receiver inside its frame.
*/
- (CGRect)bounds
{
    return CGRectMakeCopy(_bounds);
}

- (CGPoint)boundsOrigin
{
    return CGPointMakeCopy(_bounds.origin);
}

- (CGSize)boundsSize
{
    return CGSizeMakeCopy(_bounds.size);
}

/*!
    Sets the location of the receiver inside its frame. The method
    posts a CPViewBoundsDidChangeNotification to the
    default notification center if the receiver is configured to do so.
    @param aPoint the new location for the receiver
*/
- (void)setBoundsOrigin:(CGPoint)aPoint
{
    var origin = _bounds.origin;

    if (CGPointEqualToPoint(origin, aPoint))
        return;

    origin.x = aPoint.x;
    origin.y = aPoint.y;

    if (origin.x != 0 || origin.y != 0)
    {
        _boundsTransform = CGAffineTransformMakeTranslation(-origin.x, -origin.y);
        _inverseBoundsTransform = CGAffineTransformInvert(_boundsTransform);
    }
    else
    {
        _boundsTransform = nil;
        _inverseBoundsTransform = nil;
    }
 
    var index = _subviews.length;

    while (index--)
    {
        var view = _subviews[index],
            origin = view._frame.origin;
		
		var p = CGPointApplyAffineTransform(origin, _boundsTransform);	
		view._DOMElement.css({
			left : p.x,
			top : p.y
		}); 
    }
 
    if (_postsBoundsChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [[CPNotificationCenter defaultCenter] postNotificationName:CPViewBoundsDidChangeNotification object:self];
}


/*!
    Sets the receiver's size inside its frame. The method posts a
    CPViewBoundsDidChangeNotification to the default
    notification center if the receiver is configured to do so.
    @param aSize the new size for the receiver
*/
- (void)setBoundsSize:(CGSize)aSize
{
    var size = _bounds.size;

    if (CGSizeEqualToSize(size, aSize))
        return;

    var frameSize = _frame.size;

    if (!CGSizeEqualToSize(size, frameSize))
    {
        var origin = _bounds.origin;

        origin.x /= size.width / frameSize.width;
        origin.y /= size.height / frameSize.height;
    }

    size.width = aSize.width;
    size.height = aSize.height;

    if (!CGSizeEqualToSize(size, frameSize))
    {
        var origin = _bounds.origin;

        origin.x *= size.width / frameSize.width;
        origin.y *= size.height / frameSize.height;
    }

    if (_postsBoundsChangedNotifications && !_inhibitFrameAndBoundsChangedNotifications)
        [[CPNotificationCenter defaultCenter] postNotificationName:CPViewBoundsDidChangeNotification object:self];
}


/*!
    Notifies subviews that the superview changed size.
    @param aSize the size of the old superview
*/
- (void)resizeWithOldSuperviewSize:(CGSize)aSize
{
    var mask = [self autoresizingMask];

    if (mask == CPViewNotSizable)
        return;

    var frame = _superview._frame,
        newFrame = CGRectMakeCopy(_frame),
        dX = frame.size.width - aSize.width,
        dY = frame.size.height - aSize.height,
        evenFractionX = 1.0 / ((mask & CPViewMinXMargin ? 1 : 0) + (mask & CPViewWidthSizable ? 1 : 0) + (mask & CPViewMaxXMargin ? 1 : 0)),
        evenFractionY = 1.0 / ((mask & CPViewMinYMargin ? 1 : 0) + (mask & CPViewHeightSizable ? 1 : 0) + (mask & CPViewMaxYMargin ? 1 : 0)),
        baseX = (mask & CPViewMinXMargin    ? _frame.origin.x : 0) +
                (mask & CPViewWidthSizable  ? _frame.size.width : 0) +
                (mask & CPViewMaxXMargin    ? aSize.width - _frame.size.width - _frame.origin.x : 0),
        baseY = (mask & CPViewMinYMargin    ? _frame.origin.y : 0) +
                (mask & CPViewHeightSizable ? _frame.size.height : 0) +
                (mask & CPViewMaxYMargin    ? aSize.height - _frame.size.height - _frame.origin.y : 0);

    if (mask & CPViewMinXMargin)
        newFrame.origin.x += dX * (baseX > 0 ? _frame.origin.x / baseX : evenFractionX);

    if (mask & CPViewWidthSizable)
        newFrame.size.width += dX * (baseX > 0 ? _frame.size.width / baseX : evenFractionX);

    if (mask & CPViewMinYMargin)
        newFrame.origin.y += dY * (baseY > 0 ? _frame.origin.y / baseY : evenFractionY);

    if (mask & CPViewHeightSizable)
        newFrame.size.height += dY * (baseY > 0 ? _frame.size.height / baseY : evenFractionY);

    [self setFrame:newFrame];
}

/*!
    Initiates \c -superviewSizeChanged: messages to subviews.
    @param aSize the size for the subviews
*/
- (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
    var count = _subviews.length;

    while (count--)
        [_subviews[count] resizeWithOldSuperviewSize:aSize];
}

/*!
    Specifies whether the receiver view should automatically resize its
    subviews when its \c -setFrameSize: method receives a change.
    @param aFlag If \c YES, then subviews will automatically be resized
    when this view is resized. \c NO means the views will not
    be resized automatically.
*/
- (void)setAutoresizesSubviews:(BOOL)aFlag
{
    _autoresizesSubviews = !!aFlag;
}

/*!
    Reports whether the receiver automatically resizes its subviews when its frame size changes.
    @return \c YES means it resizes its subviews on a frame size change.
*/
- (BOOL)autoresizesSubviews
{
    return _autoresizesSubviews;
}

/*!
    Determines automatic resizing behavior.
    @param aMask a bit mask with options
*/
- (void)setAutoresizingMask:(unsigned)aMask
{
    _autoresizingMask = aMask;
}

/*!
    Returns the bit mask options for resizing behavior
*/
- (unsigned)autoresizingMask
{
    return _autoresizingMask;
}

/*!
    Sets whether the receiver should be hidden.
    @param aFlag \c YES makes the receiver hidden.
*/
- (void)setHidden:(BOOL)aFlag
{
    aFlag = !!aFlag;

    if (_isHidden === aFlag)
        return;

 
    _isHidden = aFlag;

	if(_isHidden)
	{
		_DOMElement.css("display", "none");
		[self _notifyViewDidHide];
	}else
	{
		_DOMElement.css("display", "block"); 
		[self setNeedsDisplay:YES];
        [self _notifyViewDidUnhide];
    }
}

- (void)_notifyViewDidHide
{
    [self viewDidHide];

    var count = [_subviews count];

    while (count--)
        [_subviews[count] _notifyViewDidHide];
}

- (void)_notifyViewDidUnhide
{
    [self viewDidUnhide];

    var count = [_subviews count];

    while (count--)
        [_subviews[count] _notifyViewDidUnhide];
}

/*!
    Returns \c YES if the receiver is hidden.
*/
- (BOOL)isHidden
{
    return _isHidden;
}


/*!
    Sets the opacity of the receiver. The value must be in the range of 0.0 to 1.0, where 0.0 is
    completely transparent and 1.0 is completely opaque.
    @param anAlphaValue an alpha value ranging from 0.0 to 1.0.
*/
- (void)setAlphaValue:(float)anAlphaValue
{
    if (_opacity == anAlphaValue)
        return;

    _opacity = anAlphaValue;

  	if (typeof _DOMElement[0].style.opacity != 'undefined')
    {
		_DOMElement.css("opacity", _opacity)
        
    }
    else
	{
		if (anAlphaValue === 1.0)
            try { _DOMElement.style.removeAttribute("filter") } catch (anException) { }
        else
            _DOMElement[0].style.filter = "alpha(opacity=" + anAlphaValue * 100 + ")";
	
	} 
}

/*!
    Returns the alpha value of the receiver. Ranges from 0.0 to
    1.0, where 0.0 is completely transparent and 1.0 is completely opaque.
*/
- (float)alphaValue
{
    return _opacity;
}

/*!
    Returns \c YES if the receiver is hidden, or one
    of it's ancestor views is hidden. \c NO, otherwise.
*/
- (BOOL)isHiddenOrHasHiddenAncestor
{
    var view = self;

    while (view && ![view isHidden])
        view = [view superview];

    return view !== nil;
}

/*!
    Returns YES if the view is not hidden, has no hidden ancestor and doesn't belong to a hidden window.
*/
- (BOOL)_isVisible
{
	return YES; 
    //return ![self isHiddenOrHasHiddenAncestor] && [[self window] isVisible];
}

/*!
    Called when the return value of isHiddenOrHasHiddenAncestor becomes YES,
    e.g. when this view becomes hidden due to a setHidden:YES message to
    itself or to one of its superviews.

    Note: in the current implementation, viewDidHide may be called multiple
    times if additional superviews are hidden, even if
    isHiddenOrHasHiddenAncestor was already YES.
*/
- (void)viewDidHide
{

}

/*!
    Called when the return value of isHiddenOrHasHiddenAncestor becomes NO,
    e.g. when this view stops being hidden due to a setHidden:NO message to
    itself or to one of its superviews.

    Note: in the current implementation, viewDidUnhide may be called multiple
    times if additional superviews are unhidden, even if
    isHiddenOrHasHiddenAncestor was already NO.
*/
- (void)viewDidUnhide
{

}

/*!
    Returns whether or not the view responds to hit tests.
    @return \c YES if this view listens to \c -hitTest messages, \c NO otherwise.
*/
- (BOOL)hitTests
{
    return _hitTests;
}

/*!
    Set whether or not the view should respond to hit tests.
    @param shouldHitTest should be \c YES if this view should respond to hit tests, \c NO otherwise.
*/
- (void)setHitTests:(BOOL)shouldHitTest
{
    _hitTests = !!shouldHitTest;
}

/*!
    Tests whether a point is contained within this view, or one of its subviews.
    @param aPoint the point to test
    @return returns the containing view, or nil if the point is not contained
*/
- (CPView)hitTest:(CGPoint)aPoint
{ 	
    
   if (_isHidden || !_hitTests || !CGRectContainsPoint(_frame, aPoint))
 		return nil;
 
    var view = nil,
        i = _subviews.length,
        adjustedPoint = CGPointMake(aPoint.x - CGRectGetMinX(_frame), aPoint.y - CGRectGetMinY(_frame));
		

    if (_inverseBoundsTransform)
        adjustedPoint = CGPointApplyAffineTransform(adjustedPoint, _inverseBoundsTransform);
 
    while (i--)
	{  
        view = [_subviews[i] hitTest:adjustedPoint]
        if (view !== nil)
            return view;
	}

    return self;
}



/*!
    Sets the background color of the receiver.
    @param aColor the new color for the receiver's background
*/
- (void)setBackgroundColor:(CPColor)aColor
{
    if (_backgroundColor == aColor)
        return;

    if (aColor == [CPNull null])
        aColor = nil;

    _backgroundColor = aColor;

 	if(_backgroundColor)
    {
		_DOMElement.css("background-color", [aColor cssString])
        if([aColor alphaComponent] === 0)
            _DOMElement.css("background-image", "none");
    }
}

/*!
    Returns the background color of the receiver
*/
- (CPColor)backgroundColor
{
    return _backgroundColor;
}

// Converting Coordinates
/*!
    Converts \c aPoint from the coordinate space of \c aView to the coordinate space of the receiver.
    @param aPoint the point to convert
    @param aView the view space to convert from
    @return the converted point
*/
- (CGPoint)convertPoint:(CGPoint)aPoint fromView:(CPView)aView
{
    return CGPointApplyAffineTransform(aPoint, _CPViewGetTransform(aView, self));
}

/*!
    Converts the point from the base coordinate system to the receiver’s coordinate system.
    @param aPoint A point specifying a location in the base coordinate system
    @return The point converted to the receiver’s base coordinate system
*/
- (CGPoint)convertPointFromBase:(CGPoint)aPoint
{
    return CGPointApplyAffineTransform(aPoint, _CPViewGetTransform(nil, self));
}

/*!
    Converts \c aPoint from the receiver's coordinate space to the coordinate space of \c aView.
    @param aPoint the point to convert
    @param aView the coordinate space to which the point will be converted
    @return the converted point
*/
- (CGPoint)convertPoint:(CGPoint)aPoint toView:(CPView)aView
{
    return CGPointApplyAffineTransform(aPoint, _CPViewGetTransform(self, aView));
}

/*!
    Converts the point from the receiver’s coordinate system to the base coordinate system.
    @param aPoint A point specifying a location in the coordinate system of the receiver
    @return The point converted to the base coordinate system
*/
- (CGPoint)convertPointToBase:(CGPoint)aPoint
{
    return CGPointApplyAffineTransform(aPoint, _CPViewGetTransform(self, nil));
}

/*!
    Convert's \c aSize from \c aView's coordinate space to the receiver's coordinate space.
    @param aSize the size to convert
    @param aView the coordinate space to convert from
    @return the converted size
*/
- (CGSize)convertSize:(CGSize)aSize fromView:(CPView)aView
{
    return CGSizeApplyAffineTransform(aSize, _CPViewGetTransform(aView, self));
}

/*!
    Convert's \c aSize from the receiver's coordinate space to \c aView's coordinate space.
    @param aSize the size to convert
    @param the coordinate space to which the size will be converted
    @return the converted size
*/
- (CGSize)convertSize:(CGSize)aSize toView:(CPView)aView
{
    return CGSizeApplyAffineTransform(aSize, _CPViewGetTransform(self, aView));
}

/*!
    Converts \c aRect from \c aView's coordinate space to the receiver's space.
    @param aRect the rectangle to convert
    @param aView the coordinate space from which to convert
    @return the converted rectangle
*/
- (CGRect)convertRect:(CGRect)aRect fromView:(CPView)aView
{
    return CGRectApplyAffineTransform(aRect, _CPViewGetTransform(aView, self));
}

/*!
    Converts the rectangle from the base coordinate system to the receiver’s coordinate system.
    @param aRect A rectangle specifying a location in the base coordinate system
    @return The rectangle converted to the receiver’s base coordinate system
*/
- (CGRect)convertRectFromBase:(CGRect)aRect
{
    return CGRectApplyAffineTransform(aRect, _CPViewGetTransform(nil, self));
}

/*!
    Converts \c aRect from the receiver's coordinate space to \c aView's coordinate space.
    @param aRect the rectangle to convert
    @param aView the coordinate space to which the rectangle will be converted
    @return the converted rectangle
*/
- (CGRect)convertRect:(CGRect)aRect toView:(CPView)aView
{
    return CGRectApplyAffineTransform(aRect, _CPViewGetTransform(self, aView));
}

/*!
    Converts the rectangle from the receiver’s coordinate system to the base coordinate system.
    @param aRect  A rectangle specifying a location in the coordinate system of the receiver
    @return The rectangle converted to the base coordinate system
*/
- (CGRect)convertRectToBase:(CGRect)aRect
{
    return CGRectApplyAffineTransform(aRect, _CPViewGetTransform(self, nil));
}

/*!
    Sets whether the receiver posts a CPViewFrameDidChangeNotification notification
    to the default notification center when its frame is changed. The default is \c NO.
    Methods that could cause a frame change notification are:
<pre>
setFrame:
setFrameSize:
setFrameOrigin:
</pre>
    @param shouldPostFrameChangedNotifications \c YES makes the receiver post
    notifications on frame changes (size or origin)
*/
- (void)setPostsFrameChangedNotifications:(BOOL)shouldPostFrameChangedNotifications
{
    shouldPostFrameChangedNotifications = !!shouldPostFrameChangedNotifications;

    if (_postsFrameChangedNotifications === shouldPostFrameChangedNotifications)
        return;

    _postsFrameChangedNotifications = shouldPostFrameChangedNotifications;
}

/*!
    Returns \c YES if the receiver posts a CPViewFrameDidChangeNotification if its frame is changed.
*/
- (BOOL)postsFrameChangedNotifications
{
    return _postsFrameChangedNotifications;
}

/*!
    Sets whether the receiver posts a CPViewBoundsDidChangeNotification notification
    to the default notification center when its bounds is changed. The default is \c NO.
    Methods that could cause a bounds change notification are:
<pre>
setBounds:
setBoundsSize:
setBoundsOrigin:
</pre>
    @param shouldPostBoundsChangedNotifications \c YES makes the receiver post
    notifications on bounds changes
*/
- (void)setPostsBoundsChangedNotifications:(BOOL)shouldPostBoundsChangedNotifications
{
    shouldPostBoundsChangedNotifications = !!shouldPostBoundsChangedNotifications;

    if (_postsBoundsChangedNotifications === shouldPostBoundsChangedNotifications)
        return;

    _postsBoundsChangedNotifications = shouldPostBoundsChangedNotifications;
}

/*!
    Returns \c YES if the receiver posts a
    CPViewBoundsDidChangeNotification when its
    bounds is changed.
*/
- (BOOL)postsBoundsChangedNotifications
{
    return _postsBoundsChangedNotifications;
}


// Displaying

/*!
    Marks the entire view as dirty, and needing a redraw.
*/
- (void)setNeedsDisplay:(BOOL)aFlag
{
    if (aFlag)
        [self setNeedsDisplayInRect:[self bounds]];
}

/*!
    Marks the area denoted by \c aRect as dirty, and initiates a redraw on it.
    @param aRect the area that needs to be redrawn
*/
- (void)setNeedsDisplayInRect:(CGRect)aRect
{
    if (![self respondsToSelector:@selector(drawRect:)])
        return;

    if (CGRectIsEmpty(aRect))
        return;

    if (_dirtyRect && !CGRectIsEmpty(_dirtyRect))
        _dirtyRect = CGRectUnion(aRect, _dirtyRect);
    else
        _dirtyRect = CGRectMakeCopy(aRect);

    if(!_graphicsContext)
        [self _createGraphicsContext];

    _CPDisplayServerAddDisplayObject(self);
}

-(void) _createGraphicsContext
{   
    if(_canvasElement)
        $(_canvasElement).remove(); 

    _canvasElement = document.createElement("canvas");
    var sz = _frame.size;
    _canvasElement.width = sz.width;
    _canvasElement.height = sz.height;

    _DOMElement.append($(_canvasElement));

    _graphicsContext = _canvasElement.getContext("2d");
}

- (BOOL)needsDisplay
{
    return _dirtyRect && !CGRectIsEmpty(_dirtyRect);
}

/*!
    Draws the entire area of the receiver as defined by its \c -bounds.
*/
- (void)display
{
    [self displayRect:[self visibleRect]];
}

-(void) displayRect:(CGRect)aRect
{   

    if([self respondsToSelector:@selector(drawRect:)])
    {
        if(_graphicsContext)
        {
            _graphicsContext.clearRect(aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height);
        }

        [self drawRect:aRect]; 

    } 
}

-(void) displayIfNeeded
{
    if([self needsDisplay])
        [self display];
}

- (void)setNeedsLayout
{
    _needsLayout = YES; 

    _CPDisplayServerAddLayoutObject(self);
}

- (void)layoutIfNeeded
{
    if (_needsLayout)
    {  
        _needsLayout = NO;

        [self layoutSubviews];
    }
}

- (void)layoutSubviews
{
}




/*!
    Returns the rectangle of the receiver not clipped by its superview.
*/
- (CGRect)visibleRect
{
    if (!_superview)
        return _bounds;

    return CGRectIntersection([self convertRect:[_superview visibleRect] fromView:_superview], _bounds);
}

-(double)borderWidth
{
    return [self valueForThemeAttribute:@"border-width"];
}



-(void) setBorderWidth:(double)borderWidth 
{   
    if([self borderWidth] === borderWidth)
        return;

    [self setValue:borderWidth forThemeAttribute:@"border-width"];

    _DOMElement.css("border-width", borderWidth);

    var count = _subviews.length, //DOM fix
        i = 0;

    for(; i < count; i++)
        _subviews[i]._DOMElement.css({
            left : _subviews[i]._frame.origin.x - borderWidth,
            top : _subviews[i]._frame.origin.y - borderWidth
        });
}

-(CPColor) borderColor
{
    return [self valueForThemeAttribute:@"border-color"];
}

-(void) setBorderColor:(CPColor)aColor 
{
     if([[self borderColor] isEqual:aColor])
        return;

    [self setValue:aColor forThemeAttribute:@"border-color"];

    _DOMElement.css("border-color", [aColor cssString]);
}



@end

@implementation CPView (CPTheming)

 

- (void)setValue:(id)aValue forThemeAttribute:(CPString)aName
{
    var currentValue = [self valueForThemeAttribute:aName];

    if(aValue !== nil)
        [_themeAttributes setObject:aValue forKey:aName];

    if ([self valueForThemeAttribute:aName] === currentValue)
        return; 

    [self setNeedsDisplay:YES];
    [self setNeedsLayout];
}

- (id)valueForThemeAttribute:(CPString)aName
{
    return [_themeAttributes objectForKey:aName];
}

-(void) removeCSSStyle:(CPString)className
{
    _DOMElement.removeClass(className)
}

-(void) addCSSStyle:(CPString)className 
{
     _DOMElement.addClass(className);
}

-(void) setThemeState:(CPString)state
{
    if(!_DOMElement.hasClass(state))
    {
	   _DOMElement.addClass(state);
	   _themeState = _DOMElement.attr("class");
     
    }
}

-(void) unsetThemeState:(CPString)state
{
	if(_DOMElement.hasClass(state))
    { 
	   _DOMElement.removeClass(state);
	   _themeState = _DOMElement.attr("class");
       
    }
}

- (BOOL)hasThemeAttribute:(CPString)aName
{
    return (_themeAttributes && _themeAttributes[aName] !== undefined);
}


-(BOOL) hasThemeState:(CPString)state
{
	return _DOMElement.hasClass(state);
}

-(void) _loadThemeAttributes
{
    var theClass = [self class];
    
    _themeAttributes = [[CPApp theme] defaultThemeAttributesForClass:class_getName(theClass)];
        
    if(!_themeAttributes)
        _themeAttributes = [CPDictionary dictionary];

    var superClass  = [theClass superclass];

    while([superClass isKindOfClass:[CPView class]])
    {
        var superclassThemeAttr =  [[CPApp theme] defaultThemeAttributesForClass:class_getName(superClass)];
        if(superclassThemeAttr)
        {
            var attr = [superclassThemeAttr allKeys],
                count = attr.length,
                i = 0;

            for(; i < count; i++)
            {
                if(![_themeAttributes containsKey:attr[i]])
                    [_themeAttributes setValue:[superclassThemeAttr objectForKey:attr[i]] forKey:attr[i]]; 
            }
        }

        superClass = [superClass superclass];
    }
}


@end


@implementation CPView (KeyView)

/*!
    Overridden by subclasses to handle a key equivalent.

    If the receiver’s key equivalent is the same as the characters of the key-down event theEvent,
    as returned by \ref CPEvent::charactersIgnoringModifiers "[anEvent charactersIgnoringModifiers]",
    the receiver should take the appropriate action and return \c YES. Otherwise, it should return
    the result of invoking super’s implementation. The default implementation of this method simply
    passes the message down the view hierarchy (from superviews to subviews)
    and returns \c NO if none of the receiver’s subviews responds \c YES.

    @param anEvent An event object that represents the key equivalent pressed
    @return \c YES if theEvent is a key equivalent that the receiver handled,
            \c NO if it is not a key equivalent that it should handle.
 
- (BOOL)performKeyEquivalent:(CPEvent)anEvent
{
    var count = [_subviews count];

    // Is reverse iteration correct here? It matches the other (correct) code like hit testing.
    while (count--)
        if ([_subviews[count] performKeyEquivalent:anEvent])
            return YES;

    return NO;
}*/

- (BOOL)canBecomeKeyView
{
    return [self acceptsFirstResponder] && ![self isHiddenOrHasHiddenAncestor];
}

- (CPView)nextKeyView
{
    return _nextKeyView;
}

- (CPView)nextValidKeyView
{
    var result = [self nextKeyView],
        resultUID = [result UID],
        unsuitableResults = {};

    while (result && ![result canBecomeKeyView])
    {
        unsuitableResults[resultUID] = 1;
        result = [result nextKeyView];

        resultUID = [result UID];

        // Did we get back to a key view we already ruled out due to ![result canBecomeKeyView]?
        if (unsuitableResults[resultUID])
            return nil;
    }

    return result;
}

- (CPView)previousKeyView
{
    return _previousKeyView;
}

- (CPView)previousValidKeyView
{
    var result = [self previousKeyView],
        firstResult = result;

    while (result && ![result canBecomeKeyView])
    {
        result = [result previousKeyView];

        // Cycled.
        if (result === firstResult)
            return nil;
    }

    return result;
}

- (void)_setPreviousKeyView:(CPView)previous
{
    if (![previous isEqual:self])
    {
        var previousWindow = [previous window];

        if (!previousWindow || previousWindow === _window)
        {
            _previousKeyView = previous;
            return;
        }
    }

    _previousKeyView = nil;
}

- (void)setNextKeyView:(CPView)next
{
    if (![next isEqual:self])
    {
        var nextWindow = [next window];

        if (!nextWindow || nextWindow === _window)
        {
            _nextKeyView = next;
            [_nextKeyView _setPreviousKeyView:self];
            return;
        }
    }

    _nextKeyView = nil;
}

@end

var CPViewAutoresizingMaskKey       = @"CPViewAutoresizingMask",
    CPViewAutoresizesSubviewsKey    = @"CPViewAutoresizesSubviews",
    CPViewBackgroundColorKey        = @"CPViewBackgroundColor",
    CPViewBoundsKey                 = @"CPViewBoundsKey",
    CPViewFrameKey                  = @"CPViewFrameKey",
    CPViewHitTestsKey               = @"CPViewHitTestsKey",
    CPViewToolTipKey                = @"CPViewToolTipKey",
    CPViewIsHiddenKey               = @"CPViewIsHiddenKey",
    CPViewOpacityKey                = @"CPViewOpacityKey",
    CPViewSubviewsKey               = @"CPViewSubviewsKey",
    CPViewSuperviewKey              = @"CPViewSuperviewKey",
    CPViewNextKeyViewKey            = @"CPViewNextKeyViewKey",
    CPViewTagKey                    = @"CPViewTagKey",
    CPViewThemeAttributesKey        = @"CPViewThemeAttributesKey",
    CPViewThemeStateKey             = @"CPViewThemeStateKey",
    CPViewWindowKey                 = @"CPViewWindowKey", 
    CPReuseIdentifierKey            = @"CPReuseIdentifierKey";

@implementation CPView (CPCoding)

/*!
    Initializes the view from an archive.
    @param aCoder the coder from which to initialize
    @return the initialized view
*/
- (id)initWithCoder:(CPCoder)aCoder
{
     
	self = [super initWithCoder:aCoder];
	
    if (self)
    {  
        _DOMElement = DOMElementPrototype.clone(false);

		_frame = [aCoder decodeRectForKey:CPViewFrameKey]; 
	 	_bounds = [aCoder decodeRectForKey:CPViewBoundsKey];
         
        _tag = [aCoder containsValueForKey:CPViewTagKey] ? [aCoder decodeIntForKey:CPViewTagKey] : -1;
		 
        _superview = [aCoder decodeObjectForKey:CPViewSuperviewKey];
        _window = [aCoder decodeObjectForKey:CPViewWindowKey];
	 	
        _autoresizingMask = [aCoder decodeIntForKey:CPViewAutoresizingMaskKey] || CPViewNotSizable;

        _autoresizesSubviews = ![aCoder containsValueForKey:CPViewAutoresizesSubviewsKey] || [aCoder decodeBoolForKey:CPViewAutoresizesSubviewsKey];
		
		_isHidden = [aCoder decodeBoolForKey:CPViewIsHiddenKey];
		_hitTests = [aCoder decodeBoolForKey:CPViewHitTestsKey];
		
		
        [self setToolTip:[aCoder decodeObjectForKey:CPViewToolTipKey]];
	 
		_subviews = [];
        _ephemeralSubviews = [CPSet set];
	 	
        var archivedSubviews = [aCoder decodeObjectForKey:CPViewSubviewsKey] || []; 
		/* add back archived subviews */
		var count = [archivedSubviews count],
            i = 0; 
	

		for(; i < count; i++)
        {  
            var view = archivedSubviews[i];
            view._superview = nil;  

		   [self addSubview:view];
        }


        _nextKeyView = [aCoder decodeObjectForKey:CPViewNextKeyViewKey];

		_themeAttributes = [aCoder decodeObjectForKey:CPViewThemeAttributesKey];
		_themeState = [aCoder decodeObjectForKey:CPViewThemeStateKey];
		
		_DOMElement.css({
			left : _frame.origin.x,
			top : _frame.origin.y,
			width :  _frame.size.width,
			height : _frame.size.height
		});

        _DOMElement.bind("mouseout mouseover", function(evt){
            [CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:self];
        });

        _themeAttributes = [aCoder decodeObjectForKey:CPViewThemeAttributesKey];

        [self setBackgroundColor:[aCoder decodeObjectForKey:CPViewBackgroundColorKey]];
       
    }

    return self;
}

/*!
    Archives the view to a coder.
    @param aCoder the object into which the view's data will be archived.
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    if (_tag !== -1)
        [aCoder encodeInt:_tag forKey:CPViewTagKey];

    [aCoder encodeRect:_frame forKey:CPViewFrameKey];
    [aCoder encodeRect:_bounds forKey:CPViewBoundsKey];

    // This will come out nil on the other side with decodeObjectForKey:
    [aCoder encodeConditionalObject:_window forKey:CPViewWindowKey];

    var count = [_subviews count],
        encodedSubviews = _subviews;

    if (count > 0 && [_ephemeralSubviews count] > 0)
    {
        encodedSubviews = [encodedSubviews copy];

        while (count--)
            if ([_ephemeralSubviews containsObject:encodedSubviews[count]])
                encodedSubviews.splice(count, 1);
    }

    if (encodedSubviews.length > 0)
        [aCoder encodeObject:encodedSubviews forKey:CPViewSubviewsKey];

    //This will come out nil on the other side with decodeObjectForKey:
    if (_superview !== nil)
        [aCoder encodeConditionalObject:_superview forKey:CPViewSuperviewKey];

    [aCoder encodeInt:_autoresizingMask forKey:CPViewAutoresizingMaskKey];  
    [aCoder encodeBool:_autoresizesSubviews forKey:CPViewAutoresizesSubviewsKey];

    [aCoder encodeObject:_backgroundColor forKey:CPViewBackgroundColorKey];
    [aCoder encodeBool:_hitTests forKey:CPViewHitTestsKey];
    [aCoder encodeFloat:_opacity forKey:CPViewOpacityKey];
    [aCoder encodeBool:_isHidden forKey:CPViewIsHiddenKey]; 
    [aCoder encodeObject:_toolTip forKey:CPViewToolTipKey];
    [aCoder encodeObject:_identifier forKey:CPReuseIdentifierKey];

    [aCoder encodeObject:_themeAttributes forKey:CPViewThemeAttributesKey];
	 
}

@end



var _CPViewGetTransform = function(/*CPView*/ fromView, /*CPView */ toView)
{
    var transform = CGAffineTransformMakeIdentity(),
        sameWindow = YES,
        fromWindow = nil,
        toWindow = nil;

    if (fromView)
    {
        var view = fromView;

        // FIXME: This doesn't handle the case when the outside views are equal.
        // If we have a fromView, "climb up" the view tree until
        // we hit the root node or we hit the toLayer.
        while (view && view != toView)
        {
            var frame = view._frame;

            transform.tx += CGRectGetMinX(frame);
            transform.ty += CGRectGetMinY(frame);

            if (view._boundsTransform)
            {
                CGAffineTransformConcatTo(transform, view._boundsTransform, transform);
            }

            view = view._superview;
        }

        // If we hit toView, then we're done.
        if (view === toView)
            return transform;

        else if (fromView && toView)
        {
            fromWindow = [fromView window];
            toWindow = [toView window];

            if (fromWindow && toWindow && fromWindow !== toWindow)
            {
                sameWindow = NO;

                var frame = [fromWindow frame];

                transform.tx += CGRectGetMinX(frame);
                transform.ty += CGRectGetMinY(frame);
            }
        }
    }

    // FIXME: For now we can do things this way, but eventually we need to do them the "hard" way.
    var view = toView;

    while (view)
    {
        var frame = view._frame;

        transform.tx -= CGRectGetMinX(frame);
        transform.ty -= CGRectGetMinY(frame);

        if (view._boundsTransform)
        {
            CGAffineTransformConcatTo(transform, view._inverseBoundsTransform, transform);
        }

        view = view._superview;
    }

    if (!sameWindow)
    {
        var frame = [toWindow frame];

        transform.tx -= CGRectGetMinX(frame);
        transform.ty -= CGRectGetMinY(frame);
    }
/*    var views = [],
        view = toView;

    while (view)
    {
        views.push(view);
        view = view._superview;
    }

    var index = views.length;

    while (index--)
    {
        var frame = views[index]._frame;

        transform.tx -= CGRectGetMinX(frame);
        transform.ty -= CGRectGetMinY(frame);
    }*/

    return transform;
};





