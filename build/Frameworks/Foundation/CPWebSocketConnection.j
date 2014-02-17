@import "CPRunLoop.j"

var CPWebSocketConnectionConnecting =0,
	CPWebSocketConnectionOpen     	=1,
	CPWebSocketConnectionClosing 	=2,
	CPWebSocketConnectionClosed 	=3; 

var _RPCId = 0; 

@implementation CPWebSocketConnection : CPObject  
{
	
	 WebSocket 					_webSocket; 
	
	 CPString 					_url @accessors(getter=url);
	
	 id							_delegate @accessors(property=delegate);

	 JSObject   				_rcpCallbackMapping;  
	
}

+(BOOL) isSupported 
{
	if(window)
		return window.WebSocket !== undefined; //check browser

	return YES; //supported on nodejs 
}

  
-(void) close
{
	if(_webSocket)
		_webSocket.close(); 
}

-(void) rpc:(JSObject)jsObject
{
	if(jsObject.method && jsObject.params)
	{	
		_RPCId++;
		if(jsObject.callback) 
			_rcpCallbackMapping[_RPCId] = jsObject.callback;

		jsObject.id = _RPCId; 
		jsObject.jsonrpc = 2.0;

		[self send:JSON.stringify(jsObject)];

	}
	else
	{
		console.error("RPC requires a method and params attribute.");
	}
	

	
}

-(void) send:(CPString)aMessage
{
	if(_webSocket)
	{
		_webSocket.send(aMessage);

		if([_delegate respondsToSelector:@selector(webSocketConnection:didSendMessage:)])
			[_delegate performSelector:@selector(webSocketConnection:didSendMessage:) withObjects:self, aMessage];
	}
}
 

 -(int) status 
 {
 	if(_webSocket)
 		return _webSocket.readyState(); 

 	return CPWebSocketConnectionClosed; 
 }



-(void) connectTo:(CPString)url callback:(Function)aCallback  
{	
 	_webSocket = new CFWebSocketConnection(url);
 	
 	_rcpCallbackMapping = {};

	_webSocket.on("open", function(){

		if([_delegate respondsToSelector:@selector(webSocketConnectionDidOpen:)])
			[_delegate performSelector:@selector(webSocketConnectionDidOpen:) withObject:self];

		if(aCallback)
		 	aCallback();
		
		
		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

	});


	_webSocket.on("close", function(){

		if([_delegate respondsToSelector:@selector(webSocketConnectionDidClose:)])
			[_delegate performSelector:@selector(webSocketConnectionDidClose:) withObject:self];
		
		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];

	});


	_webSocket.on("message", function(data){
		
		try
		{	
			//rpc callback
			var rpcObj = JSON.parse(data)  
			if(rpcObj.jsonrpc && rpcObj.result && rpcObj.id)
			{
				if(_rcpCallbackMapping[rpcObj.id])
				{
					_rcpCallbackMapping[rpcObj.id](rpcObj.result);
				}
			}
		}
		catch(err){}

		if([_delegate respondsToSelector:@selector(webSocketConnection:didReceiveMessage:)])
			[_delegate performSelector:@selector(webSocketConnection:didReceiveMessage:) withObjects:self, data];
			
		[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];


	});


	_webSocket.on("error", function(err){

		 console.log("Error with websocket connection : %s", err.message);

		if([_delegate respondsToSelector:@selector(webSocketConnection:onError:)])
			[_delegate performSelector:@selector(webSocketConnection:onError:) withObjects:self, err];
	});
	 
	 
}

 




@end