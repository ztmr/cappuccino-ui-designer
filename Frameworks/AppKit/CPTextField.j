@import <Foundation/CPString.j>

@import "CPDOMEventDispatcher.j"
@import "CPControl.j"

var CPControlTextDidBeginEditingNotification = @"CPControlTextDidBeginEditingNotification",
	CPControlTextDidEndEditingNotification = @"CPControlTextDidEndEditingNotification",
	CPControlTextDidChangeNotification = @"CPControlTextDidChangeNotification",
	CPTextFieldDidFocusNotification = @"CPTextFieldDidFocusNotification",
	CPTextFieldDidBlurNotification = @"CPTextFieldDidBlurNotification";

@implementation CPTextField : CPControl
{
	
		CPString		_placeholder @accessors(property=placeholder);   
		CPString 		_startValue; 

		BOOL            _placeholderVisible; 
		BOOL			_editable @accessors(getter=isEditable);
		BOOL 			_selectable @accessors(getter=isSelectable);
		
		id				_delegate @accessors(getter=delegate);
		
		BOOL			_bezeled @accessors(getter=isBezeled); 
		int 			_bezelStyle @accessors(getter=bezelStyle);  
		
		DOMElement		_input; 
		DOMElement		_text;     
		
		
	
}

+(CPTextField)labelWithString:(CPString)aString  
{
	var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
	[label setBezeled:NO];
	[label setEditable:NO];
	[label setStringValue:aString];
	[label setSelectable:NO];
	[label sizeToFit];
	
	return label; 
}

-(id) initWithFrame:(CGRect)aFrame   
{
	self = [super initWithFrame:aFrame];
	
	if( self )
	{
		_placeholder = nil;
		_editable = YES; 
		_selectable = YES; 
		_delegate = nil;
		_bezeled = NO; 
		_value = @""; 
		_placeholderVisible = YES;   
		_bezelStyle = CPRoundRectBezelStyle;
	
		_DOMElement.addClass("cptextfield");
 
		
		[self _setupInputControls];
		 
	
	}
	
	return self; 
}

-(void) _setupInputControls
{
	if(!_input)
	{
		_input = $("<input type='text'></input>").addClass("cptextfield-input");
		
		 

		_input.bind("propertychange keyup input paste change", function(evt){
			 
			

			 if(_value !== _input.val())
			 {		 
			 	_value = _input.val();
			 	[self _textDidChange];
			 	 
			 }
		});

		_input.bind("mousedown mouseup mousemove", function(evt){
			evt.stopPropagation(); 
			if(_editable)
				evt._cancelPreventDefault = true; 
			[CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:self];
		}); 


		_DOMElement.append(_input);
	}

	if(!_text)
	{

		_text = $("<div></div>").css({
			"outline" : "none",
			"position" : "relative",
			"text-overflow" : "ellipsis",
			"overflow" : "hidden",
			"display" : "block"
		}).addClass("cptextfield-text");

		_text.bind("propertychange keyup input paste change", function(evt){
			 
			 if(_value !== _text.text())
			 {		 
			 	_value = _text.text();
			 	[self _textDidChange]; 
			 }
		});

		_text.bind("mousedown mouseup mousemove", function(evt){
			
			evt.stopPropagation(); 
			evt._cancelPreventDefault = _editable || _selectable; 
			
			[CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:self];
		});
		
		 
		_DOMElement.append(_text);

	} 
	
}

-(void) setInputType:(CPString)type 
{
	if(_input)
		_input.attr("type", type);
}
    
-(BOOL) acceptsFirstResponder 
{
	 return _editable; 

}

-(BOOL) swallowsKey 
{
	return _editable; 
}

-(void) _textDidChange
{
	[[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidChangeNotification object:self];
}

-(void) setObjectValue:(id)obj
{	
	if(!_input)
		[self _setupInputControls];


	 if(obj !== _value)
	 {	
	 	_input.val("" +obj);
		_text.html("" + obj);

		[super setObjectValue:obj];
		[self _textDidChange];
	 }
}

-(void) setBezelStyle:(int)bezelStyle 
{
	_bezelStyle = bezelStyle; 

	[self _updateControlInputs]; 
}


-(void) setDelegate:(id)aDelegate
{
	var defaultCenter = [CPNotificationCenter defaultCenter];

    //unsubscribe the existing delegate if it exists         
    if (_delegate)   
    {
		[defaultCenter removeObserver:_delegate name:CPControlTextDidBeginEditingNotification object:self];
        [defaultCenter removeObserver:_delegate name:CPControlTextDidChangeNotification object:self];
        [defaultCenter removeObserver:_delegate name:CPControlTextDidEndEditingNotification object:self];
        [defaultCenter removeObserver:_delegate name:CPTextFieldDidFocusNotification object:self];
        [defaultCenter removeObserver:_delegate name:CPTextFieldDidBlurNotification object:self];
    }

    _delegate = aDelegate;           

	if ([_delegate respondsToSelector:@selector(controlTextDidBeginEditing:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidBeginEditing:)
                   name:CPControlTextDidBeginEditingNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(controlTextDidChange:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidChange:)
                   name:CPControlTextDidChangeNotification
                 object:self];


    if ([_delegate respondsToSelector:@selector(controlTextDidEndEditing:)])
    	[defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidEndEditing:)
                   name:CPControlTextDidEndEditingNotification
                 object:self];
    

    if ([_delegate respondsToSelector:@selector(controlTextDidFocus:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidFocus:)
                   name:CPTextFieldDidFocusNotification
                 object:self];

    if ([_delegate respondsToSelector:@selector(controlTextDidBlur:)])
        [defaultCenter
            addObserver:_delegate
               selector:@selector(controlTextDidBlur:)
                   name:CPTextFieldDidBlurNotification
                 object:self];
}

 
-(BOOL) becomeFirstResponder
{		
	if(!_editable || ![self isEnabled])
		return NO; 


	if(_bezeled)
	 	setTimeout(function(){_input.focus(); }, 20);  
	else 
		setTimeout(function(){_text.focus(); }, 20);

	_startValue = [self stringValue];

	[[CPNotificationCenter defaultCenter] postNotificationName:CPTextFieldDidFocusNotification object:self];

	_placeholderVisible = NO;

	[self _updateControlInputs];

	return [super becomeFirstResponder]; 

}

-(BOOL) resignFirstResponder 
{  	
	 
	[[CPNotificationCenter defaultCenter] postNotificationName:CPTextFieldDidBlurNotification object:self];

	if(_startValue !== [self stringValue])
		[[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidEndEditingNotification object:self];

	 if((!_value || _value == @"") && _placeholder)
	 {
	 		_placeholderVisible = YES;
	 		[self _updateControlInputs];
	 }  

	 if(_editable && _input.is( ":focus" ))
		[CPDOMEventDispatcher DOMFocusKeyWindow:YES]; 

	return [super resignFirstResponder];
}

-(void) setBezeled:(BOOL)b
{
	_bezeled = b;
	
	[self setNeedsLayout];
}

-(void) mouseDown:(CPEvent)theEvent
{	
	if(_editable)
		[[self window] makeFirstResponder:self];

	[super mouseDown:theEvent];
}

-(void) keyDown:(CPEvent)theEvent
{
	
	if([theEvent keyCode] === CPReturnKeyCode)
	 	[self triggerAction]; 
	 
	[super keyDown:theEvent];
}

 
-(void) setFrameSize:(CGSize)aSize
{
	[super setFrameSize:aSize];
	[self setNeedsLayout];

}

-(void) triggerAction
{
	[super triggerAction];

	if(_startValue !== [self stringValue])
		[[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidEndEditingNotification object:self];
}

 
-(void) _updateControlInputs
{
	if(_input && _text)
	{	
			_input.css({
				width : _frame.size.width-8,
				height : _frame.size.height-4
			});

			_text.css({
				width : _frame.size.width,
				height : _frame.size.height
			});

			_DOMElement.removeClass("rounded");
			if(_bezelStyle === CPRoundedBezelStyle)
			{
				_DOMElement.addClass("rounded");
				_input.css("width", _frame.size.width-14);
			}

			if(_selectable)
			{	
				_text.css({
					"cursor" : "text",
					"-webkit-user-select"  : "text",
					"-moz-user-select" : "text",
					"-ms-user-select" : "text",
					"user-select" : "text"
				});

			}else
			{
				_text.css({
				 
					"-webkit-user-select"  : "none",
					"-moz-user-select" : "none",
					"-ms-user-select" : "none",
					"user-select" : "none"
				});
			}
				

			if(!_editable || ![self isEnabled])
			{
				_input.attr("readonly", "readonly");
				_text.attr({
					"contenteditable" : "false", 
					role : "label" 
				});

				
	
			}
			else
			{
				_input.removeAttr("readonly");
				_text.attr({
					"contenteditable" : "true", 
					 role : 'textbox' 
				});
 
			}
	
	
			if(_bezeled)
			{	
				_input.show();
				_text.hide();
			}
			else
			{

				_input.hide();
				_text.show(); 
			}

			var textColor =  [[self textColor] cssString],
				shadowColor = [[self textShadowColor] cssString],
				shadowOffset = [self textShadowOffset],
				font = [[self font] cssString],
				fontDec = [[self font] cssTextDecoration],
				txtAlgn = [self textAlignment]
				lbm = [self lineBreakMode];

		 
			_input.css({
				color : textColor,
				font : font,
				"white-space" : lbm,
				"text-align" : txtAlgn,
				"textShadow" : shadowOffset.width + "px " + shadowOffset.height + "px " + shadowColor,
				"text-decoration" : fontDec 
			});
			
			_text.css({
				color : textColor,
				font : font,
				"white-space" : lbm,
				"text-align" : txtAlgn,
				"textShadow" : shadowOffset.width + "px " + shadowOffset.height + "px " + shadowColor,
				"text-decoration" : fontDec 
			});

			if(_placeholderVisible && _placeholder)
 			{
 				_input.addClass("placeholder-visible");
 				_input.val(_placeholder);
 			}
 			else
 			{
 				_input.removeClass("placeholder-visible");
 				if(_value != _input.val())
 				 	_input.val(_value); 
 			}
		
			 
	}
}

 

-(void) setEditable:(BOOL)editable
{
	_editable = editable;
 	[self setNeedsLayout];
	
}

-(void) setSelectable:(BOOL)sel 
{
	_selectable = sel;
	[self setNeedsLayout];
}

-(void) setEnabled:(BOOL)enabled
{
	[super setEnabled:enabled];
	[self setNeedsLayout];
}

-(void) sizeToFitInWidth:(double)width 
{
	var sz = [[self stringValue] sizeWithFont:[self font] inWidth:width];

	if(_bezeled)
		[self setFrameSize:CGSizeMake(width+1, sz.height+4)];
	else
 		[self setFrameSize:CGSizeMake(width+1, sz.height)];

}


-(void) sizeToFit
{
	var sz = [[self stringValue] sizeWithFont:[self font]];
	
	if(_bezeled)
		[self setFrameSize:CGSizeMake(sz.width+10, sz.height+4)];
	else
 		[self setFrameSize:sz];
}

 

-(void) layoutSubviews
{
	[self _updateControlInputs];
	
}

-(void) setThemeState:(CPString)aState
{
	[super setThemeState:aState];

	[self setNeedsLayout];
}

-(void) unsetThemeState:(CPString)aState
{
	[super unsetThemeState:aState];
	[self setNeedsLayout];
}



@end


var CPTextFieldPlaceholderKey 			= @"CPTextFieldPlaceholderKey",
	CPTextFieldEditableKey 				= @"CPTextFieldEditableKey",
	CPTextFieldDelegateKey 				= @"CPTextFieldDelegateKey",
	CPTextFieldBezeledKey 				= @"CPTextFieldBezeledKey",
	CPTextFieldBezelStyleKey			= @"CPTextFieldBezelStyleKey",
	CPTextFieldTextColorKey 			= @"CPTextFieldTextColorKey";
 
@implementation CPTextField (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	
	self = [super initWithCoder:aCoder];
	if(self)
	{
		
		[self _setupInputControls];
 
		_placeholder = [aCoder decodeObjectForKey:CPTextFieldPlaceholderKey];
		_editable = [aCoder decodeObjectForKey:CPTextFieldEditableKey];
		_delegate = [aCoder decodeObjectForKey:CPTextFieldDelegateKey];
		_bezeled = [aCoder decodeBoolForKey:CPTextFieldBezeledKey]; 
		_bezelStyle = [aCoder decodeIntForKey:CPTextFieldBezelStyleKey];    

		[self setFrameSize:_frame.size]; 

		_DOMElement.addClass("cptextfield");
 
	}
	
	return self; 
	
}

-(void) encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];
	
	[aCoder encodeObject:_placeholder forKey:CPTextFieldPlaceholderKey];
	[aCoder encodeBool:_editable forKey:CPTextFieldEditableKey];
	[aCoder encodeInt:_bezelStyle forKey:CPTextFieldBezelStyleKey];
	[aCoder encodeConditionalObject:_delegate forKey:CPTextFieldDelegateKey];
	[aCoder encodeBool:_bezeled forKey:CPTextFieldBezeledKey]; 
	
}



@end