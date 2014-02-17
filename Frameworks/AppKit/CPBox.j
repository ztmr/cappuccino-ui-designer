@import "CPTextField.j"
@import "CPView.j"


// CPBoxType
var CPBoxPrimary    = 0, 
	CPBoxSeparator  = 1;


// CPTitlePosition
var CPNoTitle     = 0, 
	CPAtTop       = 1, 
	CPAtBottom    = 2;



@implementation CPBox : CPView
{
	
	CPBoxType       _boxType;
    CPView          _contentView @accessors(getter=contentView);

    CPString        _title @accessors(getter=title);
    int             _titlePosition @accessors(getter=titlePosition);
 

     CPTextField     _titleView;
}



+ (id) boxEnclosingView:(CPView)aView
{
    var box = [[self alloc] initWithFrame:CGRectMakeZero()],
        enclosingView = [aView superview];

    [box setAutoresizingMask:[aView autoresizingMask]];
    [box setFrameFromContentFrame:[aView frame]];

    [enclosingView replaceSubview:aView with:box];

    [box setContentView:aView];

    return box;
}




- (id)initWithFrame:(CGRect)frameRect
{
    self = [super initWithFrame:frameRect];

    if (self)
    {
        _boxType = CPBoxPrimary; 
        _titlePosition = CPNoTitle;
        _titleView = [CPTextField labelWithString:@""];

        _DOMElement.addClass("cpbox");
        [self setTitleFont:[CPFont systemFontOfSize:12.0]];

        
    }

    return self;
}

// Configuring Boxes

/*!
    Returns the receiver's border rectangle.

    @return the border rectangle of the box
*/
- (CGRect)borderRect
{
    return [self bounds];
}

/*!
    Returns the receiver's box type. Possible values are:

    <pre>
    CPBoxPrimary 
    CPBoxSeparator
 
    </pre>

    (In the current implementation, all values act the same except CPBoxSeparator.)

    @return the box type of the box.
*/
- (CPBoxType)boxType
{
    return _boxType;
}

/*!
    Sets the receiver's box type. Valid values are:

    <pre>
    CPBoxPrimary
 
    CPBoxSeparator
   
    </pre>

    (In the current implementation, all values act the same except CPBoxSeparator.)

    @param aBoxType the box type of the box.
*/
- (void)setBoxType:(CPBoxType)aBoxType
{
    if (_boxType === aBoxType)
        return;

    _boxType = aBoxType;
    [self setNeedsLayout];
}

 


- (float)cornerRadius
{
    return [self valueForThemeAttribute:@"corner-radius"];
}

- (void)setCornerRadius:(float)radius
{
    if (radius === [self cornerRadius])
        return;

    [self setValue:radius forThemeAttribute:@"corner-radius"];
    
}


- (void)setContentView:(CPView)aView
{
    if (aView === _contentView)
        return;

    var borderWidth = [self borderWidth],
        contentMargin = [self contentViewMargins],
        bounds =  [self bounds];

    [aView setFrame:CGRectInset(bounds, contentMargin.width, contentMargin.height)];
    [aView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    //  A nil contentView is allowed (tested in Cocoa 2013-02-22).
    if (!aView)
        [_contentView removeFromSuperview];
    else if (_contentView)
        [self replaceSubview:_contentView with:aView];
    else
        [self addSubview:aView];

    _contentView = aView;
}


- (CGSize)contentViewMargins
{
    return [self valueForThemeAttribute:@"content-margin"];
}

- (void)setContentViewMargins:(CGSize)size
{
     if (size.width < 0 || size.height < 0)
         [CPException raise:CPGenericException reason:@"Margins must be positive"];

    [self setValue:CGSizeMakeCopy(size) forThemeAttribute:@"content-margin"];
}

- (void)setFrameFromContentFrame:(CGRect)aRect
{
    var offset = [self _titleHeightOffset],
        borderWidth = [self borderWidth],
        contentMargin = [self valueForThemeAttribute:@"content-margin"];

    [self setFrame:CGRectInset(aRect, -(contentMargin.width + borderWidth), -(contentMargin.height + offset[0] + borderWidth))];
}

- (void)setTitle:(CPString)aTitle
{
    if (aTitle == _title)
        return;

    _title = aTitle;

    [self _manageTitlePositioning];
}

- (void)setTitlePosition:(int)aTitlePotisition
{
    if (aTitlePotisition == _titlePosition)
        return;

    _titlePosition = aTitlePotisition;

    [self _manageTitlePositioning];
}

- (CPFont)titleFont
{
    return [_titleView font];
}

- (void)setTitleFont:(CPFont)aFont
{
    [_titleView setFont:aFont];
}

/*!
    Return the text field used to display the receiver's title.

*/
- (CPTextField)titleView
{
    return _titleView;
}


- (void)_manageTitlePositioning
{
    if (_titlePosition == CPNoTitle)
    {
        [_titleView removeFromSuperview];
        [self setNeedsLayout];
        return;
    }

    [_titleView setStringValue:_title];
    [_titleView sizeToFit];
    [_ephemeralSubviews addObject:_titleView];
    [self addSubview:_titleView];

    switch (_titlePosition)
    {
        case CPAtTop: 
            [_titleView setFrameOrigin:CGPointMake(5.0, 0.0)];
            [_titleView setAutoresizingMask:CPViewNotSizable];
            break;
        case CPAtBottom: 
            var h = [_titleView frameSize].height;
            [_titleView setFrameOrigin:CGPointMake(5.0, [self frameSize].height - h)];
            [_titleView setAutoresizingMask:CPViewMinYMargin];
            break;
    }

    [self sizeToFit];
    [self setNeedsLayout];
}

- (void)sizeToFit
{
    var contentFrame = [_contentView frame],
        offset = [self _titleHeightOffset],
        contentMargin = [self valueForThemeAttribute:@"content-margin"];

    if (!contentFrame)
        return;


    [_contentView setFrameOrigin:CGPointMake(contentMargin.width, contentMargin.height + offset[1])];
}

- (float)_titleHeightOffset
{
    if (_titlePosition == CPNoTitle)
        return [0.0, 0.0];

    switch (_titlePosition)
    {
        case CPAtTop:
            return [[_titleView frameSize].height, [_titleView frameSize].height];

        case CPAtBottom:
            return [[_titleView frameSize].height, 0.0];

        default:
            return [0.0, 0.0];
    }
}


- (void) layoutSubviews
{
    var bounds = [self bounds];
    var cornerRadius = [self cornerRadius];
     
    _DOMElement.css({
        "borderWidth" : [self borderWidth],
        "borderColor" : [[self borderColor] cssString],
        "borderType" : "solid",
        "-moz-border-radius" : cornerRadius,
        "-webkit-border-radius" : cornerRadius,
        "border-radius" : cornerRadius
    });

    /*switch (_boxType)
    {
        case CPBoxSeparator:
            // NSBox does not include a horizontal flag for the separator type. We have to determine
            // the type of separator to draw by the width and height of the frame.
            if (CGRectGetWidth(bounds) === 5.0)
                return [self _drawVerticalSeparatorInRect:bounds];
            else if (CGRectGetHeight(bounds) === 5.0)
                return [self _drawHorizontalSeparatorInRect:bounds];

            break;
    }*/

    if (_titlePosition == CPAtTop)
    {
        bounds.origin.y += [_titleView frameSize].height;
        bounds.size.height -= [_titleView frameSize].height;
    }
    if (_titlePosition == CPAtBottom)
    {
        bounds.size.height -= [_titleView frameSize].height;
    }

    var borderWidth = [self borderWidth],
        contentMargin = [self contentViewMargins]

    if(!_contentView)
    {
        _contentView = [[CPView alloc] initWithFrame:CGRectInset(bounds, contentMargin.width, contentMargin.height)];
        [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [self setAutoresizesSubviews:YES];
        [self addSubview:_contentView];
    }

   
}

@end


var CPBoxTypeKey          = @"CPBoxTypeKey",
    CPBoxBorderTypeKey    = @"CPBoxBorderTypeKey",
    CPBoxTitle            = @"CPBoxTitle",
    CPBoxTitlePosition    = @"CPBoxTitlePosition",
    CPBoxTitleView        = @"CPBoxTitleView";

@implementation CPBox (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
 
        _boxType       = [aCoder decodeIntForKey:CPBoxTypeKey]; 

        _title         = [aCoder decodeObjectForKey:CPBoxTitle];
        _titlePosition = [aCoder decodeIntForKey:CPBoxTitlePosition];

        _titleView = [CPTextField labelWithString:@""];


        [self setTitleFont:[CPFont systemFontOfSize:12.0]];
         
        _contentView   = [self subviews][0];

        [self setAutoresizesSubviews:YES];
        [_contentView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

        [self _manageTitlePositioning];



    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeInt:_boxType forKey:CPBoxTypeKey]; 
    [aCoder encodeObject:_title forKey:CPBoxTitle];
    [aCoder encodeInt:_titlePosition forKey:CPBoxTitlePosition]; 
}

@end