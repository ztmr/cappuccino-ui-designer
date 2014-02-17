function CPAddDaysToDate(aDate, numberOfDays)
{
   	aDate.setDate(aDate.getDate() + numberOfDays);
 
}

function CPConvert24HourTo12Hour(aDate)
{
	var hours = aDate.getHours();

	if(hours === 0)
		return 12; 

	if(hours <= 12)
		return hours; 
	else
		return hours - 12; 

}


function CPGetNumberOfDaysInMonth(aDate)
{
	 var d = new Date(aDate.getFullYear(), aDate.getMonth()+1, 0);
     return d.getDate();
}


function CPAddMonthsToDate(aDate, numberOfMonths)
{
	if(numberOfMonths != 0)
	{
		var month = aDate.getMonth();
		var year = aDate.getFullYear();

		var resultMonthCount = year*12 + month + numberOfMonths;
		var resultYear = Math.floor(resultMonthCount / 12);
		var resultMonth = resultMonthCount - resultYear*12; 

		aDate.setMonth(resultMonth);
		aDate.setFullYear(resultYear);

	}
}


function CPDateHasTime(start)
{
	return start.getHours() != 0 || start.getMinutes() != 0
  		|| start.getSeconds() != 0;
}

function CPDateResetTime(date)
{
	date.setHours(0,0,0,0);
}

function CPSetDateToFirstDayOfWeek(aDate)
{
	var currentDay = aDate.getDay();
	CPAddDaysToDate(aDate, -currentDay);

}

function CPSetDateToFirstDayOfMonth(aDate)
{
	CPDateResetTime(aDate);
	aDate.setDate(1);
}

function CPDaysBetweenDates(startDate, endDate)
{
	if(CPDateHasTime(startDate))
	{
		startDate = new Date(startDate);
		CPDateResetTime(startDate);
	}

	if(CPDateHasTime(endDate))
	{
		endDate = new Date(endDate);
		CPDateResetTime(endDate);
	}

	var aTime= startDate.getTime();
	var bTime = endDate.getTime();

	var adjust = 60 * 60 * 1000;
   	
   	if(bTime < aTime)
   		adjust = -1*adjust; 
 
   	return Math.floor(((bTime - aTime + adjust) / (24 * 60 * 60 * 1000)));
}