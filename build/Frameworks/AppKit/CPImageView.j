@import "CPView.j"
@import "CPImage.j"

var CPScaleToFit = 0,
	CPScaleProportionally = 1,
	CPScaleNone = 2; 

@implementation CPImageView : CPView
{
	CPImage   			_image;

	int 				_scaling @accessors(property=imageScaling); 

}

-(CPImage) image 
{
    return _image; 
}

-(void) setImage:(CPImage)anImage
{
	_image = [anImage copy];
	[_image setDelegate:self]; 
}

-(void) imageDidLoad:(id) sender
{
	[self _renderImage];
}

-(void) setFrameSize:(CGSize)aSize
{
	[super setFrameSize:aSize];

	[self _renderImage];
}

-(void)_renderImage
{

    _DOMElement.empty(); 
	if (!_image)
	    return;

	var bounds = _bounds,
    	imageDOM = [_image DOMElement],
    	imageScaling = _scaling, 
    	width = bounds.size.width,
    	height = bounds.size.height,
    	frame = [self frame];  

	if (imageScaling === CPScaleToFit)
    {	
			imageDOM.css({
    			width : width,
    			height : height
    		});
    }
    else
    {
        var size = [_image size]; 

        if (size.width == -1 && size.height == -1)
            return;

        if (imageScaling === CPScaleProportionally)
        {	
            // The max size it can be is size.width x size.height, so only
            // only proportion otherwise.
            if (width >= size.width && height >= size.height)
            {
                width = size.width;
                height = size.height;
            }
            else
            {
                var imageRatio = size.width / size.height,
                    viewRatio = width / height;

                if (viewRatio > imageRatio)
                    width = height * imageRatio;
                else
                    height = width / imageRatio;
            }
		 
 			imageDOM.css({
    			width : width,
    			height : height
			});
        }
        else
        {
        	
            width = Math.min(frame.size.width, size.width);
            height = Math.min(frame.size.height, size.height);
        }

        if (imageScaling == CPScaleNone)
        {
 			 	imageDOM.css({
    				width : width,
    				height : height
    			});

        }

     }

     imageDOM.css({
     		position : "absolute",
        	left: (frame.size.width - width)/2.0,
        	top : (frame.size.height - height)/2.0
     });


    _DOMElement.append(imageDOM);
}

@end

var CPImageViewScalingKey       = @"CPImageViewScalingKey",
    CPImageViewImageKey         = @"CPImageViewImageKey";


@implementation CPImageView (CPCoding)

-(id) initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    if( self )
    {
        _scaling = [aCoder decodeIntForKey:CPImageViewScalingKey];  
        [self setImage:[aCoder decodeObjectForKey:CPImageViewImageKey]];
    }

    return self;

}


-(void) encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeInt:_scaling forKey:CPImageViewScalingKey];
    [aCoder encodeObject:_image forKey:CPImageViewImageKey];
}

@end