@import "CPDictionary.j"
@import "CPArray.j"
@import "CPSet.j"
@import "CPCoder.j"


/*! 
    @class CPKeyedUnarchiver
    @ingroup foundation
    @brief Unarchives CP objects from a JSON Object. 

*/


var CPKeyedUnarchiverClassKey = @"__CLASS__";

var _CPDecodedObjectsByUID = {}; 
var _CPRootObject = null;  

@implementation CPKeyedUnarchiver : CPCoder
{
    JSON    _json; 

    
}

/*!
    Unarchives the JSON representation of a CP object.
    @param json JSON representation of a CP object
    @return the unarchived object.
*/

+ (id)unarchiveObjectWithData:(JSON)json
{

    _CPRootObject = json;  

    var unarchiver = [[self alloc] initForReadingWithData:json];
    var decodedObject = [unarchiver _decodeObject:json]; 

     _CPDecodedObjectsByUID = {};
     _CPRootObject = null; 

    return decodedObject; 
}

- (id)initForReadingWithData:(JSON)json
{
    if (self = [super init])
    {
        _json = json; 
    }
    return self;
}

- (id)decodeObjectForKey:(CPString)aKey
{   
    if([self _isConditionalKey:aKey]) //reference object
    {   
        var UID = _json["$$" + aKey + "$$"];

        if(UID)
        {   
            if(_CPDecodedObjectsByUID.hasOwnProperty(UID))
                return _CPDecodedObjectsByUID[UID];  // if null this dependency has been visited but is not yet encode -- circular reference -- returns null for now
            else
            {  
                var dependency = _CPCoderFindObjectWithUID(UID, _CPRootObject);
                if(dependency)
                    return [self _decodeObject:dependency];

                return null;    
            }
        }

    }

    return [self _decodeObject:_json[aKey]];
} 

-(BOOL) _isConditionalKey:(CPString)aKey 
{
    return _json.hasOwnProperty("$$" + aKey + "$$");
}

- (int)decodeNumberForKey:(CPString)aKey
{
    return [self _decodeObject:_json[aKey]];
}

- (int)decodeIntForKey:(CPString)aKey
{
    return [self _decodeObject:_json[aKey]];
}

-(double)decodeDoubleForKey:(CPString)aKey
{
	return [self _decodeObject:_json[aKey]];
}


- (float)decodeFloatForKey:(CPString)aKey
{
    return [self _decodeObject:_json[aKey]];
}

- (BOOL)decodeBoolForKey:(CPString)aKey
{
    return [self _decodeObject:_json[aKey]];
}

-(CGRect)decodeRectForKey:(CPString)aKey
{
	return JSON.parse([self _decodeObject:_json[aKey]]);
 
}

-(Point)decodePointForKey:(CPString)aKey
{
	return JSON.parse([self _decodeObject:_json[aKey]]);
}

-(Size)decodeSizeForKey:(CPString)aKey
{
 	return JSON.parse([self _decodeObject:_json[aKey]]);
}

-(BOOL)containsValueForKey:(CPString)key
{
	return _json.hasOwnProperty(key) || _json.hasOwnProperty("$$" + key + "$$");
}

- (id)_decodeObject:(JSONObject)encodedJSON
{
  
    if ([self _isJSONAPrimitive:encodedJSON]) // Primitives
    {
        return encodedJSON;
    
	}else if(Object.prototype.toString.call(encodedJSON) === '[object Array]')
	{	
	 
		 	var array = []; 
			var jsonArray = encodedJSON;
			var length = jsonArray.length;
		 
			for(var i = 0; i < length; i++)
			{
				if(jsonArray[i] != undefined)
			         array.push([self _decodeObject:jsonArray[i]]);
				 
			}
			 
			return array; 
	}
	else  
    { 
		if(encodedJSON === undefined)
			return null; 

        if(encodedJSON.hasOwnProperty(CPKeyedUnarchiverClassKey)) //CPObject
        {
             if(_CPDecodedObjectsByUID.hasOwnProperty(encodedJSON["UID"]))
                return _CPDecodedObjectsByUID[encodedJSON["UID"]];

            _CPDecodedObjectsByUID[encodedJSON["UID"]] = null; 

            var unarchiver = [[[self class] alloc] initForReadingWithData:encodedJSON];
 
            var theClass = objj_getClass(encodedJSON[CPKeyedUnarchiverClassKey]);

            _CPDecodedObjectsByUID[encodedJSON["UID"]] =  [[[theClass class] alloc] initWithCoder:unarchiver];

            return _CPDecodedObjectsByUID[encodedJSON["UID"]];
        }
        else //JS Object
        {
            return encodedJSON;
        }
	 
    }
    
    return nil;
}





- (id)_decodeDictionaryOfObjectsForKey:(CPString)aKey
{
    var decodedDictionary = [CPDictionary dictionary];
    
    var encodedJSON = _json[aKey];
    for (var key in encodedJSON)
    {
        if (key !== CPKeyedUnarchiverClassKey)
        {
            [decodedDictionary setObject:[self _decodeObject:encodedJSON[key]] forKey:key];
        }
    }

    return decodedDictionary;
}

- (BOOL)_isJSONAPrimitive:(JSONObject)json
{
    var typeOfObject = typeof(json); 
    return (typeOfObject === "string" || typeOfObject === "number" || typeOfObject === "boolean" || json === null);
}

@end




function _CPCoderGetChildNodes(rootObject)
{
    
     if(rootObject.hasOwnProperty(CPKeyedUnarchiverClassKey))
     {  
        var className = rootObject[CPKeyedUnarchiverClassKey];
        //if an array, return items
        if(className === class_getName([CPArray class]) ||
            className === class_getName([CPSet class]))
             return rootObject["CP.objects"];

        var childNodes = [];

        if(className === class_getName([CPDictionary class]))
        {   
            var objs = rootObject["CP.objects"];
            for(var key in objs)
            {    
                var obj = objs[key];
                if(obj instanceof Object && obj.hasOwnProperty(CPKeyedUnarchiverClassKey))
                    childNodes.push(obj);
            } 

            return childNodes; 
        }

        for(var property in rootObject)
        {  
            var obj = rootObject[property];
            
            if(obj instanceof Object && obj.hasOwnProperty(CPKeyedUnarchiverClassKey)) //is a CPObject
                childNodes.push(obj);
                

        }

        return childNodes; 
         
     }
     
     return [];
     
}


function _CPCoderFindObjectWithUID(UID, rootObject) /* depth first search */
{
    if(rootObject.hasOwnProperty("UID"))
    {   
        if(rootObject["UID"] === UID)
            return rootObject; 
    }
    

    var childNodes = _CPCoderGetChildNodes(rootObject);

    var count = childNodes.length,
        index = 0;

    for(; index < count; index++)
    {
        var object = _CPCoderFindObjectWithUID(UID, childNodes[index]);

        if(object)
            return object; 
    }

    return null; 

}