@import <Foundation/CPDate.j>
@import <Foundation/CPCalendarUtil.j>

@import "CPTextField.j"
@import "CPButton.j"




@implementation CPDatePicker : CPControl
{
	CPDate 					_minDate @accessors(getter=minDate);
	CPDate 					_maxDate @accessors(getter=maxDate); 

	CPDate  				_displayedMonth;
	CPDate 					_currentDate; 


	DOMElement 				_monthDayTable;
	DOMElement 				_dayLabelTable; 
	DOMElement 				_dateTableElements; 


	CPButton				_nextMonth;
	CPButton 				_prevMonth; 

	CPTextField 			_monthLabel; 



}

-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if(self)
	{
		[self _init];
		[self setBackgroundColor:[CPColor colorWithHexString:@"fafafa"]];
	}

	return self; 
}


-(void) _init 
{	
	 _minDate = new Date(Number.MIN_VALUE);
	 _maxDate = new Date(Number.MAX_VALUE);

	_monthDayTable = $("<table></table>").addClass("cpdatepicker-table");
	_monthDayTable.attr("cellspacing", 0);
	_monthDayTable.attr("cellpadding", 0);

	_monthLabel = [CPTextField labelWithString:@""];
	[_monthLabel setFont:[CPFont boldSystemFontOfSize:13.0]];
	[_ephemeralSubviews addObject:_monthLabel];
 	[self addSubview:_monthLabel];

	_dayLabelTable = $("<table></table>").addClass("cpdatepicker-day-labels");
	_dayLabelTable.attr("cellspacing", 0);
	_dayLabelTable.attr("cellpadding", 0);

	_DOMElement.append(_dayLabelTable); 

	_DOMElement.append(_monthDayTable);

	_dateTableElements = null; 

	_prevMonth = [[CPButton alloc] initWithFrame:CGRectMake(0,0, 24,24)];
	[_prevMonth setImagePosition:CPImageOnly];
	[_prevMonth setImage:[[CPImage alloc] initWithData:[CPData dataWithBase64:[self valueForThemeAttribute:@"left-arrow"]]]];
	[_prevMonth setBordered:NO];
	[_prevMonth setBackgroundColor:[CPColor clearColor]];
	[_prevMonth setImageSize:CGSizeMake(7,9)];
	[_prevMonth setTarget:self];
	[_prevMonth setAction:@selector(decrementMonth:)];
 	
 	[_ephemeralSubviews addObject:_prevMonth];
	[self addSubview:_prevMonth];

	_nextMonth = [[CPButton alloc] initWithFrame:CGRectMake(_frame.size.width - 24, 0, 24,24)];
	[_nextMonth setAutoresizingMask:CPViewMaxXMargin];
	[_nextMonth setBordered:NO];
	[_nextMonth setBackgroundColor:[CPColor clearColor]];
	[_nextMonth setImagePosition:CPImageOnly];
	[_nextMonth setImageSize:CGSizeMake(7,9)];
	[_nextMonth setImage:[[CPImage alloc] initWithData:[CPData dataWithBase64:[self valueForThemeAttribute:@"right-arrow"]]]];
	[_nextMonth setTarget:self];
	[_nextMonth setAction:@selector(incrementMonth:)];

	[_ephemeralSubviews addObject:_nextMonth];
	[self addSubview:_nextMonth];
 

}


-(void) layoutSubviews
{
	if(!_displayedMonth)
		_displayedMonth = [CPDate date];


	_dateTableElements = {};

	var displayYear = _displayedMonth.getFullYear(); 
	[_monthLabel setStringValue:(dateFormat.i18n.monthNames[12 + _displayedMonth.getMonth()] + " " + displayYear)];
	[_monthLabel sizeToFit];
	[_monthLabel setFrameOrigin:CGPointMake((_frame.size.width - _monthLabel._frame.size.width)/2.0, 3.0)];

	_currentDate = [CPDate date]; 

	var startDate = [_displayedMonth copy];
	
	CPSetDateToFirstDayOfMonth(startDate);
	CPSetDateToFirstDayOfWeek(startDate);

	_monthDayTable.empty();
	_dayLabelTable.empty();

	var dayLabelRow = $("<tr></tr>");

	for(var i = 0; i < 7; i++)
	{
		var dayTd = $("<td></td>").addClass("cpdatepicker-day-label");
		dayTd.html(dateFormat.i18n.dayNames[i]);
		dayLabelRow.append(dayTd);
		 
	}

	_dayLabelTable.append(dayLabelRow);

	for(var i = 0; i < 6; i++)
	{
		var row = $("<tr></tr>");

		for(var j = 0; j < 7; j++)
		{	
			var dateNumber = "" + startDate.getDate(); 
			var thisDate = [startDate copy];
			var dateCell = $("<td></td>").addClass("cpdatepicker-day-cell");

			dateCell.data("date", thisDate);

			_dateTableElements[startDate.toString()] = dateCell; 

			if(j === 0)
				dateCell.addClass("left");

			if(i === 0)
				dateCell.addClass("top");


			var isCurrentMonth = (_currentDate.getMonth() === _displayedMonth.getMonth()); 
 
			if(CPDaysBetweenDates(_currentDate, startDate) === 0 && isCurrentMonth)
			 			dateCell.addClass("today");
			 
			if(startDate.getMonth() !== _displayedMonth.getMonth() ||
				startDate < _minDate || startDate > _maxDate )
				dateCell.addClass("disabled");
			else
			{
					dateCell.bind("click", function(anEvent){

						   var dv = [self dateValue]; 
						   if(dv)
						   {
						   		var te = _dateTableElements[dv.toString()];
						   		if(te)
						   		{
						   			te.removeClass("selected");
						   		}
						   }

						   [self setObjectValue:$(this).data("date")];

						   dv = [self dateValue];
						   var cellEl = _dateTableElements[dv.toString()];

						   if(cellEl)
						   		cellEl.addClass("selected");

						   [[self window] makeFirstResponder:self];
						   [self triggerAction];

					})
			}

			dateCell.html(dateNumber);

			row.append(dateCell);
			CPAddDaysToDate(startDate, 1);	

		}

		_monthDayTable.append(row);
	}

}

-(void) setDisplayedMonth:(int)monthIndex year:(int)aYear
{
	_displayedMonth = new Date(aYear, monthIndex, 0,0,0,0);
	
	[self setNeedsLayout];
}


-(void) setObjectValue:(id)aValue
{
	if([aValue isKindOfClass:[CPDate class]])
		_value = aValue;
	else
		_value = new Date(aValue);
}

-(CPDate) dateValue
{
	if([_value isKindOfClass:[CPDate class]])
		return _value;

	return nil; 
}

-(CPString) stringValue 
{
	if([_formatter isKindOfClass:[CPDateFormatter class]])
		return [_formatter stringFromDate:[self dateValue]];

	return [super stringValue];
}


-(void) changeMonth:(int)numberOfMonths
{
	CPAddMonthsToDate(_displayedMonth, numberOfMonths);
	[self setNeedsLayout];
}

-(void) setMinDate:(CPDate)aDate
{
	_minDate = aDate;
	[self setNeedsLayout];
}

-(void) setMaxDate:(CPDate)aDate
{
	_maxDate = aDate;
	[self setNeedsLayout];
}



-(void) decrementMonth:(id)sender
{
	[self changeMonth:-1];
}

-(void) incrementMonth:(id)sender
{
	[self changeMonth:1];
}

@end