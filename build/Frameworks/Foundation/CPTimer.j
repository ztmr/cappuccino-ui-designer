/*
 * CPTimer.j
 * Foundation
 *
 * Created by Nick Takayama.
 * Copyright 2008.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "CPDate.j"
@import "CPInvocation.j"
@import "CPObject.j"
@import "CPRunLoop.j"

var CPTimerMinTimeInterval = 0.1;

/*!
    @class CPTimer
    @ingroup foundation

    @brief A timer object that can send a message after the given time interval.
*/
@implementation CPTimer : CPObject
{
    CPTimeInterval      _timeInterval;
    CPInvocation         _invocation;
    Function             _callback;

    BOOL                 _repeats;
    BOOL                 _isValid;
    CPDate               _fireDate;
    id                   _userInfo;
}

/*!
    Returns a new CPTimer object and adds it to the current CPRunLoop object in the default mode.
*/
+ (CPTimer)scheduledTimerWithTimeInterval:(CPTimeInterval)seconds invocation:(CPInvocation)anInvocation repeats:(BOOL)shouldRepeat
{
    var timer = [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds invocation:anInvocation repeats:shouldRepeat];

    [[CPRunLoop currentRunLoop] addTimer:timer forMode:CPDefaultRunLoopMode];

    return timer;
}

/*!
    Returns a new CPTimer object and adds it to the current CPRunLoop object in the default mode.
*/
+ (CPTimer)scheduledTimerWithTimeInterval:(CPTimeInterval)seconds target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)shouldRepeat
{
    var timer =  [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds target:aTarget selector:aSelector userInfo:userInfo repeats:shouldRepeat];

    [[CPRunLoop currentRunLoop] addTimer:timer forMode:CPDefaultRunLoopMode];

    return timer;
}

/*!
    Returns a new CPTimer object and adds it to the current CPRunLoop object in the default mode.
*/
+ (CPTimer)scheduledTimerWithTimeInterval:(CPTimeInterval)seconds callback:(Function)aFunction repeats:(BOOL)shouldRepeat
{
	 	
    var timer = [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds callback:aFunction repeats:shouldRepeat];

    [[CPRunLoop currentRunLoop] addTimer:timer forMode:CPDefaultRunLoopMode];

    return timer;
}

/*!
    Returns a new CPTimer that, when added to a run loop, will fire after seconds.
*/
+ (CPTimer)timerWithTimeInterval:(CPTimeInterval)seconds invocation:(CPInvocation)anInvocation repeats:(BOOL)shouldRepeat
{
    return [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds invocation:anInvocation repeats:shouldRepeat];
}

/*!
    Returns a new CPTimer that, when added to a run loop, will fire after seconds.
*/
+ (CPTimer)timerWithTimeInterval:(CPTimeInterval)seconds target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)shouldRepeat
{
    return [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds target:aTarget selector:aSelector userInfo:userInfo repeats:shouldRepeat];
}

/*!
    Returns a new CPTimer that, when added to a run loop, will fire after seconds.
*/
+ (CPTimer)timerWithTimeInterval:(CPTimeInterval)seconds callback:(Function)aFunction repeats:(BOOL)shouldRepeat
{
    return [[self alloc] initWithFireDate:[CPDate dateWithTimeIntervalSinceNow:seconds] interval:seconds callback:aFunction repeats:shouldRepeat];
}

/*!
    Initializes a new CPTimer that, when added to a run loop, will fire at date and then, if repeats is YES, every seconds after that.
*/
- (id)initWithFireDate:(CPDate)aDate interval:(CPTimeInterval)seconds invocation:(CPInvocation)anInvocation repeats:(BOOL)shouldRepeat
{
    self = [super init];

    if (self)
    {
        self._timeInterval = MAX(seconds, CPTimerMinTimeInterval);
        self._invocation = anInvocation;
        self._repeats = shouldRepeat;
        self._isValid = YES;
        self._fireDate = aDate;
    }

    return self;
}

/*!
    Initializes a new CPTimer that, when added to a run loop, will fire at date and then, if repeats is YES, every seconds after that.
*/
- (id)initWithFireDate:(CPDate)aDate interval:(CPTimeInterval)seconds target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)shouldRepeat
{
    var invocation = [CPInvocation invocationWithMethodSignature:1];

    [invocation setTarget:aTarget];
    [invocation setSelector:aSelector];
    [invocation setArgument:self atIndex:2];

    self = [self initWithFireDate:aDate interval:seconds invocation:invocation repeats:shouldRepeat];

    if (self)
        self._userInfo = userInfo;

    return self;
}

/*!
    Initializes a new CPTimer that, when added to a run loop, will fire at date and then, if repeats is YES, every seconds after that.
*/
- (id)initWithFireDate:(CPDate)aDate interval:(CPTimeInterval)seconds callback:(Function)aFunction repeats:(BOOL)shouldRepeat
{
    self = [super init];

    if (self)
    {
        self._timeInterval = MAX(seconds, CPTimerMinTimeInterval);
        self._callback = aFunction;
        self._repeats = shouldRepeat;
        self._isValid = YES;
        self._fireDate = aDate;
    }

    return self;
}

/*!
    Returns the receiver’s time interval.
*/
- (CPTimeInterval)timeInterval
{
   return self._timeInterval;
}

/*!
    Returns the date at which the receiver will fire.
*/
- (CPDate)fireDate
{
   return self._fireDate;
}

/*!
    Resets the receiver to fire next at a given date.
*/
- (void)setFireDate:(CPDate)aDate
{
    self._fireDate = aDate;
}

/*!
    Causes the receiver’s message to be sent to its target.
*/
- (void)fire
{
    if (!self._isValid)
        return;

    if (self._callback)
        self._callback();
    else
        [self._invocation invoke];

    if (!self._isValid)
        return;

    if (self._repeats)
        self._fireDate = [CPDate dateWithTimeIntervalSinceNow:self._timeInterval];

    else
        [self invalidate];
}

/*!
    Returns a Boolean value that indicates whether the receiver is currently valid.
*/
- (BOOL)isValid
{
   return self._isValid;
}

/*!
    Stops the receiver from ever firing again and requests its removal from its CPRunLoop object.
*/
- (void)invalidate
{
   self._isValid = NO;
   self._userInfo = nil;
   self._invocation = nil;
   self._callback = nil;
}

/*!
    Returns the receiver's userInfo object.
*/
- (id)userInfo
{
   return self._userInfo;
}

@end

 


