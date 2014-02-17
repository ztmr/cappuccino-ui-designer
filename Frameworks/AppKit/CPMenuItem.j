@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>

@import "CPImage.j"
@import "CPEvent.j" 

var CPMenuItemDOMElementPrototype = null; 



@implementation CPMenuItem : CPObject
{
		BOOL				_checkable;
		BOOL 				_selectable @accessors(property=selectable, getter=isSelectable);
		BOOL				_enabled @accessors(getter=isEnabled); 
		BOOL				_isChecked @accessors(getter=isChecked); 
		BOOL				_radio; 
		BOOL				_selected @accessors(getter=isSelected); 
		
		int					_tag @accessors(property=tag);
		
		CPImage				_icon;
		
		CPMenu				_submenu @accessors(getter=submenu);
		CPMenu				_menu;
		
		CPString			_title @accessors(getter=title); 
	
		id 					_target @accessors(property=target);
		SEL					_action @accessors(property=action);
		
		DOMElement			_DOMElement;

		 
}

+(void) initialize
{
	
	CPMenuItemDOMElementPrototype = $("<div></div>").addClass("cpmenu-item");
	CPMenuItemDOMElementPrototype.attr("role", "menuitem");
	
	CPMenuItemDOMElementPrototype.append($("<div></div>").addClass("cpmenu-item-icon"));
	CPMenuItemDOMElementPrototype.append($("<label></label>").addClass("cpmenu-item-label"));
}

+(id) menuItemWithTitle:(CPString)aTitle
{
	var m = [[CPMenuItem alloc] init];
	[m setTitle:aTitle];
	
	return m; 
}

-(id) init
{
	self = [super init];
	
	if(self)
	{
		_DOMElement = CPMenuItemDOMElementPrototype.clone(false);
		
		[self _attachEvents];
		
		_icon = null;
		_enabled = YES;
		_selectable = YES; 
		_checkable = NO;
		_isChecked = NO; 
		_radio = NO;
		_selected = NO; 
		_title = null;
		_target = null;
		_action = null; 
		_submenu = null; 
		_menu = null; 
		_tag = -1; 
		
 
		 
	}
	
	return self; 
}

-(void) _attachEvents
{
	_DOMElement.bind({
		mousedown : function(evt)
		{
			evt.stopPropagation();
			evt.preventDefault(); 
		},
		click : function(evt)
		{
			evt.stopPropagation();
			evt.preventDefault(); 
		},
		mouseup : function(evt){
			
				evt.stopPropagation();
				evt.preventDefault(); 
				
				if(![self isEnabled])
					return;

				if(![self isSelectable])
					return; 

				if(_menu._ignoreMouseUp)
					return; 

				if(_submenu)
					return; 
			
				if(evt.which < 2)
					[self triggerAction];
					
	  	},
		mouseenter : function(evt)
		{	
			evt.stopPropagation(); 
 			
 			if(![self isEnabled])
				return;
			 
			if(_menu && !_menu._disabledMouse)
			{
				_CPFocusMenu = _menu; 
				_menu._DOMElement.makeKey();
				if([self isSelectable]) 
					[_menu setHighlightedMenuItem:self];
				else
					[_menu setHighlightedMenuItem:Nil];

				self._submenutimer = setTimeout(function(){
					[self _showSubmenu:NO];
				}, 300); 
			
			}
			
		} 
	});
}

-(void) setCheckable:(BOOL)aFlag
{
	_checkable = aFlag;
	
	if(_checkable)
	{
		[self setIsRadio:NO];
		if(_isChecked)
			_DOMElement.children(".cpmenu-item-icon").addClass("checked");
		else
			_DOMElement.children(".cpmenu-item-icon").removeClass("checked");
	}
}

-(void) setChecked:(BOOL)aFlag
{
	_isChecked = aFlag;
	if(_checkable)
	{
		if(_isChecked)
			_DOMElement.children(".cpmenu-item-icon").addClass("checked");
		else
			_DOMElement.children(".cpmenu-item-icon").removeClass("checked");
	}
	
}

-(void) setEnabled:(BOOL)aFlag
{
	_enabled = aFlag; 
	
	if(_enabled)
		_DOMElement.removeClass("disabled");
	else
		_DOMElement.addClass("disabled");
}

 
-(void) setHighlighted:(BOOL)aFlag
{
	if(aFlag && _enabled)
	{
		_DOMElement.addClass("highlight");
		
	}
	else
	{
		_DOMElement.removeClass("highlight");
		[self hideSubmenu];
	}
}

-(void) _hideSubmenu
{	
	if(self._submenutimer)
	{
		clearTimeout(self._submenutimer);
		self._submenutimer = null; 
	}

	[_submenu hide];
}

-(void) _showSubmenu:(BOOL)highlightFirstItem
{
	if(_submenu)
	{
		var offset = _DOMElement.offset(); 
		
		if(offset.left + _DOMElement.width() + _submenu._DOMElement.width() <= $(window).width())
			[_submenu setPosition:CGPointMake(offset.left + _DOMElement.width(), offset.top-6)];
	 	else
			[_submenu setPosition:CGPointMake(offset.left - _submenu._DOMElement.width(), offset.top-6)];
	  
		[_submenu show:nil];
		
		if(highlightFirstItem)
			[_submenu highlightFirstItem]; 
	}
}

-(CPMenu) submenu 
{
	return _submenu; 
}

-(void) setSubmenu:(CPMenu)aMenu
{
	_submenu = aMenu;
	if(_submenu)
	{
		_DOMElement.append($("<div></div>").addClass("cpmenu-item-triangle-bullet"));
		[_submenu setSupermenu:_menu];
	}
}

-(void) setIcon:(CPImage)anImage
{
	_DOMElement.children(".cpmenu-item-icon").remove();
	
	if(anImage)
	{
		_icon = anImage;
		[_icon setSize:CGSizeMake(14,14)];
		var iconDOM = [_icon DOMElement];
		iconDOM.addClass("cpmenu-item-icon");
		_DOMElement.prepend(iconDOM);
	}
}

-(void) setIsRadio:(BOOL)aFlag
{
	_radio = aFlag; 
	
	if(_radio)
	{
		[self setCheckable:NO];
		if(_selected)
			_DOMElement.children(".cpmenu-item-icon").addClass("selected");
		else
			_DOMElement.children(".cpmenu-item-icon").removeClass("selected");
	}
	else
		_DOMElement.children(".cpmenu-item-icon").removeClass("selected");
}

-(void) setSupermenu:(CPMenu)aMenu
{
	_menu = aMenu;
	
	if(_submenu)
		[_submenu setSupermenu:_menu];
}
 

-(void) setSelected:(BOOL)aFlag
{
	_selected = aFlag;
	
	if(_radio)
	{
		if(_selected)
			_DOMElement.children(".cpmenu-item-icon").addClass("selected");
		else
			_DOMElement.children(".cpmenu-item-icon").removeClass("selected");
	}
}
 

-(void) setTitle:(CPString)aTitle
{
	
	_title = aTitle;
	
	_DOMElement.children(".cpmenu-item-label").text(_title);
}

-(void) closeSubmenu
{
	if([_submenu isVisible])
		[_submenu close:self];
}

-(void) hideSubmenu
{
	 [self _hideSubmenu];
}

-(void) toggleCheck
{
	if(_checkable)
		[self setChecked:!_isChecked];
}


-(void) triggerAction
{
	_menu._disabledMouse = YES; 
	
	var flash = setInterval(function(){
		if(_DOMElement.hasClass("highlight"))
			_DOMElement.removeClass("highlight");
		else
			_DOMElement.addClass("highlight");

	}, 60);

	setTimeout(function(){

		clearTimeout(flash);

		if(_radio)
	 	{
			[_menu unselectAllItems];
			[self setSelected:YES];
	 	}
		else if(_checkable)
		{
			[self setChecked:!_isChecked];
		}	

		[_menu setSelectedItem:self];

 		[_menu close:self]; 
 
		if(_action && _target)
		{
			[CPApp sendAction:_action to:_target from:self];
		}

		_menu._disabledMouse = NO; 

		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];


	}, 200);
	
	
	
	
}
 
@end
 

var CPMenuItemCheckableKey 					= @"CPMenuItemCheckableKey",
	CPMenuItemEnabledKey					= @"CPMenuItemEnabledKey",
	CPMenuItemIsCheckedKey					= @"CPMenuItemIsCheckedKey",
	CPMenuItemIsRadioKey					= @"CPMenuItemIsRadioKey", 
	CPMenuItemSelectableKey					= @"CPMenuItemSelectableKey",
	CPMenuItemTagKey						= @"CPMenuItemTagKey",
	CPMenuItemIconKey						= @"CPMenuItemIconKey",
	CPMenuItemSubMenuKey					= @"CPMenuItemSubMenuKey",
	CPMenuItemTitleKey						= @"CPMenuItemTitleKey",
	CPMenuItemActionKey						= @"CPMenuItemActionKey",
	CPMenuItemTargetKey						= @"CPMenuItemTargetKey";
	

@implementation CPMenuItem (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super init];
	
	if( self )
	{
	 	
		_tag = [aCoder decodeIntForKey:CPMenuItemTagKey];
		
		_DOMElement = CPMenuItemDOMElementPrototype.clone(false);
		
		[self setEnabled:[aCoder decodeBoolForKey:CPMenuItemEnabledKey]];
		[self setCheckable:[aCoder decodeBoolForKey:CPMenuItemCheckableKey]];
		[self setChecked:[aCoder decodeBoolForKey:CPMenuItemIsCheckedKey]];
		[self setIsRadio:[aCoder decodeBoolForKey:CPMenuItemIsRadioKey]];
		[self setSubmenu:[aCoder decodeObjectForKey:CPMenuItemSubMenuKey]];
		[self setSelectable:[aCoder decodeBoolForKey:CPMenuItemSelectableKey]];
		
		[self setIcon:[aCoder decodeObjectForKey:CPMenuItemIconKey]];
		
		[self setAction:[aCoder decodeObjectForKey:CPMenuItemActionKey]];
		
		if([aCoder containsValueForKey:CPMenuItemTargetKey])
			[self setTarget:[aCoder decodeObjectForKey:CPMenuItemTargetKey]];
	
		[self setTitle:[aCoder decodeObjectForKey:CPMenuItemTitleKey]];
 	

 		[self _attachEvents];
		 
	}
	
	return self; 
}

-(void) encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeBool:_checkable forKey:CPMenuItemCheckableKey];
	[aCoder encodeBool:_enabled forKey:CPMenuItemEnabledKey];
	[aCoder encodeBool:_isChecked forKey:CPMenuItemIsCheckedKey];
	[aCoder encodeBool:_radio forKey:CPMenuItemIsRadioKey];
	[aCoder encodeInt:_tag forKey:CPMenuItemTagKey];
	[aCoder encodeBool:_selectable forKey:CPMenuItemSelectableKey];
	
	[aCoder encodeObject:_icon forKey:CPMenuItemIconKey];
	[aCoder encodeObject:_submenu forKey:CPMenuItemSubMenuKey];
	[aCoder encodeObject:_title forKey:CPMenuItemTitleKey];
	[aCoder encodeObject:_action forKey:CPMenuItemActionKey]; 
	[aCoder encodeConditionalObject:_target forKey:CPMenuItemTargetKey];
}


@end


 