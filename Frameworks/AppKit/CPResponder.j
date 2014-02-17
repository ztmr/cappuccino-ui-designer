@import <Foundation/CPObject.j>
@import <Foundation/CPObjJRuntime.j>


var CPDeleteKeyCode         = 8;
var CPTabKeyCode            = 9;
var CPReturnKeyCode         = 13;
var CPEscapeKeyCode         = 27;
var CPSpaceKeyCode          = 32;
var CPPageUpKeyCode         = 33;
var CPPageDownKeyCode       = 34;
var CPLeftArrowKeyCode      = 37;
var CPUpArrowKeyCode        = 38;
var CPRightArrowKeyCode     = 39;
var CPDownArrowKeyCode      = 40;
var CPDeleteForwardKeyCode  = 46;


/*!
    @ingroup appkit
    @class CPResponder

    Subclasses of CPResonder can be part of the responder chain.
*/
@implementation CPResponder : CPObject
{
    // TODO ?: CPMenu      _menu;
    CPResponder 		_nextResponder;
}

// Changing the first responder
/*!
    Returns \c YES if the receiver is able to become the first responder. \c NO otherwise.
*/
- (BOOL)acceptsFirstResponder
{
    return NO;
}

/*!
    Notifies the receiver that it will become the first responder. The receiver can reject first
    responder if it returns \c NO. The default implementation always returns \c YES.
    @return \c YES if the receiver accepts first responder status.
*/
- (BOOL)becomeFirstResponder
{
    return YES;
}

/* Noftifies the window that they browser key focus is used by the view */

-(BOOL) swallowsKey 
{
    return NO; 
}

/*!
    Notifies the receiver that it has been asked to give up first responder status.
    @return \c YES if the receiver is willing to give up first responder status.
*/
- (BOOL)resignFirstResponder
{
    return YES;
}

// Setting the next responder
/*!
    Sets the receiver's next responder.
    @param aResponder the responder after the receiver
*/
- (void)setNextResponder:(CPResponder)aResponder
{
    _nextResponder = aResponder;
}

/*!
    Returns the responder after the receiver.
*/
- (CPResponder)nextResponder
{
    return _nextResponder;
}

-(void) mouseClicked:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

/*!
    Notifies the receiver that the user has clicked the mouse down in its area.
    @param anEvent contains information about the click
*/
- (void)mouseDown:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

/*!
    Notifies the receiver that the user has clicked the right mouse down in its area.
    @param anEvent contains information about the right click
*/
- (void)rightMouseDown:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

/*!
    Notifies the receiver that the user has initiated a drag
    over it. A drag is a mouse movement while the left button is down.
    @param anEvent contains information about the drag
*/
- (void)mouseDragged:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

/*!
    Notifies the receiver that the user has released the left mouse button.
    @param anEvent contains information about the release
*/
- (void)mouseUp:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

/*!
    Notifies the receiver that the user has released the right mouse button.
    @param anEvent contains information about the release
*/
- (void)rightMouseUp:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

/*!
    Notifies the receiver that the user has moved the mouse (with no buttons down).
    @param anEvent contains information about the movement
*/
- (void)mouseMoved:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

- (void)mouseEntered:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

/*!
    Notifies the receiver that the mouse exited the receiver's area.
    @param anEvent contains information about the exit
*/
- (void)mouseExited:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

/*!
    Notifies the receiver that the mouse scroll wheel has moved.
    @param anEvent information about the scroll
*/
- (void)scrollWheel:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

/*!
    Notifies the receiver that the user has pressed a key.
    @param anEvent information about the key press
*/
- (void)keyDown:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

/*!
    Notifies the receiver that the user has released a key.
    @param anEvent information about the key press
*/
- (void)keyUp:(CPEvent)anEvent
{
    [_nextResponder performSelector:_cmd withObject:anEvent];
}

// Dispatch methods
/*!
    The receiver will attempt to perform the command,
    if it responds to it. If not, the \c -nextResponder will be called to do it.
    @param aSelector the command to attempt
*/
- (void)doCommandBySelector:(SEL)aSelector
{
    if ([self respondsToSelector:aSelector])
        [self performSelector:aSelector];
    else
        [_nextResponder doCommandBySelector:aSelector];
}

/*!
    The receiver will attempt to perform the command, or pass it on to the next responder if it doesn't respond to it.
    @param aSelector the command to perform
    @param anObject the argument to the method
    @return \c YES if the receiver was able to perform the command, or a responder down the chain was
    able to perform the command.
*/
- (BOOL)tryToPerform:(SEL)aSelector with:(id)anObject
{
    if ([self respondsToSelector:aSelector])
    {
        [self performSelector:aSelector withObject:anObject];

        return YES;
    }

    return [_nextResponder tryToPerform:aSelector with:anObject];
}

@end

var CPResponderNextResponderKey = @"CPResponderNextResponderKey";

@implementation CPResponder (CPCoding)

/*!
    Initializes the responder with data from a coder.
    @param aCoder the coder from which data will be read
    @return the initialized responder
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        [self setNextResponder:[aCoder decodeObjectForKey:CPResponderNextResponderKey]];
        
    }

    return self;
}

/*!
    Archives the responder to a coder.
    @param aCoder the coder to which the responder will be archived
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{

    [super encodeWithCoder:aCoder];
    
    // This will come out nil on the other side with decodeObjectForKey:
    if (_nextResponder !== nil)
        [aCoder encodeConditionalObject:_nextResponder forKey:CPResponderNextResponderKey];

     
}

@end


 
