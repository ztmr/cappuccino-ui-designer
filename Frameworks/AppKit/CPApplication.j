@import <Foundation/CPObject.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPNotificationCenter.j> 
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPRunLoop.j>

@import "CPResponder.j"
@import "CPWindow.j"
@import "CPMenu.j"
@import "CPTheme.j"


var CPApp = nil;
var _CPTheme = null;
var _CPBeep = null; 


var CPApplicationDidFinishLaunchingNotification     = @"CPApplicationDidFinishLaunchingNotification";
var CPApplicationWillTerminateNotification          = @"CPApplicationWillTerminateNotification";

@implementation CPApplication : CPResponder
{
	
		id 						_delegate; 
		CPArray					_windows; 
		
		_CPMenuBar				_mainMenu; 

        CPWindow                _mainWindow; 
        CPWindow                _keyWindow; 
	
}


/*!
    Returns the singleton instance of the running application. If it
    doesn't exist, it will be created, and then returned.
    @return the application singleton
*/
+ (CPApplication)sharedApplication
{
    if (!CPApp)
        CPApp = [[CPApplication alloc] init];

    return CPApp;
}



- (id)init
{
    self = [super init];

    CPApp = self;

    if (self)
    {
		 _windows = []; 
    }

    return self;
}

-(CPMenu) mainMenu
{
    if(!_mainMenu)
         _mainMenu = [[_CPMenuBar alloc] init];

	return _mainMenu; 
}

-(CPWindow) mainWindow
{
    return _mainWindow; 
}

-(CPArray) windows 
{
    return _windows; 
}

-(CPWindow) windowWithWindowNumber:(int)windowNumber 
{
    return _windows[windowNumber];
}

- (void)setDelegate:(id)aDelegate
{
    if (_delegate == aDelegate)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter],
        delegateNotifications =
        [ 
			CPApplicationDidFinishLaunchingNotification, @selector(applicationDidFinishLaunching:),
			CPApplicationWillTerminateNotification, @selector(applicationWillTerminate:) 
        ],
        count = [delegateNotifications count];

    if (_delegate)
    {
        var index = 0;

        for (; index < count; index += 2)
        {
            var notificationName = delegateNotifications[index],
                selector = delegateNotifications[index + 1];

            if ([self._delegate respondsToSelector:selector])
                [defaultCenter removeObserver:self._delegate name:notificationName object:self];
        }
    }

    _delegate = aDelegate;

    var index = 0;

    for (; index < count; index += 2)
    {
        var notificationName = delegateNotifications[index],
            selector = delegateNotifications[index + 1];

        if ([_delegate respondsToSelector:selector])
            [defaultCenter addObserver:self._delegate selector:selector name:notificationName object:self];
    }
}

/*!
    Returns the application's delegate. The app can only have one delegate at a time.
*/
- (id)delegate
{
    return _delegate;
}

/*!
    This method is called by \c -run before the event loop begins.
    When it successfully completes, it posts the notification
    CPApplicationDidFinishLaunchingNotification. If you override
    \c -finishLaunching, the subclass method should invoke the superclass method.
*/
-(void) finishLaunching
{
        var delegateClassName = __CPInfo__.CPApplicationDelegateClass;

        if( delegateClassName != undefined && delegateClassName)
        {
                var delegateClass = objj_getClass(delegateClassName);
                if(delegateClass)
                {
                        [self setDelegate:delegateClass];
						
						[[CPNotificationCenter defaultCenter] postNotificationName:CPApplicationDidFinishLaunchingNotification
                                                                  object:self]; 
                    
                        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];	 
                        
                }
                else
               		CPLog.error(@"Could not find application delegate class called " + delegateClassName);
                
        }
        else
         	CPLog.error(@"CPApplicationDelegateClass not defined in Info.json");
          
}

-(void)sendAction:(SEL)aSelector to:(id)target from:(id)sender
{
      [target performSelector:aSelector withObject:sender];

}

 
-(void) setTheme:(CPTheme)aTheme
{
    _CPTheme = aTheme;
}

-(void) theme 
{
    if(!_CPTheme)
        _CPTheme = [[CPTheme alloc] init];

    return _CPTheme
}

-(CPWindow) keyWindow
{
    return _keyWindow; 
}
 
@end





@implementation CPApplication (Sheets)


- (void)beginSheet:(CPWindow)sheet 
        modalForWindow:(CPWindow)docWindow 
        modalDelegate:(id)modalDelegate 
        didEndSelector:(SEL)didEndSelector 
        contextInfo:(JSObject)contextInfo
{

    [docWindow _attachSheet:sheet modalDelegate:modalDelegate didEndSelector:didEndSelector contextInfo:contextInfo]; 
 
}

-(void)endSheet:(CPWindow)sheet
{
    [self endSheet:sheet returnCode:0];
}

- (void)endSheet:(CPWindow)sheet returnCode:(CPInteger)returnCode
{   
        if(!sheet._sheetContext)
            sheet._sheetContext = {};

        sheet._sheetContext.returnCode = returnCode; 
         
        [sheet _detachSheet];

		
}


@end


function CPApplicationMain()
{

     [[CPApplication sharedApplication] finishLaunching];

     return 0; 

}

function CPBeep()
{
    _CPBeep = new Audio();
    _CPBeep.src = "themes/Beep.wav";

	_CPBeep.play();   
	
}


