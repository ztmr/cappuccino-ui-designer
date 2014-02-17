/*! 
    @class CPNumber
    @ingroup foundation
    @brief CPNumber serves to box of primitive numbers.

*/

 

@import "CPObject.j"

var CPNumberUIDs = {}; 
 
@implementation CPNumber : CPObject
{


}

+ (id)alloc
{
    var result = new Number();
    result.isa = [self class];
    return result;
}

+ (id)numberWithBool:(BOOL)aBoolean
{
    return aBoolean;
}

+ (id)numberWithChar:(char)aChar
{
    if (aChar.charCodeAt)
        return aChar.charCodeAt(0);

    return aChar;
}

+ (id)numberWithDouble:(double)aDouble
{
    return aDouble;
}

+ (id)numberWithInt:(int)anInt
{
    return anInt;
}

- (id)initWithBool:(BOOL)aBoolean
{
    return aBoolean;
}

- (id)initWithChar:(char)aChar
{
    if (aChar.charCodeAt)
        return aChar.charCodeAt(0);

    return aChar;
}

- (id)initWithDouble:(double)aDouble
{
    return aDouble;
}

- (id)initWithInt:(int)anInt
{
    return anInt;
}

- (CPString)UID
{
    var UID = CPNumberUIDs["n" + self]

    if (UID === undefined)
    {
        UID = objj_generateObjectUID();
        CPNumberUIDs["n" + self] = "" + UID; 
    }
    
    return UID + "";
}

- (BOOL)boolValue
{
    // Ensure we return actual booleans.
    return self ? true : false;
}

- (char)charValue
{
    return String.fromCharCode(self);
}


- (double)doubleValue
{
    if (typeof self == "boolean")
        return self ? 1 : 0;
    return self;
}

- (int)intValue
{
    if (typeof self == "boolean")
        return self ? 1 : 0;
    return self;
}

- (CPString)stringValue
{
    return self.toString();
}


- (CPComparisonResult)compare:(NSNumber)aNumber
{
    if (self > aNumber)
        return CPOrderedDescending;
    else if (self < aNumber)
        return CPOrderedAscending;

    return CPOrderedSame;
}

- (BOOL)isEqualToNumber:(CPNumber)aNumber
{
    return self == aNumber;
}

-(BOOL) isEqual:(id)anObject
{

    return  self === anObject ||
           [anObject isKindOfClass:[self class]] &&
           [self isEqualToNumber:anObject];

}

@end

@implementation CPNumber (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    return [aCoder decodeNumber];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{   
    [super encodeWithCoder:aCoder];
    [aCoder encodeNumber:self forKey:@"self"];
}

@end



Number.prototype.isa = CPNumber;
Boolean.prototype.isa = CPNumber;