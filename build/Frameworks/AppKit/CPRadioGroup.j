@import "CPRadio.j"
@import "CPMatrix.j"


@implementation CPRadioGroup : CPMatrix
{
		CPRadio  				_selected @accessors(getter=selectedRadio); 
}


-(id) initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];

	if( self )
	{	
		[self setItemPrototype:[[CPRadio alloc] initWithFrame:CGRectMake(0,0,80,27)]];	

		_selected = Nil; 
	}	


	return self ;
}

-(void) onControlAction:(id)sender
{
	[self setSelectedRadio:sender];
	[super onControlAction:sender];
}

-(void) setSelectedRadio:(id)sender
{
	if(_selected !== sender)
	 	[_selected setState:CPControlNormalState];
		
 	_selected = sender;
 	[_selected setState:CPControlSelectedState];
 	 

}	

@end