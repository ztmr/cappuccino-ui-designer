
@import <AppKit/CPWindow.j>
@import <AppKit/CPButton.j>


 

@implementation NewProjectDialog : CPWindow 
{
	CPButton 			_createBtn;
	CPButton			_cancelBtn;

	CPTextField 		_projNameField; 
	CPTextField 		_directoryPathField; 

	CPDictionary 		_newProject @accessors(getter=newProject); 
}

-(id) init 
{
	self = [super initWithContentRect:CGRectMake(0,0, 470, 180) styleMask:CPClosableWindowMask];

	if(self )
	{	

		_newProjectID = Nil; 
		[self setTitle:@"New Project"];
		var cv = [self contentView];
			
		var nameLabel = [CPTextField labelWithString:@"Project Name:"];
		[nameLabel setFrameOrigin:CGPointMake(15,15)];

		[cv addSubview:nameLabel]

		_projNameField = [[CPTextField alloc] initWithFrame:CGRectMake(15,37, 440, 25)];
		[_projNameField setBezeled:YES];
		[_projNameField setDelegate:self];
		
		[cv addSubview:_projNameField];

		var dirLabel = [CPTextField labelWithString:@"Directory:"];
		[dirLabel setFrameOrigin:CGPointMake(15,70)];

		[cv addSubview:dirLabel];

		_directoryPathField = [[CPTextField alloc] initWithFrame:CGRectMake(15, 92, 440, 25)];
		[_directoryPathField setBezeled:YES];
		[_directoryPathField setDelegate:self];
 
		[cv addSubview:_directoryPathField];

		_createBtn = [CPButton buttonWithTitle:@"Create Project"];
		[_createBtn setTarget:self];
		[_createBtn setAction:@selector(onConfirm:)];

		var frame = CGRectCreateCopy([_createBtn frame]);
		frame.size.height = 25.0; 
		frame.origin.x = 470 - CGRectGetWidth(frame) - 15;
		frame.origin.y = 140; 

		[_createBtn setFrame:frame];
		[_createBtn setEnabled:NO];

		[cv addSubview:_createBtn];

		_cancelBtn = [CPButton buttonWithTitle:@"Cancel"];
		[_cancelBtn setFrame:CGRectMake(470 - CGRectGetWidth([_createBtn bounds]) - 100, 140, 80, 25)];

		[_cancelBtn setTarget:self];
		[_cancelBtn setAction:@selector(orderOut:)];
		[cv addSubview:_cancelBtn];

	}


	return self; 
}


-(void) reset 
{	
	_newProjectID = Nil; 
	[_directoryPathField setStringValue:@"~/Documents/"];
	[_projNameField setStringValue:@""]; 
	[self makeFirstResponder:_projNameField];
}

-(void) onConfirm:(id)sender 
{
	var projName = [[_projNameField stringValue] stringByTrimmingWhitespace],
		projDir = [[_directoryPathField stringValue] stringByTrimmingWhitespace];

	[_createBtn setEnabled:NO];

	if([projName length] > 0 && [projDir length] > 0)
	{	

		projDir = PATH.join(PATH.resolve(projDir.replace("~", getUserHome())), 
                                projName);

		createDefaultProject(projName, projDir, function(success, reason){
			 	
			 	if(success)
			 	{
			 		
			 		_newProject = @{"name" : projName, @"directory" : projDir};
						 
					[[CPNotificationCenter defaultCenter] postNotificationName:@"NewProjectCreatedNotification" object:self];

					[self orderOut:nil]; 

			 	}
			 	else
			 	{
			 		alert(reason);
			 	}
		});
 
	}
	
}

-(void)controlTextDidChange:(CPNotification)aNotification 
{
	var projName = [[_projNameField stringValue] stringByTrimmingWhitespace],
		projDir = [[_directoryPathField stringValue] stringByTrimmingWhitespace];

	[_createBtn setEnabled:([projName length] > 0 && [projDir length] > 0)];
}

@end



function getUserHome()
{
 	return process.env[(process.platform == 'win32') ? 'USERPROFILE' : 'HOME'];
}


function createDefaultProject(projName, projectDirectory, callback)
 {

      var source = PATH.resolve("./DefaultCWTProject");

      FS.exists(projectDirectory, function(exists){

      		if(!exists)
            {
            	FS.mkdir(projectDirectory, function(err){

            			if(!err)
            			{
            				NCP(source, projectDirectory, function(){

            					var defaultInfo = '{\n\t"name" : "' + projName + '",\n\t"version" : "0.0.1",\n\t"CPApplicationDelegateClass" : "AppController"\n}\n';
            					FS.writeFile(PATH.join(projectDirectory, "Info.json"),
            						 defaultInfo, function(err){

            							if(callback)
                                  			callback(true); 
            						}); 
            					 
            				}); 

            			} 
            	});

            }
            else
            {
            	 if(callback)
                  	callback(false, "Destination directory already exists.");
            }
      }); 
 }




