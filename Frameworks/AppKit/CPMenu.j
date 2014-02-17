@import <Foundation/CPObject.j>
@import <Foundation/CPArray.j>
@import <Foundation/CPIndexSet.j>

@import "_CPMenuBar.j"
@import "CPMenuItem.j"



var CPMenuDOMElementPrototype = null; 
var _CPFocusMenu = nil; 

@implementation CPMenu : CPObject
{
	DOMElement			_DOMElement;
	CGPoint				_position;
	
	CPString			_title @accessors(property=title);

	CPMenuItem			_highlightedItem;
	CPMenuItem			_selectedItem @accessors(property=selectedItem);
	
	CPMenu				_supermenu @accessors(property=supermenu);
	
	CPArray				_menuItems;
	
	double				_width @accessors(getter=width); 
	double				_bodyTop; 
	BOOL				_radio; 
	
	
	id                  _delegate @accessors(property=delegate); 


	BOOL				_upArrowVisible;
	BOOL				_downArrowVisible; 
	BOOL				_isVisible; 
	
	JSObject			_scrollTimerDown;
	JSObject			_scrollTimerUp; 
	BOOL				_disabledMouse; 
	BOOL 				_ignoreMouseUp ; 
	
	CPIndexSet			_separators; 
	
	
}

+(void) initialize
{
	CPMenuDOMElementPrototype = $("<div></div>").addClass("cpmenu");
	CPMenuDOMElementPrototype.attr({
		role : "menu",
		tabIndex : 1 
	});
	
	CPMenuDOMElementPrototype.css({
		overflow : "visible",
		zIndex : 10000
	});
	
	CPMenuDOMElementPrototype.append($("<div></div>").addClass("cpmenu-body"));
	var up = $("<div></div>").addClass("cpmenu-scrollup");
	up.append($("<div></div>").addClass("cpmenu-scrollup-img"));
	CPMenuDOMElementPrototype.append(up);
	var down = $("<div></div>").addClass("cpmenu-scrolldown");
	down.append($("<div></div>").addClass("cpmenu-scrolldown-img"));
	CPMenuDOMElementPrototype.append(down);
}


+(BOOL) menuBarVisible
{
	return _CPMenuBarVisible; 
}

+ (double)menuBarHeight
{
    return CPMenuBarHeight; 
	 
}

+(void) setMenuBarVisible:(BOOL)aFlag
{
	if(_CPMenuBarVisible === aFlag)
		return; 
	
	_CPMenuBarVisible = aFlag;

	 // add it to the DOM  
      if(_CPMenuBarVisible)
      {
          if(!CPApp._mainMenu)
              CPApp._mainMenu = [[_CPMenuBar alloc] init];

          $("body").append(CPApp._mainMenu._DOMElement);

      }else
      { 	
			if(CPApp._mainMenu)
              	CPApp._mainMenu._DOMElement.remove(); 
             
      }

      [CPApp._windows[0] _adjustContentViewSize];
}

+(id) menuWithTitle:(CPString)aTitle
{
	var a = [[CPMenu alloc] init];
	[a setTitle:aTitle];
	
	return a; 
}

-(id) init
{
	self = [super init];
	
	if( self )
	{
		_DOMElement = CPMenuDOMElementPrototype.clone(false);
		
		[self _attachEvents];
		
		_menuItems = [];
		_title = @"";
		_position = CGPointMake(0,0);
		
		_highlightedItem = null;
		_selectedItem = null;
		_supermenu = null;
		
		_separators = [CPIndexSet indexSet];
		
		_upArrowVisible = NO;
		_downArrowVisible = NO;
		_isVisible = NO; 
		
		_disabledMouse = NO;
		_ignoreMouseUp = NO; 
		_bodyTop = 0.0;
		_scrollTimerUp = null; 
		_scrollTimerDown = null; 
		
		[self _setBodyTop:5.0];
		
		[self _showDownArrow:NO];
		[self _showUpArrow:NO];
		
		[self setWidth:125.0];
		[self hide];
		 
		
	}
	
	return self; 
}

-(void) _attachEvents
{
	var up = _DOMElement.children(".cpmenu-scrollup");
	
	up.bind({
					mouseover : function(event)
					{
						event.stopPropagation();
						event.preventDefault();
						if(!_disabledMouse)
						{	
							
							if(_scrollTimerUp)
							{
								clearTimeout(_scrollTimerUp);
								_scrollTimerUp = null; 
							}

						    var sUp = function(){
							  
							   [self _scrollUpBody:2.0];
								if(_scrollTimerUp)
								{
									_scrollTimerUp = setTimeout(sUp, 2);
								}
							}; 
						
							_scrollTimerUp = setTimeout(sUp,2);
						}
					},
					mouseout : function(event)
					{ 
						if(_scrollTimerUp)
						{
							clearTimeout(_scrollTimerUp);
						}

						_scrollTimerUp = null; 
					}
		});
		
		var down = _DOMElement.children(".cpmenu-scrolldown");
		
		down.bind({
			
			mouseover : function(event)
						{
							event.preventDefault();
							event.stopPropagation();
							if(!_disabledMouse)
							{
								if(_scrollTimerDown)
								{
									clearTimeout(_scrollTimerDown);
									_scrollTimerDown = null; 
								}

								var sDown = function(){
									[self _scrollDownBody:2.0]; 
									if(_scrollTimerDown)
									{
										_scrollTimerDown = setTimeout(sDown, 2);
									}
								}; 

								_scrollTimerDown = setTimeout(sDown, 2);
							}

						},
						mouseout : function(event)
						{
							 
							if(_scrollTimerDown)
							{
								clearTimeout(_scrollTimerDown);
							}
							_scrollTimerDown = null; 
						}	
		});
		
		 
		
		_DOMElement.bind({
			mouseenter : function(evt)
			{
				evt.stopPropagation(); 
				_disabledMouse = NO;
			},
			mouseleave : function(evt)
			{
				evt.stopPropagation();
				if(_highlightedItem)
					if(![_highlightedItem submenu])
						[self setHighlightedMenuItem:nil];
			},
			keydown : function(evt)
			{	
				evt.stopPropagation();	
				evt.preventDefault(); 

				[self keyDown:evt];	 

				 _disabledMouse = NO; 

			},
			keyup : function(evt)
			{	
				evt.stopPropagation();	
				evt.preventDefault(); 
 
			},
			blur : function(evt)
			{	
				var count = _menuItems.length,
				index = 0;
				
				for(; index < count; index++)
	 			{

	 				var submenu = [_menuItems[index] submenu];
	 				if(submenu)
	 				{
	 					if(submenu === _CPFocusMenu)
	 						return;
	 				}

	 			}
				
				[self close:nil];
			} 
		});
		

		_DOMElement.on("mouseWheel", function(evt){

			if(evt.deltaY != 0)
			{
				if(evt.deltaY < 0 && _downArrowVisible)
					[self _scrollDownBody:8.0*ABS(deltaY)]; 
				else if(evt.deltaY > 0 && _upArrowVisible)
					[self _scrollUpBody:8.0*ABS(deltaY)];	
			}

		}); 
		
}

-(void) _adjustMenuHeight
{
	if(_menuItems.length > 0)
	{ 	 
		var h =  [self menuHeight]; 

		_DOMElement.css("height", MIN(h, $(window).height() - 5 - MAX(0, _position.y - 2)));
			
		[self _checkIfNeedsScrolling]; 
	}
}

 
-(void) _checkIfNeedsScrolling
{
		var bodyEl = _DOMElement.children(".cpmenu-body");

		var end = _bodyTop + bodyEl.height();
	  	
	 
		if(end > ROUND(_DOMElement.height()  - 5.0))
		{
			if(!_downArrowVisible)
			 	[self _showDownArrow:YES];
		}else
		{
			[self _showDownArrow:NO]; 
			_scrollTimerDown = null; 
			
			
		} 
	 	
	 	if(_bodyTop < 5)
		{
			if(!_upArrowVisible)
			{	
				[self _showUpArrow:YES]; 
			}
		}
		else
		{	
			_scrollTimerUp = null; 
			[self _showUpArrow:NO]; 
			
			
		}
		
		if(_bodyTop < ROUND(_DOMElement.height() - 5.0 - bodyEl.height()))
			[self _setBodyTop:_DOMElement.height() - 5.0 - bodyEl.height()];
			
		if(_bodyTop > 5)
			[self _setBodyTop:5];
}

-(void) _showDownArrow:(BOOL)aFlag
{
	if(aFlag)
	{
		_downArrowVisible = YES;
		_DOMElement.children(".cpmenu-scrolldown").show();
		
	}
	else
	{
		_downArrowVisible = NO;
		_DOMElement.children(".cpmenu-scrolldown").hide(); 
	}
}

-(void) _showUpArrow:(BOOL)aFlag
{
	if(aFlag)
	{
		_upArrowVisible = YES;
		_DOMElement.children(".cpmenu-scrollup").show();
		
	}
	else
	{
		_upArrowVisible = NO;
		_DOMElement.children(".cpmenu-scrollup").hide(); 
	}
}

 

-(void) _scrollUpBody:(double)unit 
{	
 
	[self _setBodyTop:(_bodyTop + unit)];
	[self _checkIfNeedsScrolling];
}

-(void) _scrollDownBody:(double)unit
{	
	if(_position.y - unit >= 0)
		[self setPosition:CGPointMake(_position.x, _position.y - unit)];
	else
		[self _setBodyTop:(_bodyTop - unit)];
	
	[self _checkIfNeedsScrolling];
}

-(void) _setBodyTop:(double)bt
{
 
	_bodyTop = bt;
	_DOMElement.children(".cpmenu-body").css("top", _bodyTop);
	
}

-(void) setIsRadio:(BOOL)aFlag
{
	_radio = aFlag;
	
	var count = _menuItems.length,
		index = 0;
		
	for(; index < count; index++)
 		[_menuItems[index] setIsRadio:_radio];

 	if(count > 0)
 		_selectedItem = _menuItems[0];
}

-(void) setWidth:(double)w
{
	_width = w;
	_DOMElement.css("width", w);
}

-(double)width
{
	return _width; 
}

-(void) setHighlightedMenuItem:(CPMenuItem)aMenuItem
{
	if(_highlightedItem)
		[_highlightedItem setHighlighted:NO];
		
	if(aMenuItem)
	{

		if([_menuItems containsObject:aMenuItem])
		{ 
			_highlightedItem = aMenuItem;
			[_highlightedItem setHighlighted:YES];
			 
			_CPFocusMenu = self; 
			_DOMElement.makeKey();

			if([_delegate respondsToSelector:@selector(menu:willHighlightItem:)])
				[_delegate performSelector:@selector(menu:willHighlightItem:) withObjects:self, _highlightedItem];
		}
	}
	else
		_highlightedItem = null; 
}

-(void) fadeIn:(double)fadeTime sender:(id)sender
{
	if(!$.contains(document.body, _DOMElement.get()[0]))
			$("body").append(_DOMElement);

	_ignoreMouseUp = YES;

	[self setHighlightedMenuItem:Nil];

	setTimeout(function(){ //this is needed to differentiate a click from mouse up in a popupbutton
		_ignoreMouseUp = NO;
	}, 400);

	[self _setBodyTop:5.0];
	_disabledMouse = NO;
 
	if([_delegate respondsToSelector:@selector(menuWillShow:)])
		[_delegate performSelector:@selector(menuWillShow:) withObject:self];

	 
	_DOMElement.fadeIn(fadeTime, function(){
		
		_CPFocusMenu = self; 
		_isVisible = YES; 
		[CPApp._keyWindow resignKeyWindow]; 
		_DOMElement.makeKey(); 
		
		
	});
	
	[self _adjustMenuHeight];

	
}

-(void) show:(id)sender
{	
	[self fadeIn:0 sender:sender];
}

-(void) close:(id)sender
{
	var count = _menuItems.length,
		index = 0;
	
	[self hide];
	
	for(; index < count; index++)
	 	[_menuItems[index] closeSubmenu];
	 
	if([_supermenu isVisible] && _CPFocusMenu != _supermenu)
		[_supermenu close:self];
	
	if([_delegate respondsToSelector:@selector(menuDidClose:)])
		[_delegate performSelector:@selector(menuDidClose:) withObject:self];

	if(_CPFocusMenu === self)
		_CPFocusMenu = null; 
}


-(void) hide
{	
	_DOMElement.hide();

	var count = _menuItems.length,
		index = 0;
	
 	
	for(; index < count; index++)
	{
	 	[_menuItems[index] hideSubmenu];
	 	_menuItems[index]._DOMElement.removeClass("highlight");
	 }
	
	
	_isVisible = NO;  
 
}

-(BOOL) isVisible
{
	return _isVisible; 
}

-(void) setPosition:(CGPoint)aPoint
{
	if(_position && aPoint && CGPointEqualToPoint(_position, aPoint))
			return;

	 _position = CPMakePoint(MIN(aPoint.x, $(document).width() - _DOMElement.width()), aPoint.y);

	 _DOMElement.css({
			left : _position.x,
			top : MAX(0, _position.y)
	 });

	[self _adjustMenuHeight];
}


-(CPMenu) rootMenu
{
	if(_supermenu)
		return [_supermenu rootMenu];
		
	return self; 
}

-(void) unselectAllItems
{
		var count = _menuItems.length,
			index = 0;
			
		for(; index < count; index++)
			[_menuItems[index] setSelected:NO];
		
}

-(void) highlightFirstItem 
{
	if(_menuItems.length > 0)
	{
		[self setHighlightedMenuItem:_menuItems[0]];
		_CPFocusMenu = self; 
		_DOMElement.makeKey(); 
		
	}
}

-(int) indexOfHighlightedMenuItem
{
	if(_highlightedItem)
		return [_menuItems indexOfObject:_highlightedItem inRange:nil];
	
	return CPNotFound; 
}

-(void) insertMenuItem:(CPMenuItem)aMenuItem atIndex:(CPInteger)anIndex
{
	if(anIndex > -1 && aMenuItem)
	{	
		[aMenuItem setSupermenu:self];
		[aMenuItem setIsRadio:_radio];

		if(_radio && !_selectedItem)
			_selectedItem = aMenuItem; 
 
		if(anIndex < _menuItems.length)
		{	
			[_menuItems insertObject:aMenuItem atIndex:anIndex];
			aMenuItem._DOMElement.insertBefore(_menuItems[anIndex]._DOMElement); 

		}
		else
		{ 
			 
			[_menuItems addObject:aMenuItem]; 
			_DOMElement.children(".cpmenu-body").append(aMenuItem._DOMElement);  
		}
	}	
	
}

-(void) addItem:(CPMenuItem)aMenuItem
{
	[self insertMenuItem:aMenuItem atIndex:_menuItems.length];
}

-(int) numberOfItems
{
	return _menuItems.length; 
}

-(void) addSeparator
{
	[self insertSeparatorAtIndex:_menuItems.length];
}


-(void) insertSeparatorAtIndex:(CPInteger)anIndex
{
	if(anIndex > -1)
	{
		var menuSeparator = $("<div></div>").addClass("cpmenu-item-separator");
		if(anIndex < _menuItems.length)
		{
			menuSeparator.insertBefore(_menuItems[anIndex]._DOMElement);
		}else
		{
			_DOMElement.children(".cpmenu-body").append(menuSeparator);
		}

		[_separators addIndex:anIndex]; 
	}
}

-(CPMenuItem) itemAtIndex:(CPInteger)anIndex
{
	if(anIndex > -1 && anIndex < _menuItems.length)
		return _menuItems[anIndex];
	
	return nil; 
}

-(CPMenuItem) itemWithTitle:(CPString)aString
{
	var count = _menuItems.length,
		index = 0;

		for(; index < count; index++)
		{
			if([_menuItems[index] title] === aString)
				return _menuItems[index];
		}

		return nil;
}


-(int) indexOfItem:(CPMenuItem)aMenuItem
{
	return [_menuItems indexOfObject:aMenuItem inRange:nil];
}




-(void) selectItemAtIndex:(CPInteger)anIndex
{
	var item = [self itemAtIndex:anIndex];
	
	if(item)
	{
		[_selectedItem setSelected:NO];
		
		[item setSelected:YES];
		_selectedItem = item;
		[self setHighlightedMenuItem:item];
		
	}
	
}

-(void) selectItemWithTitle:(CPString)aString
{
	var item = [self itemWithTitle:aString];
	
	if(item)
	{
		[_selectedItem setSelected:NO];
		
		[item setSelected:YES];
		_selectedItem = item;
		[self setHighlightedMenuItem:item];
		
	}
}

-(void) scrollMenuToHighlightedItem
{
		if(_highlightedItem)
		{	
			var p = _highlightedItem._DOMElement.position().top; 
			var bodyEl = _DOMElement.children(".cpmenu-body");
		 	
			if(p + 25 >  _DOMElement.height() - 5 - _downArrowVisible*14 )
			{	
				var moveby = p+ 30 - _DOMElement.height() + _downArrowVisible*14;
				if(_position.y - moveby  >= 0)
					[self setPosition:CGPointMake(_position.x, _position.y - moveby )];
				else
					[self _setBodyTop:-p - 25]
			}else
				[self _setBodyTop:5];
			
		 	
		}
}

-(void) scrollMenuToTop 
{
	[self _setBodyTop:0.0];
	[self _showUpArrow:NO];
	
}

-(CPArray) itemArray
{
	return _menuItems; 
}


-(double) menuHeight
{
	if(_menuItems.length > 0)
	{
		var itemHeight = _menuItems[0]._DOMElement.height()+1; 
		return _menuItems.length*itemHeight + [_separators count]*6 + 9; 

	}

	return [_separators count]*6 + 9; 
}


-(void) removeAllItems
{
	$.each(_menuItems, function(index, item){
			item._DOMElement.remove();
	});

	[_menuItems removeAllObjects];
}


-(void) keyDown:(CPEvent)theEvent
{
	
	_disabledMouse = YES;   
	var KC = theEvent.which; 

	if(KC === CPDownArrowKeyCode)
	{ 	
           var index = [self indexOfHighlightedMenuItem];  

           if (index < _menuItems.length - 1) {
                   index++;
                   var nextItem = _menuItems[index]; 
                   while(![nextItem isEnabled] && index < _menuItems.length)
					{
						index++;
						nextItem = _menuItems[index];
					}
				
				   [self setHighlightedMenuItem:nextItem]; 
				   [self scrollMenuToHighlightedItem];  
                  
				   return;
           }
	}else if(KC === CPUpArrowKeyCode)
	{

          var index = [self indexOfHighlightedMenuItem];
         if(index < 0)
         {
         	 var nextItem = [_menuItems lastObject];
         	 [self setHighlightedMenuItem:nextItem]; 
         	 return;
         }

		 if(index > 0)
		 {
				index--;
				var nextItem = _menuItems[index];
				while(![nextItem isEnabled] && index > -1)
				{
					index--;
					nextItem = _menuItems[index];
				}	
				[self setHighlightedMenuItem:nextItem]; 
				[self scrollMenuToHighlightedItem]; 

				return;
		 }

	}else if(KC === CPRightArrowKeyCode)
	{  
		if(_highlightedItem)
		{	 
			if([_highlightedItem submenu])
			{  
				 [_highlightedItem _showSubmenu:YES]; 
				 return; 
			} 
		}

		if([_supermenu isKindOfClass:[_CPMenuBar class]])
			[_supermenu keyDown:theEvent];
		 
		 
	

	}else if(KC === CPLeftArrowKeyCode)
	{
		
		if([_supermenu isKindOfClass:[_CPMenuBar class]])
			[_supermenu keyDown:theEvent];
		else
		{
			if(_supermenu)
			{
				_CPFocusMenu = _supermenu; 
				_supermenu._DOMElement.makeKey();
				[self hide];
			}
		}
		

	}else if(KC === CPReturnKeyCode)
	{
		if(_highlightedItem)
		{	
			[_highlightedItem triggerAction];

			return;
		} 
	}else if(KC === CPEscapeKeyCode)
	{	
		[[self rootMenu] close:self];
	} 
	else 
	{
			var keyChar = String.fromCharCode(theEvent.which).toUpperCase();

			var count =  _menuItems.length,
				sindex = [self indexOfHighlightedMenuItem],
				index = sindex+1,
				pass = 0;   

			while(index != sindex && pass < 2)
			{
				if(_menuItems[index])
				{
					var firstCharTitle = [[_menuItems[index] title] characterAtIndex:0].toUpperCase();
					if(keyChar === firstCharTitle && _menuItems[index] !== _highlightedItem)
					{
						[self setHighlightedMenuItem:_menuItems[index]]; 
						[self scrollMenuToHighlightedItem]; 
						return; 
					}
				}

				index++; 
				if(index >= count)
				{
					index = 0;
					pass++; 
				}
			}
	}
}

@end

var CPMenuPositionKey					= @"CPMenuPositionKey",
	CPMenuTitleKey						= @"CPMenuTitleKey",
	CPMenuItemsKey						= @"CPMenuItemsKey",
	CPMenuWidthKey						= @"CPMenuWidthKey",
	CPMenuRadioKey						= @"CPMenuRadioKey",
	CPMenuSeparatorsKey					= @"CPMenuSeparatorsKey",
	CPMenuDelegateKey					= @"CPMenuDelegateKey";

 

@implementation CPMenu (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];
	
	if(self)
	{
		_DOMElement = CPMenuDOMElementPrototype.clone(false);
	 
		_menuItems = []; 
		 
		[self _attachEvents];
		 
		var items = [aCoder decodeObjectForKey:CPMenuItemsKey],
			count = items.length,
			index = 0;
		
		 
		for(; index < count; index++)
		{
			[self addItem:items[index]];
		}
	
		var sep = [aCoder decodeObjectForKey:CPMenuSeparatorsKey];
		var idxes = [];

		[sep getIndexes:idxes maxCount:-1 inIndexRange:nil];

		var count = idxes.length;
		index = 0;
	
		for(; index < count; index++)
		{
			[self insertSeparatorAtIndex:idxes[index]];
		}
		
		[self setPosition:[aCoder decodePointForKey:CPMenuPositionKey]];
		[self setTitle:[aCoder decodeObjectForKey:CPMenuTitleKey]];
		[self setWidth:[aCoder decodeDoubleForKey:CPMenuWidthKey]];
		[self setIsRadio:[aCoder decodeBoolForKey:CPMenuRadioKey]];
		
		_upArrowVisible = NO;
		_downArrowVisible = NO;
		_isVisible = NO; 
		
		_disabledMouse = NO;
		_bodyTop = 0.0;
		_scrollTimerUp = null;
		_scrollTimerDown = null; 
		
		[self _setBodyTop:5.0];
		
		[self _showDownArrow:NO];
		[self _showUpArrow:NO];
	 		
	 	[self setDelegate:[aCoder decodeObjectForKey:CPMenuDelegateKey]];
	}
	
	
	return self; 
}


-(void) encodeWithCoder:(CPCoder)aCoder
{
	 
	[super encodeWithCoder:aCoder];
	 
	[aCoder encodePoint:_position forKey:CPMenuPositionKey];
	[aCoder encodeObject:_title forKey:CPMenuTitleKey];
	[aCoder encodeObject:_menuItems forKey:CPMenuItemsKey];
	[aCoder encodeDouble:_width forKey:CPMenuWidthKey];
	[aCoder encodeBool:_radio forKey:CPMenuRadioKey];
	[aCoder encodeObject:_separators forKey:CPMenuSeparatorsKey];
	[aCoder encodeConditionalObject:_delegate forKey:CPMenuDelegateKey];
}



@end

