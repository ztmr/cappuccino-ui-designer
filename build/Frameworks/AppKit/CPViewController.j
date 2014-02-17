@import "CPView.j"

@implementation CPViewController : CPResponder
{
	CPView          _view @accessors(getter=view);
    
    BOOL            _isLoading;
    BOOL            _isLazy;
    BOOL            _isViewLoaded @accessors(getter=isViewLoaded);

    id              _representedObject @accessors(property=representedObject);
    CPString        _title @accessors(property=title);

    //CPString        _cibName @accessors(property=cibName, readonly);
    //CPDictionary    _cibExternalNameTable @accessors(property=cibExternalNameTable, readonly);
 
}

-(id) initWithCibName:(CPString)aCibNameOrNil
{
	return [self initWithCibName:aCibNameOrNil externalNameTable:nil];
}

/*!
    The designated initializer. If you subclass CPViewController, you must
    call the super implementation of this method, even if you aren't using a
    Cib.

    In the specified Cib, the File's Owner proxy should have its class set to
    your view controller subclass, with the view outlet connected to the main
    view. If you pass in a nil Cib name, then you must either call -setView:
    before -view is invoked, or override -loadView to set up your views.

    @param cibNameOrNil The path to the cib to load for the root view or nil to programmatically create views.
    @param cibBundleOrNil The bundle that the cib is located in or nil for the main bundle.
*/
- (id)initWithCibName:(CPString)aCibNameOrNil externalNameTable:(CPDictionary)anExternalNameTable
{
    self = [super init];

    if (self)
    {
        // Don't load the cib until someone actually requests the view. The user may just be intending to use setView:.
        //_cibName = aCibNameOrNil;
        //_cibExternalNameTable = anExternalNameTable || @{ CPCibOwner: self };

        _isLoading = NO;
        _isLazy = NO;
    }

    return self;
}


/*!
    Manually sets the view that the controller manages.

    Setting to nil will cause -loadView to be called on all subsequent calls
    of -view.

    @param aView The view this controller should represent.
*/
- (void)setView:(CPView)aView
{
    var willChangeIsViewLoaded = (_isViewLoaded == NO && aView != nil) || (_isViewLoaded == YES && aView == nil);

    if (willChangeIsViewLoaded)
        [self willChangeValueForKey:"isViewLoaded"];

    _view = aView;
    _isViewLoaded = aView !== nil;

    if (willChangeIsViewLoaded)
        [self didChangeValueForKey:"isViewLoaded"];
}

- (void)_viewDidLoad
{
    [self willChangeValueForKey:"isViewLoaded"];
    [self viewDidLoad];
    _isViewLoaded = YES;
    [self didChangeValueForKey:"isViewLoaded"];
}

/*!
    This method is called after the view controller has loaded its associated views into memory.

    This method is called regardless of whether the views were stored in a nib
    file or created programmatically in the loadView method, but NOT when setView
    is invoked. This method is most commonly used to perform additional initialization
    steps on views that are loaded from cib files.
*/
- (void)viewDidLoad
{

}


@end



var CPViewControllerViewKey     = @"CPViewControllerViewKey",
    CPViewControllerTitleKey    = @"CPViewControllerTitleKey",
    CPViewControllerCibNameKey  = @"CPViewControllerCibNameKey",
    CPViewControllerBundleKey   = @"CPViewControllerBundleKey";

@implementation CPViewController (CPCoding)

/*!
    Initializes the view controller by unarchiving data from a coder.
    @param aCoder the coder from which the data will be unarchived
    @return the initialized view controller
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _view = [aCoder decodeObjectForKey:CPViewControllerViewKey];
        _title = [aCoder decodeObjectForKey:CPViewControllerTitleKey];
//_cibName = [aCoder decodeObjectForKey:CPViewControllerCibNameKey];
 //		_cibExternalNameTable = @{ CPCibOwner: self };
        _isLazy = YES;
    }

    return self;
}

/*!
    Archives the view controller to the provided coder.
    @param aCoder the coder to which the view controller should be archived
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_view forKey:CPViewControllerViewKey];
    [aCoder encodeObject:_title forKey:CPViewControllerTitleKey];
    //[aCoder encodeObject:_cibName forKey:CPViewControllerCibNameKey];
 
}

@end