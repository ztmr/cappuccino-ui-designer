@import <Foundation/CPObject.j>
@import <Foundation/CPData.j>
@import <Foundation/CPString.j> 
@import <Foundation/CPGeometry.j>


var CPImageLoadStatusInitialized    = 0;
var CPImageLoadStatusLoading        = 1;
var CPImageLoadStatusCompleted      = 2;
var CPImageLoadStatusCancelled      = 3;
var CPImageLoadStatusInvalidData    = 4;
var CPImageLoadStatusUnexpectedEOF  = 5;
var CPImageLoadStatusReadError      = 6;

var CPImageDidLoadNotification      = @"CPImageDidLoadNotification";


// Image Names
var CPImageNameColorPanel               = @"CPImageNameColorPanel";
var CPImageNameColorPanelHighlighted    = @"CPImageNameColorPanelHighlighted";


@implementation CPImage : CPObject
{
	CPString    _filename;
	CPString    _name;
	
	CPSize		_size; 
	unsigned    _loadStatus;
	
	id			_delegate; 
	
	Image		_DOMElement; 
}

+(id) imageNamed:(CPString)imageName
{
	return [CPImage imageWithFile:@"Resources/" +imageName];

}

+(id) imageWithFile:(CPString) aFilename
{
	return [[CPImage alloc] initWithContentsOfFile:aFilename];
}

- (id)initByReferencingFile:(CPString)aFilename size:(CPSize)aSize
{ 	 
    self = [super init];

    if (self)
    {
		_size = CGSizeCreateCopy(aSize);
        _filename = aFilename;
        _loadStatus = CPImageLoadStatusInitialized;
		_DOMElement = null; 
    }

    return self;
}

-(DOMElement) DOMElement
{
	return $(_DOMElement); 
}

- (id)initWithContentsOfFile:(CPString)aFilename size:(CPSize)aSize
{ 	
    self = [self initByReferencingFile:aFilename size:aSize];

    if (self)
        [self load];

    return self;
}

/*!
    Initializes the receiver with the contents of the specified
    image file. The method loads the data into memory.
    @param aFilename the file name of the image
    @return the initialized image
*/

- (id)initWithContentsOfFile:(CPString)aFilename
{ 	
    self = [self initByReferencingFile:aFilename size:CPMakeSize(-1, -1)];
	
    if (self)
        [self load];
 
    return self;
}

/*!
    Initializes the receiver with the specified data. The method loads the data into memory.
    @param someData the CPData object representing the image
    @return the initialized image
*/
- (id)initWithData:(CPData)someData
{
    var base64 = [someData base64],
        type = [base64 hasPrefix:@"/9j/4AAQSkZJRgABAQEASABIAAD/"] ? @"jpg" : @"png",
        dataURL = "data:image/" + type + ";base64," + base64;

    return [self initWithContentsOfFile:dataURL];
}



-(id)copy 
{
	return [CPImage imageWithFile:[self filename]];
}

- (CPString)filename
{
    return  _filename;
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}
 
- (id)delegate
{
    return _delegate;
}
 
- (void) setSize:(CGSize)aSize
{
    _size = CGSizeCreateCopy(aSize);
   
}


- (CGSize) size
{
    return _size;
}

- (unsigned)loadStatus
{
    return  _loadStatus;
} 
 
- (void)load
{
    if (_loadStatus == CPImageLoadStatusLoading || _loadStatus == CPImageLoadStatusCompleted)
        return;
		
    _loadStatus = CPImageLoadStatusLoading;
	
	_DOMElement = new Image(); 
	$(_DOMElement).mousedown(function(evt){evt.preventDefault();});
	$(_DOMElement).addClass("cpimage");
    var isSynchronous = YES;

    // FIXME: We need a better/performance way of doing this.
    _DOMElement.onload = function ()
        {
	
            if (isSynchronous)
                window.setTimeout(function() { [self imageDidLoad]; }, 0);
            else
            {
                [self imageDidLoad];
            }
            [self _derefFromImage];
        };

    _DOMElement.onerror = function ()
        {
	
            if (isSynchronous)
                window.setTimeout(function() { [self imageDidError]; }, 0);
            else
            {
                [self imageDidError];
                 
            }
            [self _derefFromImage];
        };

     _DOMElement.onabort = function ()
        {
	
            if (isSynchronous)
                window.setTimeout(function() { [self imageDidAbort]; }, 0);
            else
            {
                [self imageDidAbort];
                
            }
            [self _derefFromImage];
        };

    
    _DOMElement.src = self._filename;
	
    window.setTimeout(function() { isSynchronous = NO; }, 0);

	
}


- (void)_derefFromImage
{
    self._DOMElement.onload = null;
    self._DOMElement.onerror = null;
    self._DOMElement.onabort = null;
}

- (void)imageDidLoad
{
    self._loadStatus = CPImageLoadStatusCompleted;
 	
    if (!self._size || (self._size.width == -1 && self._size.height == -1))
         self._size = CPMakeSize(self._DOMElement.width, self._DOMElement.height);


    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPImageDidLoadNotification
        object:self];
    

    if ([self._delegate respondsToSelector:@selector(imageDidLoad:)])
        [self._delegate imageDidLoad:self];
}

- (void)imageDidError
{
    self._loadStatus = CPImageLoadStatusReadError;

    if ([self._delegate respondsToSelector:@selector(imageDidError:)])
        [self._delegate imageDidError:self];
}

- (void)imageDidAbort
{
    self._loadStatus = CPImageLoadStatusCancelled;

    if ([self._delegate respondsToSelector:@selector(imageDidAbort:)])
        [self._delegate imageDidAbort:self];
}


@end


@implementation CPImage (CPCoding)

/*!
    Initializes the image with data from a coder.
    @param aCoder the coder from which to read the image data
    @return the initialized image
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    return [self initWithContentsOfFile:[aCoder decodeObjectForKey:@"CPFilename"] size:[aCoder decodeSizeForKey:@"CPSize"]];
}

/*!
    Writes the image data from memory into the coder.
    @param aCoder the coder to which the data will be written
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_filename forKey:@"CPFilename"];
    [aCoder encodeSize:_size forKey:@"CPSize"];
}

@end

 