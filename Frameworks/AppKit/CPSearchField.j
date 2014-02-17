@import "CPTextField.j"


@implementation CPSearchField : CPTextField
{


}

-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];

	if(self)
	{	
		_placeholder = @"Search"; 
		_bezeled = YES; 
		_editable = YES; 
		_bezelStyle = CPRoundedBezelStyle; 
	}

	return self; 
}

-(void) _setupInputControls
{
	[super _setupInputControls];

	_DOMElement.addClass("search");

	_input.addClass("cpsearchfield-input");

	var clearSearch = $("<div></div>").addClass("cpsearchfield-cancel");
	clearSearch.css("top", (_frame.size.height - 22)/2.0);
	clearSearch.hide();
	
	clearSearch.bind({
		mousedown : function(evt)
		{
			$(this).addClass("pressed");
			[CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:self];
		},
		click : function(evt)
		{
			$(this).removeClass("pressed");
			[self setStringValue:@""];
			setTimeout(function(){
				_input.focus()
				}, 50); 
			$(this).hide();

			[CPDOMEventDispatcher dispatchDOMMouseEvent:evt toView:self];
		}
	});
 
	_DOMElement.append(clearSearch);

	var searchimg = $("<div></div>").addClass("cpsearchfield-image");
	searchimg.css("top", (_frame.size.height - 22)/2.0);
	_DOMElement.append(searchimg);

}

-(void) _updateControlInputs
{
	[super _updateControlInputs];

	_input.css("width", _frame.size.width-28);

}

-(void) _textDidChange
{
	[super _textDidChange];

	if([[self stringValue] stringByTrimmingWhitespace] === @"")
		_DOMElement.children(".cpsearchfield-cancel").hide();
	else
		_DOMElement.children(".cpsearchfield-cancel").show();

}


@end