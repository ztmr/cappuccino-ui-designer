@import <Foundation/CPDate.j>
@import <Foundation/CPCalendarUtil.j>

@import "CPTextField.j"
@import "CPStepper.j"

//modes
var CPDateFieldMonthYear = 			1 << 0,
	CPDateFieldMonthDayYear = 		1 << 1,
	CPDateFieldHourMinute = 		1 << 2,
	CPDateFieldHourMinuteSecond = 	1 << 3; 
 

@implementation _CPDateFieldInput : CPTextField 
{
	CPDateField 			_dateField; 
}

+(id) create:(CPDateField)dateField
{
	var input = [[self alloc] initWithFrame:CGRectMakeZero()];
	input._dateField = dateField;

	return input; 
}

-(id) initWithFrame:(CGRect)aFrame 
{
	self = [super initWithFrame:aFrame];

	if( self )
	{	
		[self setEditable:NO];
		_DOMElement.addClass("cpdatefield-input");
		[self setTextAlignment:CPCenterTextAlignment];

	}

	return self; 
}

@end



@implementation CPDateField : CPControl
{
		CPTextField					_dayField;
		CPTextField					_monthField; 
		CPTextField					_yearField; 
		CPTextField 				_hourField; 
		CPTextField 				_minuteField; 
		CPTextField 				_secondField; 
		CPTextField					_ampmField; 


		CPView 						_dayView; 
		CPView 						_monthView;
		CPView 						_yearView;
		CPView 						_hourView;
		CPView 						_minuteView;
		CPView 						_secondView; 
		CPView 						_ampmView; 

		CPTextField					_slash1;
		CPTextField					_slash2;
		CPTextField 				_colon1;
		CPTextField 				_colon2; 



		CPStepper 					_stepper; 


		CPTextField 				_selectedField; 


		CPDate 						_minDate @accessors(property=minDate);
		CPDate 						_maxDate @accessors(property=maxDate); 
		int 						_mode @accessors(getter=dateFieldMode); 


}



-(id) initWithFrame:(CGRect)aFrame
{

	self = [super initWithFrame:aFrame];

	if( self )
	{	
		_selectedField = nil; 
		[self _init];

		[self setDateValue:[CPDate date]];
	}

	return self; 
}



-(void) _init 
{

		_minDate = new Date(Number.MIN_VALUE);
		_maxDate = new Date(Number.MAX_VALUE);
		_mode = CPDateFieldMonthDayYear;
		[self setContinuous:YES];

		_DOMElement.addClass("cpdatefield");

		_monthView = [[CPView alloc] init];
		_monthField = [_CPDateFieldInput create:self];;
		 
		[_monthView addSubview:_monthField];
		[self addSubview:_monthView];

		_slash1 = [CPTextField labelWithString:@"/"];
		
		[self addSubview:_slash1];


		_dayView = [[CPView alloc] init];

		_dayField = [_CPDateFieldInput create:self];;
	 	[_dayView addSubview:_dayField];
		[self addSubview:_dayView];
 
 		_slash2 = [CPTextField labelWithString:@"/"];
		[self addSubview:_slash2];

		_yearView = [[CPView alloc] init];
		_yearField = [_CPDateFieldInput create:self];;
		[_yearView addSubview:_yearField];
		[self addSubview:_yearView];

	 
		_hourView = [[CPView alloc] init]
		_hourField = [_CPDateFieldInput create:self];;
		[_hourView addSubview:_hourField];	
		[self addSubview:_hourView];

	 
		_minuteView = [[CPView alloc] init];
		_minuteField = [_CPDateFieldInput create:self];;
		[_minuteView addSubview:_minuteField];

		[self addSubview:_minuteView];

	 	_secondView = [[CPView alloc] init];
		_secondField = [_CPDateFieldInput create:self];;

		[_secondView addSubview:_secondField];
		[self addSubview:_secondView];

	 
		_colon1 = [CPTextField labelWithString:@":"];
		[self addSubview:_colon1];
		_colon2 = [CPTextField labelWithString:@":"];
		[self addSubview:_colon2];


		_ampmView = [[CPView alloc] init];
		_ampmField = [_CPDateFieldInput create:self];;
		[_ampmView addSubview:_ampmField];
		[self addSubview:_ampmView];

	 	 

		_stepper = [[CPStepper alloc] initWithFrame:CGRectMake(_frame.size.width-18,0, 18, _frame.size.height)];
		[_stepper setValueWraps:YES];
		[_stepper setAutoresizingMask:CPViewMinXMargin|CPViewHeightSizable];
		[_stepper setTarget:self];
		[_stepper setAction:@selector(_onTick:)]

		[self addSubview:_stepper];

		[_ephemeralSubviews addObject:_slash1];
		[_ephemeralSubviews addObject:_slash2];
		[_ephemeralSubviews addObject:_dayView];
 		[_ephemeralSubviews addObject:_monthView];
 		[_ephemeralSubviews addObject:_yearView];
 		[_ephemeralSubviews addObject:_hourView];
 		[_ephemeralSubviews addObject:_minuteView];
 		[_ephemeralSubviews addObject:_secondView];
 		[_ephemeralSubviews addObject:_ampmView];
 		[_ephemeralSubviews addObject:_colon1];
 		[_ephemeralSubviews addObject:_colon2];
 
 		[_ephemeralSubviews addObject:_stepper];
}

-(void) setDateFieldMode:(int)mode 
{
	if(mode === _mode)
		return; 


	_mode = mode; 

	[self setNeedsLayout];
}


-(void) layoutSubviews
{	
	var font = [self font];

	var sz = [@"99" sizeWithFont:font]; 

	var x = 0,
		lastField = null; 
	
	if(_mode & CPDateFieldMonthYear || _mode & CPDateFieldMonthDayYear)
	{
		x = [self _positionTextField:_monthField inView:_monthView at:x size:sz];
 	 
		[_slash1 setFont:font];
		[_slash1 setHidden:NO];
		[_slash1 sizeToFit];
		[_slash1 setFrameOrigin:CGPointMake(x, (CGRectGetHeight(_monthView._frame) - CGRectGetHeight(_slash1._frame))/2.0)];

		x = CGRectGetMaxX(_slash1._frame);
	}
	else
	{
		[_monthView setHidden:YES];
		[_slash1 setHidden:YES];
	}

	if(_mode & CPDateFieldMonthDayYear)
	{
		x = [self _positionTextField:_dayField inView:_dayView at:x size:sz];

		[_slash2 setFont:font];
		[_slash2 setHidden:NO];
		[_slash2 sizeToFit];
		[_slash2 setFrameOrigin:CGPointMake(x, (CGRectGetHeight(_dayView._frame) - CGRectGetHeight(_slash2._frame))/2.0)];

		x = CGRectGetMaxX(_slash2._frame);
 
	}
	else
	{
		[_dayView setHidden:YES];
		[_slash2 setHidden:YES];
	}
		

	var sz2 = [@"99999" sizeWithFont:font];
	if(_mode & CPDateFieldMonthYear || _mode & CPDateFieldMonthDayYear)
	{
		x = [self _positionTextField:_yearField inView:_yearView at:x size:sz2];
	 
	}
	else
		[_yearView setHidden:YES];
 	
	if(_mode & CPDateFieldHourMinute || _mode & CPDateFieldHourMinuteSecond)
	{
		x = [self _positionTextField:_hourField inView:_hourView at:x+3 size:sz];

		[lastField setNextKeyView:_hourField];
		lastField = _hourField; 
 
		[_colon1 setFont:font];
		[_colon1 setHidden:NO];
		[_colon1 sizeToFit];
		[_colon1 setFrameOrigin:CGPointMake(x, 
				(CGRectGetHeight(_hourView._frame) - CGRectGetHeight(_colon1._frame))/2.0)];

		x = CGRectGetMaxX(_colon1._frame);

		x = [self _positionTextField:_minuteField inView:_minuteView at:x size:sz];
	 
	}
	else
	{
		[_hourView setHidden:YES];
		[_minuteView setHidden:YES];
		[_colon1 setHidden:YES];
	}

	if(_mode & CPDateFieldHourMinuteSecond)
	{
		[_colon2 setFont:font];
		[_colon2 setHidden:NO];
		[_colon2 sizeToFit];
		[_colon2 setFrameOrigin:CGPointMake(x, 
						(CGRectGetHeight(_minuteView._frame) - CGRectGetHeight(_colon2._frame))/2.0)];

		x = CGRectGetMaxX(_colon2._frame);	

		x = [self _positionTextField:_secondField inView:_secondView at:x size:sz];
 
	} 
	else
	{
		[_secondView setHidden:YES];
		[_colon2 setHidden:YES];
	}
	
	if(_mode & CPDateFieldHourMinute || _mode & CPDateFieldHourMinuteSecond)
	{
		var sz3 = [@"AM2" sizeWithFont:font];

		[self _positionTextField:_ampmField inView:_ampmView at:x + 3 size:sz3];
 
	}
	else
		[_ampmView setHidden:YES];
	

	[_stepper setContinuous:[self continuous]];

}	


-(void) _positionTextField:(CPTextField)textField inView:(CPView)aView at:(double)x size:(CGSize)sz 
{	
	[aView setHidden:NO];
	[aView setFrame:CGRectMake(x, 0, sz.width, _frame.size.height)];
	[textField setFont:[self font]];
	[textField setFrameSize:sz];
	[textField setCenter:[aView convertPoint:[aView center] fromView:self]];

	return CGRectGetMaxX(aView._frame); 
}

-(void) mouseDown:(CPEvent)theEvent
{
	var location = [_superview convertPoint:[theEvent locationInWindow] fromView:nil];

	
	var v = [self hitTest:location];
 
 	if(v === _monthField || v === _dayField || v === _yearField
 		|| v === _hourField || v === _minuteField || v === _secondField 
 		|| v === _ampmField)
 	{	
 		 [self _select:v];
	}

	[[self window] makeFirstResponder:self];

	[super mouseDown:theEvent];
}


-(void) _select:(_CPDateFieldInput)input 
{	
	if(input)
	{
		[_selectedField unsetThemeState:@"selected"];
		_selectedField = input; 

		[_selectedField setThemeState:@"selected"];

		[self _updateStepperToSelectedField];
	}
}


-(void) _updateStepperToSelectedField
{
	switch(_selectedField)
	{	
		case _hourField :
		case _monthField :
		{
			[_stepper setMinValue:1];
			[_stepper setMaxValue:12];

		}break; 
		case _dayField : 
		{	
			[_stepper setMinValue:1];
		 	[_stepper setMaxValue:CPGetNumberOfDaysInMonth([self dateValue])];

		}break; 
		case _yearField : 
		{
			[_stepper setMinValue:1900];
			[_stepper setMaxValue:Number.MAX_VALUE];
		
		}break;
		case _minuteField :
		case _secondField : 
		{
			[_stepper setMinValue:0];
			[_stepper setMaxValue:59];

		}break;
		case _ampmField :
		{
			[_stepper setMinValue:0];
			[_stepper setMaxValue:1];

		}break; 
	}

	if(_selectedField === _ampmField)
		[_stepper setIntValue:([_ampmField stringValue] === @"PM" ? 1 : 0)];
	else
		[_stepper setIntValue:[_selectedField intValue]];
}


-(void) setDateValue:(CPDate)aDate 
{
	[_monthField setStringValue:aDate.getMonth()+1];
	[_dayField setStringValue:aDate.getDate()];
	[_yearField setStringValue:aDate.getFullYear()];

	[_hourField setStringValue:CPConvert24HourTo12Hour(aDate)];
	[_minuteField setStringValue:(aDate.getMinutes() < 10 ? ("0" + aDate.getMinutes()) : aDate.getMinutes())];
	[_secondField setStringValue:(aDate.getSeconds() < 10 ? ("0" + aDate.getSeconds()) : aDate.getSeconds())];

	[_ampmField setStringValue:(aDate.getHours() < 12 ? @"AM" : @"PM")];

	if(_selectedField)
	{
		if(_selectedField === _ampmField)
			[_stepper setIntValue:(aDate.getHours() < 12 ? 0 : 1)];
		else
			[_stepper setIntValue:[_selectedField intValue]];
	}

	[super setObjectValue:aDate];
}

-(CPDate) dateValue
{
	if([_value isKindOfClass:[CPDate class]])
		return _value;

	return nil; 
}


-(void) _onTick:(id)sender
{
	if(_selectedField === _ampmField)
	{
		if([_stepper intValue] === 0)
			[_ampmField setStringValue:@"AM"];
		else
			[_ampmField setStringValue:@"PM"];
	}
	else
		[_selectedField setIntValue:[_stepper intValue]];

	[self _syncDate];
}

-(void) _syncDate
{
	var hours = [_hourField intValue];
	var am = ([_ampmField stringValue] === @"AM");
 
	var maxDays = CPGetNumberOfDaysInMonth(new Date([_yearField intValue], [_monthField intValue], 0));


	var newDate = new Date([_yearField intValue], [_monthField intValue]-1, 
    								([_dayField intValue] > maxDays ? maxDays : [_dayField intValue]), 
    								(am ? (hours === 12 ? 0 : hours) : (hours === 12 ? 12 : hours + 12)), 
    								[_minuteField intValue], [_secondField intValue],0);

	
	if(newDate > _maxDate)
		newDate = [_maxDate copy];

	if(newDate < _minDate)
		newDate = [_minDate copy]; 

 	[self setDateValue:newDate];  

}

-(void) keyDown:(CPEvent)theEvent
{

	var KC = [theEvent keyCode];

	if(KC === CPRightArrowKeyCode)
	{	
		 var next = nil; 
		 switch(_selectedField)
		 {
		 	case _monthField :
		 	{
		 		if(![_dayView isHidden])
		 			next = _dayField;
		 		else
		 			next = _yearField;
		 	}break;
		 	case _dayField :
		 		next = _yearField;
		 		break;
		 	case _yearField :
		 	{
		 		if(![_hourView isHidden])
		 			next = _hourField;
		 	}break;
		 	case _hourField :
		 		next = _minuteField;
		 		break;
		 	case _minuteField :
		 	{
		 		if(![_secondView isHidden])
		 			next = _secondField;
		 		else
		 			next = _ampmField;
		 	}break; 
		 	case _secondField :
		 		next = _ampmField;
		 	case _ampmField:
		 	{
		 		if(![_monthView isHidden])
		 			next = _monthField;
		 		else
		 			next = _hourField; 
		 	}break; 

		 }

		 [self _select:next];

	}
	else if(KC === CPLeftArrowKeyCode)
	{
		 var prev = nil; 
		 switch(_selectedField)
		 {
		 	case _monthField :
		 	{
		 		if(![_ampmView isHidden])
		 			prev = _ampmField;
		 		else
		 			prev = _yearField;
		 	}break;
		 	case _dayField :
		 		prev = _monthField;
		 		break;
		 	case _yearField :
		 	{
		 		if(![_dayView isHidden])
		 			prev = _dayField;
		 		else
		 			prev = _monthField; 
		 	}break;
		 	case _hourField :
		 	{ 		
		 		if(![_yearView isHidden])
		 			prev = _yearField;
		 		else
		 			prev = _ampmField; 

		 	}break;
		 	case _minuteField :
		 	{
		 		prev = _hourField; 
		 	}break; 
		 	case _secondField :
		 	{
		 		prev = _minuteField;
		 	}break;  
		 	case _ampmField:
		 	{
		 		if(![_secondView isHidden])
		 			prev = _secondField;
		 		else
		 			prev = _minuteField; 
		 	}break; 

		 }
 		 
 		 [self _select:prev];
 	
	}
	else if(KC === CPUpArrowKeyCode)
	{
		[_stepper upTick:nil];
	}
	else if(KC === CPDownArrowKeyCode)
	{
		[_stepper downTick:nil];
	}

	[super keyDown:theEvent];
}

-(BOOL) becomeFirstResponder
{	
	if(!_selectedField)
	{	
		if(![_monthView isHidden])
			[self _select:_monthField]
		else
			[self _select:_hourField];
	}


	return YES; 
}

 



@end