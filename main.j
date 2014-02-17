@import <AppKit/CPApplication.j>

@import "AppController.j"

var FS = require('fs'),
	PATH = require('path'),
	BUILD = require('./build'),
	GUI = require('nw.gui'),
	NCP = require("ncp").ncp; 
 

function main()
{
	return CPApplicationMain(); 

}




