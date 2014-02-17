@import "CPView.j"
@import "CPWindow.j"
 

var CPPopoverBehaviorApplicationDefined = 0,
	CPPopoverBehaviorTransient          = 1;



@implementation CPPopover : CPResponder
{
	int 					_popoverType @accessors(property=popoverType);
	BOOL 					_hasPointer @accessors(property=hasPointer); 


	CPWindow 				_attachedWindow;
	CGSize 					_contentSize; 
	CPView 					_contentView; 
 
	DOMElement 				_arrow; 


}


-(id) init
{
	self = [super init];

	if(self )
	{
		_attachedWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessWindowMask| CPStaticWindowMask];

		[_attachedWindow setNextResponder:self];
		[self setNextResponder:CPApp];

		_attachedWindow._DOMElement.addClass("cppopover");
		_attachedWindow.contentView._DOMElement.addClass("cppopover-content");

		_attachedWindow._DOMWindowContentDiv.bind("blur", function(evt){
				if(_popoverType === CPPopoverBehaviorTransient)
					[self close];
		}); 
		
		_arrow = $("<div></div>");
		_attachedWindow._DOMElement.append(_arrow);

		_hasPointer = YES;
		_popoverType = CPPopoverBehaviorTransient; 
		_contentView = nil; 

		[self setContentSize:CGSizeMake(100,100)];
		
		[[_attachedWindow contentView] setBackgroundColor:[CPColor colorWithHexString:@"fafafa"]];
		

	}

	return self; 
}

-(void) setContentSize:(CGSize)aSize
{	
	_contentSize = aSize; 

	[_contentView setFrame:CGRectMake(5,5, _contentSize.width, _contentSize.height)];
	[_attachedWindow setFrameSize:CGSizeMake(aSize.width+10, aSize.height+10)];	
}



-(void) close
{
	_attachedWindow._DOMElement.fadeOut(200, function(){
		[_attachedWindow orderOut:nil];
	}); 
}

-(void) setContentView:(CPView)aView 
{ 	
	if(aView === _contentView)
		return; 

	[_contentView removeFromSuperview];

	_contentView = aView; 

	[_contentView setFrame:CGRectMake(5,5, _contentSize.width, _contentSize.height)];

	[[_attachedWindow contentView] addSubview:aView];
	
	var bkcolor = [_contentView backgroundColor]; 

	[[_attachedWindow contentView] setBackgroundColor:bkcolor];

	_arrow.css("background", [bkcolor cssString]);
 
}


-(BOOL) isShown
{
	return [_attachedWindow isVisible];
}

 

-(void) keyDown:(CPEvent)theEvent
{
	if(_popoverType === CPPopoverBehaviorTransient && [theEvent keyCode] === CPEscapeKeyCode)
	{
		if([self isShown])
			[self close];
	}

	[super keyDown:theEvent];
}

-(void) showRelativeToView:(CPView)aView preferredEdge:(int)preferredEdge centerOffset:(double)centerOffset
{
	
	var viewTop = aView._DOMElement.offset().top,
		viewLeft = aView._DOMElement.offset().left,
		offTop = $("#CPWindowToolbarAndContent").offset().top,
		offLeft =  $("#CPWindowToolbarAndContent").offset().left,
		windowh = CGRectGetHeight(_attachedWindow._frame),
		windoww = CGRectGetWidth(_attachedWindow._frame),
		viewh = CGRectGetHeight(aView._frame),
		vieww = CGRectGetWidth(aView._frame);
 	
 	 
 	_arrow.removeClass();

	if(preferredEdge === CPMaxXEdge)
	{	
		[_attachedWindow setFrameOrigin:CGPointMake(
				viewLeft + vieww + 10.0 + 10.0*_hasPointer - offLeft,
				viewTop - (windowh - viewh)/2.0 + centerOffset - offTop
			)];

		_arrow.css("top", (windowh - 2)/2.0 - centerOffset);
		_arrow.addClass("arrow_w");

	}
	else if(preferredEdge === CPMinXEdge)
	{
		[_attachedWindow setFrameOrigin:CGPointMake(
				viewLeft - windoww - 10.0 - 10*_hasPointer - offLeft,
				viewTop - (windowh - viewh)/2.0 + centerOffset - offTop
		)];

		_arrow.css("top", (windowh - 2)/2.0 - centerOffset);
		_arrow.addClass("arrow_e");

	}else if(preferredEdge === CPMinYEdge)
	{
		[_attachedWindow setFrameOrigin:CGPointMake(
				viewLeft - (windoww - vieww)/2 + centerOffset - offLeft,
				viewTop - windowh - 10 - 10*_hasPointer - offTop
			)];

		_arrow.css("left", (windoww - 2)/2.0 - centerOffset);
		_arrow.addClass("arrow_s");
	}
	else if(preferredEdge === CPMaxYEdge)
	{
		[_attachedWindow setFrameOrigin:CGPointMake(
			viewLeft - (windoww - vieww)/2 + centerOffset - offLeft,
			viewTop + viewh + 10 + 10*_hasPointer - offTop
		)];

		_arrow.css("left", (windoww - 2)/2.0 - centerOffset);
		_arrow.addClass("arrow_n");
	}

	_attachedWindow._DOMElement.fadeIn(200, function(){
		[_attachedWindow makeKeyAndOrderFront:nil];
	}); 
}

@end

var CPPopoverHasPointerKey					= @"CPPopoverHasPointerKey",
	CPPopoverTypeKey 						= @"CPPopoverTypeKey",
	CPPopoverContentViewKey					= @"CPPopoverContentViewKey",
	CPPopoverContentSizeKey 				= @"CPPopoverContentSizeKey";


@implementation CPPopover (CPCoding)
 
-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];

	if(self)
	{
		_attachedWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessWindowMask| CPStaticWindowMask];

		[_attachedWindow setNextResponder:self];
		[self setNextResponder:CPApp];

		_attachedWindow._DOMElement.addClass("cppopover");
		_attachedWindow.contentView._DOMElement.addClass("cppopover-content");

		_attachedWindow._DOMElement.bind("blur", function(evt){
				if(_popoverType === CPPopoverBehaviorTransient)
					[self close];
		}); 
		
		_arrow = $("<div></div>");
		_attachedWindow._DOMElement.append(_arrow);

		_hasPointer = [aCoder decodeBoolForKey:CPPopoverHasPointerKey];
		_popoverType = [aCoder decodeIntForKey:CPPopoverTypeKey];  

		[self setContentSize:[aCoder decodeObjectForKey:CPPopoverContentSizeKey]];
		[self setContentView:[aCoder decodeObjectForKey:CPPopoverContentViewKey]];
	}

	return self; 
}


-(void) encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:_contentView forKey:CPPopoverContentViewKey];
	[aCoder encodeInt:_popoverType forKey:CPPopoverTypeKey];
	[aCoder encodeBool:_hasPointer forKey:CPPopoverHasPointerKey];
	[aCoder encodeSize:_contentSize forKey:CPPopoverContentSizeKey];
}


@end