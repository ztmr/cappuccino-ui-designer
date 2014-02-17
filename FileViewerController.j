@import <AppKit/CPOutlineView.j>



@implementation FileViewerController : CPObject
{
		CPArray 				_data ;
		CPString 				_projectName @accessors(property=projectName);
 
        CPDictionary            _fileInfo; 
}

-(id) init 
{
	self = [super init];
	if( self )
	{
		_data = Nil; 
		_projectName = @"Project"; 
        _fileInfo = @{};
	}

	return self; 

}

-(CPDictionary) _dataToDictionary:(JSObject)fileObj  
{   
    var theFiles = [];

    if(fileObj.files)
    {    
         var count = fileObj.files.length,
             i = 0;

         for(; i < count; i++)
         {  
            var d = [self _dataToDictionary:fileObj.files[i]];
            [self setInfo:d forFile:fileObj.files[i].path];
            theFiles.push(d);
         }

    }
   

    return @{@"name" : fileObj.name, @"path" : fileObj.path, @"isDirectory" : fileObj.isDirectory, "root" : NO,
                @"timestamp" : -1, @"contents" : @"", @"unsaved" : NO, @"isLoaded" : NO, 
                @"files" : theFiles};
}

-(void) setData:(CPArray)data 
{
	 console.log(data)
    _data = data;  
    _fileInfo = @{}; 

    var count = _data.length,
        i = 0; 

    var theFiles = [];

    for(; i < count; i++)
    {   
        var fileObj = _data[i];
        var d = [self _dataToDictionary:fileObj];
 
        [self setInfo:d
            forFile:fileObj.path];

        theFiles.push(d);
    }

    [self setInfo:@{@"name" : _projectName, @"isDirectory" : YES, @"root" : YES, @"unsaved" : NO,
                    @"files" : theFiles}
            forFile:@"__root__"];


}


-(id)outlineView:(CPOutlineView)outlineView numberOfChildrenOfItem:(id)anItem 
{	 
	if(!_data)
		return 0; 

    if(!anItem)
        return 1; 

    if([anItem objectForKey:@"isDirectory"])
    {
        return [[anItem objectForKey:@"files"] count]
    }

    return 0;
}

-(id) outlineView:(CPOutlineView)outlineView child:(int)childIndex ofItem:(id)anItem 
{
     if(!anItem)
     {
     	 return [self infoForFile:@"__root__"];
     }
     	
     if([anItem objectForKey:@"isDirectory"])
     {
        return [[anItem objectForKey:@"files"] objectAtIndex:childIndex];
     }
     	

    return nil; 
}

-(BOOL) outlineView:(CPOutlineView)outlineView isItemExpandable:(id)anItem 
{
	if(!anItem)
		return YES; 
    
    return  [anItem objectForKey:@"isDirectory"];
 
}

-(id) outlineView:(CPOutlineView)outlineView objectValueForTableColumn:(CPTableColumn)aTableColumn byItem:(id)anItem 
{   
    var name = [anItem objectForKey:@"name"],
        unsaved = [anItem objectForKey:@"unsaved"],
        isDir = [anItem objectForKey:@"isDirectory"];

    if(unsaved && !isDir)
    {
        return name + "*";
    }

    return name; 
}

-(CPArray) allFiles 
{
    return [_fileInfo allKeys];
}

-(void) setInfo:(CPDictionary)info forFile:(CPString)filePath
{
    [_fileInfo setObject:info forKey:filePath];
}

-(CPDictionary) infoForFile:(CPString)filePath
{   
    return [_fileInfo objectForKey:filePath];
}

@end