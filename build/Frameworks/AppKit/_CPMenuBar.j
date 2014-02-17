@import <Foundation/CPArray.j>

#define CPMenuBarHeight 28.0

var _CPMenuBarVisible = NO;

@implementation _CPMenuBar : CPResponder
{
		CPArray					_menus; 
		CPArray					_items @accessors(getter=itemArray); 
		
		BOOL					_menubarActive;
		int						_activeIndex @accessors(property=activeIndex);
		
		
		DOMElement				_DOMElement; 
		
}

-(id) init
{
	self = [super init];
	
	if(self)
	{
		_menubarActive = NO;
		_activeIndex = -1;
		
		_DOMElement = $("<div></div>").addClass("cpmenubar");
		_DOMElement.css({
			height : CPMenuBarHeight,
			position : "absolute"
		});
		
		_DOMElement.attr({
			"role" : "menubar",
			"tabindex" : 0
		});
		
		_DOMElement.bind({
			keydown: function(evt)
			{
				evt.preventDefault();
				evt.stopPropagation();
				[self keyDown:evt];
			},
			keyup : function(evt)
			{	
				evt.preventDefault();
				evt.stopPropagation();
				
			}
		});
		
		_items = []; 
		_menus = []; 

		[self setNextResponder:CPApp];
	}

	return self; 
	
}

-(CPWindow) window
{
	return [CPApp mainWindow];
}

-(CPMenu) rootMenu
{
	return self; 
}

-(BOOL) isVisible
{
	return [CPMenu menuBarVisible] && [self isActive]; 
}

-(void) close:(id)sender 
{	
	 if([sender isVisible])
	 	[sender close:nil];
	 
}

-(void) addItem:(CPMenu)aMenu
{
	var item = [[_CPMenuBarItem alloc] initWithMenu:aMenu inMenuBar:self];
	[item setIndex:_items.length]; 
	
	if(_items.length === 0)
		item._DOMElement.css("margin-left", 10);
		
	
	_DOMElement.append(item._DOMElement);
	
	[_menus addObject:aMenu];
	[_items addObject:item];
}
 
-(BOOL) isActive
{
	return _activeIndex >= 0; 
}

-(void) keyDown:(CPEvent)evt
{
	 	if([self isActive])
		{
			var KC = evt.which,
				i = _activeIndex;
			
			if(KC === CPRightArrowKeyCode)
			{
				if(i + 1 < _items.length)
				{	
					[_items[i] close];
					[_items[i+1] open]; 
				}
			}else if(KC === CPLeftArrowKeyCode)
			{	
				if(i - 1 >= 0)
				{
					[_items[i] close];
					[_items[i-1] open];
				}
				
			}
			else if(KC === CPDownArrowKeyCode)
			{
				[_items[i]._menu highlightFirstItem];
				
			}
			else if(KC === CPEscapeKeyCode)
			{
				[_items[i] close];
				_activeIndex = -1; 
			} 
		}
}




@end



@implementation _CPMenuBar (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [self init];
	if( self)
	{
		var arr = [aCoder decodeObjectForKey:@"CPMenuBarMenusKey"],
			count = arr.length,
			i = 0;
			
		for(; i < count; i++)
		{
			[self addItem:arr[i]];
		}
		
	}
	
	return self; 
	
}


-(void) encodeWithCoder:(CPCoder)aCoder
{
	
	[aCoder encodeObject:_menus forKey:@"CPMenuBarMenusKey"];


}


@end



@implementation _CPMenuBarItem : CPObject
{
	 _CPMenuBar						_menubar;
	 CPMenu							_menu;
	
	 int							_index @accessors(property=index);
	
	 DOMElement						_DOMElement;
	 
}


-(id) initWithMenu:(CPMenu)menu inMenuBar:(_CPMenuBar) menubar 
{
	self = [super init];
	
	if(self)
	{	
		_menu = menu; 
		_menu._delegate = self; 
		_menu._supermenu = menubar;  
		_menubar = menubar; 
		_index = -1; 
 
		
		_DOMElement = $("<div></div>").addClass("cpmenubar-menu");
		_DOMElement.attr({
			role : "menuitem",
			"aria-haspopup" : true,
			"tabindex" : 0
		});
		
		_menu._DOMElement.addClass("menubar");
		
		_DOMElement.bind({
			mousedown :function(evt)
			{	
				evt.preventDefault();
				evt.stopPropagation();

				CPApp._keyWindow = CPApp._mainWindow; 
				_CPResponderLastMouseDown = CPApp._mainWindow.contentView; 
 				

				if(_DOMElement.hasClass("selected"))
				{
					[self close];
				}else
				{	
					[self open];
				}  
			},
			mouseup : function(evt)
			{
				evt.preventDefault();
				evt.stopPropagation(); 
				
				if(_menu._ignoreMouseUp)
					return; 

				_DOMElement.makeKey(); 
			},
			mouseenter : function(evt)
			{	
				evt.preventDefault();
				evt.stopPropagation();  

				if([_menubar isActive])
					[self open];
				
			}
		});
		 
		var textAndArrow = $("<div></div>").addClass("cpmenubar-menu-text");
		textAndArrow.append($("<label></label>").css("float", "left").text([_menu title])); 
		textAndArrow.append($("<div></div>").addClass("cpmenubar-menu-arrow")); 

		_DOMElement.append(textAndArrow);
	}
	
	return self; 
}

-(void) menuDidClose:(CPMenu)menu
{
	[self close];
}


-(void) open
{
	[_menubar setActiveIndex:_index];
	
	_DOMElement.addClass("selected");
	
	var offset = _DOMElement.offset();
	
	[_menu setPosition:CGPointMake(offset.left, offset.top + CPMenuBarHeight + 1)];
	[_menu setWidth:MAX(180, _DOMElement.width())];
	
	if(![_menu isVisible])
		[_menu show:self];
	 

}

-(void) close
{	
	_DOMElement.removeClass("selected");
	
	if([_menu isVisible])
	 	[_menu close:self];
	 
	if([_menubar activeIndex] === _index)
		[_menubar setActiveIndex:-1];
}

@end

