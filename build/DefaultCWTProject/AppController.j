/*
 * AppController.j
 * NewApplication
 *
 * Created by You on January 29, 2013.
 * Copyright 2013, Your Company All rights reserved.
 */

@import <AppKit/CPTextField.j>

 
@implementation AppController : CPObject        
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{

    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],  
        contentView = [theWindow contentView];
     
    var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
    [label setFont:[CPFont boldSystemFontOfSize:22.0]];
    [label setStringValue:@"Hello World"];
    [label sizeToFit];

    [label setAutoresizingMask:CPViewMinXMargin|CPViewMinYMargin|CPViewMaxXMargin|CPViewMaxYMargin];
    [label setCenter:[contentView center]];

    [contentView addSubview:label];
    
    [theWindow orderFront:self];  

}


@end

 

