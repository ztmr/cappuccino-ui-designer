@import "CPColor.j"
@import "CPFont.j"


@implementation CPTheme : CPObject
{
	 
}

-(id) themeAttribute:(CPString)attr forClass:(Class)theClass
{   
    var className = class_getName(theClass);
    if([self respondsToSelector:CPSelectorFromString(className)])
    {
        var d = [self performSelector:CPSelectorFromString(className) withObject:nil];

        return [d objectForKey:attr];
    }

    return nil; 
}


-(CPDictionary) defaultThemeAttributesForClass:(CPString)className
{
	if([self respondsToSelector:CPSelectorFromString(className)])
	   return [self performSelector:CPSelectorFromString(className) withObject:nil];


	return null; 
}

-(CPDictionary) CPView
{
	return	@{
					 @"border-width" : 0.0	
				};
}

-(CPDictionary) CPControl
{
	return @{
            @"alignment": CPLeftTextAlignment,
            @"line-break-mode": CPLineBreakByClipping,
            @"text-color": [CPColor blackColor],
            @"alt-text-color" : [CPColor whiteColor],
            @"text-shadow-color" : [CPColor colorWithHexString:@"fafafa"],
            @"alt-text-shadow-color" : [CPColor colorWithHexString:@"3f3f3f"],
            @"font": [CPFont systemFontOfSize:12.0],
            @"image-position": CPNoImage,
            @"image-size" : CGSizeMake(15,15),
            @"text-shadow-offset" : CGSizeMake(0,1)
        }
}

-(CPDictionary) CPTextField
{
    return @{
                     @"border-width" : 2.0,
                     @"font": [CPFont systemFontOfSize:13.0],
                     @"text-shadow-offset" : CGSizeMake(0,1)
                    };
}

-(CPDictionary) CPButton
{
	return @{
					 @"border-width" : 1.0,
                     @"font": [CPFont boldSystemFontOfSize:13.0]
					};
}

-(CPDictionary) CPCheckBox
{
	return @{
            	@"alt-text-color" : [CPColor blackColor],
                @"alt-text-shadow-color" : [CPColor colorWithHexString:@"fafafa"],
            	@"font": [CPFont systemFontOfSize:12.0], 
            	@"image-size" : CGSizeMake(17,17),
            	@"border-width" : 0.0
        	}
}

-(CPDictionary) CPRadio
{
		return @{
            @"alt-text-color" : [CPColor blackColor],
            @"alt-text-shadow-color" : [CPColor colorWithHexString:@"fafafa"],
            @"font": [CPFont systemFontOfSize:12.0], 
            @"image-size" : CGSizeMake(18,18),
            @"border-width" : 0.0
        };
}

-(CPDictionary) CPPopUpButton
{
	return @{
         @"border-width": 0.0,
         @"trigger-width" : 25,
		 @"optimal-height" : 25,
         @"alt-text-color" : [CPColor blackColor],
         @"alt-text-shadow-color" : [CPColor colorWithHexString:@"fafafa"], 
     };
}

-(CPDictionary) CPBox 
{	
	return @{
              @"border-width": 1.0,
		      @"content-margin" : CGSizeMake(1,1),
		      @"corner-radius" : 5,
		      @"border-color" : [CPColor colorWithHexString:@"8a8a8a"]
		  };

}


-(CPDictionary) CPSlider 
{
    return @{
        @"linear-dim" : 6,
        @"circular-dim" : 28.0
    };
}

-(CPDictionary) CPStepper
{
	return     @{
    				@"up-image" :  @"iVBORw0KGgoAAAANSUhEUgAAAAYAAAAFCAYAAABmWJ3mAAAEJGlDQ1BJQ0MgUHJvZmlsZQAAOBGFVd9v21QUPolvUqQWPyBYR4eKxa9VU1u5GxqtxgZJk6XtShal6dgqJOQ6N4mpGwfb6baqT3uBNwb8AUDZAw9IPCENBmJ72fbAtElThyqqSUh76MQPISbtBVXhu3ZiJ1PEXPX6yznfOec7517bRD1fabWaGVWIlquunc8klZOnFpSeTYrSs9RLA9Sr6U4tkcvNEi7BFffO6+EdigjL7ZHu/k72I796i9zRiSJPwG4VHX0Z+AxRzNRrtksUvwf7+Gm3BtzzHPDTNgQCqwKXfZwSeNHHJz1OIT8JjtAq6xWtCLwGPLzYZi+3YV8DGMiT4VVuG7oiZpGzrZJhcs/hL49xtzH/Dy6bdfTsXYNY+5yluWO4D4neK/ZUvok/17X0HPBLsF+vuUlhfwX4j/rSfAJ4H1H0qZJ9dN7nR19frRTeBt4Fe9FwpwtN+2p1MXscGLHR9SXrmMgjONd1ZxKzpBeA71b4tNhj6JGoyFNp4GHgwUp9qplfmnFW5oTdy7NamcwCI49kv6fN5IAHgD+0rbyoBc3SOjczohbyS1drbq6pQdqumllRC/0ymTtej8gpbbuVwpQfyw66dqEZyxZKxtHpJn+tZnpnEdrYBbueF9qQn93S7HQGGHnYP7w6L+YGHNtd1FJitqPAR+hERCNOFi1i1alKO6RQnjKUxL1GNjwlMsiEhcPLYTEiT9ISbN15OY/jx4SMshe9LaJRpTvHr3C/ybFYP1PZAfwfYrPsMBtnE6SwN9ib7AhLwTrBDgUKcm06FSrTfSj187xPdVQWOk5Q8vxAfSiIUc7Z7xr6zY/+hpqwSyv0I0/QMTRb7RMgBxNodTfSPqdraz/sDjzKBrv4zu2+a2t0/HHzjd2Lbcc2sG7GtsL42K+xLfxtUgI7YHqKlqHK8HbCCXgjHT1cAdMlDetv4FnQ2lLasaOl6vmB0CMmwT/IPszSueHQqv6i/qluqF+oF9TfO2qEGTumJH0qfSv9KH0nfS/9TIp0Wboi/SRdlb6RLgU5u++9nyXYe69fYRPdil1o1WufNSdTTsp75BfllPy8/LI8G7AUuV8ek6fkvfDsCfbNDP0dvRh0CrNqTbV7LfEEGDQPJQadBtfGVMWEq3QWWdufk6ZSNsjG2PQjp3ZcnOWWing6noonSInvi0/Ex+IzAreevPhe+CawpgP1/pMTMDo64G0sTCXIM+KdOnFWRfQKdJvQzV1+Bt8OokmrdtY2yhVX2a+qrykJfMq4Ml3VR4cVzTQVz+UoNne4vcKLoyS+gyKO6EHe+75Fdt0Mbe5bRIf/wjvrVmhbqBN97RD1vxrahvBOfOYzoosH9bq94uejSOQGkVM6sN/7HelL4t10t9F4gPdVzydEOx83Gv+uNxo7XyL/FtFl8z9ZAHF4bBsrEwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAHVJREFUCB1jYGBgYPz//z+QYtDas2dPAIgNwkxA4n9YWBgzUGL2lStXZgBpDZAqsKyiomKqurr6/8DAwP8nTpyYCtbByMgoys7OXiEhIcFw7949ht27d0cC1Tsyy8rKVvLy8vozMzP/ZWVlZbxx4wankpKSOABsNy1XjAAkvgAAAABJRU5ErkJggg==",  
    				@"down-image" : @"iVBORw0KGgoAAAANSUhEUgAAAAYAAAAFCAYAAABmWJ3mAAAEJGlDQ1BJQ0MgUHJvZmlsZQAAOBGFVd9v21QUPolvUqQWPyBYR4eKxa9VU1u5GxqtxgZJk6XtShal6dgqJOQ6N4mpGwfb6baqT3uBNwb8AUDZAw9IPCENBmJ72fbAtElThyqqSUh76MQPISbtBVXhu3ZiJ1PEXPX6yznfOec7517bRD1fabWaGVWIlquunc8klZOnFpSeTYrSs9RLA9Sr6U4tkcvNEi7BFffO6+EdigjL7ZHu/k72I796i9zRiSJPwG4VHX0Z+AxRzNRrtksUvwf7+Gm3BtzzHPDTNgQCqwKXfZwSeNHHJz1OIT8JjtAq6xWtCLwGPLzYZi+3YV8DGMiT4VVuG7oiZpGzrZJhcs/hL49xtzH/Dy6bdfTsXYNY+5yluWO4D4neK/ZUvok/17X0HPBLsF+vuUlhfwX4j/rSfAJ4H1H0qZJ9dN7nR19frRTeBt4Fe9FwpwtN+2p1MXscGLHR9SXrmMgjONd1ZxKzpBeA71b4tNhj6JGoyFNp4GHgwUp9qplfmnFW5oTdy7NamcwCI49kv6fN5IAHgD+0rbyoBc3SOjczohbyS1drbq6pQdqumllRC/0ymTtej8gpbbuVwpQfyw66dqEZyxZKxtHpJn+tZnpnEdrYBbueF9qQn93S7HQGGHnYP7w6L+YGHNtd1FJitqPAR+hERCNOFi1i1alKO6RQnjKUxL1GNjwlMsiEhcPLYTEiT9ISbN15OY/jx4SMshe9LaJRpTvHr3C/ybFYP1PZAfwfYrPsMBtnE6SwN9ib7AhLwTrBDgUKcm06FSrTfSj187xPdVQWOk5Q8vxAfSiIUc7Z7xr6zY/+hpqwSyv0I0/QMTRb7RMgBxNodTfSPqdraz/sDjzKBrv4zu2+a2t0/HHzjd2Lbcc2sG7GtsL42K+xLfxtUgI7YHqKlqHK8HbCCXgjHT1cAdMlDetv4FnQ2lLasaOl6vmB0CMmwT/IPszSueHQqv6i/qluqF+oF9TfO2qEGTumJH0qfSv9KH0nfS/9TIp0Wboi/SRdlb6RLgU5u++9nyXYe69fYRPdil1o1WufNSdTTsp75BfllPy8/LI8G7AUuV8ek6fkvfDsCfbNDP0dvRh0CrNqTbV7LfEEGDQPJQadBtfGVMWEq3QWWdufk6ZSNsjG2PQjp3ZcnOWWing6noonSInvi0/Ex+IzAreevPhe+CawpgP1/pMTMDo64G0sTCXIM+KdOnFWRfQKdJvQzV1+Bt8OokmrdtY2yhVX2a+qrykJfMq4Ml3VR4cVzTQVz+UoNne4vcKLoyS+gyKO6EHe+75Fdt0Mbe5bRIf/wjvrVmhbqBN97RD1vxrahvBOfOYzoosH9bq94uejSOQGkVM6sN/7HelL4t10t9F4gPdVzydEOx83Gv+uNxo7XyL/FtFl8z9ZAHF4bBsrEwAAAAlwSFlzAAALEwAACxMBAJqcGAAAAHpJREFUCB1jlJWVbRYSEqrh5ub++///f6a/f/8ytrW17WB6/PjxpJ8/f95jZWVl/vbtG6Ovr+97Z2fnLiagqtdAiY4XL14wKCkpMbi6ui5nYGDYzwCUYAgNDWUGco5OmDDhBZCvARJjYQQCIOMvkErV0dFRAyq4AcQMANdZOCvimbEfAAAAAElFTkSuQmCC"

                };
}

 

-(CPDictionary) CPScroller 
{
    return @{

        @"minimum-scroller-knob-size" : 21.0,
        @"default-points-per-scroll" : 9,
        @"scroller-buttons-width" : 15.0,
        @"scroller-buttons-height" : 11.0

    };
}

-(CPDictionary) CPScrollView
{
    return @{
        @"scroller-thickness" : 15.0
    };
}

-(CPDictionary) CPSegmentedControl
{
    return @{
        @"font" : [CPFont boldSystemFontOfSize:12.0]
    };
}


-(CPDictionary) CPToolbar
{
    return @{
        @"overflow-arrow-image" : @"iVBORw0KGgoAAAANSUhEUgAAAAoAAAAPCAYAAADd/14OAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAU1JREFUKM9jsLS0XGFmZib1//9/BnyYwdfX97+7u/suCwsLHbwKExMT/4Owt7f3eSsrKzecCrOysv6XlZX9T01N/e/v7//E1tY2wcTEhAVDYWZm5rGampr/FRUV/4Hs/yEhIZ8cHByaTE1N+VAUxsbGcpWWlh6rra39X1VV9T83N/d/RETEX2dn59nm5uZKcIUgAuhGTqDiwyDF1dXV/wsLC/8DDfjv4eGxG+huR6BTBOFGAxXzAN36vK6u7j/IKSUlJf+TkpL++/j4bLUBArjCoKCg3oKCgv8gU2GKgfyzkZGRIU5OTjJgRUBGb0xMzH+g9WBFIMVA07cBQ0IP7kaQoqioKLC7QKYA8a/i4uLpQKdIovg6PDwcrgjokU9A6yqApnNihGN6ejpYUWVl5T1g0EQBNTLjjBlgYJ/LyMiwwRvXycnJe4CO1iGUegAs+F709mxc3QAAAABJRU5ErkJggg=="
    };
}


-(CPDictionary) CPDatePicker
{
    return @{
        @"left-arrow" : @"iVBORw0KGgoAAAANSUhEUgAAAAcAAAAJCAYAAAD+WDajAAAD8GlDQ1BJQ0MgUHJvZmlsZQAAKJGNVd1v21QUP4lvXKQWP6Cxjg4Vi69VU1u5GxqtxgZJk6XpQhq5zdgqpMl1bhpT1za2021Vn/YCbwz4A4CyBx6QeEIaDMT2su0BtElTQRXVJKQ9dNpAaJP2gqpwrq9Tu13GuJGvfznndz7v0TVAx1ea45hJGWDe8l01n5GPn5iWO1YhCc9BJ/RAp6Z7TrpcLgIuxoVH1sNfIcHeNwfa6/9zdVappwMknkJsVz19HvFpgJSpO64PIN5G+fAp30Hc8TziHS4miFhheJbjLMMzHB8POFPqKGKWi6TXtSriJcT9MzH5bAzzHIK1I08t6hq6zHpRdu2aYdJYuk9Q/881bzZa8Xrx6fLmJo/iu4/VXnfH1BB/rmu5ScQvI77m+BkmfxXxvcZcJY14L0DymZp7pML5yTcW61PvIN6JuGr4halQvmjNlCa4bXJ5zj6qhpxrujeKPYMXEd+q00KR5yNAlWZzrF+Ie+uNsdC/MO4tTOZafhbroyXuR3Df08bLiHsQf+ja6gTPWVimZl7l/oUrjl8OcxDWLbNU5D6JRL2gxkDu16fGuC054OMhclsyXTOOFEL+kmMGs4i5kfNuQ62EnBuam8tzP+Q+tSqhz9SuqpZlvR1EfBiOJTSgYMMM7jpYsAEyqJCHDL4dcFFTAwNMlFDUUpQYiadhDmXteeWAw3HEmA2s15k1RmnP4RHuhBybdBOF7MfnICmSQ2SYjIBM3iRvkcMki9IRcnDTthyLz2Ld2fTzPjTQK+Mdg8y5nkZfFO+se9LQr3/09xZr+5GcaSufeAfAww60mAPx+q8u/bAr8rFCLrx7s+vqEkw8qb+p26n11Aruq6m1iJH6PbWGv1VIY25mkNE8PkaQhxfLIF7DZXx80HD/A3l2jLclYs061xNpWCfoB6WHJTjbH0mV35Q/lRXlC+W8cndbl9t2SfhU+Fb4UfhO+F74GWThknBZ+Em4InwjXIyd1ePnY/Psg3pb1TJNu15TMKWMtFt6ScpKL0ivSMXIn9QtDUlj0h7U7N48t3i8eC0GnMC91dX2sTivgloDTgUVeEGHLTizbf5Da9JLhkhh29QOs1luMcScmBXTIIt7xRFxSBxnuJWfuAd1I7jntkyd/pgKaIwVr3MgmDo2q8x6IdB5QH162mcX7ajtnHGN2bov71OU1+U0fqqoXLD0wX5ZM005UHmySz3qLtDqILDvIL+iH6jB9y2x83ok898GOPQX3lk3Itl0A+BrD6D7tUjWh3fis58BXDigN9yF8M5PJH4B8Gr79/F/XRm8m241mw/wvur4BGDj42bzn+Vmc+NL9L8GcMn8F1kAcXjEKMJAAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA5ElEQVQYlU2Ov0rDUBxGv+/ea5PbiIMKDZFsDk46iM5BH0DrIrioWRwrZHPLQ/goznkHO4vgUsQOpR20vX9+LhU88zlwICIAwKqqjIhARGDtdpkXe8+mbVslIhGAJ2mKonzIi51HrfU+1yXyPD+32eZTkqRnvSSFdw7sZdnhYHcw6vftdZLaTCkFEN6tVsqcHp8Mf5bLGlCIMQhIR2AjakNd39+Nqc2rD66IQUqQWilCRER3Xfd9Nbwcf04mL/PFYua8PyDVVoiBBKBFJGBN0zRHb+8fo6/p9ObvliTVf+m2ri9+AZpHXcHKEf6jAAAAAElFTkSuQmCC",
        @"right-arrow" : @"iVBORw0KGgoAAAANSUhEUgAAAAcAAAAJCAYAAAD+WDajAAAD8GlDQ1BJQ0MgUHJvZmlsZQAAKJGNVd1v21QUP4lvXKQWP6Cxjg4Vi69VU1u5GxqtxgZJk6XpQhq5zdgqpMl1bhpT1za2021Vn/YCbwz4A4CyBx6QeEIaDMT2su0BtElTQRXVJKQ9dNpAaJP2gqpwrq9Tu13GuJGvfznndz7v0TVAx1ea45hJGWDe8l01n5GPn5iWO1YhCc9BJ/RAp6Z7TrpcLgIuxoVH1sNfIcHeNwfa6/9zdVappwMknkJsVz19HvFpgJSpO64PIN5G+fAp30Hc8TziHS4miFhheJbjLMMzHB8POFPqKGKWi6TXtSriJcT9MzH5bAzzHIK1I08t6hq6zHpRdu2aYdJYuk9Q/881bzZa8Xrx6fLmJo/iu4/VXnfH1BB/rmu5ScQvI77m+BkmfxXxvcZcJY14L0DymZp7pML5yTcW61PvIN6JuGr4halQvmjNlCa4bXJ5zj6qhpxrujeKPYMXEd+q00KR5yNAlWZzrF+Ie+uNsdC/MO4tTOZafhbroyXuR3Df08bLiHsQf+ja6gTPWVimZl7l/oUrjl8OcxDWLbNU5D6JRL2gxkDu16fGuC054OMhclsyXTOOFEL+kmMGs4i5kfNuQ62EnBuam8tzP+Q+tSqhz9SuqpZlvR1EfBiOJTSgYMMM7jpYsAEyqJCHDL4dcFFTAwNMlFDUUpQYiadhDmXteeWAw3HEmA2s15k1RmnP4RHuhBybdBOF7MfnICmSQ2SYjIBM3iRvkcMki9IRcnDTthyLz2Ld2fTzPjTQK+Mdg8y5nkZfFO+se9LQr3/09xZr+5GcaSufeAfAww60mAPx+q8u/bAr8rFCLrx7s+vqEkw8qb+p26n11Aruq6m1iJH6PbWGv1VIY25mkNE8PkaQhxfLIF7DZXx80HD/A3l2jLclYs061xNpWCfoB6WHJTjbH0mV35Q/lRXlC+W8cndbl9t2SfhU+Fb4UfhO+F74GWThknBZ+Em4InwjXIyd1ePnY/Psg3pb1TJNu15TMKWMtFt6ScpKL0ivSMXIn9QtDUlj0h7U7N48t3i8eC0GnMC91dX2sTivgloDTgUVeEGHLTizbf5Da9JLhkhh29QOs1luMcScmBXTIIt7xRFxSBxnuJWfuAd1I7jntkyd/pgKaIwVr3MgmDo2q8x6IdB5QH162mcX7ajtnHGN2bov71OU1+U0fqqoXLD0wX5ZM005UHmySz3qLtDqILDvIL+iH6jB9y2x83ok898GOPQX3lk3Itl0A+BrD6D7tUjWh3fis58BXDigN9yF8M5PJH4B8Gr79/F/XRm8m241mw/wvur4BGDj42bzn+Vmc+NL9L8GcMn8F1kAcXjEKMJAAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA50lEQVQYlTXOMUvDQByG8ffuf3cx6NJQMEQq1lpRCkFRcc038BsInZ2zZ3LLUFA3V8Fv4KKrs7O7pOBom5zivS72mX/DgzTbuo3jZEASJFEUhQGgSAJ7+wccjsbvWTa4AmBWqKoqrQ4nOY21+PYdvO9e2sXXddM0zwCgJvnRr3UugDAhBPiuXSyX7eP8cz5T+fEprbUk8APSai0KCFiLosqISBARRSgnWmN9I35NN9Ob8e7Ok9Ei2roIxshHP+ndnZ+d3Jdl2QCAiZzz/aT3MBpuz+q6fsN/SinB5XR6sdonCQBCUpHEH8nCXnoQx8OdAAAAAElFTkSuQmCC"
    };
}

-(CPDictionary) CPButtonBar
{
    return @{
        @"plus-image" : @"iVBORw0KGgoAAAANSUhEUgAAAAsAAAAMCAYAAAC0qUeeAAAAK0lEQVQoz2P4//8/AzIGgv8wjCE3SBQjSxKBaaX4PxpAczOq3CANZ3zOBAD2LyPrrDPrsgAAAABJRU5ErkJggg==",
        @"minus-image" : @"iVBORw0KGgoAAAANSUhEUgAAAAsAAAAECAAAAAB9kZovAAAADklEQVQIW2NgIAL8RwAAQe4K9jsMoRAAAAAASUVORK5CYII=",
        @"action-image" : @"iVBORw0KGgoAAAANSUhEUgAAABYAAAAOCAQAAACBOCRGAAABJ0lEQVQokWNggAFmIO5n+A/EDAzcDHiAJEMD4wEGVqBSEORj72VYh1Mtxy6QIqBysGKWzWB6Dw7FpVuhZsIhxx+juzgU//esvc3wX+dj3/W3hyde0/nI8afo5v9W7Gr7IabV7fnv/p/rv2vdHqj5/WDZaVBeBdRgCLztD+FeC4A7BwhuVvH+Yvgv8+19HFgy7jFEijcFopg/FcIHioNM4q2/xPB/9v7/LBCDs//vT3nI8lf4OkM0MITjgfR/4/c/DvzPhmj+Fpjw6L8FwtXHGP8Cg+4fcngw3oR7n+l/FpIPTe6BpIOfQZSBQobzj+EzXEHX6v+8/M63Moji/yG1t12eferDoRiovPxdzH9mkFdB3vofsnzWf1acioEKWCBehXjrvwY2NQAEI6SNiWcsuAAAAABJRU5ErkJggg=="
    };
}

-(CPDictionary) CPColorPanel 
{
    return @{
        @"colorwheel-toolbar-image" : @"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",
        @"colorwheel-toolbar-image-highlight" : @"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",
        @"slider-toolbar-image" : @"iVBORw0KGgoAAAANSUhEUgAAACAAAAAgBAMAAACBVGfHAAAAElBMVEX///9ycnL////1AAAq/wAAAP9LuqjfAAAAAXRSTlMAQObYZgAAAF9JREFUeF6djsENwDAMAr2C2YCs4BWygvdfpUorxVF51Or94AFnv3B/RdAPDAMcBQ0BRtEoZENexEPl/AY8xBZgic0FOB8ahWzIi3ionRdgie1lGnIDZjYK2ZAX8fjmAnTrM80J8Uf9AAAAAElFTkSuQmCC",
        @"slider-toolbar-image-highlight" : @"iVBORw0KGgoAAAANSUhEUgAAACAAAAAgBAMAAACBVGfHAAAAFVBMVEUAAAD///9QUFCysrKrAAAdsgAAALK1Th7fAAAAAnRSTlMAAHaTzTgAAABmSURBVHhejZHBDYAwDAOzAivEG7grdIWu0P1HQIBUF/wg97yHc1Li+FAQEZmxkwnmRqCBTTDQwS4Kwjb8ijrEW+YNuIVdgAobF+B4KAjbsCvW4XUpQIWtZQbmApyzIGzDrljH/7NP2V9QOcU6+SgAAAAASUVORK5CYII="

    };
}

-(CPDictionary)CPColorWell
{
    return @{
        "border-width" : 1.0
    };
}


-(CPDictionary)CPDateField
{
    return @{
        @"border-width" : 2.0,
        @"font" : [CPFont systemFontOfSize:14.0]
    };
}

-(CPDictionary) CPAlert 
{
	return @{
		@"warning-icon" : @"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",
		@"informational-icon" : @"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",
		@"critical-icon" : @"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" 
	};
	
}

-(CPDictionary) CPTableView 
{
    return @{
        @"sourceListSelectionStartColor" : @"#5fabd1",
        @"sourceListSelectionEndColor" : @"#3182D0",
        @"sourceListTopLineColor" : @"#517fc8",
        @"sourceListBottomLineColor" : @"#23407c",
        @"selectionColor" : @"#3879d9",
        @"gridLineColor" : @"#b5b5b5"
    };
}

 

@end




