var fs = require('fs'),
	path = require('path'),
	objj_make = require("./objj_make.js");



var buildClientExecutable = function(appDir, publicDir, debug)
{	
	
	if(debug === null)
		debug = false;
    
    //read in Info.json
	var infoJSON = fs.readFileSync(path.join(appDir, "Info.json"), "UTF-8");
	var build = "var __CPInfo__ = " + infoJSON ;
	build+=objj_make.objj_make(path.join(appDir,"main.j"), appDir, debug)
	fs.writeFileSync(path.join(publicDir,"app.js"), build);
};


exports.buildClientExecutable = buildClientExecutable; 