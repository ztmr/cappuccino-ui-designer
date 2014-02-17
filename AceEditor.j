@import <AppKit/CPTextField.j>


var AceEditorFileChangeNotification = @"AceEditorFileChangeNotification",
	AceEditorMarkFileUnsavedNotification = @"AceEditorMarkFileUnsavedNotification"; 


@implementation AceEditor : CPView
{

	DOMElement 			editor;
	id 					_delegate @accessors(getter=delegate); 
	CPDictionary 		_activeFile @accessors(getter=activeFile); 
}

 

-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if( self )
	{
		[self setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

		_DOMElement.attr('id', "ace");
 		_DOMElement.css("fontSize", 14);

		editor = nil;
		_delegate = nil;
		_activeFile = nil;  
		
	}

	return self; 
}

-(void) setDelegate:(id)aDelegate 
{
	if(_delegate == aDelegate)
		return ;

	var defaultCenter = [CPNotificationCenter defaultCenter];

	if([_delegate respondsToSelector:@selector(aceEditorTextDidChange:)])
	{
		[defaultCenter removeObserver:_delegate
                          name:AceEditorFileChangeNotification
                        object:self];

    }


    _delegate = aDelegate;

    if([_delegate respondsToSelector:@selector(aceEditorTextDidChange:)])
    {
    	[defaultCenter addObserver:_delegate
            selector:@selector(aceEditorTextDidChange:)
            name:AceEditorFileChangeNotification
            object:self];
    }


}

-(void) mouseDown:(CPEvent)theEvent
{
	[[self window] makeFirstResponder:self];
}

-(BOOL) acceptsFirstResponder 
{
	 return YES; 

}

-(CPString) text 
{
	if(editor)
		return editor.getValue();

	return @""; 
}

-(BOOL) swallowsKey 
{
	return YES; 
}

-(void) setFile:(CPDictionary)fileInfo
{
	if(editor)
	{	
		_activeFile = fileInfo;
		var fileName = [fileInfo objectForKey:@"name"]; 

		if([fileName hasSuffix:".j"])
			editor.getSession().setMode("ace/mode/objectivej");
		else if([fileName hasSuffix:".js"] || [fileName hasSuffix:".json"] )
			editor.getSession().setMode("ace/mode/javascript");
		else if([fileName hasSuffix:".css"])
			editor.getSession().setMode("ace/mode/css");
		else if([fileName hasSuffix:".html"])
			editor.getSession().setMode("ace/mode/html");

		editor.setValue([_activeFile objectForKey:@"contents"]);
		editor.gotoLine(0);

		
	}
}



-(void) setup 
{
	if(!editor)
	{
		editor = ace.edit("ace");
    	editor.setTheme("ace/theme/tomorrow_night_bright");
    	editor.getSession().setUseWorker(false);
    	editor.getSession().setMode("ace/mode/objectivej");

    	editor.getSession().on('change', function(e) {
    		
    		var newText = [self text];
    		var oldText = [_activeFile objectForKey:@"contents"];

    		if(![oldText isEqualToString:newText])
    		{
    			[_activeFile setObject:[self text] forKey:@"contents"];
    			var unsaved = [_activeFile objectForKey:@"unsaved"];
    			[_activeFile setObject:YES forKey:@"unsaved"];

    			if(!unsaved)
				{ 
					[[CPNotificationCenter defaultCenter] postNotificationName:AceEditorMarkFileUnsavedNotification object:self];
				}

				[[CPNotificationCenter defaultCenter] postNotificationName:AceEditorFileChangeNotification object:self];
    		} 
		});
 
    	editor.setShowPrintMargin(false);

    }
}

@end