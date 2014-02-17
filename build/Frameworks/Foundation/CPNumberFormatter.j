@import "CPString.j" 
@import "CPNumber.j"

 

var CPNumberFormatterNoStyle            = 0,
	CPNumberFormatterDecimalStyle       = 1,
	CPNumberFormatterCurrencyStyle      = 2,
	CPNumberFormatterPercentStyle       = 3,
	CPNumberFormatterScientificStyle    = 4;

 
@implementation CPNumberFormatter : CPObject
{
	CPNumberFormatterStyle          _numberStyle @accessors(property=numberStyle);
    CPString                        _groupingSeparator @accessors(property=groupingSeparator);
	CPUInteger                      _fractionDigits @accessors(property=numberOfFractionDigits); 
    CPString                        _currencyCode @accessors(property=currencyCode);
    CPString                        _currencySymbol @accessors(property=currencySymbol); 

}


- (id)init
{
    if (self = [super init])
    {
     
        _fractionDigits = 2;
        _groupingSeparator = Nil; 
        _numberStyle = CPNumberFormatterDecimalStyle; 

        // FIXME Add locale support.
        _currencyCode = @"USD";
        _currencySymbol = @"$";
    }

    return self;
}



 

- (CPString)stringFromNumber:(CPNumber)number
{
    if (_numberStyle == CPNumberFormatterPercentStyle)
    {
        number *= 100.0;
    }

    var dcmn = [number doubleValue];

    // TODO Add locale support.
    switch (_numberStyle)
    {
        case CPNumberFormatterCurrencyStyle:
        case CPNumberFormatterDecimalStyle:
        case CPNumberFormatterPercentStyle:
        {
        	var string = dcmn.toFixed(_fractionDigits); 

        	if (_numberStyle === CPNumberFormatterCurrencyStyle)
            {
				dcmn = [string doubleValue];
				string = dcmn.toFixed(2);
				
                if (_currencySymbol)
                    string = _currencySymbol + string;
                else
                    string = _currencyCode + string;
            }

            if (_numberStyle == CPNumberFormatterPercentStyle)
            {
                string += "%";
            }
        	
            if(_groupingSeparator)
            {
                var decPos = string.lastIndexOf(".");
                var preFrac = string; 
                if(decPos > - 1)
            	   preFrac = string.substring(0, decPos);
                
            	var len = preFrac.length;
            	var groupingSeparatorList = [];
            	var dcount = 0; 
            	for(var i = len; i >=0; i--)
            	{	
        			if(dcount === 3 && i != 0)
                    {
        				groupingSeparatorList.push(i);
                        dcount = 0; 
                    }

                    dcount++; 
            	}
            	var ngs = groupingSeparatorList.length;
            	for(var i = 0; i < ngs; i++)
            	{
            		var index = groupingSeparatorList[i];
            		string = string.substring(0, index) + _groupingSeparator + string.substring(index);
            	}
            }
            return string; 
        }break;
        case CPNumberFormatterScientificStyle :
        {
            //TODO
        }break; 

    }
     
    return [number stringValue];
}



@end




var CPNumberFormatterStyleKey                   = @"CPNumberFormatterStyleKey",
    CPNumberFormatterFractionDigitsKey          = @"CPNumberFormatterFractionDigitsKey", 
    CPNumberFormatterGroupingSeparatorKey       = @"CPNumberFormatterGroupingSeparatorKey",
    CPNumberFormatterCurrencyCodeKey            = @"CPNumberFormatterCurrencyCodeKey",
    CPNumberFormatterCurrencySymbolKey          = @"CPNumberFormatterCurrencySymbolKey";

@implementation CPNumberFormatter (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _numberStyle = [aCoder decodeIntForKey:CPNumberFormatterStyleKey];
        _fractionDigits = [aCoder decodeIntForKey:CPNumberFormatterFractionDigitsKey];
        _groupingSeparator = [aCoder decodeObjectForKey:CPNumberFormatterGroupingSeparatorKey];
        _currencyCode = [aCoder decodeObjectForKey:CPNumberFormatterCurrencyCodeKey];
        _currencySymbol = [aCoder decodeObjectForKey:CPNumberFormatterCurrencySymbolKey];
         
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_numberStyle forKey:CPNumberFormatterStyleKey];
    [aCoder encodeInt:_fractionDigits forKey:CPNumberFormatterFractionDigitsKey]; 
    [aCoder encodeObject:_groupingSeparator forKey:CPNumberFormatterGroupingSeparatorKey];
    [aCoder encodeObject:_currencyCode forKey:CPNumberFormatterCurrencyCodeKey];
    [aCoder encodeObject:_currencySymbol forKey:CPNumberFormatterCurrencySymbolKey];
     
}

@end
