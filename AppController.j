/*
 * AppController.j
 * NewApplication
 *
 * Created by You on January 29, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */




@import <AppKit/CPSplitView.j>
@import <AppKit/CPColorPanel.j>
@import <AppKit/CPToolbar.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPSegmentedControl.j>
@import <AppKit/CPAlert.j>  

@import <AppKit/CPOutlineView.j> 


@import "NewFileDialog.j"
@import "FileViewerController.j"  
@import "NewProjectDialog.j"
@import "CibEditorView.j"
@import "CibInspectorView.j"
@import "AceEditor.j"

var CompileAndRunToolbarItemIdentifier =         @"CompileAndRunToolbarItemIdentifier",
	  DebugReleasePopupToolbarItemIdentifier =     @"DebugReleasePopupToolbarItemIdentifier",
    PanelVisibleControlToolbarItemIdentifier =   @"PanelVisibleControlToolbarItemIdentifier";





@implementation AppController : CPObject        
{

    CPOutlineView               outlineView; 
    CPSplitView                 splitView;  

    NewFileDialog               newFileDialog; 
    NewProjectDialog            newProjectDialog;
    FileViewerController        fileViewerController; 
    CibEditorView               cibView; 
    CibInspectorView            cibInspectorView; 
    AceEditor                   aceEditor; 


    id                          _testWindow; 

    int                          _activeContextMode;

    int                         lastCenterSplitPos;  


    CPDictionary                _currentProject; 
 


}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
       

    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],  
        contentView = [theWindow contentView];
     
    var toolbar = [[CPToolbar alloc] initWithIdentifier:"ToolBar"];
    [toolbar setDelegate:self];
    [theWindow setToolbar:toolbar];

    var bounds = [contentView bounds];

    splitView = [[CPSplitView alloc] initWithFrame:bounds];

    [splitView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

    outlineView = [[CPOutlineView alloc] initWithFrame:CGRectMake(0,0, 240, CGRectGetHeight([contentView bounds]))];
    [outlineView setHasHeader:NO];
    [outlineView setAutoresizingMask:CPViewHeightSizable];
    
    fileViewerController = [[FileViewerController alloc] init];
    [outlineView setDataSource:fileViewerController];
    [outlineView setDelegate:self];

    var column1 = [[CPTableColumn alloc] initWithIdentifier:@"COL1"];
    [column1 setWidth:200];
    [outlineView addTableColumn:column1];
    [outlineView setEmptyText:@""];
    [outlineView setBackgroundColor:[CPColor colorWithHexString:@"ebedf1"]];

    _activeContextMode = 2; 

    var centerView = [[CPView alloc] initWithFrame:CGRectMake(240,0, CGRectGetWidth(bounds) - 540, CGRectGetHeight(bounds))];
    [centerView setBackgroundColor:[CPColor colorWithWhite:0.87 alpha:1.0]];
    [centerView setAutoresizingMask:CPViewWidthSizable];
   
    
    cibView = [[CibEditorView alloc] initWithFrame:[centerView bounds]];
    [cibView setHidden:YES];
    
    [centerView addSubview:cibView];

    aceEditor = [[AceEditor alloc] initWithFrame:[centerView bounds]];
    [aceEditor setHidden:YES];

    [centerView addSubview:aceEditor];


    [splitView fixDivider:YES atIndex:0];
    [splitView fixDivider:YES atIndex:1];
    [splitView setDividerThickness:0]; 

    
    var rightView = [[CPSplitView alloc] initWithFrame:CGRectMake(CGRectGetWidth(bounds) - 300, 0, 300, CGRectGetHeight(bounds))];
    
    cibInspectorView = [[CibInspectorView alloc] initWithFrame:[rightView bounds]];
    [cibInspectorView setHidden:YES];
    [rightView addSubview:cibInspectorView];
     
    [splitView addSubview:outlineView];
    [splitView addSubview:centerView];
    [splitView addSubview:rightView];


    [contentView addSubview:splitView];

    [self setupMenuBar]; 

    _currentProjectId = Nil; 
    
    
    [theWindow orderFront:self];  
    

    [aceEditor setup];

    _testWindow = nil; 

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(fileMarkedAsUnsaved:)
                                        name:AceEditorMarkFileUnsavedNotification object:aceEditor];

    
   
    
}

-(void) fileMarkedAsUnsaved:(CPNotification)aNotification
{ 
    var sel = [outlineView selectedRow];
    var item = [outlineView itemAtRow:sel]; 

    if([item objectForKey:@"isLoaded"])
        [outlineView reloadData];
}

- (CPArray)toolbarItemIdentifiers:(CPToolbar)aToolbar
{
 
  return [DebugReleasePopupToolbarItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier, CompileAndRunToolbarItemIdentifier, 
			CPToolbarFlexibleSpaceItemIdentifier, 
			CPToolbarFlexibleSpaceItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier, PanelVisibleControlToolbarItemIdentifier];

}

//this delegate method returns the actual toolbar item for the given identifier

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anItemIdentifier 
{
    var toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];

    if (anItemIdentifier === CompileAndRunToolbarItemIdentifier)
    {
        [toolbarItem setImage:[CPImage imageNamed:@"build.png"]];
        [toolbarItem setAlternateImage:[CPImage imageNamed:@"build_highlighted.png"]];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(buildAndRun:)];
        [toolbarItem setLabel:@"Run"];
    }
	else if(anItemIdentifier === DebugReleasePopupToolbarItemIdentifier)
	{
		var popup = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0,0, 150, 25)];
		[popup addItemWithTitle:@"Debug"];
        [popup addItemWithTitle:@"Release"];
        [popup setBezelStyle:CPTexturedRoundedBezelStyle];

        [toolbarItem setView:popup];
		
		
		[toolbarItem setLabel:@"Configuration"];
		
	}
    else if(anItemIdentifier === PanelVisibleControlToolbarItemIdentifier)
    {
        var seg = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0,0,115, 25)];

        [seg setImagePosition:CPImageOnly];
        [seg setSegmentStyle:CPSegmentStyleTexturedRounded];
        [seg setTrackingStyle:CPSegmentSwitchTrackingSelectAny];  
        
        [seg setTarget:self];
        [seg setAction:@selector(onToggleVisiblePanels:)];

        [seg setSegmentCount:3]; 
        [seg setImage:[CPImage imageNamed:@"leftPanel.png"] forSegment:0];
        [seg setImage:[CPImage imageNamed:@"leftPanel_highlighted.png"] 
           forSegment:0 
              inState:CPControlSelectedState];
        

        [seg setImage:[CPImage imageNamed:@"bottomPanel.png"] forSegment:1];
        [seg setImage:[CPImage imageNamed:@"bottomPanel_highlighted.png"] 
           forSegment:1 
              inState:CPControlSelectedState];
       
        [seg setImage:[CPImage imageNamed:@"rightPanel.png"] forSegment:2];
        [seg setImage:[CPImage imageNamed:@"rightPanel_highlighted.png"] 
           forSegment:2 
              inState:CPControlSelectedState];

        [toolbarItem setView:seg];

        [seg setSelected:YES forSegment:0];
        [seg setSelected:YES forSegment:1];
        [seg setSelected:YES forSegment:2];

        [toolbarItem setLabel:@"View"];   
    }
    

    return toolbarItem;   
} 


-(void) buildAndRun:(id) sender      
{   
  if(_currentProject)
  {   
      if(_testWindow)
        _testWindow.close(); 

      [self saveAllFiles];

       var appDir = [_currentProject objectForKey:@"directory"];

       BUILD.buildClientExecutable(appDir, appDir, true);

       _testWindow = GUI.Window.open('file://' + appDir + "/index.html", {
            position: 'center',
            width: 800,
            height: 600,
            title : [_currentProject objectForKey:@"name"]
        });

       var loadOnce = false; 
       _testWindow.on("loaded", function(){

          if(!loadOnce)
            _testWindow.reload(); 

          loadOnce = true; 
       })
   }
     
}




-(IBAction) onToggleVisiblePanels:(id)sender 
{
    var index = [sender changedSegment],
        bounds = [[splitView superview] bounds],
        selected = [sender isSelectedForSegment:index];

    if(index == 0)
    {
        var x = [splitView positionOfDividerAtIndex:0];

        if(x > 0 && !selected)
        {   
             [splitView setPosition:0 ofDividerAtIndex:0];

        }
        else if(x < 240 && selected)
        {
             [splitView setPosition:240 ofDividerAtIndex:0];
        }
    }  

     
    if(index === 1)
    {  
       var y = [cibView positionOfDividerAtIndex:0];

       if(y >= lastCenterSplitPos && selected)
       {    
           [cibView fixDivider:NO atIndex:0]; 
           [cibView setPosition:lastCenterSplitPos ofDividerAtIndex:0];
       }
       else if(y <= CGRectGetHeight(bounds) && !selected )
       {
            lastCenterSplitPos = y;
            [cibView fixDivider:YES atIndex:0]; 
            [cibView setPosition:CGRectGetHeight(bounds) ofDividerAtIndex:0];
             
       }
    } 

    if(index == 2)
    {
        var x = [splitView positionOfDividerAtIndex:1];

        if(x >= CGRectGetWidth(bounds)-300 && selected)
        {   
            [splitView setPosition:CGRectGetWidth(bounds)-300 ofDividerAtIndex:1];
             

        }
        else if(x <= CGRectGetWidth(bounds) && !selected)
        {
            [splitView setPosition:CGRectGetWidth(bounds) ofDividerAtIndex:1];
             
        }
    }  

}

 

-(void) outlineViewSelectionDidChange:(CPNotification)aNotification
{
    var sel = [outlineView selectedRow];
    var item = [outlineView itemAtRow:sel]; 
    var isDir = [item objectForKey:@"isDirectory"];

    if(!isDir)
    { 
         var filename = [item objectForKey:@"name"],
             filepath = [item objectForKey:@"path"];


        var result = readFile(filepath);

        if(result)
        { 

            var stime = result.time;

            var fileInfo = [fileViewerController infoForFile:filepath];
            var ftime = [fileInfo objectForKey:@"timestamp"];

            if(stime > ftime)
            {   
                [fileInfo setObject:result.contents forKey:@"contents"];
                [fileInfo setObject:result.time forKey:@"timestamp"];
                [fileInfo setObject:YES forKey:@"isLoaded"];
                
            } 

            if([filename hasSuffix:@".cib"])
            {
                [self switchContext:1];
            }
            else
            {   
                [self switchContext:0];
                [aceEditor setFile:fileInfo];
                [fileInfo setObject:NO forKey:@"unsaved"];
                [outlineView reloadData];
                
            }
      } 
 
        
    }
   
}

-(void) saveAllFiles 
{
    var allFilePaths = [fileViewerController allFiles],
        count = [allFilePaths count],
        i = 0;

    for(; i < count; i++)
    { 
        var filepath = [allFilePaths objectAtIndex:i];
        var fileInfo = [fileViewerController infoForFile:filepath];

        if([fileInfo objectForKey:@"unsaved"])
        {
            var result = saveFile(filepath, [fileInfo objectForKey:@"contents"]);

            if(result)
            {
              [fileInfo setObject:result.time forKey:@"timestamp"];
              [fileInfo setObject:NO forKey:@"unsaved"];

              

            } 
        }
    }

    [outlineView reloadData];
}

-(void) onSaveFile:(id)sender 
{

     var sel = [outlineView selectedRow];
    var item = [outlineView itemAtRow:sel]; 
    var isDir = [item objectForKey:@"isDirectory"];

    if(!isDir)
    {
         var filename = [item objectForKey:@"name"],
             filepath = [item objectForKey:@"path"];

        var result = saveFile(filepath, [item objectForKey:@"contents"]);

        if(result)
        {
            [item setObject:result.time forKey:@"timestamp"];
            [item setObject:NO forKey:@"unsaved"];

            [outlineView reloadData];

        } 

    }

}

 

-(void) onOpenProject:(id)sender 
{
      setTimeout(function(){

           var chooser = $("#fileopen");

          chooser.change(function(evt) {
              
              var file = null;
              if(evt.target.files.length > 0)
                file = evt.target.files[0];

              if(file)
              { 

                  var reader = new FileReader(); 

                  var directory = PATH.dirname($(this).val());
 
                  reader.onload = function(e)
                  { 

                        var result = reader.result; 
                        try
                        {
                            var projInfo = JSON.parse(result);
                            
                            if(projInfo.name)
                            {

                                setTimeout(function(){

                                  [self doOpenProject:@{
                                      @"name" : projInfo.name,
                                      @"directory" : directory
                                }];

                                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

                              }, 500); 
                                 
                            }
                        }
                        catch(err)
                        {

                        }
                }

                reader.readAsText(file); 

              } 
          });

          chooser.trigger('click');  

      }, 160); 
}


-(void) doOpenProject:(CPDictionary)projectToOpen
{ 
    _currentProject = projectToOpen; 

    var projdir = [_currentProject objectForKey:@"directory"];

    var theFiles = getFilesInDirectory(projdir);
    
    if(theFiles)
    {
            [fileViewerController setProjectName:[_currentProject objectForKey:@"name"]];
            [fileViewerController setData:theFiles];
            [outlineView reloadData];
            [outlineView expandItem:[outlineView itemAtRow:0]];

            window.document.title = "Atlas - " + [_currentProject objectForKey:@"name"];

    } 

   
}



-(void) setupMenuBar
{

    [CPMenu setMenuBarVisible:YES];

         var fileMenu = [CPMenu menuWithTitle:@"File"];

         var newMenuItem = [CPMenuItem menuItemWithTitle:@"New..."];
         var newMenu = [CPMenu menuWithTitle:@"newItem"];
         var newFile = [CPMenuItem menuItemWithTitle:@"New File..."];
         

         [newFile setTarget:self];
         [newFile setAction:@selector(newFile:)];

         var newProject = [CPMenuItem menuItemWithTitle:@"New Project..."];

         [newProject setTarget:self];
         [newProject setAction:@selector(newProject:)]

         [newMenu addItem:newFile];
         [newMenu addItem:newProject];

         [newMenuItem setSubmenu:newMenu];
         
         [fileMenu addItem:newMenuItem];

         var openFile = [CPMenuItem menuItemWithTitle:@"Open Project..."];
         $("body").append($("<input type='file' id='fileopen'></input>"));
         [openFile setTarget:self];
         [openFile setAction:@selector(onOpenProject:)];
         
          
         
         [fileMenu addItem:openFile];
         [fileMenu addSeparator];

         var saveItem = [CPMenuItem menuItemWithTitle:@"Save"];
         [saveItem setTarget:self];
         [saveItem setAction:@selector(onSaveFile:)];

         [fileMenu addItem:saveItem];
         [fileMenu addItem:[CPMenuItem menuItemWithTitle:@"Save As..."]];

         [fileMenu addSeparator];

         [fileMenu addItem:[CPMenuItem menuItemWithTitle:@"Close File"]]; 

         [[CPApp mainMenu] addItem:fileMenu]; 

         var editMenu = [CPMenu menuWithTitle:@"Edit"];
 
         [editMenu addItem:[CPMenuItem menuItemWithTitle:@"Undo"]];
         [editMenu addItem:[CPMenuItem menuItemWithTitle:@"Redo"]];
         [editMenu addSeparator];

         [editMenu addItem:[CPMenuItem menuItemWithTitle:@"Copy"]];
         [editMenu addItem:[CPMenuItem menuItemWithTitle:@"Cut"]];
         [editMenu addItem:[CPMenuItem menuItemWithTitle:@"Paste"]];
          
         [[CPApp mainMenu] addItem:editMenu];  

}

-(void) newProject:(id)sender  
{
    if(!newProjectDialog)
    {
      newProjectDialog = [[NewProjectDialog alloc] init];
      

      [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(onNewProjectCreated:)
                                            name:@"NewProjectCreatedNotification" object:newProjectDialog];

    }
    [newProjectDialog reset];
    [newProjectDialog center];
    [newProjectDialog makeKeyAndOrderFront:nil];

}

-(void) newFile:(id)sender 
{
    if(!newFileDialog)
    {
        newFileDialog = [[NewFileDialog alloc] init];        
    } 


    [newFileDialog reset];
    [newFileDialog center];
    [newFileDialog makeKeyAndOrderFront:nil];
    
}

-(void)onNewProjectCreated:(CPNotification)aNotification
{
    [self doOpenProject:[newProjectDialog newProject]];

}


-(void) switchContext:(int)contextMode 
{
     if(contextMode !== _activeContextMode)
     {
          _activeContextMode = contextMode;

          if(_activeContextMode == 0) //code editor
          {
                [cibInspectorView setHidden:YES];
                [cibView setHidden:YES];
                [aceEditor setHidden:NO];

          }
          else if(_activeContextMode == 1)  //cib editor
          {
              [cibView setHidden:NO];
              [cibInspectorView setHidden:NO];
              [aceEditor setHidden:YES];

          }
          else
          {
              [cibView setHidden:NO];
              [cibInspectorView setHidden:NO];
              [aceEditor setHidden:NO];
          }
     }
}

@end


@implementation OpenProjectWindow : CPWindow 
{
    DOMElement          _inputFileEl; 

    CPButton            _openBtn;
    CPButton            _cancelBtn; 


    CPDictionary        _projectToOpen; 



    id                  _target @accessors(property=target);
    SEL                 _action @accessors(property=action);

}

-(id) init 
{
    self = [super initWithContentRect:CGRectMake(0,0, 340, 180) styleMask:CPClosableWindowMask];

    if( self )
    {

        _projectToOpen = nil; 

        [self setTitle:@"Open Project"];
        var cv = [self contentView];

        var label = [CPTextField labelWithString:@"Select the Project's Info.json file:"];
        [label setFrameOrigin:CGPointMake(15,15)];
        [cv addSubview:label];


        _inputFileEl = $("<input type='file' id='fileopen'></input>");
        _inputFileEl.click(function(evt){
              evt.stopPropagation();
        });

        _inputFileEl.on("change", function(evt){
              var reader = new FileReader();
              if(evt.target.files.length > 0)
              {
                  var file = evt.target.files[0]; 
 
                  reader.onload = function(e)
                  {
                        var result = reader.result;
                        try
                        {
                            var projInfo = JSON.parse(result);

                            if(projInfo.projectDir)
                            {
                                _projectToOpen = @{
                                      @"name" : projInfo.name,
                                      @"directory" : projInfo.projectDir

                                };
                            }
                        }
                        catch(err)
                        {

                        }
                  }

                  reader.readAsText(file);

              }
             

        });
         

        _inputFileEl.css({
            position : "absolute",
            left : 15,
            top : 45
        });

       

        cv._DOMElement.append(_inputFileEl);

        _cancelBtn = [CPButton buttonWithTitle:@"Cancel"];
        [_cancelBtn setFrame:CGRectMake(160, 140, 80,25)];
        [_cancelBtn setTarget:self];
        [_cancelBtn setAction:@selector(orderOut:)];
        
        [cv addSubview:_cancelBtn];


        _openBtn = [CPButton buttonWithTitle:@"Open"];
        [_openBtn setFrame:CGRectMake(245, 140,80,25)];
        [_openBtn setTarget:self];
        [_openBtn setAction:@selector(onOpen:)];

        [cv addSubview:_openBtn];

    }

    return self; 
}

-(void) onOpen:(id)sender 
{ 
    if(_projectToOpen)
        [_target performSelector:_action withObject:_projectToOpen];


    [self orderOut:nil];

}



@end


function saveFile(filePath, data)
{
    var stats = FS.statSync(filePath);
    var time = stats.mtime.getTime();

    FS.writeFileSync(filePath, data);

    return {time : time};

}
   
function readFile(filePath)
{
  var exists = FS.existsSync(filePath);

    if(exists)
    { 
      var stats = FS.statSync(filePath);
      var time = stats.mtime.getTime(); 
    
      var data = FS.readFileSync(filePath, "UTF-8");


      return {time : time, contents : data}; 

    }

    return null; 
}


function getFilesInDirectory(dirPath)
 {
    var theFiles = [];

    var exists = FS.existsSync(dirPath);
    if(!exists)
      return null; 

    var files = FS.readdirSync(dirPath),
      count = files.length,
      i = 0;  
    
    for(; i < count; i++)
    {
      var file = files[i];
      if(file.length > 0 && file[0] != ".")
      {
        var fobj = {"name" : file, "path" : PATH.join(dirPath, file)};
        var stats = FS.statSync(PATH.join(dirPath, file));

        if(stats.isDirectory())
        {
          fobj.isDirectory = true;
          fobj.files = getFilesInDirectory(PATH.join(dirPath, file));
          theFiles.push(fobj);


        } 
        else if(stats.isFile())
        {
          fobj.isDirectory = false; 
          theFiles.push(fobj);
        }
      }
      
    }

    return theFiles; 
 }

