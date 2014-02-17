 /*
 * CPNotification.j
 * Foundation
 *
*/
 
@import "CPObject.j"

/*!
    @class CPNotification
    @ingroup foundation
    @brief A notification that can be posted to a CPNotificationCenter.

    Represents a notification for posting to an CPNotificationCenter. Consists
    of a name, an object, and an optional dictionary. The notification center
    will check for observers registered to receive either notifications with
    the name, the object, or both and pass the notification instance on to them.

    To create a notification use one of the class methods. The default init
    method will throw a CPUnsupportedMethodException.
*/
@implementation CPNotification : CPObject 
{
    CPString        _name;
    id              _object;
    CPDictionary    _userInfo;
}

/*!
    Creates a new notification with the specified name, object and dictionary.
    @param aNotificationName the name of the notification
    @param anObject the associated object
    @param aUserInfo the associated dictionary
    @return the new notification
*/
+ (CPNotification)notificationWithName:(CPString)aNotificationName object:(id)anObject userInfo:(CPDictionary)aUserInfo
{
    return [[self alloc] initWithName:aNotificationName object:anObject userInfo:aUserInfo];
}

/*!
    Creates a new notification with the specified name and object.
    @param aNotificationName the name of the notification
    @param anObject the associated object
    @return the new notification
*/
+ (CPNotification)notificationWithName:(CPString)aNotificationName object:(id)anObject
{
    return [[self alloc] initWithName:aNotificationName object:anObject userInfo:nil];
}

/*!
    @throws CPUnsupportedMethodException always, because the method should not be used
*/
- (id)init
{
    CPLog.warn("CPNotification's init method should not be used");
}

/*!
    Initializes the notification with a name, object and dictionary
    @param aNotificationName the name of the notification
    @param anObject the associated object
    @param aUserInfo the associated dictionary
    @return the initialized notification
    @ignore
*/
- (id)initWithName:(CPString)aNotificationName object:(id)anObject userInfo:(CPDictionary)aUserInfo
{
    self = [super init];

    if (self)
    {
        _name = aNotificationName;
        _object = anObject;
        _userInfo = aUserInfo;
    }

    return self;
}

/*!
    Returns the notification name.
*/
- (CPString)name
{
    return _name;
}

/*!
    Returns the notification's object.
*/
- (id)object
{
    return _object;
}

/*!
    Returns the notification's dictionary.
*/
- (CPDictionary)userInfo
{
    return _userInfo;
}

@end
