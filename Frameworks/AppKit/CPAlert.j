@import "CPWindow.j"
@import "CPImageView.j"
@import "CPTextField.j"

var CPWarningAlertStyle = 0,
    CPInformationalAlertStyle = 1,
    CPCriticalAlertStyle = 2;


#define ALERT_WIDTH 400
#define ALERT_HEIGHT 150

@implementation CPAlert : CPObject
{
	CPWindow 		_theWindow @accessors(getter=window); 
	
	CPString 		_messageText @accessors(getter=messageText);
	CPString 		_informativeText @accessors(getter=informativeText);
 	
	CPImage			_icon 	@accessors(getter=icon);
	
	CPTextField		_messageTextField;
	CPTextField 	_informativeTextField; 
	CPImageView		_iconImageView; 
	
	CPArray 		_buttons @accessors(getter=buttons); 
	
	int				_alertStyle @accessors(getter=alertStyle); 		
}

+(id) warningAlertWithMessageText:(CPString)text defaultButton:(CPString)buttonText informativeText:(CPString)infoText
{
	var a = [[CPAlert alloc] init];
	[a setMessageText:text];
	[a setInformativeText:infoText];
	[a setAlertStyle:CPWarningAlertStyle];
	
    [a addButtonWithTitle:buttonText];
 

	return a; 
	 
}

+(id) informativeAlertWithMessageText:(CPString)text defaultButton:(CPString)buttonText informativeText:(CPString)infoText
{
	var a = [[CPAlert alloc] init];
	[a setMessageText:text];
	[a setInformativeText:infoText];
	[a setAlertStyle:CPInformationalAlertStyle];
	
    [a addButtonWithTitle:buttonText];
 

	return a; 
	 
}

+(id) criticalAlertWithMessageText:(CPString)text defaultButton:(CPString)buttonText informativeText:(CPString)infoText
{
	var a = [[CPAlert alloc] init];
	[a setMessageText:text];
	[a setInformativeText:infoText];
	[a setAlertStyle:CPCriticalAlertStyle];
	
    [a addButtonWithTitle:buttonText];
 

	return a; 
	 
}


-(id) init
{
	self = [super init];
	
	if(self)
	{
		_theWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0,0, ALERT_WIDTH, ALERT_HEIGHT) styleMask:0];
		
		_messageTextField = [CPTextField labelWithString:@""];
		[_messageTextField setLineBreakMode:CPLineBreakByWordWrapping];
		[_messageTextField setFont:[CPFont boldSystemFontOfSize:13.0]];
		_informativeTextField = [CPTextField labelWithString:@""];
		[_informativeTextField setLineBreakMode:CPLineBreakByWordWrapping];
		[_informativeTextField setFont:[CPFont systemFontOfSize:12.0]];
		_iconImageView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0, 64,64)];
		
		var cv = [_theWindow contentView];
		[cv addSubview:_messageTextField];
		[cv addSubview:_informativeTextField];
		[cv addSubview:_iconImageView];
		
		_buttons = []; 
	}
	
	return self; 
}

-(void) setAlertStyle:(int)aStyle
{
	_alertStyle = aStyle; 
	 
	var theme = [CPApp theme];
	
	if(_alertStyle === CPWarningAlertStyle)
	{
		[self setIcon:[[CPImage alloc] initWithData:[CPData dataWithBase64:[theme themeAttribute:@"warning-icon" forClass:[self class]]]]];
	}
	else if(_alertStyle === CPInformationalAlertStyle)
	{
		[self setIcon:[[CPImage alloc] initWithData:[CPData dataWithBase64:[theme themeAttribute:@"informational-icon" forClass:[self class]]]]];
	}
	else if(_alertStyle === CPCriticalAlertStyle)
	{
		[self setIcon:[[CPImage alloc] initWithData:[CPData dataWithBase64:[theme themeAttribute:@"critical-icon" forClass:[self class]]]]];
	} 
	
}

-(void) setMessageText:(CPString)aString
{
	_messageText = aString;
	[_messageTextField setStringValue:_messageText];
	
}

-(void) setInformativeText:(CPString)aString
{
	_informativeText = aString; 
	[_informativeTextField setStringValue:_informativeText];
}

-(void) setIcon:(CPImage)anImage
{
	_icon = [anImage copy];
	
	[_iconImageView setImage:_icon];
	
}

-(void) runModal
{
	[self layout];
	[_theWindow setModal:YES];
	[_theWindow center];
	[_theWindow makeKeyAndOrderFront:nil];
}

-(CPButton) addButtonWithTitle:(CPString)aTitle
{
	var b = [CPButton buttonWithTitle:aTitle];
	[b setFrameSize:CGSizeMake(MAX(80, b._frame.size.width), 25)];

	[b setTarget:self];
	[b setAction:@selector(_endAlert:)];
	[b setAutoresizingMask:CPViewMaxYMargin|CPViewMaxXMargin];

	[_buttons addObject:b];
	
	
	[[_theWindow contentView] addSubview:b];
	
	return b; 
}

-(void) _endAlert:(id)sender 
{
	if([_theWindow isSheet])
		[CPApp endSheet:_theWindow];
	else
		[_theWindow orderOut:sender];
}

-(void) layout
{
	[_iconImageView setFrameOrigin:CGPointMake(15,15)];
	
	[_messageTextField sizeToFitInWidth:(ALERT_WIDTH - 110)];
	[_messageTextField setFrameOrigin:CGPointMake(94,15)];
	
	[_informativeTextField sizeToFitInWidth:(ALERT_WIDTH - 110)];
	[_informativeTextField setFrameOrigin:CGPointMake(94, CGRectGetMaxY([_messageTextField frame]) +10)];
	
	if(CGRectGetMaxY([_informativeTextField frame]) >= ALERT_HEIGHT - 60)
		[_theWindow setFrameSize:CGSizeMake(_theWindow._frame.size.width, CGRectGetMaxY([_informativeTextField frame]) + 80)];
		
	var count = [_buttons count],
		i = 0;
	
	var cvframe = [[_theWindow contentView] frame];
	
	var x = cvframe.size.width - 15,
	 	y = cvframe.size.height - 15;
 	for(; i < count; i++)
	{
		var b = _buttons[i];
		[b setFrameOrigin:CGPointMake(x-b._frame.size.width, y-b._frame.size.height)];

		x = x-b._frame.size.width-15; 
	}
	
}

-(void) beginSheetModalForWindow:(CPWindow)window 
		modalDelegate:(id)modalDelegate 
		didEndSelector:(SEL)alertDidEndSelector contextInfo:(JSObject)contextInfo
{
	[self layout];
		
	[CPApp beginSheet:_theWindow
		        modalForWindow:window
		        modalDelegate:modalDelegate		
		        didEndSelector:alertDidEndSelector
		        contextInfo:contextInfo];
	
	
}



@end