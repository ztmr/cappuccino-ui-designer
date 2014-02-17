(function(global){


CPLog = function(aString)
{
    if(typeof console != "undefined")
        console.log(aString);

};

CPLog.error = function(aString)
{
    if(typeof console != "undefined")
            console.error(aString);
};

CPLog.warn = function(aString)
{
    if(typeof console != "undefined")
        console.warn(aString);  
};

Npm = global; 
NO = false;
YES = true;
nil = null;
Nil = null;
NULL = null;
ABS = Math.abs; 
ASIN = Math.asin;
ACOS = Math.acos;
ATAN = Math.atan; 
ATAN2 = Math.atan2;
SIN = Math.sin;
COS = Math.cos;
TAN = Math.tan;
EXP = Math.exp;
POW = Math.pow;
CEIL = Math.ceil;
FLOOR = Math.floor;
ROUND = Math.round;
MIN = Math.min;
MAX = Math.max;
RAND = Math.random;
SQRT = Math.sqrt;
E = Math.E;
LN2 = Math.LN2;
LN10 = Math.LN10;
LOG2E = Math.LOG2E;
LOG10E = Math.LOG10E;
PI = Math.PI;
PI2 = Math.PI * 2.0;
PI_2 = Math.PI / 2.0;
SQRT1_2 = Math.SQRT1_2;
SQRT2 = Math.SQRT2;
 


OBJECT_COUNT = 0;
REGISTERED_CLASSES = { };

objj_generateObjectUID = function()
{   
    return OBJECT_COUNT++;
};

objj_ivar = function( aName, aType)
{
    this.name = aName;
    this.type = aType;
};


objj_method = function( aName, anImplementation, types)
{
    this.name = aName;
    this.method_imp = anImplementation;
    this.types = types;
};

/* use this to allocate class */ 
objj_class = function(displayName)
{
    this.isa = null;
    this.version = 0;
    this.super_class = null;
    this.sub_classes = [];
    this.name = null; 
    this.info = {};
    this.ivar_list = []; 
    this.ivar_store = function(){}
    this.ivar_dtable = this.ivar_store.prototype;   
    this.method_list = [];
    this.method_store = function(){}
    this.method_dtable = this.method_store.prototype;
    this.allocator = function() { };
    this._UID = -1;
     
};

objj_object = function()
{
    this.isa = null;
    this._UID = -1;
};

objj_getClass = function( aName)
{ 
    var theClass = REGISTERED_CLASSES[aName];
    return theClass ? theClass : null; 
};

objj_allocateClassPair = function(superclass, aName)
{

    var classObject = new objj_class(aName),
    rootClassObject = classObject;


    if(superclass)
    {
        rootClassObject = superclass;
        while (rootClassObject.superclass)
            rootClassObject = rootClassObject.superclass;
			
		if(!superclass.allocator)
			throw new Error("Unknown superclass for object " + aName);
			
        classObject.allocator.prototype = new superclass.allocator;
        classObject.ivar_dtable = classObject.ivar_store.prototype = new superclass.ivar_store;
        classObject.method_dtable = classObject.method_store.prototype = new superclass.method_store; 

        classObject.super_class = superclass; 
     
    }   
    else
    {
        classObject.info.rootObject = true; 
        classObject.allocator.prototype = new objj_object(); 

    }

    classObject.isa = classObject; 
    classObject.name = aName; 
    classObject._UID = objj_generateObjectUID(); 
  
    
    return classObject;
};



objj_lookUpClass =  function(/*String*/ aName)
{
    var theClass = REGISTERED_CLASSES[aName];

    return theClass ? theClass : Nil;
};

objj_msgSend = function( aReceiver, aSelector)
{
    if (aReceiver == null)
        return null;
    
    var isa = aReceiver.isa;
   
    var method = isa.method_dtable[aSelector]; 
     
    if(!method){CPLog.error(isa.name + " does not implement selector '" + aSelector + "'"); return;}

    if(method)
    { 

        var implementation =  method.method_imp ;
        
        switch(arguments.length)
        {
            case 2: return implementation(aReceiver, aSelector);
            case 3: return implementation(aReceiver, aSelector, arguments[2]);
            case 4: return implementation(aReceiver, aSelector, arguments[2], arguments[3]);
        }
    
        return implementation.apply(aReceiver, arguments);
    }
};


objj_msgSendSuper = function( aSuper, aSelector)
{
    var super_class = aSuper.super_class;
    arguments[0] = aSuper.receiver;
     
    var method = super_class.method_dtable[aSelector];

    if(!method){CPLog.error(super_class.name + " does not implement selector '" + aSelector + "'"); return;}
    
    if(method)
    {
        var implementation =  method.method_imp ;
        return implementation.apply(aSuper.receiver, arguments);
    }
};



objj_registerClassPair = function(aClass)
{
    global[aClass.name] = aClass;
    REGISTERED_CLASSES[aClass.name] = aClass;    
};


class_createInstance = function( aClass)
{
    if (!aClass)
        throw new Error("*** Attempting to create object with Nil class.");
    
    var object = new aClass.allocator();
    object.isa = aClass;
    object._UID = objj_generateObjectUID();
     
    return object;
};

class_addIvars = function(aClass, ivars)
{
    var count = ivars.length;
        thePrototype = aClass.allocator.prototype;
    for (var index = 0; index < count;  index++)
    {
        var ivar = ivars[index],
            name = ivar.name;
        if (typeof thePrototype[name] === "undefined")
        {
            aClass.ivar_list.push(ivar);
            aClass.ivar_dtable[name] = ivar;
            thePrototype[name] = null;
        }
    }
};

class_addMethod = function(/*Class*/ aClass, /*SEL*/ aName, /*IMP*/ anImplementation, /*Array<String>*/ types)
{
    if(!aName)
        return NO; 
    // FIXME: return NO if it exists?
    var method = new objj_method(aName, anImplementation, types);

    aClass.method_list.push(method);
    aClass.method_dtable[aName] = method; 
 
    if(aName == "initialize")
        objj_msgSend(aClass, "initialize");

    return YES;
};

class_addMethods = function( aClass, methods)
{
    var index = 0,
        count = methods.length,
        method_list = aClass.method_list,
        method_dtable = aClass.method_dtable;
    
    
    for (var index = 0; index < count; index++)
    {
        var method = methods[index];
         
        if(method)
        { 
            method_list.push(method);
            method_dtable[method.name] = method;

            if(method.name == "initialize")
                objj_msgSend(aClass, "initialize");
        }
    }
 
};


class_copyMethodList = function( aClass)
{
    return aClass.method_list.slice(0);
};

 

class_getInstanceMethod = function( aClass, aSelector)
{
    if (!aClass || !aSelector)
        return null;
    var method = aClass.method_dtable[aSelector];
    return method ? method : null;
};


class_getInstanceVariable = function(/*Class*/ aClass, /*String*/ aName)
{
    if (!aClass || !aName)
        return NULL;

    // FIXME: this doesn't appropriately deal with Object's properties.
    var variable = aClass.ivar_dtable[aName];

    return variable;
}





class_getName = function(/*Class*/ aClass)
{
    if (aClass == Nil)
        return "";

    return aClass.name;
}


class_getMethodImplementation = function( aClass, aSelector)
{
    var method = aClass.method_dtable[aSelector]; 

    if(method)
    {
        var implementation =  method.method_imp;
        return implementation;
    }
    else
    {
        CPLog.error(aClass.name + " does not implement selector '" + aSelector + "'")
    }

    return null; 
}

method_getName = function( aMethod)
{
    return aMethod.name;
};


sel_getUid = function( aName)
{
    return aName;
};

sel_getName = function(aSelector)
{
    return aSelector ? aSelector : "<null selector>";
};

/*CFData */

CFData = function()
{
    this._rawString = NULL;

    this._propertyList = NULL;
    this._propertyListFormat = NULL;

    this._JSONObject = NULL;

    this._bytes = NULL;
    this._base64 = NULL;
};

CFData.prototype.propertyList = function()
{
    if (!this._propertyList)
        this._propertyList = CFPropertyList.propertyListFromString(this.rawString());

    return this._propertyList;
};

CFData.prototype.JSONObject = function()
{
    if (!this._JSONObject)
    {
        try
        {
            this._JSONObject = JSON.parse(this.rawString());
        }
        catch (anException)
        {
        }
    }

    return this._JSONObject;
};

CFData.prototype.rawString = function()
{
    if (this._rawString === NULL)
    {
        if (this._propertyList)
            this._rawString = CFPropertyList.stringFromPropertyList(this._propertyList, this._propertyListFormat);

        else if (this._JSONObject)
            this._rawString = JSON.stringify(this._JSONObject);

        else if (this._bytes)
            this._rawString = CFData.bytesToString(this._bytes);

        else if (this._base64)
            this._rawString = CFData.decodeBase64ToString(this._base64, true);

        else
            throw new Error("Can't convert data to string.");
    }

    return this._rawString;
};

CFData.prototype.bytes = function()
{
    if (this._bytes === NULL)
    {
        var bytes = CFData.stringToBytes(this.rawString());
        this.setBytes(bytes);
    }

    return this._bytes;
};

CFData.prototype.base64 = function()
{
    if (this._base64 === NULL)
    {
        var base64;
        if (this._bytes)
            base64 = CFData.encodeBase64Array(this._bytes);
        else
            base64 = CFData.encodeBase64String(this.rawString());

        this.setBase64String(base64);
    }

    return this._base64;
};

CFMutableData = function()
{
    CFData.call(this);
};

CFMutableData.prototype = new CFData();

function clearMutableData(/*CFMutableData*/ aData)
{
    this._rawString = NULL;

    this._propertyList = NULL;
    this._propertyListFormat = NULL;

    this._JSONObject = NULL;

    this._bytes = NULL;
    this._base64 = NULL;
}

CFMutableData.prototype.setPropertyList = function(/*PropertyList*/ aPropertyList, /*Format*/ aFormat)
{
    clearMutableData(this);

    this._propertyList = aPropertyList;
    this._propertyListFormat = aFormat;
};

CFMutableData.prototype.setJSONObject = function(/*Object*/ anObject)
{
    clearMutableData(this);

    this._JSONObject = anObject;
};

CFMutableData.prototype.setRawString = function(/*String*/ aString)
{
    clearMutableData(this);

    this._rawString = aString;
};

CFMutableData.prototype.setBytes = function(/*Array*/ bytes)
{
    clearMutableData(this);

    this._bytes = bytes;
};

CFMutableData.prototype.setBase64String = function(/*String*/ aBase64String)
{
    clearMutableData(this);

    this._base64 = aBase64String;
};

// Base64 encoding and decoding

var base64_map_to = [
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "0","1","2","3","4","5","6","7","8","9","+","/","="],
    base64_map_from = [];

for (var i = 0; i < base64_map_to.length; i++)
    base64_map_from[base64_map_to[i].charCodeAt(0)] = i;

CFData.decodeBase64ToArray = function(input, strip)
{
    if (strip)
        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

    var pad = (input[input.length-1] == "=" ? 1 : 0) + (input[input.length-2] == "=" ? 1 : 0),
        length = input.length,
        output = [];

    var i = 0;
    while (i < length)
    {
        var bits =  (base64_map_from[input.charCodeAt(i++)] << 18) |
                    (base64_map_from[input.charCodeAt(i++)] << 12) |
                    (base64_map_from[input.charCodeAt(i++)] << 6) |
                    (base64_map_from[input.charCodeAt(i++)]);

        output.push((bits & 0xFF0000) >> 16);
        output.push((bits & 0xFF00) >> 8);
        output.push(bits & 0xFF);
    }

    // strip "=" padding from end
    if (pad > 0)
        return output.slice(0, -1 * pad);

    return output;
};

CFData.encodeBase64Array = function(input)
{
    var pad = (3 - (input.length % 3)) % 3,
        length = input.length + pad,
        output = [];

    // pad with nulls
    if (pad > 0) input.push(0);
    if (pad > 1) input.push(0);

    var i = 0;
    while (i < length)
    {
        var bits =  (input[i++] << 16) |
                    (input[i++] << 8)  |
                    (input[i++]);

        output.push(base64_map_to[(bits & 0xFC0000) >> 18]);
        output.push(base64_map_to[(bits & 0x3F000) >> 12]);
        output.push(base64_map_to[(bits & 0xFC0) >> 6]);
        output.push(base64_map_to[bits & 0x3F]);
    }

    // pad with "=" and revert array to previous state
    if (pad > 0)
    {
        output[output.length - 1] = "=";
        input.pop();
    }
    if (pad > 1)
    {
        output[output.length - 2] = "=";
        input.pop();
    }

    return output.join("");
};

CFData.decodeBase64ToString = function(input, strip)
{
    return CFData.bytesToString(CFData.decodeBase64ToArray(input, strip));
};

CFData.decodeBase64ToUtf16String = function(input, strip)
{
    return CFData.bytesToUtf16String(CFData.decodeBase64ToArray(input, strip));
};

CFData.bytesToString = function(bytes)
{
    // This is relatively efficient, I think:
    return String.fromCharCode.apply(NULL, bytes);
};

CFData.stringToBytes = function(input)
{
    var temp = [];
    for (var i = 0; i < input.length; i++)
        temp.push(input.charCodeAt(i));

    return temp;
};

CFData.encodeBase64String = function(input)
{
    var temp = [];
    for (var i = 0; i < input.length; i++)
        temp.push(input.charCodeAt(i));

    return CFData.encodeBase64Array(temp);
};

CFData.bytesToUtf16String = function(bytes)
{
    // Strings are encoded with 16 bits per character.
    var temp = [];
    for (var i = 0; i < bytes.length; i += 2)
        temp.push(bytes[i + 1] << 8 | bytes[i]);
    // This is relatively efficient, I think:
    return String.fromCharCode.apply(NULL, temp);
};

CFData.encodeBase64Utf16String = function(input)
{
    // charCodeAt returns UTF-16.
    var temp = [];
    for (var i = 0; i < input.length; i++)
    {
        var c = input.charCodeAt(i);
        temp.push(c & 0xFF);
        temp.push((c & 0xFF00) >> 8);
    }

    return CFData.encodeBase64Array(temp);
};


/* CFDictionary */

CFDictionary = function(/*CFDictionary*/ aDictionary)
{
    this._keys = [];
    this._count = 0;
    this._buckets = { };
    this._UID = objj_generateObjectUID();
}

var indexOf = Array.prototype.indexOf,
    hasOwnProperty = Object.prototype.hasOwnProperty;

CFDictionary.prototype.copy = function()
{
    // Immutable, so no need to actually copy.
    return this;
};

CFDictionary.prototype.mutableCopy = function()
{
    var newDictionary = new CFMutableDictionary(),
        keys = this._keys,
        count = this._count;

    newDictionary._keys = keys.slice();
    newDictionary._count = count;

    var index = 0,
        buckets = this._buckets,
        newBuckets = newDictionary._buckets;

    for (; index < count; ++index)
    {
        var key = keys[index];

        newBuckets[key] = buckets[key];
    }

    return newDictionary;
};

CFDictionary.prototype.containsKey = function(/*String*/ aKey)
{
    return hasOwnProperty.apply(this._buckets, [aKey]);
};

CFDictionary.prototype.containsValue = function(/*id*/ anObject)
{
    var keys = this._keys,
        buckets = this._buckets,
        index = 0,
        count = keys.length;

    for (; index < count; ++index)
        if (buckets[keys[index]] === anObject)
            return YES;

    return NO;
};

 

CFDictionary.prototype.count = function()
{
    return this._count;
};

 

CFDictionary.prototype.countOfKey = function(/*String*/ aKey)
{
    return this.containsKey(aKey) ? 1 : 0;
};

CFDictionary.prototype.countOfValue = function(/*id*/ anObject)
{
    var keys = this._keys,
        buckets = this._buckets,
        index = 0,
        count = keys.length,
        countOfValue = 0;

    for (; index < count; ++index)
        if (buckets[keys[index]] === anObject)
            ++countOfValue;

    return countOfValue;
};

 

CFDictionary.prototype.keys = function()
{
    return this._keys.slice();
};

 

CFDictionary.prototype.valueForKey = function(/*String*/ aKey)
{
    var buckets = this._buckets;

    if (!hasOwnProperty.apply(buckets, [aKey]))
        return nil;

    return buckets[aKey];
};

 

CFDictionary.prototype.toString = function()
{
    var string = "{\n",
        keys = this._keys,
        index = 0,
        count = this._count;

    for (; index < count; ++index)
    {
        var key = keys[index];

        string += "\t" + key + " = \"" + String(this.valueForKey(key)).split('\n').join("\n\t") + "\"\n";
    }

    return string + "}";
};

/* CFMutableDictionary */
CFMutableDictionary = function(/*CFDictionary*/ aDictionary)
{
    CFDictionary.apply(this, []);
}

CFMutableDictionary.prototype = new CFDictionary();

CFMutableDictionary.prototype.copy = function()
{
    return this.mutableCopy();
};

CFMutableDictionary.prototype.addValueForKey = function(/*String*/ aKey, /*Object*/ aValue)
{
    if (this.containsKey(aKey))
        return;

    ++this._count;

    this._keys.push(aKey);
    this._buckets[aKey] = aValue;
};

CFMutableDictionary.prototype.removeValueForKey = function(/*String*/ aKey)
{
    var indexOfKey = -1;

    if (indexOf)
        indexOfKey = indexOf.call(this._keys, aKey);
    else
    {
        var keys = this._keys,
            index = 0,
            count = keys.length;

        for (; index < count; ++index)
            if (keys[index] === aKey)
            {
                indexOfKey = index;
                break;
            }
    }

    if (indexOfKey === -1)
        return;

    --this._count;

    this._keys.splice(indexOfKey, 1);
    delete this._buckets[aKey];
};

 

CFMutableDictionary.prototype.removeAllValues = function()
{
    this._count = 0;
    this._keys = [];
    this._buckets = { };
};

 

CFMutableDictionary.prototype.replaceValueForKey = function(/*String*/ aKey, /*Object*/ aValue)
{
    if (!this.containsKey(aKey))
        return;

    this._buckets[aKey] = aValue;
};

 

CFMutableDictionary.prototype.setValueForKey = function(/*String*/ aKey, /*Object*/ aValue)
{
    if (aValue === nil || aValue === undefined)
        this.removeValueForKey(aKey);

    else if (this.containsKey(aKey))
        this.replaceValueForKey(aKey, aValue);

    else
        this.addValueForKey(aKey, aValue);
};

/*Event Dispatcher */

function EventDispatcher(/*Object*/ anOwner)
{
    this._eventListenersForEventNames = { };
    this._owner = anOwner;
}

EventDispatcher.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    var eventListenersForEventNames = this._eventListenersForEventNames;

    if (!hasOwnProperty.call(eventListenersForEventNames, anEventName))
    {
        var eventListenersForEventName = [];
        eventListenersForEventNames[anEventName] = eventListenersForEventName;
    }
    else
        var eventListenersForEventName = eventListenersForEventNames[anEventName];

    var index = eventListenersForEventName.length;

    while (index--)
        if (eventListenersForEventName[index] === anEventListener)
            return;

    eventListenersForEventName.push(anEventListener);
}

EventDispatcher.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    var eventListenersForEventNames = this._eventListenersForEventNames;

    if (!hasOwnProperty.call(eventListenersForEventNames, anEventName))
        return;

    var eventListenersForEventName = eventListenersForEventNames[anEventName],
        index = eventListenersForEventName.length;

    while (index--)
        if (eventListenersForEventName[index] === anEventListener)
            return eventListenersForEventName.splice(index, 1);
}

EventDispatcher.prototype.dispatchEvent = function(/*Event*/ anEvent)
{
    var type = anEvent.type,
        eventListenersForEventNames = this._eventListenersForEventNames;

    if (hasOwnProperty.call(eventListenersForEventNames, type))
    {
        var eventListenersForEventName = this._eventListenersForEventNames[type],
            index = 0,
            count = eventListenersForEventName.length;

        for (; index < count; ++index)
            eventListenersForEventName[index](anEvent);
    }

    var manual = (this._owner || this)["on" + type];

    if (manual)
        manual(anEvent);
}

/* CFURL */

var CFURLsForCachedUIDs,
    CFURLPartsForURLStrings,
    CFURLCachingEnableCount = 0;

function enableCFURLCaching()
{
    if (++CFURLCachingEnableCount !== 1)
        return;

    CFURLsForCachedUIDs = { };
    CFURLPartsForURLStrings = { };
}

function disableCFURLCaching()
{
    CFURLCachingEnableCount = MAX(CFURLCachingEnableCount - 1, 0);

    if (CFURLCachingEnableCount !== 0)
        return;

    delete CFURLsForCachedUIDs;
    delete CFURLPartsForURLStrings;
}

var URL_RE = new RegExp( /* url */
    "^" +
    "(?:" +
        "([^:/?#]+):" + /* scheme */
    ")?" +
    "(?:" +
        "(//)" + /* authorityRoot */
        "(" + /* authority */
            "(?:" +
                "(" + /* userInfo */
                    "([^:@]*)" + /* user */
                    ":?" +
                    "([^:@]*)" + /* password */
                ")?" +
                "@" +
            ")?" +
            "([^:/?#]*)" + /* domain */
            "(?::(\\d*))?" + /* port */
        ")" +
    ")?" +
    "([^?#]*)" + /*path*/
    "(?:\\?([^#]*))?" + /* queryString */
    "(?:#(.*))?" /*fragment */
);

var URI_KEYS =
[
    "url",
    "scheme",
    "authorityRoot",
    "authority",
        "userInfo",
            "user",
            "password",
        "domain",
        "portNumber",
    "path",
    "queryString",
    "fragment"
];

function CFURLGetParts(/*CFURL*/ aURL)
{
    if (aURL._parts)
        return aURL._parts;

    var URLString = aURL.string(),
        isMHTMLURL = URLString.match(/^mhtml:/);

    if (isMHTMLURL)
        URLString = URLString.substr("mhtml:".length);

    if (CFURLCachingEnableCount > 0 && hasOwnProperty.call(CFURLPartsForURLStrings, URLString))
    {
        aURL._parts = CFURLPartsForURLStrings[URLString];
        return aURL._parts;
    }

    aURL._parts = { };

    var parts = aURL._parts,
        results = URL_RE.exec(URLString),
        index = results.length;

    while (index--)
        parts[URI_KEYS[index]] = results[index] || NULL;

    parts.portNumber = parseInt(parts.portNumber, 10);

    if (isNaN(parts.portNumber))
        parts.portNumber = -1;

    parts.pathComponents = [];

    if (parts.path)
    {
        var split = parts.path.split("/"),
            pathComponents = parts.pathComponents,
            count = split.length;

        for (index = 0; index < count; ++index)
        {
            var component = split[index];

            if (component)
                pathComponents.push(component);

            else if (index === 0)
                pathComponents.push("/");
        }

        parts.pathComponents = pathComponents;
    }

    if (isMHTMLURL)
    {
        parts.url = "mhtml:" + parts.url;
        parts.scheme = "mhtml:" + parts.scheme;
    }

    if (CFURLCachingEnableCount > 0)
        CFURLPartsForURLStrings[URLString] = parts;

    return parts;
}

CFURL = function(/*CFURL|String*/ aURL, /*CFURL*/ aBaseURL)
{
    aURL = aURL || "";

    if (aURL instanceof CFURL)
    {
        if (!aBaseURL)
            return new CFURL(aURL.absoluteString());

        var existingBaseURL = aURL.baseURL();

        if (existingBaseURL)
            aBaseURL = new CFURL(existingBaseURL.absoluteURL(), aBaseURL);

        aURL = aURL.string();
    }

    // Use the cache if it's enabled.
    if (CFURLCachingEnableCount > 0)
    {
        var cacheUID = aURL + " " + (aBaseURL && aBaseURL.UID() || "");

        if (hasOwnProperty.call(CFURLsForCachedUIDs, cacheUID))
            return CFURLsForCachedUIDs[cacheUID];

        CFURLsForCachedUIDs[cacheUID] = this;
    }

    if (aURL.match(/^data:/))
    {
        var parts = { },
            index = URI_KEYS.length;

        while (index--)
            parts[URI_KEYS[index]] = "";

        parts.url = aURL;
        parts.scheme = "data";
        parts.pathComponents = [];

        this._parts = parts;
        this._standardizedURL = this;
        this._absoluteURL = this;
    }

    this._UID = objj_generateObjectUID();

    this._string = aURL;
    this._baseURL = aBaseURL;
}

 

CFURL.prototype.UID = function()
{
    return this._UID;
};

 

var URLMap = { };

CFURL.prototype.mappedURL = function()
{
    return URLMap[this.absoluteString()] || this;
};

 

CFURL.setMappedURLForURL = function(/*CFURL*/ fromURL, /*CFURL*/ toURL)
{
    URLMap[fromURL.absoluteString()] = toURL;
};

 

CFURL.prototype.schemeAndAuthority = function()
{
    var string = "",
        scheme = this.scheme();

    if (scheme)
        string += scheme + ":";

    var authority = this.authority();

    if (authority)
        string += "//" + authority;

    return string;
};

 

CFURL.prototype.absoluteString = function()
{
    if (this._absoluteString === undefined)
        this._absoluteString = this.absoluteURL().string();

    return this._absoluteString;
};

 ;

CFURL.prototype.toString = function()
{
    return this.absoluteString();
};

 

function resolveURL(aURL)
{
    aURL = aURL.standardizedURL();

    var baseURL = aURL.baseURL();

    if (!baseURL)
        return aURL;

    var parts = aURL._parts || CFURLGetParts(aURL),
        resolvedParts,
        absoluteBaseURL = baseURL.absoluteURL(),
        baseParts = absoluteBaseURL._parts || CFURLGetParts(absoluteBaseURL);

    if (parts.scheme || parts.authority)
        resolvedParts = parts;

    else
    {
        resolvedParts = { };

        resolvedParts.scheme = baseParts.scheme;
        resolvedParts.authority = baseParts.authority;
        resolvedParts.userInfo = baseParts.userInfo;
        resolvedParts.user = baseParts.user;
        resolvedParts.password = baseParts.password;
        resolvedParts.domain = baseParts.domain;
        resolvedParts.portNumber = baseParts.portNumber;

        resolvedParts.queryString = parts.queryString;
        resolvedParts.fragment = parts.fragment;

        var pathComponents = parts.pathComponents;

        if (pathComponents.length && pathComponents[0] === "/")
        {
            resolvedParts.path = parts.path;
            resolvedParts.pathComponents = pathComponents;
        }

        else
        {
            var basePathComponents = baseParts.pathComponents,
                resolvedPathComponents = basePathComponents.concat(pathComponents);

            // If baseURL is a file, then get rid of that file from the path components.
            if (!baseURL.hasDirectoryPath() && basePathComponents.length)
                resolvedPathComponents.splice(basePathComponents.length - 1, 1);

            // If this doesn't start with a "..", then we're simply appending to already standardized paths.
            if (pathComponents.length && (pathComponents[0] === ".." || pathComponents[0] === "."))
                standardizePathComponents(resolvedPathComponents, YES);

            resolvedParts.pathComponents = resolvedPathComponents;
            resolvedParts.path = pathFromPathComponents(resolvedPathComponents, pathComponents.length <= 0 || aURL.hasDirectoryPath());
        }
    }

    var resolvedString = URLStringFromParts(resolvedParts),
        resolvedURL = new CFURL(resolvedString);

    resolvedURL._parts = resolvedParts;
    resolvedURL._standardizedURL = resolvedURL;
    resolvedURL._standardizedString = resolvedString;
    resolvedURL._absoluteURL = resolvedURL;
    resolvedURL._absoluteString = resolvedString;

    return resolvedURL;
}

function pathFromPathComponents(/*Array*/ pathComponents, /*BOOL*/ isDirectoryPath)
{
    var path = pathComponents.join("/");

    if (path.length && path.charAt(0) === "/")
        path = path.substr(1);

    if (isDirectoryPath)
        path += "/";

    return path;
}

function standardizePathComponents(/*Array*/ pathComponents, /*BOOL*/ inPlace)
{
    var index = 0,
        resultIndex = 0,
        count = pathComponents.length,
        result = inPlace ? pathComponents : [],
        startsWithPeriod = NO;

    for (; index < count; ++index)
    {
        var component = pathComponents[index];

        if (component === "")
            continue;

        if (component === ".")
        {
            startsWithPeriod = resultIndex === 0;

            continue;
        }

        if (component !== ".." || resultIndex === 0 || result[resultIndex - 1] === "..")
        {
            result[resultIndex] = component;

            resultIndex++;

            continue;
        }

        if (resultIndex > 0 && result[resultIndex - 1] !== "/")
            --resultIndex;
    }

    if (startsWithPeriod && resultIndex === 0)
        result[resultIndex++] = ".";

    result.length = resultIndex;

    return result;
}

function URLStringFromParts(/*Object*/ parts)
{
    var string = "",
        scheme = parts.scheme;

    if (scheme)
        string += scheme + ":";

    var authority = parts.authority;

    if (authority)
        string += "//" + authority;

    string += parts.path;

    var queryString = parts.queryString;

    if (queryString)
        string += "?" + queryString;

    var fragment = parts.fragment;

    if (fragment)
        string += "#" + fragment;

    return string;
}

CFURL.prototype.absoluteURL = function()
{
    if (this._absoluteURL === undefined)
        this._absoluteURL = resolveURL(this);

    return this._absoluteURL;
};

 

CFURL.prototype.standardizedURL = function()
{
    if (this._standardizedURL === undefined)
    {
        var parts = this._parts || CFURLGetParts(this),
            pathComponents = parts.pathComponents,
            standardizedPathComponents = standardizePathComponents(pathComponents, NO);

        var standardizedPath = pathFromPathComponents(standardizedPathComponents, this.hasDirectoryPath());

        if (parts.path === standardizedPath)
            this._standardizedURL = this;

        else
        {
            var standardizedParts = CFURLPartsCreateCopy(parts);

            standardizedParts.pathComponents = standardizedPathComponents;
            standardizedParts.path = standardizedPath;

            var standardizedURL = new CFURL(URLStringFromParts(standardizedParts), this.baseURL());

            standardizedURL._parts = standardizedParts;
            standardizedURL._standardizedURL = standardizedURL;

            this._standardizedURL = standardizedURL;
        }
    }

    return this._standardizedURL;
};

 

function CFURLPartsCreateCopy(parts)
{
    var copiedParts = { },
        count = URI_KEYS.length;

    while (count--)
    {
        var partName = URI_KEYS[count];

        copiedParts[partName] = parts[partName];
    }

    return copiedParts;
}

CFURL.prototype.string = function()
{
    return this._string;
};
 

CFURL.prototype.authority = function()
{
    var authority = PARTS(this).authority;

    if (authority)
        return authority;

    var baseURL = this.baseURL();

    return baseURL && baseURL.authority() || "";
};

 
CFURL.prototype.hasDirectoryPath = function()
{
    var hasDirectoryPath = this._hasDirectoryPath;

    if (hasDirectoryPath === undefined)
    {
        var path = this.path();

        if (!path)
            return NO;

        if (path.charAt(path.length - 1) === "/")
            return YES;

        var lastPathComponent = this.lastPathComponent();

        hasDirectoryPath = lastPathComponent === "." || lastPathComponent === "..";

        this._hasDirectoryPath = hasDirectoryPath;
    }

    return hasDirectoryPath;
};

 

CFURL.prototype.hostName = function()
{
    return this.authority();
};

 

CFURL.prototype.fragment = function()
{
    return (this._parts || CFURLGetParts(this)).fragment;
};

 

CFURL.prototype.lastPathComponent = function()
{
    if (this._lastPathComponent === undefined)
    {
        var pathComponents = this.pathComponents(),
            pathComponentCount = pathComponents.length;

        if (!pathComponentCount)
            this._lastPathComponent = "";

        else
            this._lastPathComponent = pathComponents[pathComponentCount - 1];
    }

    return this._lastPathComponent;
};

 

CFURL.prototype.path = function()
{
    return (this._parts || CFURLGetParts(this)).path;
};

 

CFURL.prototype.createCopyDeletingLastPathComponent = function()
{
    var parts = this._parts || CFURLGetParts(this),
        components = standardizePathComponents(parts.pathComponents, NO);

    if (components.length > 0)
        if (components.length > 1 || components[0] !== "/")
            components.pop();

    // pathFromPathComponents() returns an empty path for ["/"]
    var isRoot = components.length === 1 && components[0] === "/";

    parts.pathComponents = components;
    parts.path = isRoot ? "/" : pathFromPathComponents(components, NO);
    return new CFURL(URLStringFromParts(parts));
};

 

CFURL.prototype.pathComponents = function()
{
    return (this._parts || CFURLGetParts(this)).pathComponents;
};

 

CFURL.prototype.pathExtension = function()
{
    var lastPathComponent = this.lastPathComponent();

    if (!lastPathComponent)
        return NULL;

    lastPathComponent = lastPathComponent.replace(/^\.*/, '');

    var index = lastPathComponent.lastIndexOf(".");

    return index <= 0 ? "" : lastPathComponent.substring(index + 1);
};

 

CFURL.prototype.queryString = function()
{
    return (this._parts || CFURLGetParts(this)).queryString;
};
 

CFURL.prototype.scheme = function()
{
    var scheme = this._scheme;

    if (scheme === undefined)
    {
        scheme = (this._parts || CFURLGetParts(this)).scheme;

        if (!scheme)
        {
            var baseURL = this.baseURL();

            scheme = baseURL && baseURL.scheme();
        }

        this._scheme = scheme;
    }

    return scheme;
};

 

CFURL.prototype.user = function()
{
    return (this._parts || CFURLGetParts(this)).user;
};

 

CFURL.prototype.password = function()
{
    return (this._parts || CFURLGetParts(this)).password;
};

 

CFURL.prototype.portNumber = function()
{
    return (this._parts || CFURLGetParts(this)).portNumber;
};
 

CFURL.prototype.domain = function()
{
    return (this._parts || CFURLGetParts(this)).domain;
};

 

CFURL.prototype.baseURL = function()
{
    return this._baseURL;
};

 
CFURL.prototype.asDirectoryPathURL = function()
{
    if (this.hasDirectoryPath())
        return this;

    var lastPathComponent = this.lastPathComponent();

    // We do this because on globals the path may start with C: and be
    // misinterpreted as a scheme.
    if (lastPathComponent !== "/")
        lastPathComponent = "./" + lastPathComponent;

    return new CFURL(lastPathComponent + "/", this);
};

 

function CFURLGetResourcePropertiesForKeys(/*CFURL*/ aURL)
{
    if (!aURL._resourcePropertiesForKeys)
        aURL._resourcePropertiesForKeys = new CFMutableDictionary();

    return aURL._resourcePropertiesForKeys;
}

CFURL.prototype.resourcePropertyForKey = function(/*String*/ aKey)
{
    return CFURLGetResourcePropertiesForKeys(this).valueForKey(aKey);
};

 

CFURL.prototype.setResourcePropertyForKey = function(/*String*/ aKey, /*id*/ aValue)
{
    CFURLGetResourcePropertiesForKeys(this).setValueForKey(aKey, aValue);
};

 

CFURL.prototype.staticResourceData = function()
{
    var data = new CFMutableData();

    data.setRawString(StaticResource.resourceAtURL(this).contents());

    return data;
};

/* CFHTTPRequest */

var asynchronousTimeoutCount = 0,
    asynchronousTimeoutId = null,
    asynchronousFunctionQueue = [];

function Asynchronous(/*Function*/ aFunction)
{
    var currentAsynchronousTimeoutCount = asynchronousTimeoutCount;

    if (asynchronousTimeoutId === null)
    {
        global.setNativeTimeout(function()
        {
            var queue = asynchronousFunctionQueue,
                index = 0,
                count = asynchronousFunctionQueue.length;

            ++asynchronousTimeoutCount;
            asynchronousTimeoutId = null;
            asynchronousFunctionQueue = [];

            for (; index < count; ++index)
                queue[index]();
        }, 0);
    }

    return function()
    {
        var args = arguments;

        if (asynchronousTimeoutCount > currentAsynchronousTimeoutCount)
            aFunction.apply(this, args);
        else
            asynchronousFunctionQueue.push(function()
            {
                aFunction.apply(this, args);
            });
    };
}

var NativeRequest = require("xmlhttprequest").XMLHttpRequest;


CFHTTPRequest = function()
{
		
    this._isOpen = false;
    this._requestHeaders = {};
    this._mimeType = null;

    this._eventDispatcher = new EventDispatcher(this);
    this._nativeRequest = new NativeRequest();

    var self = this;
    this._stateChangeHandler = function()
    {
        determineAndDispatchHTTPRequestEvents(self);
    };

    this._nativeRequest.onreadystatechange = this._stateChangeHandler;

    if (CFHTTPRequest.AuthenticationDelegate !== nil)
        this._eventDispatcher.addEventListener("HTTP403", function()
            {
                CFHTTPRequest.AuthenticationDelegate(self);
            });
}

CFHTTPRequest.UninitializedState    = 0;
CFHTTPRequest.LoadingState          = 1;
CFHTTPRequest.LoadedState           = 2;
CFHTTPRequest.InteractiveState      = 3;
CFHTTPRequest.CompleteState         = 4;

//override to forward all CFHTTPRequest authorization failures to a single function
CFHTTPRequest.AuthenticationDelegate = nil;

CFHTTPRequest.prototype.status = function()
{
    try
    {
        return this._nativeRequest.status || 0;
    }
    catch (anException)
    {
        return 0;
    }
};

CFHTTPRequest.prototype.statusText = function()
{
    try
    {
        return this._nativeRequest.statusText || "";
    }
    catch (anException)
    {
        return "";
    }
};

CFHTTPRequest.prototype.readyState = function()
{
    return this._nativeRequest.readyState;
};

CFHTTPRequest.prototype.success = function()
{
    var status = this.status();

    if (status >= 200 && status < 300)
        return YES;

    // file:// requests return with status 0, to know if they succeeded, we
    // need to know if there was any content.
    return status === 0 && this.responseText() && this.responseText().length;
};

CFHTTPRequest.prototype.responseXML = function()
{
    var responseXML = this._nativeRequest.responseXML;

    if (responseXML && (NativeRequest === global.XMLHttpRequest))
        return responseXML;

    return parseXML(this.responseText());
};

CFHTTPRequest.prototype.responsePropertyList = function()
{
    var responseText = this.responseText();

    if (CFPropertyList.sniffedFormatOfString(responseText) === CFPropertyList.FormatXML_v1_0)
        return CFPropertyList.propertyListFromXML(this.responseXML());

    return CFPropertyList.propertyListFromString(responseText);
};

CFHTTPRequest.prototype.responseText = function()
{
    return this._nativeRequest.responseText;
};

CFHTTPRequest.prototype.setRequestHeader = function(/*String*/ aHeader, /*Object*/ aValue)
{
    this._requestHeaders[aHeader] = aValue;
};

CFHTTPRequest.prototype.getResponseHeader = function(/*String*/ aHeader)
{
    return this._nativeRequest.getResponseHeader(aHeader);
};

CFHTTPRequest.prototype.getAllResponseHeaders = function()
{
    return this._nativeRequest.getAllResponseHeaders();
};

CFHTTPRequest.prototype.overrideMimeType = function(/*String*/ aMimeType)
{
    this._mimeType = aMimeType;
};

CFHTTPRequest.prototype.open = function(/*String*/ aMethod, /*String*/ aURL, /*Boolean*/ isAsynchronous, /*String*/ aUser, /*String*/ aPassword)
{
    this._isOpen = true;
    this._URL = aURL;
    this._async = isAsynchronous;
    this._method = aMethod;
    this._user = aUser;
    this._password = aPassword;
    return this._nativeRequest.open(aMethod, aURL, isAsynchronous, aUser, aPassword);
};

CFHTTPRequest.prototype.send = function(/*Object*/ aBody)
{
    if (!this._isOpen)
    {
        delete this._nativeRequest.onreadystatechange;
        this._nativeRequest.open(this._method, this._URL, this._async, this._user, this._password);
        this._nativeRequest.onreadystatechange = this._stateChangeHandler;
    }

    for (var i in this._requestHeaders)
    {
        if (this._requestHeaders.hasOwnProperty(i))
            this._nativeRequest.setRequestHeader(i, this._requestHeaders[i]);
    }

    if (this._mimeType && "overrideMimeType" in this._nativeRequest)
        this._nativeRequest.overrideMimeType(this._mimeType);

    this._isOpen = false;

    try
    {
        return this._nativeRequest.send(aBody);
    }
    catch (anException)
    {
        // FIXME: Do something more complex, with 404's?
        this._eventDispatcher.dispatchEvent({ type:"failure", request:this });
    }
};

CFHTTPRequest.prototype.abort = function()
{
    this._isOpen = false;
    return this._nativeRequest.abort();
};

CFHTTPRequest.prototype.addEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
};

CFHTTPRequest.prototype.removeEventListener = function(/*String*/ anEventName, /*Function*/ anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
};

function determineAndDispatchHTTPRequestEvents(/*CFHTTPRequest*/ aRequest)
{
    var eventDispatcher = aRequest._eventDispatcher;

    eventDispatcher.dispatchEvent({ type:"readystatechange", request:aRequest});

    var nativeRequest = aRequest._nativeRequest,
        readyStates = ["uninitialized", "loading", "loaded", "interactive", "complete"];

    if (readyStates[aRequest.readyState()] === "complete")
    {
        var status = "HTTP" + aRequest.status();
        eventDispatcher.dispatchEvent({ type:status, request:aRequest });

        var result = aRequest.success() ? "success" : "failure";
        eventDispatcher.dispatchEvent({ type:result, request:aRequest });

        eventDispatcher.dispatchEvent({ type:readyStates[aRequest.readyState()], request:aRequest});
    }
    else
        eventDispatcher.dispatchEvent({ type:readyStates[aRequest.readyState()], request:aRequest});
}

var NativeWebSocket = require('ws');

CFWebSocketConnection = function(aURL)
{
	this._nativeWebSocket = new NativeWebSocket(aURL);

}

CFWebSocketConnection.prototype.on = function(wsEvent, callback)
{
	this._nativeWebSocket.on(wsEvent, callback);
}

CFWebSocketConnection.prototype.send = function(aMessage)
{
	this._nativeWebSocket.send(aMessage);
}

CFWebSocketConnection.prototype.close = function()
{
	this._nativeWebSocket.close(); 
}

CFWebSocketConnection.prototype.readyState = function()
{
	return this._nativeWebSocket.readyState; 
}


global.onload = function(){ main(); }


})(global);

