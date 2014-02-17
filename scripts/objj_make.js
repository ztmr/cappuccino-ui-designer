var objjCompiler = require("./objjc.js");
var fs = require("fs");
var path = require("path"); 

 
function union(set1, set2)
{
	var set3 = {};
    for (var attrname in set1) { set3[attrname] = set1[attrname]; }
    for (var attrname in set2) { set3[attrname] = set2[attrname]; }
    return set3;
}

exports.resolveImportFilePath = function(importPath, filePath, appDir)
{	
	if(importPath.indexOf("Frameworks") === 0)
	{	//check global frameworks
		var globalFrameworkPath = path.resolve(path.join(appDir,importPath));
		if(fs.existsSync(globalFrameworkPath))
			return globalFrameworkPath;

		//check local framework path
		return path.resolve(path.join(filePath,importPath));
		 
	}

	var relToSameDir = path.resolve(path.join(filePath,importPath)); //relative to same directory
	if(fs.existsSync(relToSameDir))
		return relToSameDir


	//return relative to appDir as default
	return path.resolve(path.join(appDir, importPath));
	 
}

exports.objj_make = function(mainFile, appDir, debug)
{
	var CLASS_DEFs = {}; 
	var MACRO_DEFs = {}; 
	var PROTOCOL_DEFs = {}; 
	var IMPORTED_FILES = {};
	var WARNINGS = {}; 
	var SEEN_PATHS = {}; 

	if(debug === undefined)
		debug = true; 
		
	if(appDir === undefined)
		appDir = process.cwd(); 

	mainFile = path.resolve(mainFile);
  	var mainSource = fs.readFileSync(mainFile, "UTF-8");
  	 
 	var value =	objjCompiler.compile(mainSource, mainFile);
  
  	WARNINGS = union(WARNINGS, value.warnings);

	function processImports(importsArray, currentDirectory)
	{
		var importCode = ""; 
		var count = importsArray.length;

		for(var i = 0; i < count; i++)
		{	
			var importPath = exports.resolveImportFilePath(importsArray[i], currentDirectory, appDir); 
		
			if(!SEEN_PATHS[importPath]) //prevent circular references in imports
			{	
				SEEN_PATHS[importPath] = 1; 

				if(IMPORTED_FILES[importPath] === undefined)
				{ 	
					//see if its already compiled
					if(!fs.existsSync(path.dirname(mainFile)+"/.build"))
						fs.mkdirSync(path.dirname(mainFile)+"/.build"); 

					var builtPath = path.dirname(mainFile) + "/.build/" + path.basename(importPath)  + ".o"; 
					var value = null; 
					var needsCompile = true; 
					var importSource = null; 

					try
					{
						var builtStats = fs.statSync(builtPath);
						var sourceStats = fs.statSync(importPath);

						if(builtStats.mtime.getTime() > sourceStats.mtime.getTime()) // object code is up to date
						{
							needsCompile = false;
							value = JSON.parse(fs.readFileSync(builtPath, "UTF-8"));
							CLASS_DEFs = union(CLASS_DEFs, value.classDefs);  
							MACRO_DEFs = union(MACRO_DEFs, value.macroDefines);
							PROTOCOL_DEFs = union(PROTOCOL_DEFs, value.protocalDefs);
							WARNINGS = union(WARNINGS, value.warnings);
						} 
					}
					catch(err)
					{
						needsCompile = true;
					}

					if(needsCompile)
					{
						importSource = fs.readFileSync(importPath, "UTF-8");
						value = objjCompiler.compile(importSource, importPath);

					 	var procImp = processImports(value.dependencies, path.dirname(importPath));

					 	console.log("Compiling %s...", path.basename(importPath));

						var pass2 = objjCompiler.compile(importSource, importPath, {"macros" : MACRO_DEFs, 
																				"classDefs" : CLASS_DEFs,
																				"protocolDefs" : PROTOCOL_DEFs,
																				includeMethodFunctionNames : debug 
																			});

						IMPORTED_FILES[importPath] = 1; 
						importCode+=(procImp + pass2.code());
	 
						fs.writeFileSync(builtPath, JSON.stringify({
							dependencies : pass2.dependencies,
							compiledCode : pass2.compiledCode,
							classDefs : pass2.classDefs,
							macroDefines : pass2.macroDefines,
							protocolDefs : pass2.protocolDefs
						}));
					}
					else
					{	
					  	IMPORTED_FILES[importPath] = 1; 
						importCode+=(processImports(value.dependencies, path.dirname(importPath)) + value.compiledCode); 
					}
				}
			}
		}

		return importCode; 

	}

	SEEN_PATHS[mainFile] = 1;

	var out = (processImports(value.dependencies, path.dirname(mainFile)) + 
	     	  objjCompiler.compile(mainSource, mainFile, {"macros" : MACRO_DEFs, 
												 	  "classDefs" : CLASS_DEFs,
									  			 	  "protocolDefs" : PROTOCOL_DEFs,
								  			      		includeMethodFunctionNames : debug}).code());
	
	
	for(var warning in WARNINGS)
		console.log("Warning: %s", WARNINGS[warning].message);


	return out; 
}


