@import <Foundation/CPArray.j>
@import <Foundation/CPKeyedArchiver.j>
@import <Foundation/CPKeyedUnarchiver.j>

@import "CPControl.j"



@implementation CPMatrix : CPControl
{

	int  					_rows @accessors(getter=rows);
	int 					_columns @accessors(getter=columns); 
	
	id						_itemPrototype @accessors(property=itemPrototype);

	CPArray					_content @accessors(getter=content); 



}

-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];
	if(self)
	{
		[self setRows:1];
		[self setColumns:1];
	}

	return self; 
}

-(BOOL)acceptsFirstResponder
{
	return NO; 
}

-(void) setContent:(CPArray)content
{
	_content = content;
	[_ephemeralSubviews removeAllObjects];
	[self setNeedsLayout];
}

-(void) setRows:(int)rows
{
	[_ephemeralSubviews removeAllObjects];
	_rows = rows;
	[self setNeedsLayout];
}

-(void) setColumns:(int)columns
{
	[_ephemeralSubviews removeAllObjects];

	_columns = columns;
	[self setNeedsLayout];
}

-(void)_doLayout:(BOOL)sizeToFit
{
	if(_itemPrototype)
	{
		var iw = _frame.size.width/_columns - 2;
		var ih = _frame.size.height/_rows - 2; 

		var count = MIN([_content count], _columns*_rows),
			index = 0;

		var ccol = 0, crow = 0,
			xpos = 0, ypos = 0, rowH = 0,
			maxH = 0, maxW = 0, x, y; 

 		
 		var archive = [CPKeyedArchiver archivedDataWithRootObject:_itemPrototype];
 		var lastRowView = null,
 			lastColumnView = null; 

 		for(; index < count; index++)
 		{
 			var config = null;
 			if(index < [_content count])
 				config = [_content objectAtIndex:index];

 			var protoClone = [CPKeyedUnarchiver unarchiveObjectWithData:archive];

 			[protoClone setFrameOrigin:CGPointMake(xpos, ypos)]; 
 			if([protoClone isKindOfClass:[CPControl class]])
 			{
	 			[protoClone setTarget:self];
	 			[protoClone setAction:@selector(onControlAction:)];
	 			[protoClone setEnabled:[self isEnabled]];
	 			[protoClone setFont:[self font]];
	 			[protoClone setTextAlignment:[self textAlignment]];
	 			[protoClone setTextColor:[self textColor]];
	 			[protoClone setLineBreakMode:[self lineBreakMode]];
	 		}

 			if(config)
 			{
 				for(var citem in config)
 					[protoClone setValue:config[citem] forKeyPath:citem];
 			} 

 			if(sizeToFit && [protoClone respondsToSelector:@selector(sizeToFit)])
 				[protoClone sizeToFit]; 

 			[_ephemeralSubviews addObject:protoClone];

 			if(rowH < CGRectGetHeight([protoClone frame]))
 				rowH = CGRectGetHeight([protoClone frame]);

 			if(maxH < CGRectGetHeight([protoClone frame]))
 				maxH = CGRectGetHeight([protoClone frame]);

 			if(maxW < CGRectGetWidth([protoClone frame]))
 				maxW = CGRectGetWidth([protoClone frame]);


 			if(ccol === _columns-1)
 				lastColumnView = protoClone; 

 			if(ccol < _columns - 1)
 			{
 				xpos+=CGRectGetWidth([protoClone frame]);
 				ccol++;
 			}
 			else
 			{	
 				 
 				xpos = 0;
 				ypos+=rowH;
 				rowH = 0;
 				ccol = 0;
 				crow++; 
 				
 			}	

 			lastRowView = protoClone;

 		} 
 		
 		if(sizeToFit)
 		 	[self setFrameSize:CGSizeMake(CGRectGetMaxX([lastColumnView frame]) + (_columns-1)*2, CGRectGetMaxY([lastRowView frame]) + _rows*2)];
 		
	}
	else
	{
		[CPException raise:@"CPMatrixNoPrototype" reason:@"No item prototype for CPMatrix"];
	}


}

-(void) onControlAction:(id)sender
{
	[self triggerAction];
}

-(void) layoutSubviews
{
	while([_subviews count])
		[[_subviews objectAtIndex:0] removeFromSuperview];
	 
	if([_ephemeralSubviews count] == 0)
		[self _doLayout:NO];

	[_ephemeralSubviews enumerateObjectsUsingBlock:function(aView){
		 [self addSubview:aView];
	}];

}
 

-(void) setEnabled:(BOOL)aFlag
{
	[super setEnabled:aFlag];

	var count = [_subviews count],
		i = 0;

	for(; i < count; i++)
	{
		if([[_subviews objectAtIndex:i] respondsToSelector:@selector(setEnabled:)])
			[[_subviews objectAtIndex:i] setEnabled:aFlag];
	}
}

-(id) itemAtRow:(int)aRow column:(int)aCol
{
	var index = aRow*_columns + aCol; 
	 
	return [_subviews objectAtIndex:index];
	
}

-(void)setCellSize:(CGSize)aSize
{
	[_ephemeralSubviews removeAllObjects];

	[_itemPrototype setFrameSize:aSize];

	[self setNeedsLayout];
}

-(void) sizeToFit
{	
	  
     [_ephemeralSubviews removeAllObjects]

	 [self _doLayout:YES];

	 [self setNeedsLayout];
	 
}



@end


var CPMatrixRowsKey 			= @"CPMatrixRowsKey",
	CPMatrixColumnsKey			= @"CPMatrixColumnsKey",
	CPMatrixPrototypeKey		= @"CPMatrixPrototypeKey",
	CPMatrixContentKey			= @"CPMatrixContentKey";


@implementation CPMatrix (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
	self = [super initWithCoder:aCoder];

	if( self )
	{
		[self setRows:[aCoder decodeIntForKey:CPMatrixRowsKey]];
		[self setColumns:[aCoder decodeIntForKey:CPMatrixColumnsKey]];
		[self setItemPrototype:[aCoder decodeObjectForKey:CPMatrixPrototypeKey]];
		[self setContent:[aCoder decodeObjectForKey:CPMatrixContentKey]];
	}
	

	return self; 
}


-(void)encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeInt:_rows forKey:CPMatrixRowsKey];
	[aCoder encodeInt:_columns forKey:CPMatrixColumnsKey];
	[aCoder encodeObject:_itemPrototype forKey:CPMatrixPrototypeKey];
	[aCoder encodeObject:_content forKey:CPMatrixContentKey];
}


@end