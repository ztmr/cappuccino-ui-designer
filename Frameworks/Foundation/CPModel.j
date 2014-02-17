@import "CPObject.j"

@implementation CPModel : CPObject 
{

}



@end


@implementation CPModel (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder 
{
	self = [super init];

	if(self)
	{
		var theClass = objj_getClass(class_getName([self class]));

		var ivarCount = theClass.ivar_list.length,
			i = 0; 

		for(; i < ivarCount; i++)
		{
			var ivar = theClass.ivar_list[i];

			[self setValue:[aCoder decodeObjectForKey:ivar.name] forKey:ivar.name];
 
		}

	}

	return self; 
}

-(void) encodeWithCoder:(CPCoder)aCoder 
{
	[super encodeWithCoder:aCoder];

	var theClass = objj_getClass(class_getName([self class]));

	var ivarCount = theClass.ivar_list.length,
		i = 0; 

	for(; i < ivarCount; i++)
	{
		var ivar = theClass.ivar_list[i];
	    var d = [self valueForKey:ivar.name];
		[aCoder encodeObject:d forKey:ivar.name];
	}

}

@end