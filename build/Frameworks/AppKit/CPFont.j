@import <Foundation/CPObject.j>
@import <Foundation/CPString.j> 

var CPFontDefaultSystemFontFace = @"Helvetica Neue, Arial, sans-serif",
    CPFontDefaultSystemFontSize = 12;

var _CPFonts                        = {},
    _CPFontSystemFontFace           = CPFontDefaultSystemFontFace,
    _CPFontSystemFontSize           = 12,
    _CPFontFallbackFaces            = CPFontDefaultSystemFontFace.split(", "),
    _CPFontStripRegExp              = new RegExp("(^\\s*[\"']?|[\"']?\\s*$)", "g");


@implementation CPFont : CPObject
{
    CPString    _name;
    float       _size; 
    float       _lineHeight;
    BOOL        _isBold;          
    BOOL        _isItalic;       
	BOOL		_isUnderline;	 
    CPString    _cssString;
}

 
+ (CPString)systemFontFace
{
    return _CPFontSystemFontFace;
}

+ (CPString)setSystemFontFace:(CPString)aFace
{
    _CPFontSystemFontFace = _CPFontNormalizedNameArray(aFace).join(", ");
}

+ (float)systemFontSize
{
    return _CPFontSystemFontSize;
}

/*!
    Sets the default system font size.
*/
+ (float)setSystemFontSize:(float)size
{
    if (size > 0)
        _CPFontSystemFontSize = size;
}

+ (CPFont)fontWithName:(CPString)aName size:(float)aSize
{
    return [CPFont fontWithName:aName size:aSize bold:NO italic:NO underline:NO];
}

+ (CPFont)fontWithName:(CPString)aName size:(float)aSize italic:(BOOL)italic
{
    return [CPFont fontWithName:aName size:aSize bold:NO italic:italic underline:NO];
}

+ (CPFont)boldFontWithName:(CPString)aName size:(float)aSize
{
    return [CPFont fontWithName:aName size:aSize bold:YES italic:NO underline:NO];
}

+ (CPFont)boldFontWithName:(CPString)aName size:(float)aSize italic:(BOOL)italic
{
    return [CPFont fontWithName:aName size:aSize bold:YES italic:italic underline:NO];
}

+ (CPFont)systemFontOfSize:(CPSize)aSize
{
    return [CPFont fontWithName:_CPFontSystemFontFace size:aSize bold:NO italic:NO underline:NO];
}

+ (CPFont)boldSystemFontOfSize:(CPSize)aSize
{
    return [CPFont fontWithName:_CPFontSystemFontFace size:aSize bold:YES italic:NO underline:NO];
}

+ (CPFont)fontWithName:(CPString)aName size:(float)aSize bold:(BOOL)isBold italic:(BOOL)isItalic underline:(BOOL)underline
{
    return [[CPFont alloc] _initWithName:aName size:aSize bold:isBold italic:isItalic underline:underline];
}

- (id)_initWithName:(CPString)aName size:(float)aSize bold:(BOOL)isBold italic:(BOOL)isItalic underline:(BOOL)underline
{
    self = [super init];

    if (self)
    {
        _name = _CPFontNormalizedNameArray(aName).join(", ");
        _size = aSize; 
        _lineHeight = 1.0;
		_isUnderline = underline; 
        _isBold = isBold;
        _isItalic = isItalic;

        _cssString = _CPFontCreateCSSString(_name, _size, _isBold, _isItalic);

        _CPFonts[_cssString] = self;
    }

    return self;
}

 

- (float)defaultLineHeightForFont
{ 
    return _lineHeight;
}

/*!
    Returns the font size (in CSS px)
*/
- (float)size
{
    return _size;
}

/*!
    Returns the font as a CSS string
*/
- (CPString)cssString
{
    return _cssString;
}

-(CPString) cssTextDecoration
{
	var s = @"";
	if (_isUnderline) {
         s = @"underline";
    } 
	else {
       s = @"none";
    }

    return s;
}

/*!
    Returns the font's family name
*/
- (CPString)familyName
{
    return _name;
}

- (BOOL)isEqual:(id)anObject
{
    return [anObject isKindOfClass:[CPFont class]] && [anObject cssString] === _cssString;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"%@ %@", [super description], [self cssString]];
}

- (id)copy
{
    return [[CPFont alloc] _initWithName:_name size:_size bold:_isBold italic:_isItalic];
}



 


@end

var CPFontNameKey     = @"CPFontNameKey",
    CPFontSizeKey     = @"CPFontSizeKey",
    CPFontIsBoldKey   = @"CPFontIsBoldKey",
    CPFontIsItalicKey = @"CPFontIsItalicKey",
	CPFontIsUnderlineKey = @"CPFontIsUnderlineKey";

@implementation CPFont (CPCoding)

/*!
    Initializes the font from a coder.
    @param aCoder the coder from which to read the font data
    @return the initialized font
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    var fontName = [aCoder decodeObjectForKey:CPFontNameKey];
	
     var   size = [aCoder decodeFloatForKey:CPFontSizeKey],
        isBold = [aCoder decodeBoolForKey:CPFontIsBoldKey],
        isItalic = [aCoder decodeBoolForKey:CPFontIsItalicKey];
		isUnderline = [aCoder decodeBoolForKey:CPFontIsUnderlineKey];
    
	return [self _initWithName:fontName size:size bold:isBold italic:isItalic underline:isUnderline];
}

/*!
    Writes the font information out to a coder.
    @param aCoder the coder to which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
	[super encodeWithCoder:aCoder];
    [aCoder encodeObject:_name forKey:CPFontNameKey];
    [aCoder encodeFloat:_size forKey:CPFontSizeKey];
    [aCoder encodeBool:_isBold forKey:CPFontIsBoldKey];
    [aCoder encodeBool:_isItalic forKey:CPFontIsItalicKey];
	[aCoder encodeBool:_isUnderline forKey:CPFontIsUnderlineKey];
}

@end
 
var DefaultFont                 = nil; 

@implementation CPString (CPStringDrawing)

/*!
    Returns a dictionary with the items "ascender", "descender", "lineHeight"
*/

+ (CPSize)sizeOfString:(CPString)aString withFont:(CPFont)aFont forWidth:(float)aWidth
{
    if (!aFont)
    {
        if (!DefaultFont)
            DefaultFont = [CPFont systemFontOfSize:12.0];

        aFont = DefaultFont;
    }
 
    var span = $("<div></div>"); 
    
    span.css({
            "float" : "left",
            "padding" : 0,
            "font"  : [aFont cssString],
            "text-decoration" : [aFont cssTextDecoration],
            "display" : "none"
            
        });
    
    if(aWidth)
    {
		span.css({
			width : Math.round(aWidth)
		});
    }
    
    var isIE = navigator.userAgent.indexOf("MSIE") != -1;
    span.html(aString);
	
	$('body').append(span); 

	sz = CPMakeSize($(span).width()+1, $(span).height()+1 - isIE);
    
    span.remove();
	
	return sz; 
}
 
- (CPSize)sizeWithFont:(CPFont)aFont
{
    return [self sizeWithFont:aFont inWidth:Nil];
}

- (CPSize)sizeWithFont:(CPFont)aFont inWidth:(float)aWidth
{
	 return [CPString sizeOfString:self withFont:aFont forWidth:aWidth];
}

@end

// aName must be normalized
var _CPFontCreateCSSString = function(aName, aSize, isBold, isItalic)
{
    var properties = (isItalic ? "italic " : "") + (isBold ? "bold " : "") + aSize + "px ";

    return properties + _CPFontConcatNameWithFallback(aName);
};


var _CPFontConcatNameWithFallback = function(aName)
{
	 
    var names = _CPFontNormalizedNameArray(aName),
        fallbackFaces = _CPFontFallbackFaces.slice(0);

    // Remove the fallback names used in the names passed in
    for (var i = 0; i < names.length; ++i)
    {
        for (var j = 0; j < fallbackFaces.length; ++j)
        {
            if (names[i].toLowerCase() === fallbackFaces[j].toLowerCase())
            {
                fallbackFaces.splice(j, 1);
                break;
            }
        }

        if (names[i].indexOf(" ") > 0)
            names[i] = '"' + names[i] + '"';
    }

    return names.concat(fallbackFaces).join(", ");
};

var _CPFontNormalizedNameArray = function(aName)
{
	if(aName)
	{
    	var names = aName.split(",");

    	for (var i = 0; i < names.length; ++i)
        	names[i] = names[i].replace(_CPFontStripRegExp, "");

    	return names;
	}
	
	return null; 
};

