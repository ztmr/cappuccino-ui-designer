@import <Foundation/CPArray.j>
@import <Foundation/CPIndexSet.j>

@import "CPControl.j"
@import "CPButton.j" 

//style
var CPSegmentStyleRounded = 1,
   	CPSegmentStyleTexturedRounded = 2,
   	CPSegmentStyleSquare = 3; 

//tracking

var CPSegmentSwitchTrackingSelectOne = 0,
	CPSegmentSwitchTrackingSelectAny = 1,
	CPSegmentSwitchTrackingMomentary = 2;



@implementation CPSegmentedControl : CPControl
{	

	JSObject 					_segmentTitles; 
	JSObject					_segmentWidths; 
	JSObject					_segmentImages; 
	JSObject					_segmentTags; 

	CPArray						_segments; 

	CPIndexSet					_selectedIndexes @accessors(getter=selectedSegments); 

	int 						_lastChangedSegment @accessors(getter=changedSegment);
	int 						_segmentCount @accessors(getter=segmentCount);
	 

	int 						_segmentStyle @accessors(getter=segmentStyle);
	int   						_trackingStyle @accessors(getter=trackingStyle);

}

-(id) initWithFrame:(CGRect)aFrame
{

	self = [super initWithFrame:aFrame];
	if(self)
	{
		_segmentTitles = {};
		_segmentWidths = {};
		_segmentImages = {};  
		_segmentTags = {}; 
		_segments = []; 

		_selectedIndexes = [CPIndexSet indexSet];
		_segmentCount = 0; 

		_segmentStyle = CPSegmentStyleRounded;
		_trackingStyle = CPSegmentSwitchTrackingSelectOne;
 		 
	}


	return self;

}


-(BOOL)acceptsFirstResponder
{
	return NO; 
}

-(CPString)labelForSegment:(int)segment 
{

	if(_segmentTitles.hasOwnProperty(segment))
		return _segmentTitles[segment];


	return @""; 
}



-(int) tagForSegment:(int)segment
{
	if(_segmentTags.hasOwnProperty(segment))
		return _segmentTags[segment];


	return -1; 
}

-(void) setTag:(int)tag forSegment:(int)segment
{
	if(segment > -1 && segment < _segmentCount)
		_segmentTags[segment] = tag; 
}

-(void)setLabel:(CPString)aString forSegment:(int)segment
{
	[self setLabel:aString forSegment:segment inState:CPControlNormalState];
}

-(void) setLabel:(CPString)aString forSegment:(int)segment inState:(int)state
{
	if(segment > -1 && segment < _segmentCount)
	{	
		if(!_segmentTitles[segment])
			_segmentTitles[segment] = {};

		_segmentTitles[segment][state] = aString;

		if(segment < [_segments count])
		{
			[[_segments objectAtIndex:segment] setTitle:aString forState:state];
		}
		else
			[self setNeedsLayout];
	}
}

-(CPImage) imageForSegment:(int)segment inState:(int)state 
{

	if(_segmentImages.hasOwnProperty(segment))
	{
		if(_segmentImages[segment].hasOwnProperty(state))
			return _segmentImages[segment][state];
	}
		


	return nil;
}

-(void) setImage:(CPImage)anImage forSegment:(int)segment 
{
	[self setImage:anImage forSegment:segment inState:CPControlNormalState];
}

-(void) setImage:(CPImage)anImage forSegment:(int)segment inState:(int)state
{	
	if(segment > -1 && segment < _segmentCount)
	{
		if(!_segmentImages[segment])
			_segmentImages[segment] = {};

		_segmentImages[segment][state] = anImage;

		if(segment < [_segments count])
		{
			[[_segments objectAtIndex:segment] setImage:anImage forState:state];
		}
		else
			[self setNeedsLayout];
	}

}

-(double) widthForSegment:(int)segment 
{
	if(_segmentWidths.hasOwnProperty(segment))
		return _segmentWidths[segment];

	return 0.0; 
}

-(void) setWidth:(double)aWidth forSegment:(int)segment
{
	if(segment > -1 && segment < _segmentCount)
	{
		_segmentWidths[segment] = aWidth;

		[self setNeedsLayout];
	}
}

-(void) setSegmentCount:(int)segCount 
{
	if(_segmentCount === segCount)
		return; 

	_segmentCount = segCount; 

	[self setNeedsLayout];
}


-(void) setSegmentStyle:(int)segStyle 
{
	if(_segmentStyle === segStyle)
		return;

	_segmentStyle = segStyle;

	[self setNeedsLayout];
}

-(void) setTrackingStyle:(int)trackingStyle 
{
	_trackingStyle = trackingStyle; 
}

-(void) selectSegmentWithTag:(int)aTag
{
	for(var idx in _segmentTags)
	{
		if(_segmentTags[idx] === aTag)
		{
			if(_trackingStyle == CPSegmentSwitchTrackingSelectOne)
				[self setSelected:NO forSegment:[_selectedIndexes firstIndex]];
			
			[self setSelected:YES forSegment:idx];
			return; 
		}
	}
}

-(BOOL) isSelectedForSegment:(int)segment 
{
	return [_selectedIndexes containsIndex:segment];
}

-(void) setSelected:(BOOL)aFlag forSegment:(int)segment
{
	if(segment > -1 && segment < _segmentCount)
	{
		if(aFlag)
			[_selectedIndexes addIndex:segment];
		else
			[_selectedIndexes removeIndex:segment]; 

		if(segment < [_segments count])
		{	
			if(aFlag)
				[[_segments objectAtIndex:segment] setState:CPControlSelectedState];
			else
				[[_segments objectAtIndex:segment] setState:CPControlNormalState];
		}
		else
			[self setNeedsLayout];

	}
}
 

-(void) layoutSubviews
{
		if([_segments count] !== _segmentCount)
		{
			[_segments removeAllObjects];
			[_ephemeralSubviews removeAllObjects];

			while([[self subviews] count])
				[[[self subviews] objectAtIndex:0] removeFromSuperview];

			var x = 0,
				w = (_frame.size.width)/_segmentCount;

			
			for(var i = 0; i < _segmentCount; i++) 
			{
				var segment = [[CPButton alloc] initWithFrame:CGRectMake(x, 0, w, _frame.size.height)];
				//[segment setAutoresizingMask:CPViewWidthSizable];
				
				[segment setTarget:self];
				[segment setAction:@selector(_onSelect:)];
				 
				[segment setThemeAttributes:[self themeAttributes]];
				[segment setEnabled:[self isEnabled]];

				if(_segmentStyle === CPSegmentStyleTexturedRounded)
					[segment setBezelStyle:CPTexturedRoundedBezelStyle];
				else if(_segmentStyle === CPSegmentStyleSquare)
					[segment setBezelStyle:CPRegularSquareBezelStyle];
				
				segment._DOMElement.addClass("cpsegment");

				if(i === 0)
					segment._DOMElement.addClass("left");
	 			if(i === _segmentCount -1)
					segment._DOMElement.addClass("right");
				 
				if([_selectedIndexes containsIndex:i])
				{ 	
					[segment setState:CPControlSelectedState];
				}
				else
					[segment setState:CPControlNormalState];
 
				if(_segmentTitles.hasOwnProperty(i))
				{
					for(var state in _segmentTitles[i])
					{
						if(_segmentTitles[i].hasOwnProperty(state))
							[segment setTitle:_segmentTitles[i][state] forState:state]; 
					}
				}
					

				if(_segmentImages.hasOwnProperty(i))
				{
					for(var state in _segmentImages[i])
					{
						if(_segmentImages[i].hasOwnProperty(state))
							[segment setImage:_segmentImages[i][state] forState:state]; 
					}
				}
				
 
				if(_segmentWidths.hasOwnProperty(i))
					[segment setFrameSize:CGSizeMake(_segmentWidths[i], CGRectGetHeight(segment._frame))];

				[self addSubview:segment];
				
				[_ephemeralSubviews addObject:segment];
				[_segments addObject:segment];

				x+=(CGRectGetWidth(segment._frame) - 1);
				w = (_frame.size.width - CGRectGetMaxX(segment._frame))/(_segmentCount - i - 1);
			}

			_autoresizesSubviews = NO; 
			[self setFrameSize:CGSizeMake(x + _segmentCount-1, _frame.size.height)];
			_autoresizesSubviews = YES;	
	} 

}

-(void) _onSelect:(id)sender 
{	
	_lastChangedSegment = [_segments indexOfObject:sender];


	if(_trackingStyle == CPSegmentSwitchTrackingSelectOne)
		[self setSelected:NO forSegment:[_selectedIndexes firstIndex]];

	if(_trackingStyle === CPSegmentSwitchTrackingSelectAny || 
		_trackingStyle === CPSegmentSwitchTrackingSelectOne)
	{
		[self setSelected:![_selectedIndexes containsIndex:_lastChangedSegment] forSegment:_lastChangedSegment];
 
	}

	[self triggerAction];
}


-(void) sizeToFit
{
	var index = 0,
		w = 0,
		h = 0,
		width =0;  
	
	for(; index < _segmentCount; index++)
	{	
		w = 0; 

		if(_segmentImages.hasOwnProperty(index))
		{ 
			w = MIN(MAX(16,_frame.size.height - 2), 32); 
		}

		if(_segmentTitles.hasOwnProperty(index))
		{
			var sz = [_segmentTitles[index] sizeWithFont:[self font]]; 
			w+=(sz.width + 22)
			h = MAX(h, sz.height+10);
		}
		else
			w+=10; 

		_segmentWidths[index] = w; 
		width+=w; 
	}

	[self setFrameSize:CGSizeMake(width,_frame.size.height)];   
	
}


-(void) setEnabled:(BOOL)bool 
{
	[super setEnabled:bool];

	var count = [_subviews count],
		i = 0;

	for(; i < count; i++)
	{
		[[_subviews objectAtIndex:i] setEnabled:bool];
	}

}

-(void) setEnable:(BOOL)bool forSegment:(int)segment 
{
	if(segment > -1 && segment < _segments.length)
	{
		[[_subviews objectAtIndex:segment] setEnabled:bool];
	}
}


 - (void)resizeSubviewsWithOldSize:(CGSize)aSize
{
	var count = _segments.length,
		i = 0; 

	var x = 0; 

	for(; i < count; i++)
	{
		var seg = [_segments objectAtIndex:i];
		var p = seg._frame.size.width/aSize.width;
		var newWidth = p*_frame.size.width;

		[self setWidth:newWidth forSegment:i];

		[seg setFrame:CGRectMake(x, 0, newWidth, _frame.size.height)];
		x+=(newWidth-1); 
	}

	 

}

@end


var CPSegmentedControlTitlesKey 					= @"CPSegmentedControlTitlesKey",
	CPSegmentedControlWidthsKey						= @"CPSegmentedControlWidthsKey",
	CPSegmentedControlImagesKey						= @"CPSegmentedControlImagesKey",
	CPSegmentControlAltImagesKey					= @"CPSegmentControlAltImagesKey",
	CPSegmentedControlCountKey						= @"CPSegmentedControlCountKey",
	CPSegmentedControlStyleKey						= @"CPSegmentedControlStyleKey",
	CPSegmentControlTagsKey 						= @"CPSegmentedControlTagsKey", 
	CPSegmentedControlTrackingKey					= @"CPSegmentedControlTrackingKey";
 
@implementation CPSegmentedControl (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];

	if(self)
	{
		_segmentTitles = [aCoder decodeObjectForKey:CPSegmentedControlTitlesKey];
		_segmentWidths = [aCoder decodeObjectForKey:CPSegmentedControlWidthsKey];
		_segmentTags = [aCoder decodeObjectForKey:CPSegmentedControlTagsKey];
		 
		_segmentImages = [aCoder decodeObjectForKey:CPSegmentedControlImagesKey];
		_segments = []; 

		_selectedIndexes = [CPIndexSet indexSet];
		_segmentCount = [aCoder decodeObjectForKey:CPSegmentedControlCountKey]; 

		_segmentStyle = [aCoder decodeObjectForKey:CPSegmentedControlStyleKey];
		_trackingStyle = [aCoder decodeObjectForKey:CPSegmentedControlTrackingKey];

		_DOMElement.css("overflow", "visible"); //this is need due to border clipping
	}


	return self;
}


-(void) encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_segmentTitles forKey:CPSegmentedControlTitlesKey];
	[aCoder encodeObject:_segmentWidths forKey:CPSegmentedControlWidthsKey];
	[aCdoer encodeObject:_segmentTags forKey:CPSegmentedControlTagsKey];
	[aCoder encodeInt:_segmentCount forKey:CPSegmentedControlCountKey];
	[aCoder encodeInt:_segmentStyle forKey:CPSegmentedControlStyleKey];
	[aCoder encodeInt:_trackingStyle forKey:CPSegmentedControlTrackingKey];
	[aCoder encodeObject:_segmentImages forKey:CPSegmentedControlImagesKey];
	 

	[aCoder encodeObject:imgPaths forKey:CPSegmentedControlImagesKey];


}


@end