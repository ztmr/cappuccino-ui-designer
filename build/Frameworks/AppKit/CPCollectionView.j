@import <Foundation/CPArray.j>
@import <Foundation/CPIndexSet.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>


@import "CPScrollView.j"
@import "CPCollectionViewItem.j"

if(!Object.keys)
{
	Object.keys = function(anObject)
	{
	 	var keys = [];
		for(var aKey in anObject)
			keys.push(aKey);
			
		return keys; 
	};
}
 


@implementation CPCollectionView : CPView
{
	double 							_verticalMargin @accessors(property=verticalMargin);
	double							_spacing @accessors(property=horizontalMargin);

	CGSize   						_minSize @accessors(getter=minItemSize);
	CGSize 							_maxSize @accessors(getter=maxItemSize);
	CGSize 							_itemSize ;

	int 							_maxNumberOfColumns @accessors(property=maximumNumberOfColumns) ;  

	BOOL							_selectable @accessors(property=selectable);
	BOOL							_allowsMultipleSelection @accessors(property=allowsMultipleSelection);
	BOOL							_allowsEmptySelection @accessors(property=allowsEmptySelection);
	BOOL							_allowsAnimation @accessors(property=allowsAnimation);


	CPCollectionViewItem			_itemPrototype @accessors(property=itemPrototype);
	id 								_delegate @accessors(property=delegate); 

	CPIndexSet						_selectedIndexes @accessors(getter=selectionIndexes); 

	CPArray							_content @accessors(getter=content); 


	CPView 							_contentView;
	CPScrollView					_scrollView; 

	int 							_ncols;
	int 							_nrows; 
	double 							_virtualHeight;
	JSObject						_cachedItems;
	JSTimer 						_renderTimer; 
	int 							_lastStart;
	int 							_lastEnd;


}

-(BOOL)acceptsFirstResponder 
{
	return YES; 
}

-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];

	if(self)
	{	
		_maxNumberOfColumns = Number.MAX_VALUE; 
		_maxNumberOfRows = Number.MAX_VALUE; 
		_verticalMargin = 5.0;
		_minSize = CGSizeMake(50,50);
		_maxSize = CGSizeMake(Number.MAX_VALUE,Number.MAX_VALUE);

		_selectedIndexes = [CPIndexSet indexSet];

		_contentView = null; 
		_scrollView = null; 
		_spacing = 5.0;
		_ncols = 0.0;
		_nrows = 0.0; 
		_virtualHeight = 0;
		_cachedItems = {};
		_renderTimer = null; 
		_selectable = YES; 
		_allowsAnimation = YES;
		_allowsEmptySelection = NO;
		_allowsMultipleSelection = YES; 

		_lastStart = Number.MAX_VALUE;
		_lastEnd = -1; 

		[self _init];
		
	}

	return self; 
}

-(void) _init 
{

	_DOMElement.addClass("cpcollectionview");

	if(!_contentView)
	{
		_contentView = [[CPView alloc] initWithFrame:CGRectMakeZero()];
		[_contentView setAutoresizesSubviews:NO]; 
	}

	if(!_scrollView)
	{
		_scrollView = [[CPScrollView alloc] initWithFrame:[self bounds]];
		[_scrollView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
		[_scrollView setDocumentView:_contentView];
		[_scrollView setHasHorizontalScroller:NO];

		 
		[_ephemeralSubviews addObject:_scrollView]; 
		[self addSubview:_scrollView];
	} 

	[[CPNotificationCenter defaultCenter] addObserver:self 
										  selector:@selector(onScrollTop:) 
										  name:CPScrollTopNotification 
										  object:_scrollView];

}




-(void) setContent:(CPArray)content 
{	
	
	if([_content isEqual:content])
		return; 

	_content = content;
	 
	[self reloadContent];
}

-(void) setMinItemSize:(CGSize)aSize 
{
	if(CGSizeEqualToSize(_minSize, aSize))
		return;

	_minSize = CGSizeMake(MIN(aSize.width, _maxSize.width), MIN(aSize.height, _maxSize.height));

	if(self.itemPrototype)
		[self _reloadWithCache:_allowsAnimation];

}



-(void) setMaxItemSize:(CGSize)aSize 
{
	if(CGSizeEqualToSize(_maxSize, aSize))
		return;

	_maxSize = aSize;

	if(self.itemPrototype)
		[self _reloadWithCache:_allowsAnimation];

}

-(void) setHorizontalMargin:(double)value 
{
	if(_spacing===value)
		return;

	_spacing = value;

	if(self.itemPrototype)
		[self _reloadWithCache:_allowsAnimation];
}

-(CPScrollView) scrollView 
{
	return _scrollView; 
}
 

-(void) onScrollTop:(CPNotification)aNotification
{
	if(_renderTimer)
	{
		clearTimeout(_renderTimer);
		_renderTimer = null; 
	}
}

-(void) setItemPrototype:(id)proto 
{	

	_itemPrototype = proto;
	_itemPrototype._collectionView = self;

	[self _reloadWithCache:_allowsAnimation];
}

-(void) _computeSpacing
{
	if(_content && _itemPrototype)
	{	

		//compute layout
		
		var iw = _minSize.width,
			ih = _minSize.height;

		_ncols = MIN(_maxNumberOfColumns, FLOOR((_frame.size.width - 16-_spacing)/(iw + _spacing)))
		 
		if(_ncols < 1)
			_ncols = 1; 

		var horizontalWidth = _spacing+_ncols*(iw + _spacing) + 16;
		 
		while(horizontalWidth < _frame.size.width && iw < _maxSize.width)
		{
			iw+=1.0;
			horizontalWidth = _spacing+_ncols*(iw + _spacing) + 16;
			 
		}
 
		var n = _content.length; 
 	 
		_nrows = MIN(_maxNumberOfRows, CEIL(n/_ncols));

		_virtualHeight = (ih + _verticalMargin)*_nrows + _verticalMargin; 
		
		_itemSize = CGSizeMake(iw,ih);

		[_contentView setFrameSize:CGSizeMake(_frame.size.width, MAX(_frame.size.height - 16.0, 
			 _virtualHeight))]; 
	}

}

-(void) _layout:(BOOL)animate
{
 	
	if(!_itemPrototype)
		[CPException raise:CPInternalInconsistencyException reason:@"CPCollectionView has no item prototype!"];

	if(_content && _itemPrototype)
	{ 
		var n = MIN(_ncols*_nrows, _content.length);
		 
		var iw = _itemSize.width,
			ih = _itemSize.height; 

		 
		 
		var scrollTop = [_scrollView scrollTop],
			bottomScrollRow = MAX(0, CEIL(scrollTop/(ih + _verticalMargin)) - 50),
			startIndex = MAX(0, _ncols*(bottomScrollRow - 1)),
			topScrollRow = CEIL((scrollTop + _frame.size.height)/(ih + _verticalMargin)) + 50,
			endIndex = MIN(n, _ncols*(topScrollRow + 1)),
			index  = startIndex; 

		
 		if(startIndex < _lastStart || endIndex > _lastEnd)
 		{
 			_lastEnd = endIndex;
 			_lastStart = startIndex; 

			var xpos = _spacing,
				ypos = _verticalMargin + (ih + _verticalMargin)*MAX(0, (bottomScrollRow - 1)),
				colcount = 0;  

			var archive = [CPKeyedArchiver archivedDataWithRootObject:_itemPrototype];
			
			for(; index < endIndex; index++)
			{
				var item = null; 
				var key = "" + index; 
				if(_cachedItems.hasOwnProperty(key)) 
				{	
					item = _cachedItems[key];
				}
				else
				{	
					var obj = _content[index];

					item = [CPKeyedUnarchiver unarchiveObjectWithData:archive];
					item._collectionView = self; 
					[item setRepresentedObject:obj];
					
					_cachedItems[key] = item;  

				}

				var v = [item view]; 
				
				[v setFrameSize:CGSizeCreateCopy(_itemSize)];
				
				var frame = [v frame];
				var pt = CGPointMake(xpos, ypos);
				v._nextOrigin = pt; 
 			 
				[_contentView addSubview:v];

				if(!CGPointEqualToPoint(frame.origin, pt) && animate)
				{
					v._DOMElement.animate({left:pt.x, top:pt.y}, 200, $.proxy(function(){
							[this setFrameOrigin:this._nextOrigin]; 
					}, v));

				}
				else 
					[v setFrameOrigin:pt]; 
				 
				colcount++; 
				xpos+=(iw + _spacing);
				if(colcount >= _ncols)
				{
					xpos = _spacing; 
					colcount = 0;
					ypos+=(ih + _verticalMargin);
				} 
			} 
		}
		
	}
}

-(void) setFrameSize:(CGSize)aSize
{	
	[super setFrameSize:aSize];

	if(!_itemPrototype)
		[CPException raise:CPInternalInconsistencyException reason:@"CPCollectionView has no item prototype!"];


	[_contentView setFrameSize:CGSizeMake(_frame.size.width, 
						MAX(_frame.size.height - 16.0, _virtualHeight))];
	
	if(_renderTimer)
	{
		clearTimeout(_renderTimer);
		_renderTimer = null; 
	}
	
	_lastStart = Number.MAX_VALUE;
	_lastEnd = -1;

	var timeout = _allowsAnimation ? 200 : 0; 
	
	_renderTimer = setTimeout(function(){
		[self _computeSpacing];
		[self _layout:(_allowsAnimation && Object.keys(_cachedItems).length > 0)];
		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
	}, timeout); 
}

-(CPCollectionViewItem) itemAtIndex:(int)anIndex
{
	if(_cachedItems.hasOwnProperty(""+anIndex))
		return _cachedItems[""+anIndex];

	return nil; 
}

-(void) setSelectionIndexes:(CPIndexSet)indexes 
{

	if(!indexes)
		indexes = [CPIndexSet indexSet];

	if(!_selectable || [_selectedIndexes isEqual:indexes])
		return;

	_selectedIndexes = indexes;

	var count = Object.keys(_cachedItems).length,
		index = 0;

	 
	for(; index < count; index++)
	{
		var item = [self itemAtIndex:index];
		[item setSelected:[_selectedIndexes containsIndex:index]];
	}

	if(_delegate && [_delegate respondsToSelector:@selector(collectionViewDidChangeSelection:)])
		[_delegate performSelector:@selector(collectionViewDidChangeSelection:) withObject:self];

}

-(void) _reloadWithCache:(BOOL)animate
{

	_lastStart = Number.MAX_VALUE;
	_lastEnd = -1;
	
	[self _computeSpacing];
	[self _layout:animate]; 

	var _selIndexes = _selectedIndexes;
	[self setSelectionIndexes:nil];
	[self setSelectionIndexes:_selIndexes]; 
}

-(void) reloadContent
{	
	 
	if(_contentView)
	{
		_contentView._DOMElement.empty();
		_contentView._subviews = [];
	}
	
	_cachedItems = {};
	[self _reloadWithCache:NO];
}

-(void) mouseDown:(CPEvent)theEvent
{
	[[self window] makeFirstResponder:self];

	var pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
 
	var x = pt.x, 
		y = pt.y + [_scrollView scrollTop]; 

	var iw = _itemSize.width,
		ih = _itemSize.height; 


	var row = CEIL(y/(ih + _verticalMargin));
	var col = CEIL(x/(iw + _spacing));

	var index = _ncols*(row - 1) + col - 1; 
	var key = "" + index;

	if(_cachedItems.hasOwnProperty(key))
	{	
		var item = _cachedItems[key];
		var frame = [[item view] frame];
		
		if(CGRectContainsPoint(frame, CPMakePoint(x,y)))
		{
			if(_allowsMultipleSelection && [theEvent shiftKey])
			{
					[item setSelected:YES];
					if(![_selectedIndexes containsIndex:index])
					{	
						[_selectedIndexes addIndex:index];
							if(_delegate && [_delegate respondsToSelector:@selector(collectionViewDidChangeSelection:)])
								[_delegate performSelector:@selector(collectionViewDidChangeSelection:) withObject:self];
					} 
			}
			else
			{	 
			 	[self setSelectionIndexes:[CPIndexSet indexSetWithIndex:index]];
			}

		}else
		{	 if(_allowsEmptySelection)
				[self setSelectionIndexes:nil];
		}
	}else
	{
	 	 if(_allowsEmptySelection)
			[self setSelectionIndexes:nil];
	}

	[super mouseDown:theEvent];
}


-(void) keyDown:(CPEvent)theEvent
{
	var selectedIndex = [_selectedIndexes firstIndex]; 
		 
	if(selectedIndex > -1)
	{ 
		var nextIndex = selectedIndex; 
		var kc = [theEvent keyCode];

		if(kc === CPRightArrowKeyCode)
		{
			 nextIndex++; 
		}
		else if(kc === CPLeftArrowKeyCode)
		{
			 nextIndex--; 
		}
		else if(kc === CPDownArrowKeyCode)
		{
			nextIndex+=_ncols;
		}
		else if(kc === CPUpArrowKeyCode)
		{
			nextIndex-=_ncols;
		}
		else
	 	{
	 		[super keyDown:theEvent];
	 	}

	 	 if(nextIndex != selectedIndex && nextIndex >= 0 && nextIndex < _content.length)
	 	 {
		 	 var idxset = [CPIndexSet indexSetWithIndex:nextIndex];
			 [self setSelectionIndexes:idxset]; 
			 var key = "" +  nextIndex;
			 var item = _cachedItems[key]
			 if(item)
			 {
			 	var rect = item._view._frame; 
 
			 	if(![_scrollView isRectVisible:rect])
			 		[_scrollView setScrollTop:rect.origin.y - _verticalMargin];
 
			 }
	 	 }


	}
}


@end