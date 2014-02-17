@import <Foundation/CPData.j>

@import "CPViewController.j"





/*!
    Represents an object inside a CPCollectionView.
*/
@implementation CPCollectionViewItem : CPViewController
{
    BOOL                    _isSelected;
    CPData                  _cachedArchive;

    CPCollectionView        _collectionView; 
}

- (id)copy
{
     
    var copy = [[[self class] alloc] initWithCibName:nil];

    [copy setRepresentedObject:[self representedObject]];
    [copy setSelected:_isSelected];

    return copy;
}

// Setting the Represented Object
/*!
    Sets the object to be represented by this item.
    @param anObject the object to be represented
*/
- (void)setRepresentedObject:(id)anObject
{
    [super setRepresentedObject:anObject];

    var view = [self view];

    if ([view respondsToSelector:@selector(setRepresentedObject:)])
        [view setRepresentedObject:[self representedObject]];
}

// Modifying the Selection
/*!
    Sets whether this view item should be selected.
    @param shouldBeSelected \c YES makes the item selected. \c NO deselects it.
*/
- (void)setSelected:(BOOL)shouldBeSelected
{
    shouldBeSelected = !!shouldBeSelected;

    if (_isSelected === shouldBeSelected)
        return;

    _isSelected = shouldBeSelected;

    var view = [self view];

    if ([view respondsToSelector:@selector(setSelected:)])
        [view setSelected:[self isSelected]];
}

/*!
    Returns \c YES if the item is currently selected. \c NO if the item is not selected.
*/
- (BOOL)isSelected
{
    return _isSelected;
}

// Parent Collection View
/*!
    Returns the collection view of which this item is a part.
*/
- (CPCollectionView)collectionView
{
    return _collectionView; 
}

@end
