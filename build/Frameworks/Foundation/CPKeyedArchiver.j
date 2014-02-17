@import "CPCoder.j" 

/*! 
    @class CPKeyedArchiver
    @ingroup foundation
    @brief Archives CP objects into a JSON Object. 

*/

var CPKeyedArchiverClassKey = @"__CLASS__";
 

@implementation CPKeyedArchiver : CPCoder
{
    id          _json; 
}


/*!
    Archives the object into a JSON Object
    @param rootObject the object to archive
    @return a JSON Object
*/

+(id)archivedDataWithRootObject:(id)rootObject
{
    var json = {};
    var archiver = [[self alloc] initForWritingWithMutableData:json];
    
    return [archiver _encodeObject:rootObject];

   
     
}

+ (BOOL)allowsKeyedCoding
{
    return YES;
}

- (id)initForWritingWithMutableData:(JSON)json
{
    if (self = [super init])
    {
        _json = json; 
         
    }
    return self;
}

-(void) encodeConditionalObject:(id)objectToEncode forKey:(CPString)aKey
{   
     _json["$$" + aKey + "$$"] =  [objectToEncode UID];
}

- (void)encodeObject:(id)objectToEncode forKey:(CPString)aKey
{   
    _json[aKey] = [self _encodeObject:objectToEncode];
     
    
}

- (JSON)_encodeObject:(id)objectToEncode
{
    var encodedJSON = {};
    
    if ([self _isObjectAPrimitive:objectToEncode])  // Primitives or Null
    {
        encodedJSON = objectToEncode;
    }
    else if(objectToEncode.isa != undefined) // CP objects  
    {
	 
        var archiver = [[[self class] alloc] initForWritingWithMutableData:encodedJSON];
        encodedJSON[CPKeyedArchiverClassKey] = class_getName([objectToEncode class]);
        [objectToEncode encodeWithCoder:archiver];

    }else // JS Objects
    {
        encodedJSON = objectToEncode
    }
    

    return encodedJSON;
}

-(void)_encodeArrayOfObjects:(CPArray)array forKey:(CPString)key
{
	 
	var jsonArray =  [];
	var count = [array count];
	for(var i = 0; i < count; i++)
	{
		var obj = array[i];
		jsonArray.push([self _encodeObject:obj]);
	}
	
	_json[key] = jsonArray;
	
}

- (void)encodeNumber:(int)aNumber forKey:(CPString)aKey
{
    [self encodeObject:aNumber forKey:aKey];
}

-(void)encodeDouble:(double)aNumber forKey:(CPString)aKey
{
	 [self encodeObject:aNumber forKey:aKey];
}

- (void)encodeFloat:(float)aNumber forKey:(CPString)aKey
{
    [self encodeObject:aNumber forKey:aKey];
}

- (void)encodeBool:(BOOL)aBoolean forKey:(CPString)aKey
{
    [self encodeObject:aBoolean forKey:aKey];
}

-(void)encodeRect:(Rect)aRect forKey:(CPString)aKey
{
 	[self encodeObject:JSON.stringify(aRect) forKey:aKey];
	
}

-(void)encodePoint:(Point)aPoint forKey:(CPString)aKey
{ 
	[self encodeObject:JSON.stringify(aPoint) forKey:aKey];
	
}

-(void)encodeSize:(Size)aSize forKey:(CPString)aKey
{
	[self encodeObject:JSON.stringify(aSize) forKey:aKey];
}

- (void)encodeInt:(int)anInt forKey:(CPString)aKey
{
    [self encodeObject:anInt forKey:aKey];
}

- (JSONObject)_encodeDictionaryOfObjects:(CPDictionary)dictionaryToEncode forKey:(CPString)aKey
{
    var encodedDictionary = {};
    
    var keys = [dictionaryToEncode allKeys];
    for (var i = 0; i < [keys count]; i++)
    {
        encodedDictionary[keys[i]] = [self _encodeObject:[dictionaryToEncode objectForKey:keys[i]]];
    }
    
    _json[aKey] = encodedDictionary;
}

- (BOOL)_isObjectAPrimitive:(id)anObject
{
    var typeOfObject = typeof(anObject); 
    return (typeOfObject === "string" || typeOfObject === "number" || typeOfObject === "boolean" || 
          anObject === null);
}

@end
