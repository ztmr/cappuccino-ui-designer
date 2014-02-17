/* ***** BEGIN LICENSE BLOCK *****
 * Distributed under the BSD license:
 *
 * Copyright (c) 2010, Ajax.org B.V.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Ajax.org B.V. nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL AJAX.ORG B.V. BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ***** END LICENSE BLOCK ***** */
define('ace/mode/xquery', ['require', 'exports', 'module' , 'ace/worker/worker_client', 'ace/lib/oop', 'ace/mode/text', 'ace/mode/xquery/XQueryLexer', 'ace/range', 'ace/mode/behaviour/xquery', 'ace/mode/folding/cstyle'], function(require, exports, module) {


var WorkerClient = require("../worker/worker_client").WorkerClient;
var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var XQueryLexer = require("./xquery/XQueryLexer").XQueryLexer;
var Range = require("../range").Range;
var XQueryBehaviour = require("./behaviour/xquery").XQueryBehaviour;
var CStyleFoldMode = require("./folding/cstyle").FoldMode;


var Mode = function(parent) {
    this.$tokenizer   = new XQueryLexer();
    this.$behaviour   = new XQueryBehaviour();
    this.foldingRules = new CStyleFoldMode();
};

oop.inherits(Mode, TextMode);

(function() {

    this.getNextLineIndent = function(state, line, tab) {
      var indent = this.$getIndent(line);
      var match = line.match(/\s*(?:then|else|return|[{\(]|<\w+>)\s*$/);
      if (match)
        indent += tab;
        return indent;
    };
    
    this.checkOutdent = function(state, line, input) {
      if (! /^\s+$/.test(line))
            return false;

        return /^\s*[\}\)]/.test(input);
    };
    
    this.autoOutdent = function(state, doc, row) {
      var line = doc.getLine(row);
        var match = line.match(/^(\s*[\}\)])/);

        if (!match) return 0;

        var column = match[1].length;
        var openBracePos = doc.findMatchingBracket({row: row, column: column});

        if (!openBracePos || openBracePos.row == row) return 0;

        var indent = this.$getIndent(doc.getLine(openBracePos.row));
        doc.replace(new Range(row, 0, row, column-1), indent);
    };

    this.$getIndent = function(line) {
        var match = line.match(/^(\s+)/);
        if (match) {
            return match[1];
        }

        return "";
    };
    
    this.toggleCommentLines = function(state, doc, startRow, endRow) {
        var i, line;
        var outdent = true;
        var re = /^\s*\(:(.*):\)/;

        for (i=startRow; i<= endRow; i++) {
            if (!re.test(doc.getLine(i))) {
                outdent = false;
                break;
            }
        }

        var range = new Range(0, 0, 0, 0);
        for (i=startRow; i<= endRow; i++) {
            line = doc.getLine(i);
            range.start.row  = i;
            range.end.row    = i;
            range.end.column = line.length;

            doc.replace(range, outdent ? line.match(re)[1] : "(:" + line + ":)");
        }
    };
    
    this.createWorker = function(session) {
        this.$deltas = [];
        var worker = new WorkerClient(["ace"], "ace/mode/xquery_worker", "XQueryWorker");
        var that = this;

        session.getDocument().on('change', function(evt){
          that.$deltas.push(evt.data);
        });

        worker.attachToDocument(session.getDocument());
        
        worker.on("start", function(e) {
          that.$deltas = [];
        });

        worker.on("error", function(e) {
          session.setAnnotations([e.data]);
        });
        
        worker.on("ok", function(e) {
          session.clearAnnotations();
        });
        
        worker.on("highlight", function(tokens) {
          if(that.$deltas.length > 0) return;
          that.$tokenizer.tokens = tokens.data.tokens;
          that.$tokenizer.lines  = session.getDocument().getAllLines();
          session.bgTokenizer.lines = [];
          session.bgTokenizer.states = [];
          
          var rows = Object.keys(that.$tokenizer.tokens);
          for(var i=0; i < rows.length; i++) {
            var row = parseInt(rows[i]);
            session.bgTokenizer.fireUpdateEvent(row, row);
          }
        });
        
        return worker;
    };
    
}).call(Mode.prototype);

exports.Mode = Mode;
});
 
define('ace/mode/xquery/XQueryLexer', ['require', 'exports', 'module' , 'ace/mode/xquery/XQueryTokenizer'], function(require, exports, module) {
  
  var XQueryTokenizer = require("./XQueryTokenizer").XQueryTokenizer;
  
  var TokenHandler = function(code) {
      
    var input = code;
    
    this.tokens = [];
 
    this.reset = function(code) {
      input = input;
      this.tokens = [];
    };
    
    this.startNonterminal = function(name, begin) {};

    this.endNonterminal = function(name, end) {};

    this.terminal = function(name, begin, end) {
      this.tokens.push({
        name: name,
        value: input.substring(begin, end)
      });
    };

    this.whitespace = function(begin, end) {
      this.tokens.push({
        name: "WS",
        value: input.substring(begin, end)
      });
    };
  };

    var keys = "after|ancestor|ancestor-or-self|and|as|ascending|attribute|before|case|cast|castable|child|collation|comment|copy|count|declare|default|delete|descendant|descendant-or-self|descending|div|document|document-node|element|else|empty|empty-sequence|end|eq|every|except|first|following|following-sibling|for|function|ge|group|gt|idiv|if|import|insert|instance|intersect|into|is|item|last|le|let|lt|mod|modify|module|namespace|namespace-node|ne|node|only|or|order|ordered|parent|preceding|preceding-sibling|processing-instruction|rename|replace|return|satisfies|schema-attribute|schema-element|self|some|stable|start|switch|text|to|treat|try|typeswitch|union|unordered|validate|where|with|xquery|contains|paragraphs|sentences|times|words|by|collectionreturn|variable|version|option|when|encoding|toswitch|catch|tumbling|sliding|window|at|using|stemming|collection|schema|while|on|nodes|index|external|then|in|updating|value|of|containsbreak|loop|continue|exit|returning|append|json|position".split("|");
    var keywords = keys.map(
      function(val) { return { name: "'" + val + "'", token: "keyword" }; }
    );
    
    var ncnames = keys.map(
      function(val) { return { name: "'" + val + "'", token: "text", next: function(stack){ stack.pop(); } }; }
    );

    var cdata = "constant.language";
    var number = "constant";
    var xmlcomment = "comment";
    var pi = "xml-pe";
    var pragma = "constant.buildin";
    
    var Rules = {
      start: [
        { name: "'(#'", token: pragma, next: function(stack){ stack.push("Pragma"); } },
        { name: "'(:'", token: "comment", next: function(stack){ stack.push("Comment"); } },
        { name: "'(:~'", token: "comment.doc", next: function(stack){ stack.push("CommentDoc"); } },
        { name: "'<!--'", token: xmlcomment, next: function(stack){ stack.push("XMLComment"); } },
        { name: "'<?'", token: pi, next: function(stack) { stack.push("PI"); } },
        { name: "''''", token: "string", next: function(stack){ stack.push("AposString"); } },
        { name: "'\"'", token: "string", next: function(stack){ stack.push("QuotString"); } },
        { name: "Annotation", token: "support.function" },
        { name: "ModuleDecl", token: "keyword", next: function(stack){ stack.push("Prefix"); } },
        { name: "OptionDecl", token: "keyword", next: function(stack){ stack.push("_EQName"); } },
        { name: "AttrTest", token: "support.type" },
        { name: "Variable",  token: "variable" },
        { name: "'<![CDATA['", token: cdata, next: function(stack){ stack.push("CData"); } },
        { name: "IntegerLiteral", token: number },
        { name: "DecimalLiteral", token: number },
        { name: "DoubleLiteral", token: number },
        { name: "Operator", token: "keyword.operator" },
        { name: "EQName", token: function(val) { return keys.indexOf(val) !== -1 ? "keyword" : "support.function"; } },
        { name: "'('", token:"lparen" },
        { name: "')'", token:"rparen" },
        { name: "Tag", token: "meta.tag", next: function(stack){ stack.push("StartTag"); } },
        { name: "'}'", token: "text", next: function(stack){ if(stack.length > 1) { stack.pop(); } } },
        { name: "'{'", token: "text" } //, next: function(stack){ if(stack.length > 1) { stack.pop(); } } }
      ].concat(keywords),
      _EQName: [
        { name: "EQName", token: "text", next: function(stack) { stack.pop(); } }
      ].concat(ncnames),
      Prefix: [
        { name: "NCName", token: "text", next: function(stack) { stack.pop(); } }
      ].concat(ncnames),
      StartTag: [
        { name: "'>'", token: "meta.tag", next: function(stack){ stack.push("TagContent"); } },
        { name: "QName", token: "entity.other.attribute-name" },
        { name: "'='", token: "text" },
        { name: "''''", token: "string", next: function(stack){ stack.push("AposAttr"); } },
        { name: "'\"'", token: "string", next: function(stack){ stack.push("QuotAttr"); } },
        { name: "'/>'", token: "meta.tag.r", next: function(stack){ stack.pop(); } }
      ],
      TagContent: [
        { name: "ElementContentChar", token: "text" },
        { name: "'<![CDATA['", token: cdata, next: function(stack){ stack.push("CData"); } },
        { name: "'<!--'", token: xmlcomment, next: function(stack){ stack.push("XMLComment"); } },
        { name: "Tag", token: "meta.tag", next: function(stack){ stack.push("StartTag"); } },
        { name: "PredefinedEntityRef", token: "constant.language.escape" },
        { name: "CharRef", token: "constant.language.escape" },
        { name: "'{{'", token: "text" },
        { name: "'}}'", token: "text" },
        { name: "'{'", token: "text", next: function(stack){ stack.push("start"); } },
        { name: "EndTag", token: "meta.tag", next: function(stack){ stack.pop(); stack.pop(); } }
      ],
      AposAttr: [
        { name: "''''", token: "string", next: function(stack){ stack.pop(); } },
        { name: "EscapeApos", token: "constant.language.escape" },
        { name: "AposAttrContentChar", token: "string" },
        { name: "PredefinedEntityRef", token: "constant.language.escape" },
        { name: "CharRef", token: "constant.language.escape" },
        { name: "'{{'", token: "string" },
        { name: "'}}'", token: "string" },
        { name: "'{'", token: "text", next: function(stack){ stack.push("start"); } }
      ],
      QuotAttr: [
        { name: "'\"'", token: "string", next: function(stack){ stack.pop(); } },
        { name: "EscapeQuot", token: "constant.language.escape" },
        { name: "QuotAttrContentChar", token: "string" },
        { name: "PredefinedEntityRef", token: "constant.language.escape" },
        { name: "CharRef", token: "constant.language.escape" },
        { name: "'{{'", token: "string" },
        { name: "'}}'", token: "string" },
        { name: "'{'", token: "text", next: function(stack){ stack.push("start"); } }
      ],
      Pragma: [
        { name: "PragmaContents", token: pragma },
        { name: "'#)'", token: pragma, next: function(stack){ stack.pop(); } }
      ],
      Comment: [
        { name: "CommentContents", token: "comment" },
        { name: "'(:'", token: "comment", next: function(stack){ stack.push("Comment"); } },
        { name: "':)'", token: "comment", next: function(stack){ stack.pop(); } }
      ],
      CommentDoc: [
        { name: "DocCommentContents", token: "comment.doc" },
        { name: "DocTag", token: "comment.doc.tag" },
        { name: "'(:'", token: "comment.doc", next: function(stack){ stack.push("CommentDoc"); } },
        { name: "':)'", token: "comment.doc", next: function(stack){ stack.pop(); } }
      ],
      XMLComment: [
        { name: "DirCommentContents", token: xmlcomment },
        { name: "'-->'", token: xmlcomment, next: function(stack){ stack.pop(); } }
      ],
      CData: [
        { name: "CDataSectionContents", token: cdata },
        { name: "']]>'", token: cdata, next: function(stack){ stack.pop(); } }
      ],
      PI: [
        { name: "DirPIContents", token: pi },
        { name: "PITarget", token: pi },
        { name: "S", token: pi },
        { name: "'?>'", token: pi, next: function(stack){ stack.pop(); } }
      ],
      AposString: [
        { name: "''''", token: "string", next: function(stack){ stack.pop(); } },
        { name: "PredefinedEntityRef", token: "constant.language.escape" },
        { name: "CharRef", token: "constant.language.escape" },
        { name: "EscapeApos", token: "constant.language.escape" },
        { name: "AposChar", token: "string" }
      ],
      QuotString: [
        { name: "'\"'", token: "string", next: function(stack){ stack.pop(); } },
        { name: "PredefinedEntityRef", token: "constant.language.escape" },
        { name: "CharRef", token: "constant.language.escape" },
        { name: "EscapeQuot", token: "constant.language.escape" },
        { name: "QuotChar", token: "string" }
      ]
    };
    
exports.XQueryLexer = function() {
  
  this.tokens = [];
  
  this.getLineTokens = function(line, state, row) {
    state = (state === "start" || !state) ? '["start"]' : state;
    var stack = JSON.parse(state);
    var h = new TokenHandler(line);
    var tokenizer = new XQueryTokenizer(line, h);
    var tokens = [];
    
    while(true) {
      var currentState = stack[stack.length - 1];
      try {
        
        h.tokens = [];
        tokenizer["parse_" + currentState]();
        var info = null;
        
        if(h.tokens.length > 1 && h.tokens[0].name === "WS") {
          tokens.push({
            type: "text",
            value: h.tokens[0].value
          });
          h.tokens.splice(0, 1);
        }
        
        var token = h.tokens[0];
        var rules  = Rules[currentState];
        for(var k = 0; k < rules.length; k++) {
          var rule = Rules[currentState][k];
          if((typeof(rule.name) === "function" && rule.name(token)) || rule.name === token.name) {
            info = rule;
            break;
          }
        }
        
        if(token.name === "EOF") { break; }
        
        tokens.push({
          type: info === null ? "text" : (typeof(info.token) === "function" ? info.token(token.value) : info.token),
          value: token.value
        });
        
        if(info && info.next) {
          info.next(stack);    
        }  
      
      } catch(e) {
        if(e instanceof tokenizer.ParseException) {
          var index = 0;
          for(var i=0; i < tokens.length; i++) {
            index += tokens[i].value.length;
          }
          tokens.push({ type: "text", value: line.substring(index) });
          return {
            tokens: tokens,
            state: JSON.stringify(["start"])
          };
        } else {
          throw e;
        }  
      }
    }
   
    
    if(this.tokens[row] !== undefined) {
      var cachedLine = this.lines[row];
      var begin = sharedStart([line, cachedLine]);
      var diff = cachedLine.length - line.length;
      var idx = 0;
      var col = 0;
      for(var i = 0; i < tokens.length; i++) {
        var token = tokens[i];
        for(var j = 0; j < this.tokens[row].length; j++) {
          var semanticToken = this.tokens[row][j];
          if(
             ((col + token.value.length) <= begin.length && semanticToken.sc === col && semanticToken.ec === (col + token.value.length)) ||
             (semanticToken.sc === (col + diff) && semanticToken.ec === (col + token.value.length + diff))
            ) {
            idx = i;
            tokens[i].type = semanticToken.type;
          }
        }
        col += token.value.length;
      }
    }

    return {
      tokens: tokens,
      state: JSON.stringify(stack)
    };
  };
  
  function sharedStart(A) {
    var tem1, tem2, s, A = A.slice(0).sort();
    tem1 = A[0];
    s = tem1.length;
    tem2 = A.pop();
    while(s && tem2.indexOf(tem1) == -1) {
        tem1 = tem1.substring(0, --s);
    }
    return tem1;
  }
};
});

                                                            define('ace/mode/xquery/XQueryTokenizer', ['require', 'exports', 'module' ], function(require, exports, module) {
                                                            var XQueryTokenizer = exports.XQueryTokenizer = function XQueryTokenizer(string, parsingEventHandler)
                                                            {
                                                              init(string, parsingEventHandler);
  var self = this;

  this.ParseException = function(b, e, s, o, x)
  {
    var
      begin = b,
      end = e,
      state = s,
      offending = o,
      expected = x;

    this.getBegin = function() {return begin;};
    this.getEnd = function() {return end;};
    this.getState = function() {return state;};
    this.getExpected = function() {return expected;};
    this.getOffending = function() {return offending;};

    this.getMessage = function()
    {
      return offending < 0 ? "lexical analysis failed" : "syntax error";
    };
  };

  function init(string, parsingEventHandler)
  {
    eventHandler = parsingEventHandler;
    input = string;
    size = string.length;
    reset(0, 0, 0);
  }

  this.getInput = function()
  {
    return input;
  };

  function reset(l, b, e)
  {
                 b0 = b; e0 = b;
    l1 = l; b1 = b; e1 = e;
    end = e;
    eventHandler.reset(input);
  }

  this.getOffendingToken = function(e)
  {
    var o = e.getOffending();
    return o >= 0 ? XQueryTokenizer.TOKEN[o] : null;
  };

  this.getExpectedTokenSet = function(e)
  {
    var expected;
    if (e.getExpected() < 0)
    {
      expected = XQueryTokenizer.getTokenSet(- e.getState());
    }
    else
    {
      expected = [XQueryTokenizer.TOKEN[e.getExpected()]];
    }
    return expected;
  };

  this.getErrorMessage = function(e)
  {
    var tokenSet = this.getExpectedTokenSet(e);
    var found = this.getOffendingToken(e);
    var prefix = input.substring(0, e.getBegin());
    var lines = prefix.split("\n");
    var line = lines.length;
    var column = lines[line - 1].length + 1;
    var size = e.getEnd() - e.getBegin();
    return e.getMessage()
         + (found == null ? "" : ", found " + found)
         + "\nwhile expecting "
         + (tokenSet.length == 1 ? tokenSet[0] : ("[" + tokenSet.join(", ") + "]"))
         + "\n"
         + (size == 0 || found != null ? "" : "after successfully scanning " + size + " characters beginning ")
         + "at line " + line + ", column " + column + ":\n..."
         + input.substring(e.getBegin(), Math.min(input.length, e.getBegin() + 64))
         + "...";
  };

  this.parse_start = function()
  {
    eventHandler.startNonterminal("start", e0);
    lookahead1W(14);                // ModuleDecl | Annotation | OptionDecl | Operator | Variable | Tag | AttrTest |
    switch (l1)
    {
    case 54:                        // '<![CDATA['
      shift(54);                    // '<![CDATA['
      break;
    case 53:                        // '<!--'
      shift(53);                    // '<!--'
      break;
    case 55:                        // '<?'
      shift(55);                    // '<?'
      break;
    case 39:                        // '(#'
      shift(39);                    // '(#'
      break;
    case 41:                        // '(:~'
      shift(41);                    // '(:~'
      break;
    case 40:                        // '(:'
      shift(40);                    // '(:'
      break;
    case 35:                        // '"'
      shift(35);                    // '"'
      break;
    case 37:                        // "'"
      shift(37);                    // "'"
      break;
    case 272:                       // '}'
      shift(272);                   // '}'
      break;
    case 269:                       // '{'
      shift(269);                   // '{'
      break;
    case 38:                        // '('
      shift(38);                    // '('
      break;
    case 42:                        // ')'
      shift(42);                    // ')'
      break;
    case 48:                        // '/'
      shift(48);                    // '/'
      break;
    case 60:                        // '['
      shift(60);                    // '['
      break;
    case 61:                        // ']'
      shift(61);                    // ']'
      break;
    case 45:                        // ','
      shift(45);                    // ','
      break;
    case 47:                        // '.'
      shift(47);                    // '.'
      break;
    case 52:                        // ';'
      shift(52);                    // ';'
      break;
    case 50:                        // ':'
      shift(50);                    // ':'
      break;
    case 34:                        // '!'
      shift(34);                    // '!'
      break;
    case 271:                       // '|'
      shift(271);                   // '|'
      break;
    case 2:                         // Annotation
      shift(2);                     // Annotation
      break;
    case 1:                         // ModuleDecl
      shift(1);                     // ModuleDecl
      break;
    case 3:                         // OptionDecl
      shift(3);                     // OptionDecl
      break;
    case 12:                        // AttrTest
      shift(12);                    // AttrTest
      break;
    case 13:                        // Wildcard
      shift(13);                    // Wildcard
      break;
    case 15:                        // IntegerLiteral
      shift(15);                    // IntegerLiteral
      break;
    case 16:                        // DecimalLiteral
      shift(16);                    // DecimalLiteral
      break;
    case 17:                        // DoubleLiteral
      shift(17);                    // DoubleLiteral
      break;
    case 5:                         // Variable
      shift(5);                     // Variable
      break;
    case 6:                         // Tag
      shift(6);                     // Tag
      break;
    case 4:                         // Operator
      shift(4);                     // Operator
      break;
    case 33:                        // EOF
      shift(33);                    // EOF
      break;
    default:
      parse_EQName();
    }
    eventHandler.endNonterminal("start", e0);
  };

  this.parse_StartTag = function()
  {
    eventHandler.startNonterminal("StartTag", e0);
    lookahead1W(8);                 // QName | S^WS | EOF | '"' | "'" | '/>' | '=' | '>'
    switch (l1)
    {
    case 57:                        // '>'
      shift(57);                    // '>'
      break;
    case 49:                        // '/>'
      shift(49);                    // '/>'
      break;
    case 27:                        // QName
      shift(27);                    // QName
      break;
    case 56:                        // '='
      shift(56);                    // '='
      break;
    case 35:                        // '"'
      shift(35);                    // '"'
      break;
    case 37:                        // "'"
      shift(37);                    // "'"
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("StartTag", e0);
  };

  this.parse_TagContent = function()
  {
    eventHandler.startNonterminal("TagContent", e0);
    lookahead1(11);                 // Tag | EndTag | PredefinedEntityRef | ElementContentChar | CharRef | EOF |
    switch (l1)
    {
    case 23:                        // ElementContentChar
      shift(23);                    // ElementContentChar
      break;
    case 6:                         // Tag
      shift(6);                     // Tag
      break;
    case 7:                         // EndTag
      shift(7);                     // EndTag
      break;
    case 54:                        // '<![CDATA['
      shift(54);                    // '<![CDATA['
      break;
    case 53:                        // '<!--'
      shift(53);                    // '<!--'
      break;
    case 18:                        // PredefinedEntityRef
      shift(18);                    // PredefinedEntityRef
      break;
    case 29:                        // CharRef
      shift(29);                    // CharRef
      break;
    case 270:                       // '{{'
      shift(270);                   // '{{'
      break;
    case 273:                       // '}}'
      shift(273);                   // '}}'
      break;
    case 269:                       // '{'
      shift(269);                   // '{'
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("TagContent", e0);
  };

  this.parse_AposAttr = function()
  {
    eventHandler.startNonterminal("AposAttr", e0);
    lookahead1(10);                 // PredefinedEntityRef | EscapeApos | AposAttrContentChar | CharRef | EOF | "'" |
    switch (l1)
    {
    case 20:                        // EscapeApos
      shift(20);                    // EscapeApos
      break;
    case 25:                        // AposAttrContentChar
      shift(25);                    // AposAttrContentChar
      break;
    case 18:                        // PredefinedEntityRef
      shift(18);                    // PredefinedEntityRef
      break;
    case 29:                        // CharRef
      shift(29);                    // CharRef
      break;
    case 270:                       // '{{'
      shift(270);                   // '{{'
      break;
    case 273:                       // '}}'
      shift(273);                   // '}}'
      break;
    case 269:                       // '{'
      shift(269);                   // '{'
      break;
    case 37:                        // "'"
      shift(37);                    // "'"
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("AposAttr", e0);
  };

  this.parse_QuotAttr = function()
  {
    eventHandler.startNonterminal("QuotAttr", e0);
    lookahead1(9);                  // PredefinedEntityRef | EscapeQuot | QuotAttrContentChar | CharRef | EOF | '"' |
    switch (l1)
    {
    case 19:                        // EscapeQuot
      shift(19);                    // EscapeQuot
      break;
    case 24:                        // QuotAttrContentChar
      shift(24);                    // QuotAttrContentChar
      break;
    case 18:                        // PredefinedEntityRef
      shift(18);                    // PredefinedEntityRef
      break;
    case 29:                        // CharRef
      shift(29);                    // CharRef
      break;
    case 270:                       // '{{'
      shift(270);                   // '{{'
      break;
    case 273:                       // '}}'
      shift(273);                   // '}}'
      break;
    case 269:                       // '{'
      shift(269);                   // '{'
      break;
    case 35:                        // '"'
      shift(35);                    // '"'
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("QuotAttr", e0);
  };

  this.parse_CData = function()
  {
    eventHandler.startNonterminal("CData", e0);
    lookahead1(3);                  // CDataSectionContents | EOF | ']]>'
    switch (l1)
    {
    case 11:                        // CDataSectionContents
      shift(11);                    // CDataSectionContents
      break;
    case 62:                        // ']]>'
      shift(62);                    // ']]>'
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("CData", e0);
  };

  this.parse_XMLComment = function()
  {
    eventHandler.startNonterminal("XMLComment", e0);
    lookahead1(1);                  // DirCommentContents | EOF | '-->'
    switch (l1)
    {
    case 9:                         // DirCommentContents
      shift(9);                     // DirCommentContents
      break;
    case 46:                        // '-->'
      shift(46);                    // '-->'
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("XMLComment", e0);
  };

  this.parse_PI = function()
  {
    eventHandler.startNonterminal("PI", e0);
    lookahead1(2);                  // DirPIContents | EOF | '?>'
    switch (l1)
    {
    case 10:                        // DirPIContents
      shift(10);                    // DirPIContents
      break;
    case 58:                        // '?>'
      shift(58);                    // '?>'
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("PI", e0);
  };

  this.parse_Pragma = function()
  {
    eventHandler.startNonterminal("Pragma", e0);
    lookahead1(0);                  // PragmaContents | EOF | '#)'
    switch (l1)
    {
    case 8:                         // PragmaContents
      shift(8);                     // PragmaContents
      break;
    case 36:                        // '#)'
      shift(36);                    // '#)'
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("Pragma", e0);
  };

  this.parse_Comment = function()
  {
    eventHandler.startNonterminal("Comment", e0);
    lookahead1(4);                  // CommentContents | EOF | '(:' | ':)'
    switch (l1)
    {
    case 51:                        // ':)'
      shift(51);                    // ':)'
      break;
    case 40:                        // '(:'
      shift(40);                    // '(:'
      break;
    case 30:                        // CommentContents
      shift(30);                    // CommentContents
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("Comment", e0);
  };

  this.parse_CommentDoc = function()
  {
    eventHandler.startNonterminal("CommentDoc", e0);
    lookahead1(5);                  // DocTag | DocCommentContents | EOF | '(:' | ':)'
    switch (l1)
    {
    case 31:                        // DocTag
      shift(31);                    // DocTag
      break;
    case 32:                        // DocCommentContents
      shift(32);                    // DocCommentContents
      break;
    case 51:                        // ':)'
      shift(51);                    // ':)'
      break;
    case 40:                        // '(:'
      shift(40);                    // '(:'
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("CommentDoc", e0);
  };

  this.parse_QuotString = function()
  {
    eventHandler.startNonterminal("QuotString", e0);
    lookahead1(6);                  // PredefinedEntityRef | EscapeQuot | QuotChar | CharRef | EOF | '"'
    switch (l1)
    {
    case 18:                        // PredefinedEntityRef
      shift(18);                    // PredefinedEntityRef
      break;
    case 29:                        // CharRef
      shift(29);                    // CharRef
      break;
    case 19:                        // EscapeQuot
      shift(19);                    // EscapeQuot
      break;
    case 21:                        // QuotChar
      shift(21);                    // QuotChar
      break;
    case 35:                        // '"'
      shift(35);                    // '"'
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("QuotString", e0);
  };

  this.parse_AposString = function()
  {
    eventHandler.startNonterminal("AposString", e0);
    lookahead1(7);                  // PredefinedEntityRef | EscapeApos | AposChar | CharRef | EOF | "'"
    switch (l1)
    {
    case 18:                        // PredefinedEntityRef
      shift(18);                    // PredefinedEntityRef
      break;
    case 29:                        // CharRef
      shift(29);                    // CharRef
      break;
    case 20:                        // EscapeApos
      shift(20);                    // EscapeApos
      break;
    case 22:                        // AposChar
      shift(22);                    // AposChar
      break;
    case 37:                        // "'"
      shift(37);                    // "'"
      break;
    default:
      shift(33);                    // EOF
    }
    eventHandler.endNonterminal("AposString", e0);
  };

  this.parse_Prefix = function()
  {
    eventHandler.startNonterminal("Prefix", e0);
    lookahead1W(13);                // NCName^Token | S^WS | 'after' | 'allowing' | 'ancestor' | 'ancestor-or-self' |
    whitespace();
    parse_NCName();
    eventHandler.endNonterminal("Prefix", e0);
  };

  this.parse__EQName = function()
  {
    eventHandler.startNonterminal("_EQName", e0);
    lookahead1W(12);                // EQName^Token | S^WS | 'after' | 'allowing' | 'ancestor' | 'ancestor-or-self' |
    whitespace();
    parse_EQName();
    eventHandler.endNonterminal("_EQName", e0);
  };

  function parse_EQName()
  {
    eventHandler.startNonterminal("EQName", e0);
    switch (l1)
    {
    case 75:                        // 'attribute'
      shift(75);                    // 'attribute'
      break;
    case 89:                        // 'comment'
      shift(89);                    // 'comment'
      break;
    case 113:                       // 'document-node'
      shift(113);                   // 'document-node'
      break;
    case 114:                       // 'element'
      shift(114);                   // 'element'
      break;
    case 117:                       // 'empty-sequence'
      shift(117);                   // 'empty-sequence'
      break;
    case 138:                       // 'function'
      shift(138);                   // 'function'
      break;
    case 145:                       // 'if'
      shift(145);                   // 'if'
      break;
    case 158:                       // 'item'
      shift(158);                   // 'item'
      break;
    case 178:                       // 'namespace-node'
      shift(178);                   // 'namespace-node'
      break;
    case 184:                       // 'node'
      shift(184);                   // 'node'
      break;
    case 209:                       // 'processing-instruction'
      shift(209);                   // 'processing-instruction'
      break;
    case 219:                       // 'schema-attribute'
      shift(219);                   // 'schema-attribute'
      break;
    case 220:                       // 'schema-element'
      shift(220);                   // 'schema-element'
      break;
    case 236:                       // 'switch'
      shift(236);                   // 'switch'
      break;
    case 237:                       // 'text'
      shift(237);                   // 'text'
      break;
    case 246:                       // 'typeswitch'
      shift(246);                   // 'typeswitch'
      break;
    default:
      parse_FunctionName();
    }
    eventHandler.endNonterminal("EQName", e0);
  }

  function parse_FunctionName()
  {
    eventHandler.startNonterminal("FunctionName", e0);
    switch (l1)
    {
    case 14:                        // EQName^Token
      shift(14);                    // EQName^Token
      break;
    case 63:                        // 'after'
      shift(63);                    // 'after'
      break;
    case 66:                        // 'ancestor'
      shift(66);                    // 'ancestor'
      break;
    case 67:                        // 'ancestor-or-self'
      shift(67);                    // 'ancestor-or-self'
      break;
    case 68:                        // 'and'
      shift(68);                    // 'and'
      break;
    case 72:                        // 'as'
      shift(72);                    // 'as'
      break;
    case 73:                        // 'ascending'
      shift(73);                    // 'ascending'
      break;
    case 77:                        // 'before'
      shift(77);                    // 'before'
      break;
    case 81:                        // 'case'
      shift(81);                    // 'case'
      break;
    case 82:                        // 'cast'
      shift(82);                    // 'cast'
      break;
    case 83:                        // 'castable'
      shift(83);                    // 'castable'
      break;
    case 86:                        // 'child'
      shift(86);                    // 'child'
      break;
    case 87:                        // 'collation'
      shift(87);                    // 'collation'
      break;
    case 96:                        // 'copy'
      shift(96);                    // 'copy'
      break;
    case 98:                        // 'count'
      shift(98);                    // 'count'
      break;
    case 101:                       // 'declare'
      shift(101);                   // 'declare'
      break;
    case 102:                       // 'default'
      shift(102);                   // 'default'
      break;
    case 103:                       // 'delete'
      shift(103);                   // 'delete'
      break;
    case 104:                       // 'descendant'
      shift(104);                   // 'descendant'
      break;
    case 105:                       // 'descendant-or-self'
      shift(105);                   // 'descendant-or-self'
      break;
    case 106:                       // 'descending'
      shift(106);                   // 'descending'
      break;
    case 111:                       // 'div'
      shift(111);                   // 'div'
      break;
    case 112:                       // 'document'
      shift(112);                   // 'document'
      break;
    case 115:                       // 'else'
      shift(115);                   // 'else'
      break;
    case 116:                       // 'empty'
      shift(116);                   // 'empty'
      break;
    case 119:                       // 'end'
      shift(119);                   // 'end'
      break;
    case 121:                       // 'eq'
      shift(121);                   // 'eq'
      break;
    case 122:                       // 'every'
      shift(122);                   // 'every'
      break;
    case 124:                       // 'except'
      shift(124);                   // 'except'
      break;
    case 127:                       // 'first'
      shift(127);                   // 'first'
      break;
    case 128:                       // 'following'
      shift(128);                   // 'following'
      break;
    case 129:                       // 'following-sibling'
      shift(129);                   // 'following-sibling'
      break;
    case 130:                       // 'for'
      shift(130);                   // 'for'
      break;
    case 139:                       // 'ge'
      shift(139);                   // 'ge'
      break;
    case 141:                       // 'group'
      shift(141);                   // 'group'
      break;
    case 143:                       // 'gt'
      shift(143);                   // 'gt'
      break;
    case 144:                       // 'idiv'
      shift(144);                   // 'idiv'
      break;
    case 146:                       // 'import'
      shift(146);                   // 'import'
      break;
    case 152:                       // 'insert'
      shift(152);                   // 'insert'
      break;
    case 153:                       // 'instance'
      shift(153);                   // 'instance'
      break;
    case 155:                       // 'intersect'
      shift(155);                   // 'intersect'
      break;
    case 156:                       // 'into'
      shift(156);                   // 'into'
      break;
    case 157:                       // 'is'
      shift(157);                   // 'is'
      break;
    case 163:                       // 'last'
      shift(163);                   // 'last'
      break;
    case 165:                       // 'le'
      shift(165);                   // 'le'
      break;
    case 167:                       // 'let'
      shift(167);                   // 'let'
      break;
    case 171:                       // 'lt'
      shift(171);                   // 'lt'
      break;
    case 173:                       // 'mod'
      shift(173);                   // 'mod'
      break;
    case 174:                       // 'modify'
      shift(174);                   // 'modify'
      break;
    case 175:                       // 'module'
      shift(175);                   // 'module'
      break;
    case 177:                       // 'namespace'
      shift(177);                   // 'namespace'
      break;
    case 179:                       // 'ne'
      shift(179);                   // 'ne'
      break;
    case 191:                       // 'only'
      shift(191);                   // 'only'
      break;
    case 193:                       // 'or'
      shift(193);                   // 'or'
      break;
    case 194:                       // 'order'
      shift(194);                   // 'order'
      break;
    case 195:                       // 'ordered'
      shift(195);                   // 'ordered'
      break;
    case 199:                       // 'parent'
      shift(199);                   // 'parent'
      break;
    case 205:                       // 'preceding'
      shift(205);                   // 'preceding'
      break;
    case 206:                       // 'preceding-sibling'
      shift(206);                   // 'preceding-sibling'
      break;
    case 211:                       // 'rename'
      shift(211);                   // 'rename'
      break;
    case 212:                       // 'replace'
      shift(212);                   // 'replace'
      break;
    case 213:                       // 'return'
      shift(213);                   // 'return'
      break;
    case 217:                       // 'satisfies'
      shift(217);                   // 'satisfies'
      break;
    case 222:                       // 'self'
      shift(222);                   // 'self'
      break;
    case 228:                       // 'some'
      shift(228);                   // 'some'
      break;
    case 229:                       // 'stable'
      shift(229);                   // 'stable'
      break;
    case 230:                       // 'start'
      shift(230);                   // 'start'
      break;
    case 241:                       // 'to'
      shift(241);                   // 'to'
      break;
    case 242:                       // 'treat'
      shift(242);                   // 'treat'
      break;
    case 243:                       // 'try'
      shift(243);                   // 'try'
      break;
    case 247:                       // 'union'
      shift(247);                   // 'union'
      break;
    case 249:                       // 'unordered'
      shift(249);                   // 'unordered'
      break;
    case 253:                       // 'validate'
      shift(253);                   // 'validate'
      break;
    case 259:                       // 'where'
      shift(259);                   // 'where'
      break;
    case 263:                       // 'with'
      shift(263);                   // 'with'
      break;
    case 267:                       // 'xquery'
      shift(267);                   // 'xquery'
      break;
    case 65:                        // 'allowing'
      shift(65);                    // 'allowing'
      break;
    case 74:                        // 'at'
      shift(74);                    // 'at'
      break;
    case 76:                        // 'base-uri'
      shift(76);                    // 'base-uri'
      break;
    case 78:                        // 'boundary-space'
      shift(78);                    // 'boundary-space'
      break;
    case 79:                        // 'break'
      shift(79);                    // 'break'
      break;
    case 84:                        // 'catch'
      shift(84);                    // 'catch'
      break;
    case 91:                        // 'construction'
      shift(91);                    // 'construction'
      break;
    case 94:                        // 'context'
      shift(94);                    // 'context'
      break;
    case 95:                        // 'continue'
      shift(95);                    // 'continue'
      break;
    case 97:                        // 'copy-namespaces'
      shift(97);                    // 'copy-namespaces'
      break;
    case 99:                        // 'decimal-format'
      shift(99);                    // 'decimal-format'
      break;
    case 118:                       // 'encoding'
      shift(118);                   // 'encoding'
      break;
    case 125:                       // 'exit'
      shift(125);                   // 'exit'
      break;
    case 126:                       // 'external'
      shift(126);                   // 'external'
      break;
    case 134:                       // 'ft-option'
      shift(134);                   // 'ft-option'
      break;
    case 147:                       // 'in'
      shift(147);                   // 'in'
      break;
    case 148:                       // 'index'
      shift(148);                   // 'index'
      break;
    case 154:                       // 'integrity'
      shift(154);                   // 'integrity'
      break;
    case 164:                       // 'lax'
      shift(164);                   // 'lax'
      break;
    case 185:                       // 'nodes'
      shift(185);                   // 'nodes'
      break;
    case 192:                       // 'option'
      shift(192);                   // 'option'
      break;
    case 196:                       // 'ordering'
      shift(196);                   // 'ordering'
      break;
    case 215:                       // 'revalidation'
      shift(215);                   // 'revalidation'
      break;
    case 218:                       // 'schema'
      shift(218);                   // 'schema'
      break;
    case 221:                       // 'score'
      shift(221);                   // 'score'
      break;
    case 227:                       // 'sliding'
      shift(227);                   // 'sliding'
      break;
    case 233:                       // 'strict'
      shift(233);                   // 'strict'
      break;
    case 244:                       // 'tumbling'
      shift(244);                   // 'tumbling'
      break;
    case 245:                       // 'type'
      shift(245);                   // 'type'
      break;
    case 250:                       // 'updating'
      shift(250);                   // 'updating'
      break;
    case 254:                       // 'value'
      shift(254);                   // 'value'
      break;
    case 255:                       // 'variable'
      shift(255);                   // 'variable'
      break;
    case 256:                       // 'version'
      shift(256);                   // 'version'
      break;
    case 260:                       // 'while'
      shift(260);                   // 'while'
      break;
    case 90:                        // 'constraint'
      shift(90);                    // 'constraint'
      break;
    case 169:                       // 'loop'
      shift(169);                   // 'loop'
      break;
    default:
      shift(214);                   // 'returning'
    }
    eventHandler.endNonterminal("FunctionName", e0);
  }

  function parse_NCName()
  {
    eventHandler.startNonterminal("NCName", e0);
    switch (l1)
    {
    case 26:                        // NCName^Token
      shift(26);                    // NCName^Token
      break;
    case 63:                        // 'after'
      shift(63);                    // 'after'
      break;
    case 68:                        // 'and'
      shift(68);                    // 'and'
      break;
    case 72:                        // 'as'
      shift(72);                    // 'as'
      break;
    case 73:                        // 'ascending'
      shift(73);                    // 'ascending'
      break;
    case 77:                        // 'before'
      shift(77);                    // 'before'
      break;
    case 81:                        // 'case'
      shift(81);                    // 'case'
      break;
    case 82:                        // 'cast'
      shift(82);                    // 'cast'
      break;
    case 83:                        // 'castable'
      shift(83);                    // 'castable'
      break;
    case 87:                        // 'collation'
      shift(87);                    // 'collation'
      break;
    case 98:                        // 'count'
      shift(98);                    // 'count'
      break;
    case 102:                       // 'default'
      shift(102);                   // 'default'
      break;
    case 106:                       // 'descending'
      shift(106);                   // 'descending'
      break;
    case 111:                       // 'div'
      shift(111);                   // 'div'
      break;
    case 115:                       // 'else'
      shift(115);                   // 'else'
      break;
    case 116:                       // 'empty'
      shift(116);                   // 'empty'
      break;
    case 119:                       // 'end'
      shift(119);                   // 'end'
      break;
    case 121:                       // 'eq'
      shift(121);                   // 'eq'
      break;
    case 124:                       // 'except'
      shift(124);                   // 'except'
      break;
    case 130:                       // 'for'
      shift(130);                   // 'for'
      break;
    case 139:                       // 'ge'
      shift(139);                   // 'ge'
      break;
    case 141:                       // 'group'
      shift(141);                   // 'group'
      break;
    case 143:                       // 'gt'
      shift(143);                   // 'gt'
      break;
    case 144:                       // 'idiv'
      shift(144);                   // 'idiv'
      break;
    case 153:                       // 'instance'
      shift(153);                   // 'instance'
      break;
    case 155:                       // 'intersect'
      shift(155);                   // 'intersect'
      break;
    case 156:                       // 'into'
      shift(156);                   // 'into'
      break;
    case 157:                       // 'is'
      shift(157);                   // 'is'
      break;
    case 165:                       // 'le'
      shift(165);                   // 'le'
      break;
    case 167:                       // 'let'
      shift(167);                   // 'let'
      break;
    case 171:                       // 'lt'
      shift(171);                   // 'lt'
      break;
    case 173:                       // 'mod'
      shift(173);                   // 'mod'
      break;
    case 174:                       // 'modify'
      shift(174);                   // 'modify'
      break;
    case 179:                       // 'ne'
      shift(179);                   // 'ne'
      break;
    case 191:                       // 'only'
      shift(191);                   // 'only'
      break;
    case 193:                       // 'or'
      shift(193);                   // 'or'
      break;
    case 194:                       // 'order'
      shift(194);                   // 'order'
      break;
    case 213:                       // 'return'
      shift(213);                   // 'return'
      break;
    case 217:                       // 'satisfies'
      shift(217);                   // 'satisfies'
      break;
    case 229:                       // 'stable'
      shift(229);                   // 'stable'
      break;
    case 230:                       // 'start'
      shift(230);                   // 'start'
      break;
    case 241:                       // 'to'
      shift(241);                   // 'to'
      break;
    case 242:                       // 'treat'
      shift(242);                   // 'treat'
      break;
    case 247:                       // 'union'
      shift(247);                   // 'union'
      break;
    case 259:                       // 'where'
      shift(259);                   // 'where'
      break;
    case 263:                       // 'with'
      shift(263);                   // 'with'
      break;
    case 66:                        // 'ancestor'
      shift(66);                    // 'ancestor'
      break;
    case 67:                        // 'ancestor-or-self'
      shift(67);                    // 'ancestor-or-self'
      break;
    case 75:                        // 'attribute'
      shift(75);                    // 'attribute'
      break;
    case 86:                        // 'child'
      shift(86);                    // 'child'
      break;
    case 89:                        // 'comment'
      shift(89);                    // 'comment'
      break;
    case 96:                        // 'copy'
      shift(96);                    // 'copy'
      break;
    case 101:                       // 'declare'
      shift(101);                   // 'declare'
      break;
    case 103:                       // 'delete'
      shift(103);                   // 'delete'
      break;
    case 104:                       // 'descendant'
      shift(104);                   // 'descendant'
      break;
    case 105:                       // 'descendant-or-self'
      shift(105);                   // 'descendant-or-self'
      break;
    case 112:                       // 'document'
      shift(112);                   // 'document'
      break;
    case 113:                       // 'document-node'
      shift(113);                   // 'document-node'
      break;
    case 114:                       // 'element'
      shift(114);                   // 'element'
      break;
    case 117:                       // 'empty-sequence'
      shift(117);                   // 'empty-sequence'
      break;
    case 122:                       // 'every'
      shift(122);                   // 'every'
      break;
    case 127:                       // 'first'
      shift(127);                   // 'first'
      break;
    case 128:                       // 'following'
      shift(128);                   // 'following'
      break;
    case 129:                       // 'following-sibling'
      shift(129);                   // 'following-sibling'
      break;
    case 138:                       // 'function'
      shift(138);                   // 'function'
      break;
    case 145:                       // 'if'
      shift(145);                   // 'if'
      break;
    case 146:                       // 'import'
      shift(146);                   // 'import'
      break;
    case 152:                       // 'insert'
      shift(152);                   // 'insert'
      break;
    case 158:                       // 'item'
      shift(158);                   // 'item'
      break;
    case 163:                       // 'last'
      shift(163);                   // 'last'
      break;
    case 175:                       // 'module'
      shift(175);                   // 'module'
      break;
    case 177:                       // 'namespace'
      shift(177);                   // 'namespace'
      break;
    case 178:                       // 'namespace-node'
      shift(178);                   // 'namespace-node'
      break;
    case 184:                       // 'node'
      shift(184);                   // 'node'
      break;
    case 195:                       // 'ordered'
      shift(195);                   // 'ordered'
      break;
    case 199:                       // 'parent'
      shift(199);                   // 'parent'
      break;
    case 205:                       // 'preceding'
      shift(205);                   // 'preceding'
      break;
    case 206:                       // 'preceding-sibling'
      shift(206);                   // 'preceding-sibling'
      break;
    case 209:                       // 'processing-instruction'
      shift(209);                   // 'processing-instruction'
      break;
    case 211:                       // 'rename'
      shift(211);                   // 'rename'
      break;
    case 212:                       // 'replace'
      shift(212);                   // 'replace'
      break;
    case 219:                       // 'schema-attribute'
      shift(219);                   // 'schema-attribute'
      break;
    case 220:                       // 'schema-element'
      shift(220);                   // 'schema-element'
      break;
    case 222:                       // 'self'
      shift(222);                   // 'self'
      break;
    case 228:                       // 'some'
      shift(228);                   // 'some'
      break;
    case 236:                       // 'switch'
      shift(236);                   // 'switch'
      break;
    case 237:                       // 'text'
      shift(237);                   // 'text'
      break;
    case 243:                       // 'try'
      shift(243);                   // 'try'
      break;
    case 246:                       // 'typeswitch'
      shift(246);                   // 'typeswitch'
      break;
    case 249:                       // 'unordered'
      shift(249);                   // 'unordered'
      break;
    case 253:                       // 'validate'
      shift(253);                   // 'validate'
      break;
    case 255:                       // 'variable'
      shift(255);                   // 'variable'
      break;
    case 267:                       // 'xquery'
      shift(267);                   // 'xquery'
      break;
    case 65:                        // 'allowing'
      shift(65);                    // 'allowing'
      break;
    case 74:                        // 'at'
      shift(74);                    // 'at'
      break;
    case 76:                        // 'base-uri'
      shift(76);                    // 'base-uri'
      break;
    case 78:                        // 'boundary-space'
      shift(78);                    // 'boundary-space'
      break;
    case 79:                        // 'break'
      shift(79);                    // 'break'
      break;
    case 84:                        // 'catch'
      shift(84);                    // 'catch'
      break;
    case 91:                        // 'construction'
      shift(91);                    // 'construction'
      break;
    case 94:                        // 'context'
      shift(94);                    // 'context'
      break;
    case 95:                        // 'continue'
      shift(95);                    // 'continue'
      break;
    case 97:                        // 'copy-namespaces'
      shift(97);                    // 'copy-namespaces'
      break;
    case 99:                        // 'decimal-format'
      shift(99);                    // 'decimal-format'
      break;
    case 118:                       // 'encoding'
      shift(118);                   // 'encoding'
      break;
    case 125:                       // 'exit'
      shift(125);                   // 'exit'
      break;
    case 126:                       // 'external'
      shift(126);                   // 'external'
      break;
    case 134:                       // 'ft-option'
      shift(134);                   // 'ft-option'
      break;
    case 147:                       // 'in'
      shift(147);                   // 'in'
      break;
    case 148:                       // 'index'
      shift(148);                   // 'index'
      break;
    case 154:                       // 'integrity'
      shift(154);                   // 'integrity'
      break;
    case 164:                       // 'lax'
      shift(164);                   // 'lax'
      break;
    case 185:                       // 'nodes'
      shift(185);                   // 'nodes'
      break;
    case 192:                       // 'option'
      shift(192);                   // 'option'
      break;
    case 196:                       // 'ordering'
      shift(196);                   // 'ordering'
      break;
    case 215:                       // 'revalidation'
      shift(215);                   // 'revalidation'
      break;
    case 218:                       // 'schema'
      shift(218);                   // 'schema'
      break;
    case 221:                       // 'score'
      shift(221);                   // 'score'
      break;
    case 227:                       // 'sliding'
      shift(227);                   // 'sliding'
      break;
    case 233:                       // 'strict'
      shift(233);                   // 'strict'
      break;
    case 244:                       // 'tumbling'
      shift(244);                   // 'tumbling'
      break;
    case 245:                       // 'type'
      shift(245);                   // 'type'
      break;
    case 250:                       // 'updating'
      shift(250);                   // 'updating'
      break;
    case 254:                       // 'value'
      shift(254);                   // 'value'
      break;
    case 256:                       // 'version'
      shift(256);                   // 'version'
      break;
    case 260:                       // 'while'
      shift(260);                   // 'while'
      break;
    case 90:                        // 'constraint'
      shift(90);                    // 'constraint'
      break;
    case 169:                       // 'loop'
      shift(169);                   // 'loop'
      break;
    default:
      shift(214);                   // 'returning'
    }
    eventHandler.endNonterminal("NCName", e0);
  }

  var lk, b0, e0;
  var l1, b1, e1;
  var eventHandler;

  function error(b, e, s, l, t)
  {
    throw new self.ParseException(b, e, s, l, t);
  }

  function shift(t)
  {
    if (l1 == t)
    {
      whitespace();
      eventHandler.terminal(XQueryTokenizer.TOKEN[l1], b1, e1 > size ? size : e1);
      b0 = b1; e0 = e1; l1 = 0;
    }
    else
    {
      error(b1, e1, 0, l1, t);
    }
  }

  function whitespace()
  {
    if (e0 != b1)
    {
      b0 = e0;
      e0 = b1;
      eventHandler.whitespace(b0, e0);
    }
  }

  function matchW(set)
  {
    var code;
    for (;;)
    {
      code = match(set);
      if (code != 28)               // S^WS
      {
        break;
      }
    }
    return code;
  }

  function lookahead1W(set)
  {
    if (l1 == 0)
    {
      l1 = matchW(set);
      b1 = begin;
      e1 = end;
    }
  }

  function lookahead1(set)
  {
    if (l1 == 0)
    {
      l1 = match(set);
      b1 = begin;
      e1 = end;
    }
  }

  var input;
  var size;
  var begin;
  var end;

  function match(tokenSetId)
  {
    var nonbmp = false;
    begin = end;
    var current = end;
    var result = XQueryTokenizer.INITIAL[tokenSetId];
    var state = 0;

    for (var code = result & 4095; code != 0; )
    {
      var charclass;
      var c0 = current < size ? input.charCodeAt(current) : 0;
      ++current;
      if (c0 < 0x80)
      {
        charclass = XQueryTokenizer.MAP0[c0];
      }
      else if (c0 < 0xd800)
      {
        var c1 = c0 >> 4;
        charclass = XQueryTokenizer.MAP1[(c0 & 15) + XQueryTokenizer.MAP1[(c1 & 31) + XQueryTokenizer.MAP1[c1 >> 5]]];
      }
      else
      {
        if (c0 < 0xdc00)
        {
          var c1 = current < size ? input.charCodeAt(current) : 0;
          if (c1 >= 0xdc00 && c1 < 0xe000)
          {
            ++current;
            c0 = ((c0 & 0x3ff) << 10) + (c1 & 0x3ff) + 0x10000;
            nonbmp = true;
          }
        }
        var lo = 0, hi = 5;
        for (var m = 3; ; m = (hi + lo) >> 1)
        {
          if (XQueryTokenizer.MAP2[m] > c0) hi = m - 1;
          else if (XQueryTokenizer.MAP2[6 + m] < c0) lo = m + 1;
          else {charclass = XQueryTokenizer.MAP2[12 + m]; break;}
          if (lo > hi) {charclass = 0; break;}
        }
      }

      state = code;
      var i0 = (charclass << 12) + code - 1;
      code = XQueryTokenizer.TRANSITION[(i0 & 15) + XQueryTokenizer.TRANSITION[i0 >> 4]];

      if (code > 4095)
      {
        result = code;
        code &= 4095;
        end = current;
      }
    }

    result >>= 12;
    if (result == 0)
    {
      end = current - 1;
      var c1 = end < size ? input.charCodeAt(end) : 0;
      if (c1 >= 0xdc00 && c1 < 0xe000) --end;
      return error(begin, end, state, -1, -1);
    }

    if (nonbmp)
    {
      for (var i = result >> 9; i > 0; --i)
      {
        --end;
        var c1 = end < size ? input.charCodeAt(end) : 0;
        if (c1 >= 0xdc00 && c1 < 0xe000) --end;
      }
    }
    else
    {
      end -= result >> 9;
    }

    return (result & 511) - 1;
  }
}

XQueryTokenizer.getTokenSet = function(tokenSetId)
{
  var set = [];
  var s = tokenSetId < 0 ? - tokenSetId : INITIAL[tokenSetId] & 4095;
  for (var i = 0; i < 274; i += 32)
  {
    var j = i;
    var i0 = (i >> 5) * 2066 + s - 1;
    var i1 = i0 >> 2;
    var i2 = i1 >> 2;
    var f = XQueryTokenizer.EXPECTED[(i0 & 3) + XQueryTokenizer.EXPECTED[(i1 & 3) + XQueryTokenizer.EXPECTED[(i2 & 3) + XQueryTokenizer.EXPECTED[i2 >> 2]]]];
    for ( ; f != 0; f >>>= 1, ++j)
    {
      if ((f & 1) != 0)
      {
        set.push(XQueryTokenizer.TOKEN[j]);
      }
    }
  }
  return set;
};

XQueryTokenizer.MAP0 =
[ 66, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 27, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 32, 31, 31, 33, 31, 31, 31, 31, 31, 31, 34, 35, 36, 35, 31, 35, 37, 38, 39, 40, 41, 42, 43, 44, 45, 31, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 31, 61, 62, 63, 64, 35
];

XQueryTokenizer.MAP1 =
[ 108, 124, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 156, 181, 181, 181, 181, 181, 214, 215, 213, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 214, 247, 261, 277, 293, 309, 347, 363, 379, 416, 416, 416, 408, 331, 323, 331, 323, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 433, 433, 433, 433, 433, 433, 433, 316, 331, 331, 331, 331, 331, 331, 331, 331, 394, 416, 416, 417, 415, 416, 416, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 416, 330, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 331, 416, 66, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 27, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 35, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 32, 31, 31, 33, 31, 31, 31, 31, 31, 31, 34, 35, 36, 35, 31, 35, 37, 38, 39, 40, 41, 42, 43, 44, 45, 31, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 31, 61, 62, 63, 64, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 31, 31, 35, 35, 35, 35, 35, 35, 35, 65, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65
];

XQueryTokenizer.MAP2 =
[ 57344, 63744, 64976, 65008, 65536, 983040, 63743, 64975, 65007, 65533, 983039, 1114111, 35, 31, 35, 31, 31, 35
];

XQueryTokenizer.INITIAL =
[ 36865, 2, 45059, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
];

XQueryTokenizer.TRANSITION =
[ 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17152, 17933, 17949, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 18103, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19148, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 19203, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 32228, 18636, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 18758, 19692, 19878, 18787, 18820, 18858, 18917, 18947, 18963, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19219, 19235, 19265, 19301, 19397, 19413, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17872, 19502, 17949, 22219, 19599, 18165, 22218, 22159, 19518, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 18103, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19148, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 19203, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 32228, 18636, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 18758, 19692, 19878, 18787, 18820, 18858, 18917, 18947, 18963, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19219, 19235, 19265, 19301, 19397, 19413, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17347, 17933, 19547, 22219, 19599, 18351, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17857, 19666, 19708, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19737, 17933, 19765, 22219, 19599, 19087, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19794, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 19818, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 19331, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17257, 17933, 36858, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17302, 17933, 36858, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17197, 19666, 19285, 22219, 19599, 18165, 22218, 18207, 29084, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 19936, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 19853, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17842, 17933, 35043, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17887, 19894, 36858, 22219, 19599, 18165, 22218, 19778, 19910, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19560, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17362, 19952, 36858, 22219, 19599, 18165, 22218, 18989, 22825, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 18771, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17332, 17933, 36858, 22219, 19599, 18165, 19968, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 21087, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 19987, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18512, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17317, 17933, 36858, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18141, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17377, 17933, 36858, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17167, 20029, 23280, 29869, 32392, 26301, 29995, 23207, 31237, 29869, 31250, 29869, 29869, 24985, 22938, 24985, 24985, 20045, 29996, 26368, 29996, 29996, 36172, 20061, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 20081, 29996, 29996, 29996, 29996, 29996, 24519, 20107, 29869, 29869, 29869, 29869, 20141, 20165, 24985, 24985, 24985, 28705, 19453, 20185, 29996, 29996, 29996, 23461, 24527, 22405, 29869, 29869, 29870, 24985, 25690, 24985, 24985, 23723, 20530, 29996, 35108, 29996, 29996, 23796, 29869, 29869, 27020, 26677, 24985, 24985, 30264, 23436, 29988, 29996, 29996, 35941, 20197, 36669, 29869, 32391, 20218, 24985, 25779, 36472, 20387, 30585, 20237, 29869, 25148, 20271, 35783, 20294, 31536, 20745, 30219, 33247, 20340, 31935, 27285, 32924, 20361, 20408, 20453, 35464, 32016, 32595, 27550, 20278, 32592, 20486, 27633, 20419, 26679, 31532, 20428, 20502, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17392, 17933, 23280, 29869, 32392, 36447, 29995, 23345, 30172, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 20546, 29996, 29996, 29996, 29996, 35439, 20061, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 20081, 29996, 29996, 29996, 29996, 29996, 24519, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 23461, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 20530, 29996, 29996, 29996, 29996, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17467, 17933, 20562, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17272, 17933, 23280, 29869, 32392, 22946, 29995, 23345, 33016, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 20597, 29996, 29996, 29996, 29996, 35302, 20061, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 20613, 29996, 29996, 29996, 29996, 29996, 20640, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 20664, 29996, 29996, 29996, 29996, 26181, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 33956, 28593, 29996, 29996, 29996, 29996, 28680, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 20684, 20712, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 20736, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17902, 20761, 20777, 21367, 20844, 21550, 20806, 21639, 20823, 20860, 20886, 20876, 21361, 17978, 18001, 18017, 21541, 18931, 22042, 20902, 20918, 21630, 21184, 20947, 20955, 20971, 21505, 21370, 21249, 19602, 18127, 18700, 19602, 18157, 20996, 20807, 21027, 21604, 20807, 21597, 21782, 21212, 21350, 21058, 21511, 21242, 21074, 18298, 18327, 18343, 18367, 18472, 21391, 22011, 21103, 21130, 21011, 21139, 19346, 21793, 21466, 21155, 21916, 21962, 18457, 18497, 19249, 18528, 23440, 21420, 21114, 21171, 21293, 21200, 21228, 21835, 21265, 21475, 17985, 18572, 18588, 18616, 19749, 22049, 21042, 21281, 21309, 21339, 21822, 21323, 18664, 18688, 21386, 21407, 20931, 21436, 21452, 21491, 21527, 18917, 21566, 21582, 21620, 21655, 21667, 21683, 21699, 21715, 21753, 20790, 19079, 21769, 21809, 20840, 18712, 18721, 20980, 21851, 21902, 20836, 21888, 21932, 21948, 21998, 22027, 22065, 22081, 19361, 22097, 22113, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17407, 17933, 36858, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19531, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 18978, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 19166, 22132, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 20696, 36061, 20581, 18403, 18425, 22147, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 22175, 18885, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 22210, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17212, 17933, 27067, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17812, 17933, 36858, 22219, 19599, 18600, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17827, 22235, 22251, 22219, 19599, 18165, 22218, 29097, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 17962, 22309, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 18196, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 19802, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17182, 22336, 36858, 22219, 19599, 18672, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17287, 22352, 36858, 22219, 19599, 18165, 22218, 18648, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 23376, 29869, 32392, 20149, 22368, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 28881, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 22455, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 23500, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 18040, 29996, 29996, 29996, 29996, 28680, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 26055, 22479, 29996, 29996, 29996, 22503, 29869, 29869, 32391, 24985, 24985, 20736, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 23376, 29869, 32392, 20149, 22368, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 28881, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 22455, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 24272, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 18040, 29996, 29996, 29996, 29996, 28680, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 26055, 22479, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 20736, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 23376, 29869, 32392, 20149, 22368, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 31206, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 22455, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 24272, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 18040, 29996, 29996, 29996, 29996, 28680, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 26055, 22479, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 20736, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 23376, 29869, 32392, 20149, 22368, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 28881, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 22524, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 24272, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 18040, 29996, 29996, 29996, 29996, 28680, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 26055, 22479, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 20736, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 23376, 29869, 32392, 30272, 22368, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22548, 29996, 29996, 29996, 29996, 28881, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 22455, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 24272, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 18040, 29996, 29996, 29996, 29996, 28680, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 26055, 22479, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 20736, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 23376, 29869, 32392, 20149, 22368, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 35439, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 23164, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 23461, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 20530, 29996, 29996, 29996, 29996, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17497, 17933, 23376, 29869, 32392, 35472, 22564, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 35439, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 23164, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 23461, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 20530, 29996, 29996, 29996, 29996, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 23376, 29869, 32392, 20149, 22368, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 35439, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 23164, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 23461, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 20530, 29996, 29996, 29996, 29996, 21737, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17422, 17933, 36858, 22219, 19599, 18165, 22218, 18207, 32336, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 22581, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17242, 17933, 36858, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17917, 22597, 36858, 22219, 19599, 18165, 22218, 36871, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 22613, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17512, 17933, 22661, 22695, 22734, 22778, 22794, 22810, 34358, 29869, 29869, 29869, 22854, 24985, 24985, 24985, 25418, 22385, 29996, 29996, 29996, 30579, 28881, 22873, 34380, 29869, 22857, 22903, 22962, 22981, 24985, 24985, 23073, 23097, 23122, 23149, 29996, 29996, 23198, 23223, 22455, 29372, 29869, 29263, 28216, 30486, 23249, 35379, 32893, 29889, 24985, 23265, 25784, 23336, 27529, 28525, 29996, 23361, 20648, 34949, 29869, 30190, 34219, 24483, 23410, 24985, 31903, 23429, 18040, 23456, 23477, 29996, 23494, 23516, 23861, 22762, 29869, 26677, 23550, 23572, 24985, 26055, 22479, 23600, 23622, 29996, 20197, 23313, 29292, 32391, 35777, 34162, 20736, 36480, 27872, 23667, 29869, 29869, 32392, 24985, 20276, 26376, 33607, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 35746, 35228, 20437, 32184, 32616, 28997, 23689, 27549, 32795, 31605, 26679, 31532, 20428, 32154, 33986, 32305, 29564, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17527, 17933, 23376, 29869, 32392, 20149, 22368, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 28881, 22401, 29869, 29869, 29869, 29500, 27550, 24985, 24985, 24985, 31554, 23718, 22421, 29996, 29996, 29996, 24251, 23742, 22455, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 24272, 24866, 29869, 29869, 29869, 34956, 23764, 24985, 24985, 24985, 25771, 18040, 23789, 29996, 29996, 29996, 23812, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 26055, 22479, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 20736, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 34756, 23840, 23894, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17542, 17933, 23376, 31731, 32392, 23936, 22368, 23952, 35980, 24002, 24039, 29869, 29869, 24057, 24124, 24985, 24985, 22385, 24145, 24176, 29996, 29996, 28881, 24197, 23182, 23878, 26610, 29869, 27550, 26524, 24366, 24985, 24213, 24985, 22421, 22432, 24233, 24250, 24267, 29996, 22455, 29869, 29869, 29869, 29869, 24288, 32393, 24985, 24985, 24985, 34766, 28705, 29992, 29996, 29996, 29996, 30886, 24272, 24527, 29869, 29869, 25853, 29870, 24985, 24985, 24985, 24307, 23723, 18040, 29996, 29996, 29996, 24327, 28680, 29869, 23320, 29869, 26677, 24985, 35638, 24985, 26055, 22479, 29996, 32866, 29996, 23673, 29869, 24345, 24023, 24985, 24364, 20736, 24382, 29212, 20191, 29869, 30944, 32392, 24985, 35890, 26376, 26570, 24402, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 24425, 20744, 26678, 26698, 32025, 24469, 24506, 24546, 27549, 20345, 20419, 26679, 24596, 20428, 32154, 33986, 24624, 24655, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17557, 17933, 23376, 30229, 31963, 20149, 24693, 23345, 36408, 34050, 25367, 32711, 28363, 24727, 24746, 23021, 24968, 22385, 24762, 24781, 20624, 29412, 28881, 22401, 29869, 29869, 29869, 27693, 27550, 24985, 24985, 24985, 32636, 24985, 22421, 29996, 29996, 29996, 34907, 29996, 22455, 24797, 33272, 29869, 29869, 33416, 24821, 34068, 24985, 24985, 27511, 24852, 18049, 24900, 24917, 29996, 29996, 24934, 25540, 29869, 29869, 22674, 29870, 24965, 24985, 24985, 24984, 23723, 18040, 25002, 29996, 33383, 29996, 28680, 30656, 29869, 25019, 26677, 23081, 24217, 33573, 26055, 22479, 21872, 36361, 25062, 20197, 29869, 29869, 32391, 24985, 24985, 20736, 29996, 20387, 20191, 29869, 27448, 32392, 24985, 33738, 18556, 31536, 25084, 29869, 32393, 20274, 28729, 20392, 29870, 24985, 35900, 27373, 22965, 29476, 32595, 32385, 25107, 25134, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 22749, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17572, 17933, 23376, 25173, 25208, 25246, 25262, 25304, 34358, 29591, 25348, 26027, 32721, 33305, 25383, 25403, 32517, 25440, 30637, 25456, 25476, 20720, 25526, 25563, 26634, 25624, 31771, 34502, 28011, 25640, 25671, 25706, 25757, 28851, 25800, 25816, 25832, 25877, 25927, 26907, 25978, 30452, 26022, 29869, 25578, 23394, 32393, 26043, 24985, 24580, 26091, 26110, 29992, 26140, 29996, 29909, 26176, 26197, 22463, 20255, 30016, 26228, 35197, 31321, 32424, 35013, 26263, 26298, 18040, 26317, 26337, 27933, 26359, 26398, 29269, 31084, 31624, 26677, 32762, 30542, 26426, 26055, 22479, 35585, 34110, 26446, 20306, 26466, 30236, 26482, 26509, 23773, 26540, 26556, 31451, 26591, 23175, 29847, 34472, 25424, 23556, 27365, 32664, 20745, 33162, 32393, 32770, 33791, 26382, 27318, 34528, 35551, 26626, 27127, 26650, 26659, 26675, 26695, 26714, 26730, 26767, 26797, 26679, 31532, 23702, 26830, 33986, 26865, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17587, 17933, 24639, 23871, 36509, 20149, 26896, 23345, 34358, 31761, 29869, 29869, 29869, 36124, 24985, 24985, 24985, 22385, 32564, 29996, 29996, 29996, 28881, 22401, 29869, 29869, 29869, 27014, 27550, 24985, 24985, 24985, 30350, 24985, 22421, 29996, 29996, 29996, 25460, 29996, 22455, 29869, 29869, 20125, 29869, 29869, 32393, 24985, 24985, 26930, 24985, 28705, 29992, 29996, 29996, 26949, 29996, 24272, 24527, 29869, 29869, 28223, 29870, 24985, 24985, 24985, 25734, 23723, 18040, 29996, 29996, 29996, 26970, 28680, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 26055, 22479, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 20736, 29996, 20387, 20191, 33136, 29869, 24677, 24985, 20276, 35738, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 26991, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 27036, 32154, 24072, 27052, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17602, 17933, 27103, 29869, 32392, 20149, 22368, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 35439, 27150, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 27170, 29996, 29996, 29996, 29996, 29996, 23164, 29869, 29869, 28004, 29869, 29869, 32393, 24985, 28113, 24985, 24985, 22718, 29992, 29996, 25003, 29996, 29996, 23461, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 20530, 29996, 29996, 29996, 29996, 23796, 29869, 29869, 25510, 26677, 24985, 24985, 28953, 23436, 29988, 29996, 29996, 30309, 28065, 24409, 29679, 27204, 23106, 27225, 27763, 36691, 27914, 27241, 30675, 25989, 25905, 30516, 27271, 35116, 32053, 20745, 27307, 27341, 27389, 23233, 26154, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32463, 27412, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 23376, 27446, 27464, 35256, 27487, 23057, 34358, 29869, 29869, 34794, 29869, 24985, 24985, 24985, 27509, 22385, 29996, 29996, 29996, 27527, 35439, 22401, 29869, 29869, 29869, 29869, 24108, 24985, 24985, 24985, 24985, 34032, 22421, 29996, 29996, 29996, 29996, 24901, 23164, 30445, 29869, 29869, 29869, 29869, 35624, 24985, 24985, 24985, 24985, 28705, 22194, 29996, 29996, 29996, 29996, 23461, 24527, 29869, 29869, 29869, 27545, 24985, 24985, 24985, 36548, 23723, 20530, 29996, 29996, 29996, 23748, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 27566, 25741, 33807, 30055, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17617, 17933, 23376, 27584, 27605, 35673, 27649, 30925, 34358, 20462, 27683, 29869, 27716, 27471, 27750, 24985, 27797, 27843, 27493, 27859, 29996, 27888, 27949, 22401, 25039, 29869, 30435, 27984, 24017, 26430, 24985, 28292, 33092, 34870, 22421, 31651, 29996, 24386, 28027, 28053, 24160, 24884, 29869, 29869, 20065, 36673, 28087, 28110, 24985, 24985, 28129, 28150, 35316, 28185, 29996, 29996, 28673, 29706, 27963, 24348, 20318, 28206, 28394, 28239, 25230, 28256, 33526, 28308, 22116, 29996, 32819, 29967, 28332, 28379, 24879, 25590, 27116, 28418, 28453, 28470, 28494, 23436, 18481, 28524, 28541, 28565, 24608, 24446, 20248, 32165, 28618, 28640, 36529, 28662, 27901, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 27291, 22508, 28696, 31521, 28721, 34274, 29870, 24985, 35900, 20744, 28745, 28761, 28810, 27550, 20278, 32592, 27549, 20345, 20419, 28836, 28867, 20428, 32154, 33986, 32305, 28917, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 23376, 29869, 32392, 20149, 22368, 23345, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 35439, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 23164, 25188, 29869, 29869, 29869, 29869, 28978, 24985, 24985, 24985, 24985, 28705, 28602, 29996, 29996, 29996, 29996, 23461, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 20530, 29996, 29996, 29996, 29996, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17632, 17933, 29013, 24086, 22709, 29029, 29045, 29069, 36654, 34388, 32083, 31493, 29852, 29113, 29126, 29133, 29149, 22385, 29199, 34628, 33476, 29237, 35439, 27150, 29285, 26807, 36078, 29869, 33239, 23008, 31791, 24985, 28286, 26094, 27170, 27667, 33883, 29996, 24704, 24329, 23164, 29869, 29869, 31290, 29764, 23645, 32393, 24985, 24985, 29308, 22995, 22718, 29992, 29996, 29996, 29324, 29346, 23461, 24527, 30748, 29869, 29869, 29870, 24985, 29388, 24985, 24985, 23723, 20530, 29996, 29409, 29996, 29996, 23796, 28932, 29869, 29869, 26410, 26744, 24985, 24985, 29428, 28794, 30879, 29996, 29996, 29450, 28071, 29869, 32391, 31911, 24985, 25779, 31828, 20387, 20191, 29869, 20202, 32392, 24985, 29471, 26376, 31536, 29492, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 29516, 27550, 20278, 32592, 25954, 29550, 29580, 29527, 29607, 20428, 29632, 29666, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17647, 17933, 23376, 24100, 32750, 20149, 29695, 23345, 29722, 25861, 29869, 20120, 29756, 33579, 24985, 32945, 29780, 22385, 26954, 29996, 32673, 29807, 35439, 22401, 29834, 29869, 29868, 29869, 27550, 34981, 29886, 31356, 24985, 24985, 22421, 33615, 29905, 35325, 29996, 29996, 30124, 24291, 25363, 29869, 31405, 29869, 32393, 29164, 24985, 33436, 29925, 28705, 29943, 34327, 29996, 33196, 29963, 23461, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 28134, 29983, 29996, 29996, 29996, 29996, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 30013, 29869, 32391, 30032, 24985, 25779, 22638, 30050, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 30071, 32087, 29927, 35900, 20091, 28402, 27396, 28346, 27550, 30772, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 34249, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17662, 17933, 24949, 27255, 22887, 30093, 30109, 30157, 34358, 24805, 30135, 32839, 29869, 31327, 27624, 28240, 24985, 22385, 26975, 27827, 22369, 29996, 35439, 30206, 31416, 29869, 29869, 29869, 27550, 30252, 24985, 24985, 24985, 24985, 22421, 30288, 29996, 29996, 29996, 29996, 25491, 29869, 29869, 29869, 30325, 33408, 30344, 24985, 24985, 28437, 34888, 28705, 21729, 29996, 29996, 36588, 29996, 30366, 24527, 30395, 30424, 30468, 29870, 36428, 30502, 25720, 30532, 23723, 20530, 31674, 30567, 30601, 30629, 32873, 24041, 30653, 30672, 30691, 24490, 36342, 36210, 30716, 18539, 25068, 34086, 31811, 30740, 31255, 31484, 29643, 35645, 30764, 23034, 29996, 30788, 20191, 30836, 34211, 33726, 30852, 20276, 30868, 30902, 20745, 30941, 35876, 20274, 34186, 20392, 26006, 28478, 35900, 30960, 30408, 30976, 31005, 28943, 31038, 31066, 27549, 30700, 20419, 26679, 31532, 33998, 31100, 33986, 32305, 26781, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17677, 17933, 23376, 31133, 36009, 31176, 31192, 31222, 34358, 29869, 25998, 31271, 25091, 24985, 28094, 31306, 31343, 22385, 29996, 29330, 31379, 31438, 28579, 31472, 35350, 33144, 29869, 29869, 31509, 31552, 28271, 31570, 24985, 24573, 31592, 31648, 23133, 31667, 29996, 27819, 23164, 29869, 36607, 29869, 31690, 29869, 32393, 24985, 31707, 28989, 24985, 28705, 29992, 29996, 27181, 28549, 29996, 23461, 31728, 29869, 29869, 29869, 33034, 24985, 24985, 24985, 24985, 36521, 29434, 29996, 29996, 29996, 29996, 31747, 29869, 33640, 29869, 27325, 24985, 31787, 24985, 23584, 34715, 29996, 31807, 29996, 35525, 25192, 29869, 30820, 36250, 24985, 25779, 31827, 31844, 20191, 29869, 29869, 32392, 24985, 20276, 36324, 31868, 28037, 29869, 31892, 25387, 31927, 20392, 31951, 32002, 32041, 32069, 32103, 32139, 27003, 27550, 20278, 32181, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32200, 33349, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17692, 17933, 23376, 23651, 27430, 32260, 32276, 32321, 32372, 33280, 22679, 33054, 31632, 25911, 32409, 28454, 28624, 22385, 28190, 32448, 22565, 32538, 28775, 22401, 29869, 29869, 23389, 29869, 27550, 24985, 24985, 29534, 24985, 24985, 22421, 29996, 29996, 28169, 29996, 29996, 30803, 29869, 25046, 32492, 29869, 29869, 32393, 24985, 32509, 24985, 24985, 28705, 32533, 29996, 32554, 29996, 29996, 24181, 24527, 29869, 36189, 29869, 29870, 24985, 24985, 31117, 24985, 29393, 32580, 29996, 29996, 35333, 29996, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 31975, 22190, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 27773, 26575, 32611, 32632, 32652, 20744, 26678, 26698, 32595, 27550, 20278, 32697, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 32737, 27730, 32786, 34820, 32811, 34725, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 35439, 32835, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 32855, 29996, 29996, 29996, 29996, 29996, 23164, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 34990, 29992, 29996, 29996, 29996, 29996, 23461, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 20530, 29996, 29996, 29996, 29996, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 20324, 29869, 32392, 32889, 20276, 35949, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17707, 17933, 23376, 32909, 36300, 32969, 32985, 33001, 34358, 29869, 33050, 31422, 33070, 24985, 25223, 24730, 25655, 22385, 29996, 36820, 24765, 30613, 35439, 33108, 29869, 33160, 29869, 34371, 33178, 24985, 26274, 24985, 31363, 26493, 22421, 33194, 31852, 29996, 36271, 31876, 25942, 33212, 29455, 33230, 33263, 29869, 33296, 24985, 33321, 33845, 24985, 34776, 22627, 29996, 33365, 24711, 33381, 22645, 24527, 33399, 29740, 29869, 29870, 33864, 33432, 29175, 24985, 23723, 20530, 23606, 33452, 33470, 29996, 23796, 33492, 29869, 29869, 33511, 24985, 24985, 20221, 23436, 30724, 29996, 29996, 34685, 25844, 29869, 29869, 31111, 24985, 24985, 27354, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 31456, 33542, 33558, 33595, 33631, 26678, 26698, 32595, 33664, 20278, 33680, 27549, 20345, 20419, 26679, 31532, 28820, 33714, 33986, 33764, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17722, 17933, 26212, 31615, 23908, 20149, 33780, 23345, 34358, 33823, 27734, 29869, 29869, 24836, 24986, 33861, 24985, 22385, 35083, 29997, 33880, 29996, 35439, 22401, 33694, 28357, 29869, 29869, 30814, 29183, 28646, 24985, 24985, 31576, 22421, 28901, 20668, 29996, 29996, 26321, 33899, 29869, 29869, 36710, 24453, 33118, 33929, 24985, 24985, 33950, 33972, 28705, 21865, 29996, 29996, 27925, 34014, 23461, 24527, 29869, 26247, 23528, 29870, 24985, 24985, 27615, 34030, 23723, 20530, 29996, 29996, 29818, 29996, 26914, 29869, 34048, 25602, 26677, 20169, 24985, 34066, 23436, 26067, 36229, 29996, 34084, 20197, 29869, 29869, 32391, 24985, 24985, 27810, 29996, 34102, 20191, 29869, 27700, 32392, 24985, 34126, 26376, 31050, 30077, 29869, 34152, 20274, 34178, 20392, 34443, 34537, 34136, 34202, 26678, 26698, 25276, 25547, 28962, 32592, 33648, 34235, 25118, 20511, 34265, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17737, 17933, 26880, 25288, 24560, 34290, 34306, 34343, 34404, 34434, 34459, 34488, 24530, 34518, 34553, 34569, 34585, 34602, 34618, 34651, 34667, 34683, 34701, 34741, 33913, 34418, 34792, 25608, 27550, 34810, 34836, 34862, 24985, 34886, 22421, 23046, 30914, 34318, 29996, 34904, 29361, 31022, 34923, 29869, 29869, 34939, 32393, 34972, 35006, 24985, 29791, 35029, 19376, 35072, 35099, 29996, 29053, 35132, 26124, 29869, 35187, 26606, 35220, 35244, 31712, 35272, 33934, 27209, 31986, 32681, 27188, 35288, 36827, 23796, 23824, 35349, 29869, 27425, 35366, 24985, 24985, 35402, 29988, 35426, 29996, 29996, 35455, 33127, 35488, 26841, 28508, 24311, 20374, 26343, 30301, 35519, 29735, 31148, 25962, 27134, 35541, 35567, 35701, 26160, 35609, 35661, 30551, 35689, 29616, 29870, 24985, 35717, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 35762, 23920, 23851, 35503, 35799, 20428, 32154, 33986, 35815, 35861, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17752, 17933, 23376, 31160, 22928, 35916, 35932, 35965, 35996, 23293, 29869, 29869, 32493, 34846, 24985, 24985, 24985, 36025, 29221, 29996, 29996, 29996, 36041, 22401, 27589, 23534, 31016, 36077, 24670, 24985, 36094, 36112, 32116, 26849, 22421, 29996, 36140, 36159, 18548, 34635, 29252, 29869, 36188, 29869, 29869, 29869, 32393, 28429, 24985, 24985, 24985, 28705, 28164, 35593, 29996, 29996, 29996, 23461, 22532, 29869, 29869, 29869, 29870, 36205, 24985, 24985, 24985, 24129, 19444, 36226, 29996, 29996, 29996, 22439, 23303, 29869, 29869, 35204, 36245, 24985, 24985, 23436, 35410, 36266, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 31286, 32476, 20274, 27781, 20392, 29870, 24985, 33748, 20744, 26678, 26698, 32595, 27550, 32953, 32592, 26814, 33335, 24436, 26679, 31532, 20428, 32291, 36287, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17767, 17933, 23376, 30482, 33083, 20149, 36316, 23345, 34358, 30141, 29869, 33698, 29869, 23413, 24985, 34586, 24985, 22385, 36567, 29996, 23478, 29996, 35439, 22401, 29869, 27968, 29869, 29869, 27550, 24985, 24985, 36340, 24985, 24985, 22421, 29996, 29996, 36358, 29996, 29996, 23164, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 23461, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 20530, 29996, 29996, 29996, 29996, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17782, 17933, 23376, 33495, 32392, 36377, 22368, 36393, 34358, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 22385, 29996, 29996, 29996, 29996, 35439, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 25892, 29869, 29869, 29869, 29869, 29869, 36424, 24985, 24985, 24985, 24985, 28705, 28895, 29996, 29996, 29996, 29996, 23461, 24527, 29869, 26243, 29869, 22916, 24985, 27568, 24985, 24985, 36444, 20530, 29996, 36143, 29996, 33454, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17797, 17933, 23376, 31080, 33836, 20149, 36463, 23345, 36496, 29869, 31691, 29869, 30185, 24985, 24985, 36545, 25682, 22385, 29996, 29996, 36564, 27658, 35439, 22401, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 22421, 29996, 29996, 29996, 29996, 29996, 31394, 29869, 29869, 25506, 29869, 29869, 32393, 24985, 29650, 24985, 24985, 28705, 36583, 29996, 26450, 29996, 29996, 23461, 24527, 36604, 29869, 29869, 29870, 36096, 24985, 24985, 24985, 35386, 28789, 29947, 29996, 29996, 29996, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17482, 17933, 23376, 33214, 32392, 36623, 22368, 36639, 34358, 29869, 29869, 29869, 25029, 24985, 24985, 24985, 26282, 22385, 29996, 29996, 29996, 22487, 35439, 22401, 33029, 29869, 20470, 29869, 27550, 26751, 24985, 30034, 24985, 24985, 22421, 19381, 29996, 24234, 29996, 29996, 23164, 29869, 27994, 29869, 29869, 29869, 32393, 26933, 24985, 24985, 24985, 28705, 29992, 24918, 36689, 29996, 29996, 23461, 24527, 29869, 27154, 29869, 30328, 24985, 24985, 25157, 24985, 32123, 20530, 29996, 29996, 35576, 29996, 26075, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 23634, 29869, 29869, 32935, 24985, 24985, 28316, 29996, 20387, 20191, 29869, 36707, 32392, 32432, 20276, 26376, 35729, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17452, 17933, 35830, 22219, 19599, 18165, 36726, 18207, 19679, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18872, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 30379, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17437, 17933, 36858, 22219, 19599, 18165, 22218, 35056, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18311, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17227, 17933, 32215, 22219, 19599, 18165, 22218, 18207, 23967, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18282, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 36746, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17242, 17933, 36858, 22219, 19599, 18165, 22218, 18207, 25319, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18381, 18801, 18065, 18084, 22317, 19278, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 18181, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 17242, 17933, 23280, 29869, 32392, 23726, 29995, 23345, 30172, 29869, 29869, 29869, 29869, 24985, 24985, 24985, 24985, 36793, 29996, 29996, 29996, 29996, 35439, 20061, 29869, 29869, 29869, 29869, 27550, 24985, 24985, 24985, 24985, 24985, 36809, 29996, 29996, 29996, 29996, 29996, 24519, 29869, 29869, 29869, 29869, 29869, 32393, 24985, 24985, 24985, 24985, 28705, 29992, 29996, 29996, 29996, 29996, 23461, 24527, 29869, 29869, 29869, 29870, 24985, 24985, 24985, 24985, 23723, 20530, 29996, 29996, 29996, 29996, 23796, 29869, 29869, 29869, 26677, 24985, 24985, 24985, 23436, 29988, 29996, 29996, 29996, 20197, 29869, 29869, 32391, 24985, 24985, 25779, 29996, 20387, 20191, 29869, 29869, 32392, 24985, 20276, 26376, 31536, 20745, 29869, 32393, 20274, 33799, 20392, 29870, 24985, 35900, 20744, 26678, 26698, 32595, 27550, 20278, 32592, 27549, 20345, 20419, 26679, 31532, 20428, 32154, 33986, 32305, 30989, 20527, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 36843, 35145, 19285, 22219, 19599, 18165, 22218, 19015, 35158, 18804, 18068, 18087, 22320, 17978, 18001, 18017, 21541, 18030, 18801, 18065, 18084, 22317, 19721, 19195, 23986, 18230, 22287, 19971, 22293, 19602, 18127, 18700, 19602, 18157, 30379, 22219, 18223, 22280, 22219, 23980, 19116, 32349, 27080, 18246, 36730, 22273, 18269, 18298, 18327, 18343, 18367, 18472, 18742, 32356, 27087, 18253, 22264, 18111, 36055, 20575, 18397, 18419, 18441, 21962, 18457, 18497, 19249, 18528, 18620, 36061, 20581, 18403, 18425, 20002, 18897, 19833, 32240, 22838, 17985, 18572, 18588, 18616, 19119, 18901, 19837, 32244, 36761, 36777, 19868, 35845, 18664, 18688, 18737, 36773, 25332, 19878, 18787, 18820, 18858, 18917, 18947, 19576, 19005, 18832, 35171, 19031, 19047, 18842, 19063, 19316, 19079, 19103, 19158, 19595, 21973, 21982, 19923, 19135, 20013, 19591, 19182, 19618, 19235, 19265, 19301, 19634, 19650, 19429, 19469, 19484, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 19486, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 118821, 102440, 106539, 98348, 118821, 118821, 118821, 36880, 19, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 20480, 36880, 40978, 21, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 20480, 36880, 40978, 45076, 22, 24, 28, 34, 34, 0, 34, 34, 34, 0, 0, 0, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 0, 0, 45, 0, 0, 20576, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 42, 42, 42, 0, 0, 1118208, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 0, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 90, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 95, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 97, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 12379, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 20480, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 57437, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 143449, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 176128, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 188416, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 196702, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 217088, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 249856, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 1114232, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 1105961, 1105961, 1105961, 0, 0, 1105920, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 38, 102440, 106539, 98348, 0, 0, 200704, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 46, 68, 98, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 47, 68, 99, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 48, 69, 100, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 49, 70, 101, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 50, 71, 102, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 51, 72, 103, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 52, 73, 104, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 53, 74, 105, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 54, 75, 106, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 55, 76, 107, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 56, 77, 108, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 57, 78, 109, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 58, 79, 110, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 59, 80, 111, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 60, 81, 112, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 61, 82, 113, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 62, 83, 114, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 63, 84, 115, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 64, 85, 116, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 65, 86, 117, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 66, 87, 118, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 39, 102440, 106539, 98348, 67, 88, 119, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 233472, 102440, 106539, 98348, 0, 0, 20480, 36880, 40978, 45076, 22, 24, 28, 90144, 94243, 237568, 102440, 106539, 98348, 0, 0, 20569, 36880, 40978, 45076, 22, 24, 28, 90144, 155684, 155648, 102440, 155684, 98348, 0, 0, 155648, 36880, 40978, 45076, 22, 24, 28, 147489, 94243, 147456, 147489, 106539, 98348, 0, 0, 147456, 36880, 40978, 45076, 22, 25, 29, 90144, 94243, 118821, 102440, 106539, 98348, 118821, 118821, 118821, 36880, 40978, 45076, 22, 26, 30, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 159836, 36880, 40978, 45076, 22, 27, 31, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 208985, 36880, 40978, 45076, 23, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 253952, 36880, 0, 40978, 40978, 45076, 0, 22, 22, 24, 24, 24, 24, 28, 28, 28, 28, 90144, 0, 0, 94243, 0, 118821, 0, 2211840, 102440, 0, 0, 106539, 98348, 0, 2158592, 2158592, 2158592, 0, 127, 127, 0, 0, 0, 0, 0, 0, 0, 2211840, 0, 0, 2207744, 2207744, 2207744, 2396160, 2404352, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2523136, 2207744, 2207744, 2207744, 2207744, 2207744, 2609152, 2207744, 2207744, 2596864, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2670592, 2207744, 2686976, 2207744, 2695168, 2207744, 2703360, 2744320, 2207744, 2207744, 2777088, 2207744, 2801664, 2207744, 2207744, 2834432, 2207744, 2207744, 2207744, 2891776, 2207744, 2207744, 2207744, 0, 0, 0, 0, 0, 0, 2166784, 0, 0, 0, 0, 0, 0, 0, 0, 1319, 0, 0, 0, 0, 98, 98, 98, 98, 98, 98, 98, 1109, 98, 98, 98, 98, 2158592, 2158592, 2596864, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2670592, 2158592, 2686976, 2158592, 2695168, 2158592, 2703360, 2744320, 2158592, 2158592, 2744320, 2158592, 2158592, 2777088, 2158592, 2801664, 2158592, 2158592, 2834432, 2158592, 2158592, 2158592, 2891776, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 645, 0, 2158592, 0, 2158592, 2158592, 2158592, 2379776, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3178496, 2158592, 0, 0, 0, 0, 0, 2555904, 2207744, 2207744, 2207744, 2207744, 2207744, 2588672, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2633728, 2207744, 2207744, 2207744, 0, 0, 0, 0, 0, 0, 2166784, 550, 0, 0, 0, 0, 288, 2207744, 2207744, 2207744, 3096576, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 0, 0, 0, 0, 0, 0, 2162688, 0, 0, 546, 0, 548, 0, 0, 2170880, 0, 0, 554, 0, 2158592, 2158592, 2158592, 2379776, 2158592, 0, 0, 0, 32768, 0, 0, 0, 0, 0, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 2158592, 2555904, 2158592, 2158592, 2158592, 2158592, 2158592, 2588672, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2633728, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2691072, 2158592, 2158592, 2158592, 2158592, 2158592, 2740224, 2748416, 2768896, 2793472, 2158592, 2158592, 2158592, 2854912, 2883584, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3178496, 2158592, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2433024, 2437120, 2207744, 2207744, 2207744, 0, 0, 0, 0, 0, 0, 2166784, 0, 0, 0, 0, 0, 287, 2207744, 2207744, 2207744, 2494464, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2572288, 2207744, 2207744, 2207744, 0, 0, 0, 0, 0, 0, 2166784, 0, 0, 0, 0, 0, 288, 2207744, 2613248, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2691072, 2207744, 2207744, 2207744, 2207744, 2207744, 2740224, 2748416, 2768896, 2793472, 2207744, 2207744, 2207744, 2854912, 2883584, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 0, 0, 0, 0, 0, 0, 2162688, 137, 2207744, 2207744, 2207744, 3010560, 2207744, 3035136, 2207744, 2207744, 2207744, 2207744, 3072000, 2207744, 2207744, 3104768, 2207744, 2207744, 2207744, 0, 0, 0, 0, 172032, 0, 2166784, 0, 0, 0, 0, 0, 288, 2158592, 2158592, 2621440, 2158592, 2158592, 2158592, 2678784, 2158592, 2707456, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2859008, 2158592, 2895872, 2158592, 2158592, 2158592, 2859008, 2158592, 2895872, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3006464, 2158592, 2158592, 3043328, 2158592, 2158592, 3092480, 2158592, 2158592, 3112960, 2158592, 2158592, 3092480, 2158592, 2158592, 3112960, 2158592, 2158592, 2158592, 3141632, 2158592, 2158592, 3162112, 3166208, 2158592, 2359296, 2207744, 2502656, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2576384, 2207744, 2600960, 2207744, 2207744, 2621440, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 3178496, 2207744, 0, 0, 0, 0, 0, 0, 0, 0, 98, 98, 1484, 98, 98, 98, 98, 98, 2207744, 2207744, 2678784, 2207744, 2707456, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2859008, 2207744, 2895872, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 3178496, 2207744, 0, 0, 0, 0, 0, 0, 53248, 2207744, 3112960, 2207744, 2207744, 2207744, 3141632, 2207744, 2207744, 3162112, 3166208, 2207744, 0, 0, 0, 0, 0, 0, 0, 0, 1482, 98, 98, 98, 98, 98, 98, 98, 897, 98, 98, 98, 98, 98, 98, 98, 98, 1719, 98, 98, 98, 98, 98, 98, 98, 2207744, 2207744, 2207744, 2207744, 2699264, 2723840, 2207744, 2207744, 2207744, 2813952, 2818048, 2207744, 2887680, 2207744, 2207744, 2916352, 2207744, 2207744, 2965504, 2207744, 2973696, 2207744, 2207744, 2994176, 2207744, 3039232, 3055616, 3067904, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 20480, 0, 0, 0, 0, 0, 2162688, 20480, 2207744, 2207744, 2207744, 3194880, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2359296, 2158592, 2158592, 2158592, 2158592, 2965504, 2158592, 2973696, 2158592, 2158592, 2995688, 2158592, 3039232, 3055616, 3067904, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 40978, 0, 22, 22, 24, 24, 127, 4329472, 2207744, 2207744, 2207744, 2514944, 2519040, 2207744, 2207744, 2568192, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 0, 0, 0, 0, 0, 0, 2162688, 229376, 2207744, 2207744, 2899968, 2207744, 2207744, 2207744, 2969600, 2207744, 2207744, 2207744, 2207744, 3031040, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2772992, 2785280, 2207744, 2809856, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2158879, 2158879, 2158879, 2158879, 2158879, 0, 0, 0, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158732, 2158732, 2474124, 2158732, 2158732, 2207744, 2207744, 3149824, 0, 0, 0, 0, 0, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2433024, 2437120, 2158592, 2158592, 2465792, 2158592, 2158592, 2486272, 2158592, 2158592, 2158592, 2516569, 2519040, 2158592, 2158592, 2568192, 2158592, 2158592, 2158592, 22, 127, 0, 0, 0, 0, 0, 0, 0, 0, 2211840, 0, 0, 2158592, 2441216, 2158592, 2158592, 2158592, 2490368, 2158592, 2158592, 2158592, 2158592, 2560000, 2158592, 2584576, 2617344, 2158592, 2158592, 2158592, 2396160, 2404352, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2596864, 2666496, 2727936, 2158592, 2158592, 2158592, 2904064, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3100672, 2158592, 2158592, 3125248, 3137536, 3145728, 2158592, 2400256, 2408448, 2158592, 2457600, 2158592, 2158592, 2158592, 2158592, 0, 0, 2158592, 2158592, 2158592, 2158592, 2625536, 2650112, 0, 0, 3125248, 3137536, 3145728, 2367488, 2371584, 2207744, 2207744, 2412544, 2207744, 2441216, 2207744, 2207744, 2207744, 2490368, 2207744, 2207744, 2207744, 0, 546, 0, 548, 0, 0, 2166784, 0, 0, 0, 554, 0, 0, 0, 554, 0, 288, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2416640, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2523136, 2158592, 2158592, 2158592, 2158592, 2158592, 2609152, 2207744, 2207744, 2560000, 2207744, 2584576, 2617344, 2207744, 2207744, 2666496, 2727936, 2207744, 2207744, 2207744, 2904064, 2207744, 2207744, 2207744, 545, 545, 547, 547, 0, 0, 2166784, 0, 552, 553, 553, 0, 288, 2207744, 2207744, 2207744, 2207744, 2207744, 3100672, 2207744, 2207744, 3125248, 3137536, 3145728, 2367488, 2371584, 2158592, 2158592, 2412544, 2158592, 2441216, 2158592, 2158592, 2158592, 2490368, 2158592, 2158592, 1625, 2158592, 2158592, 2560000, 2158592, 2584576, 2617344, 2158592, 122880, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 40978, 0, 22, 22, 24, 0, 127, 28, 2158592, 2666496, 0, 0, 2727936, 2158592, 2158592, 0, 2158592, 2904064, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 0, 0, 2146304, 2146304, 2224128, 2224128, 2224128, 2232320, 2158592, 3121152, 2207744, 2400256, 2408448, 2207744, 2457600, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2625536, 2650112, 2732032, 2736128, 2826240, 2940928, 2207744, 2977792, 2207744, 2990080, 2207744, 2207744, 2207744, 3121152, 2158592, 2400256, 2408448, 2732032, 2736128, 0, 2826240, 2940928, 2158592, 2977792, 2158592, 2990080, 2158592, 2158592, 2158592, 3121152, 2158592, 2158592, 2469888, 2207744, 2469888, 2207744, 2207744, 2207744, 2527232, 2535424, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 0, 0, 0, 163840, 0, 0, 2162688, 0, 3108864, 2158592, 2158592, 2469888, 2158592, 2158592, 2158592, 0, 0, 2527232, 2535424, 2158592, 2158592, 2158592, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2416640, 2158592, 2158592, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2981888, 2207744, 2207744, 2158592, 2158592, 2473984, 2158592, 2158592, 0, 0, 0, 645, 0, 0, 0, 0, 0, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3108864, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3178496, 2158592, 0, 0, 141, 0, 0, 2564096, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2158592, 2158592, 2158592, 2158592, 0, 0, 0, 2158592, 0, 2158592, 2158592, 2158592, 2379776, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3178496, 2158592, 0, 645, 0, 0, 0, 2564096, 2158592, 2158592, 1512, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2420736, 2158592, 2506752, 2158592, 2580480, 2158592, 2830336, 2158592, 2158592, 2158592, 3002368, 2207744, 2420736, 2207744, 2506752, 2207744, 2580480, 2207744, 2830336, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 3006464, 2207744, 2207744, 3043328, 2207744, 2207744, 3092480, 2207744, 2207744, 3002368, 2158592, 2420736, 2158592, 2506752, 0, 0, 2158592, 2580480, 2158592, 0, 2830336, 2158592, 2158592, 2158592, 22, 127, 127, 0, 0, 0, 0, 0, 0, 0, 2211840, 0, 0, 0, 0, 0, 0, 2158592, 2158592, 2158592, 3002368, 2158592, 2498560, 2158592, 2158592, 2158592, 2158592, 2158592, 2207744, 2498560, 2207744, 2207744, 2207744, 2207744, 2207744, 2158592, 2158592, 2158592, 2527232, 2535424, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3108864, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 3178496, 2207744, 0, 1084, 0, 1088, 0, 1092, 0, 0, 0, 2359436, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2424972, 2158732, 2445452, 2453644, 2158732, 2207744, 2629632, 2945024, 2207744, 0, 0, 2158879, 2629919, 2945311, 2158879, 2531468, 2158732, 2531328, 2207744, 0, 0, 1100, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 854, 98, 98, 98, 98, 2498560, 0, 2024, 2158592, 2158592, 0, 2158592, 2158592, 2158592, 2375680, 2158592, 2158592, 2158592, 2158592, 2998272, 2375680, 2207744, 2207744, 2207744, 2207744, 2998272, 2375680, 0, 2024, 2158592, 2158592, 2158592, 2158592, 2998272, 2158592, 2629632, 2945024, 2158592, 2207744, 2629632, 2945024, 2207744, 0, 0, 2158592, 2629632, 2945024, 2158592, 2531328, 2158592, 2531328, 2207744, 0, 0, 1312, 0, 0, 0, 1318, 0, 0, 0, 0, 0, 0, 98, 98, 98, 98, 98, 1107, 98, 98, 98, 98, 98, 98, 0, 2531328, 2158592, 2158592, 2207744, 0, 2158592, 2158592, 2207744, 0, 2158592, 2158592, 2207744, 0, 2158592, 2957312, 2957312, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 40978, 40978, 45076, 0, 22, 22, 25, 25, 25, 25, 128, 128, 128, 128, 90144, 128, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 141, 2158592, 2158592, 2158592, 22, 127, 127, 0, 122880, 0, 0, 0, 77824, 0, 2211840, 0, 0, 0, 0, 94243, 0, 0, 0, 2211840, 102440, 0, 0, 106539, 98348, 137, 2158592, 2158592, 2158592, 22, 2224485, 2224485, 0, 0, 0, 0, 0, 0, 0, 2211840, 0, 0, 2158592, 2441216, 2158592, 2158592, 2158592, 2490368, 2158592, 2158592, 0, 2158592, 2158592, 2560000, 2158592, 2584576, 2617344, 2158592, 2158592, 2158592, 2564096, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2564096, 2158592, 2158592, 0, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2420736, 2158592, 2506752, 2158592, 2580480, 2498560, 0, 0, 2158592, 2158592, 0, 2158592, 2158592, 2158592, 2375680, 2158592, 2158592, 2158592, 2158592, 2998272, 2375680, 2207744, 2207744, 2207744, 2207744, 2998272, 2375680, 0, 0, 2158592, 2158592, 2158592, 2158592, 2998272, 2158592, 2629632, 2945024, 0, 40978, 40978, 45076, 0, 22, 22, 24, 24, 24, 24, 28, 28, 28, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2158592, 2158592, 2158592, 1508, 2158592, 2158592, 2158592, 1512, 2158592, 2899968, 2158592, 2158592, 2158592, 2969600, 2158592, 2158592, 81920, 0, 94243, 0, 0, 0, 2211840, 0, 0, 0, 106539, 98348, 0, 2158592, 2158592, 2158592, 2146304, 2224128, 2224128, 0, 0, 0, 0, 0, 0, 0, 2211840, 0, 0, 17, 40978, 45076, 22, 24, 28, 90144, 94243, 0, 102440, 106539, 98348, 0, 0, 0, 0, 0, 0, 0, 0, 2158879, 2158879, 2158879, 2158879, 2158879, 2416927, 2158879, 2158879, 0, 132, 94243, 0, 0, 0, 2211840, 102440, 0, 0, 106539, 98348, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 40978, 0, 22, 22, 2224253, 2224253, 2224485, 2232449, 0, 0, 2158592, 648, 2158592, 2158592, 2158592, 2379776, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3178496, 2158592, 0, 32768, 0, 0, 0, 0, 546, 0, 548, 0, 0, 2170880, 0, 0, 554, 833, 2158592, 2158592, 2158592, 2379776, 2158592, 2158592, 2158592, 2609152, 2158592, 2158592, 2158592, 2158592, 2699264, 2723840, 2158592, 2158592, 2158592, 2813952, 2818048, 2158592, 2887680, 2158592, 2158592, 2916352, 0, 827, 0, 829, 0, 0, 2170880, 0, 0, 831, 0, 2158592, 2158592, 2158592, 2379776, 2158592, 2158592, 2158592, 2899968, 2158592, 2158592, 2158592, 2969600, 2158592, 2158592, 2158592, 2158592, 3031040, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3149824, 0, 2367488, 2371584, 2158592, 2158592, 2412544, 0, 40978, 40978, 45076, 0, 22, 22, 2224253, 2224253, 2224253, 2224253, 2232449, 2232449, 2232449, 2232449, 90144, 2232449, 2232449, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 141, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2981888, 2158592, 2158592, 2207744, 2207744, 2473984, 2207744, 2207744, 2207744, 0, 0, 0, 0, 0, 0, 2166784, 0, 0, 0, 0, 0, 555, 151552, 40978, 40978, 45076, 0, 22, 22, 24, 24, 24, 212992, 28, 28, 28, 212992, 90144, 53532, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3096576, 2158592, 2158592, 0, 546, 0, 548, 0, 0, 2170880, 0, 53248, 554, 0, 2158592, 2158592, 2158592, 2379776, 2158592, 2158592, 2158592, 3141632, 2158592, 2158592, 3162112, 3166208, 2158592, 0, 0, 0, 2158592, 2158592, 2158592, 2158592, 0, 0, 0, 2158592, 2158592, 2158592, 2981888, 2158592, 2158592, 2158592, 2158592, 0, 121, 122, 45076, 0, 22, 22, 24, 24, 24, 24, 28, 28, 28, 28, 90144, 68, 68, 68, 24852, 24852, 12566, 12566, 0, 0, 2166784, 550, 0, 53533, 53533, 0, 288, 369, 0, 371, 0, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 990, 46, 46, 0, 546, 0, 548, 57893, 0, 2170880, 0, 0, 554, 0, 98, 98, 98, 98, 98, 1851, 98, 46, 46, 46, 46, 1856, 46, 46, 46, 937, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 949, 46, 46, 46, 46, 423, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 974, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 1013, 68, 68, 68, 68, 68, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 68, 68, 68, 1025, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1449, 68, 68, 98, 98, 98, 98, 98, 1119, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1680, 46, 46, 46, 68, 68, 1584, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1471, 68, 1659, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1667, 46, 46, 46, 46, 46, 46, 1560, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1198, 46, 1200, 46, 46, 46, 46, 68, 68, 1694, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 98, 0, 0, 1713, 98, 98, 98, 98, 98, 98, 98, 0, 98, 98, 1723, 98, 98, 98, 98, 0, 46, 46, 46, 46, 46, 46, 1538, 46, 46, 46, 46, 46, 1208, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1668, 46, 46, 46, 46, 68, 68, 68, 1771, 1772, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 0, 0, 0, 98, 68, 68, 68, 68, 68, 1821, 68, 68, 68, 68, 68, 68, 1827, 68, 68, 68, 0, 0, 0, 0, 0, 0, 98, 98, 98, 1615, 98, 98, 98, 0, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 46, 46, 46, 68, 98, 98, 98, 98, 98, 98, 0, 0, 1839, 98, 98, 98, 98, 0, 0, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 98, 1883, 98, 1885, 98, 0, 1888, 0, 98, 98, 0, 98, 98, 1848, 98, 98, 98, 98, 1852, 46, 46, 46, 46, 46, 46, 46, 385, 46, 46, 46, 46, 46, 46, 46, 46, 704, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1951, 46, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 1963, 98, 2023, 0, 98, 98, 0, 98, 98, 98, 46, 46, 46, 46, 46, 46, 68, 68, 1994, 68, 1995, 68, 68, 68, 68, 68, 68, 98, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 98, 98, 98, 68, 68, 68, 24852, 24852, 12566, 12566, 0, 0, 2166784, 0, 0, 53533, 53533, 0, 288, 0, 0, 94243, 0, 0, 0, 2211840, 102440, 0, 0, 106539, 98348, 138, 2158592, 2158592, 2158592, 2158592, 2158592, 2502656, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2576384, 2158592, 2600960, 2158592, 2158592, 2621440, 2158592, 2158592, 2158592, 68, 68, 68, 24852, 24852, 12566, 12566, 0, 0, 282, 551, 0, 53533, 53533, 0, 288, 0, 546, 0, 548, 57893, 551, 551, 0, 0, 554, 0, 98, 98, 98, 98, 98, 98, 605, 98, 98, 607, 98, 98, 610, 98, 98, 98, 98, 642, 0, 0, 0, 0, 29319, 926, 0, 0, 0, 46, 46, 46, 46, 46, 46, 46, 1187, 46, 46, 46, 46, 46, 1096, 0, 0, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 870, 98, 98, 98, 68, 68, 68, 68, 1301, 1476, 0, 0, 0, 0, 1307, 1478, 0, 0, 0, 0, 0, 0, 0, 288, 0, 0, 0, 288, 0, 2359296, 2158592, 2158592, 1313, 1480, 0, 0, 0, 0, 1319, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 628, 98, 98, 98, 98, 98, 98, 68, 68, 68, 1476, 0, 1478, 0, 1480, 0, 98, 98, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 46, 46, 46, 0, 40978, 40978, 45076, 0, 22, 22, 2224254, 2224254, 167936, 2224254, 2232450, 2232450, 167936, 2232450, 90144, 0, 0, 94243, 0, 0, 0, 2211976, 102440, 0, 0, 106539, 98348, 0, 2158732, 2158732, 2158732, 2527372, 2535564, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 3109004, 2207744, 0, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 0, 2232450, 0, 0, 0, 0, 0, 0, 0, 0, 370, 0, 141, 2158732, 2158732, 2158732, 2564236, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2396300, 2404492, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2597004, 2777228, 2158732, 2801804, 2158732, 2158732, 2834572, 2158732, 2158732, 2158732, 2891916, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2670732, 2158732, 2687116, 2158732, 2695308, 2158732, 2703500, 2744460, 2158732, 2158732, 2158879, 2158879, 2597151, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2670879, 2158879, 2687263, 2158879, 2695455, 2158879, 2703647, 2744607, 2158879, 2158879, 2777375, 2158879, 2801951, 2158879, 2158879, 2834719, 2158879, 2158879, 2158879, 2892063, 2158879, 2158879, 2158879, 0, 2158879, 2158879, 2158879, 0, 2158879, 2900255, 2158879, 2158879, 2158879, 2969887, 2158879, 2158879, 646, 0, 2158592, 0, 2158732, 2158732, 2158732, 2379916, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2556044, 2158732, 2158732, 2158732, 2158732, 2158732, 2588812, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2633868, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2982028, 2158732, 2158732, 2207744, 2207744, 2473984, 2207744, 2207744, 2207744, 0, 546, 0, 548, 0, 0, 2170880, 0, 0, 554, 0, 2158879, 2158879, 2158879, 2380063, 2158879, 2158879, 2158879, 2158879, 2158879, 3010847, 2158879, 3035423, 2158879, 2158879, 2158879, 2158879, 3072287, 2158879, 2158879, 3105055, 2158879, 2556191, 2158879, 2158879, 2158879, 2158879, 2158879, 2588959, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2634015, 2158879, 2158879, 2158879, 2158879, 2699551, 2724127, 2158879, 2158879, 2158879, 2814239, 2818335, 2158879, 2887967, 2158879, 2158879, 2916639, 2158732, 2691212, 2158732, 2158732, 2158732, 2158732, 2158732, 2740364, 2748556, 2769036, 2793612, 2158732, 2158732, 2158732, 2855052, 2883724, 3178636, 2158732, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2433024, 2437120, 2207744, 2207744, 2207744, 0, 0, 0, 0, 0, 0, 2166784, 0, 0, 0, 0, 57344, 288, 2158879, 2158879, 2158879, 2613535, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2691359, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2576671, 2158879, 2601247, 2158879, 2158879, 2621727, 2158879, 2158879, 2158879, 2740511, 2748703, 2769183, 2793759, 2158879, 2158879, 2158879, 2855199, 2883871, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 3178783, 2158879, 0, 0, 0, 0, 0, 2859148, 2158732, 2896012, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 3006604, 2158732, 2158732, 3043468, 2679071, 2158879, 2707743, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2859295, 2158879, 2896159, 2158879, 2158879, 2158879, 22, 0, 358, 0, 0, 0, 0, 0, 0, 0, 2211840, 0, 0, 2158879, 2158879, 2158879, 3141919, 2158879, 2158879, 3162399, 3166495, 2158879, 0, 0, 0, 2158732, 2158732, 2158732, 2158732, 2433164, 2437260, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2494604, 2158732, 2158732, 2158732, 2158732, 2416780, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2523276, 2158732, 2158732, 2158732, 3072140, 2158732, 2158732, 3104908, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2207744, 2207744, 2207744, 2379776, 2207744, 2207744, 2887820, 2158732, 2158732, 2916492, 2158732, 2158732, 2965644, 2158732, 2973836, 2158732, 2158732, 2994316, 2158732, 3039372, 3055756, 3068044, 2158879, 2158879, 2965791, 2158879, 2973983, 2158879, 2158879, 2994463, 2158879, 3039519, 3055903, 3068191, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 3006751, 2158879, 2158879, 3043615, 2158879, 2158879, 3092767, 2158879, 2158879, 3113247, 2158879, 2158879, 2158879, 3195167, 0, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2465932, 2158732, 2158732, 2158732, 3149964, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2465792, 2207744, 2207744, 2486272, 2486412, 2158732, 2158732, 2158732, 2515084, 2519180, 2158732, 2158732, 2568332, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2572428, 2158732, 2158732, 2158732, 2158732, 2613388, 2158732, 2158732, 2158732, 2158732, 2158732, 3088524, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 3096716, 2158732, 2158732, 2207744, 2207744, 3149824, 0, 0, 0, 0, 0, 0, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2433311, 2437407, 2158879, 2158879, 2466079, 2158879, 2158879, 2486559, 2158879, 2158879, 2158879, 2515231, 2519327, 2158879, 2158879, 2568479, 2158879, 2158879, 2158879, 2158879, 2158879, 2425119, 2158879, 2445599, 2453791, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2502943, 2158879, 2158879, 3031327, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 3150111, 0, 2367628, 2371724, 2158732, 2158732, 2412684, 2158732, 2441356, 2158732, 2158732, 2158732, 2490508, 2158732, 2158732, 2158732, 2158732, 2560140, 2158732, 2584716, 2617484, 2158732, 2158732, 2621580, 2158732, 2158732, 2158732, 2678924, 2158732, 2707596, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 3195020, 2207744, 2207744, 2207744, 2207744, 2207744, 2416640, 2207744, 2207744, 2666636, 2728076, 2158732, 2158732, 2158732, 2904204, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 3100812, 2158732, 2158732, 2773132, 2785420, 2158732, 2809996, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 3010700, 2158732, 3035276, 2158732, 3125388, 3137676, 3145868, 2367488, 2371584, 2207744, 2207744, 2412544, 2207744, 2441216, 2207744, 2207744, 2207744, 2490368, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 3088384, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 0, 0, 0, 168216, 281, 0, 2162688, 0, 2207744, 2207744, 2207744, 2207744, 2207744, 3100672, 2207744, 2207744, 3125248, 3137536, 3145728, 2367775, 2371871, 2158879, 2158879, 2412831, 2158879, 2441503, 2158879, 2158879, 2158879, 2490655, 2158879, 2158879, 0, 2158879, 2158879, 2560287, 2158879, 2584863, 2617631, 2158879, 2158879, 2158879, 2158879, 3096863, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2773279, 2785567, 2158879, 2810143, 2158879, 2158879, 2158879, 2158879, 2666783, 0, 0, 2728223, 2158879, 2158879, 0, 2158879, 2904351, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 3088671, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 0, 40978, 0, 22, 22, 0, 2224254, 358, 2232450, 2158879, 3100959, 2158879, 2158879, 3125535, 3137823, 3146015, 2158732, 2400396, 2408588, 2158732, 2457740, 2158732, 2158732, 2158732, 2158732, 2625676, 2650252, 2732172, 2736268, 2826380, 2941068, 2158732, 2977932, 2158732, 2990220, 2158732, 2158732, 2158732, 3121292, 2207744, 2400256, 2408448, 2207744, 2457600, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2625536, 2650112, 2732032, 2736128, 2826240, 2940928, 2207744, 2977792, 2207744, 2990080, 2207744, 2207744, 2207744, 3121152, 2158879, 2400543, 2408735, 2158879, 2457887, 2158879, 2158879, 2158879, 2158879, 0, 0, 2158879, 2158879, 2158879, 2158879, 2625823, 2650399, 0, 0, 0, 0, 98, 98, 98, 1105, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1381, 0, 0, 46, 46, 46, 46, 2732319, 2736415, 0, 2826527, 2941215, 2158879, 2978079, 2158879, 2990367, 2158879, 2158879, 2158879, 3121439, 2158732, 2158732, 2470028, 3108864, 2158879, 2158879, 2470175, 2158879, 2158879, 2158879, 0, 0, 2527519, 2535711, 2158879, 2158879, 2158879, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2158732, 2158732, 2158732, 2158732, 2158732, 2502796, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2576524, 2158732, 2601100, 0, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 3109151, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2158732, 2900108, 2158732, 2158732, 2158732, 2969740, 2158732, 2158732, 2158732, 2158732, 3031180, 2158732, 2158732, 2158732, 2609292, 2158732, 2158732, 2158732, 2158732, 2699404, 2723980, 2158732, 2158732, 2158732, 2814092, 2818188, 2158732, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2981888, 2207744, 2207744, 2158879, 2158879, 2474271, 2158879, 2158879, 0, 0, 0, 0, 98, 98, 1104, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1499, 98, 98, 98, 98, 98, 2564096, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2158879, 2158879, 2158879, 2158879, 0, 0, 0, 2158879, 2158879, 2158879, 2158879, 0, 0, 0, 2158879, 2158879, 2158879, 2982175, 2158879, 2158879, 2158732, 2158732, 3092620, 2158732, 2158732, 3113100, 2158732, 2158732, 2158732, 3141772, 2158732, 2158732, 3162252, 3166348, 2158732, 2359296, 2564383, 2158879, 2158879, 0, 0, 2158879, 2158879, 2158879, 2158879, 2158879, 2158732, 2420876, 2158732, 2506892, 2158732, 2580620, 2158732, 2830476, 2158732, 2158732, 2158732, 3002508, 2207744, 2420736, 2207744, 2506752, 2207744, 2580480, 2207744, 2830336, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2424832, 2207744, 2445312, 2453504, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 0, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2473984, 2158592, 2158592, 2207744, 3002368, 2158879, 2421023, 2158879, 2507039, 0, 0, 2158879, 2580767, 2158879, 0, 2830623, 2158879, 2158879, 2158879, 2158879, 2158879, 2494751, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2572575, 2158879, 3002655, 2158732, 2498700, 2158732, 2158732, 2158732, 2158732, 2158732, 2207744, 2498560, 2207744, 2207744, 2207744, 2207744, 2207744, 2158879, 2158879, 2158879, 2396447, 2404639, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2158879, 2523423, 2158879, 2158879, 2158879, 2158879, 2158879, 2609439, 2498847, 0, 0, 2158879, 2158879, 0, 2158879, 2158879, 2158879, 2375820, 2158732, 2158732, 2158732, 2158732, 2998412, 2375680, 2207744, 2207744, 2207744, 2207744, 2998272, 2375967, 0, 0, 2158879, 2158879, 2158879, 2158879, 2998559, 2158732, 2629772, 2945164, 0, 2531615, 2158879, 2158732, 2207744, 0, 2158879, 2158732, 2207744, 0, 2158879, 2158732, 2207744, 0, 2158879, 2957452, 2957312, 2957599, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 98, 1321, 98, 0, 141, 0, 2359296, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2424832, 2158592, 2445312, 2453504, 2158592, 2158592, 2158592, 3141632, 2158592, 2158592, 3162112, 3166208, 2158592, 0, 141, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 40978, 0, 22, 22, 25, 25, 127, 128, 2207744, 2207744, 2207744, 3194880, 546, 0, 0, 0, 546, 0, 548, 0, 0, 0, 548, 0, 0, 1317, 0, 0, 0, 0, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1112, 2207744, 2207744, 3149824, 546, 0, 548, 0, 554, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 40978, 40978, 45076, 241664, 22, 22, 24, 24, 24, 24, 28, 28, 28, 28, 90144, 0, 0, 94243, 0, 0, 204800, 2211840, 102440, 0, 0, 106539, 98348, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 3010560, 2158592, 3035136, 2158592, 2158592, 2158592, 2158592, 3072000, 2158592, 2158592, 3104768, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2772992, 2785280, 2158592, 2809856, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2207744, 2207744, 2207744, 2379776, 2207744, 2207744, 32768, 0, 2158592, 0, 2158592, 2158592, 2158592, 2379776, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3088384, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 40978, 40978, 0, 0, 22, 22, 24, 24, 24, 24, 28, 28, 28, 28, 90144, 0, 40978, 40978, 45076, 0, 22, 22, 24, 127, 24, 24, 28, 131203, 28, 28, 90144, 53533, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 614, 68, 68, 68, 24852, 24852, 12566, 12566, 0, 57893, 0, 0, 0, 53533, 53533, 371, 288, 369, 29319, 371, 0, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1202, 46, 46, 25402, 546, 13116, 548, 57893, 0, 0, 54078, 54078, 554, 0, 98, 98, 98, 98, 98, 98, 848, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 0, 0, 46, 46, 46, 1385, 98, 642, 0, 0, 0, 925, 29319, 0, 0, 0, 0, 46, 46, 46, 46, 46, 46, 1186, 46, 46, 46, 46, 46, 46, 0, 1480, 0, 0, 0, 0, 1319, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 629, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1531, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1756, 46, 46, 46, 98, 642, 0, 924, 0, 925, 29319, 0, 0, 0, 0, 46, 46, 46, 46, 46, 1185, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 24852, 24852, 12566, 12566, 0, 57893, 283, 0, 0, 53533, 53533, 371, 288, 53534, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 615, 2158592, 2158592, 3031040, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3149824, 225280, 2367488, 2371584, 2158592, 2158592, 2412544, 0, 40978, 40978, 45076, 0, 123, 124, 24, 24, 24, 24, 28, 28, 28, 28, 90144, 2158592, 2158592, 2158592, 4243812, 127, 127, 0, 0, 0, 0, 0, 0, 0, 2211840, 0, 0, 0, 0, 1102, 98, 98, 98, 98, 98, 1108, 98, 98, 98, 98, 98, 98, 1623, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1177, 0, 925, 0, 0, 0, 0, 133, 94243, 0, 0, 0, 39, 102440, 0, 0, 106539, 98348, 28811, 46, 46, 46, 46, 1221, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 413, 46, 46, 46, 46, 147, 151, 46, 46, 46, 46, 46, 176, 46, 181, 46, 187, 46, 190, 46, 46, 46, 68, 210, 68, 68, 68, 224, 68, 68, 68, 68, 68, 68, 68, 68, 68, 25402, 1086, 13116, 1090, 54078, 1094, 0, 204, 46, 46, 68, 68, 214, 218, 68, 68, 68, 68, 68, 243, 68, 248, 68, 68, 68, 68, 68, 98, 0, 2039, 98, 98, 98, 98, 98, 46, 46, 46, 46, 1404, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1411, 254, 68, 257, 68, 68, 271, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 53533, 98, 98, 98, 294, 298, 98, 98, 98, 98, 98, 323, 98, 328, 98, 334, 98, 337, 98, 98, 351, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 141, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3194880, 2207744, 2207744, 2207744, 2207744, 2207744, 2416640, 2207744, 2207744, 46, 46, 441, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 710, 46, 369, 29319, 371, 649, 46, 46, 46, 46, 46, 46, 46, 46, 46, 660, 46, 46, 46, 68, 211, 68, 68, 68, 226, 68, 68, 240, 68, 68, 68, 251, 46, 713, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 725, 46, 46, 46, 46, 1234, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 233, 68, 68, 68, 68, 68, 68, 68, 495, 68, 68, 68, 68, 68, 68, 68, 68, 0, 0, 0, 0, 0, 282, 95, 0, 46, 46, 730, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 1873, 68, 68, 68, 68, 68, 747, 68, 68, 68, 68, 68, 68, 68, 68, 68, 760, 68, 68, 68, 68, 68, 68, 1067, 68, 68, 68, 68, 68, 1072, 68, 68, 68, 68, 68, 68, 751, 752, 68, 68, 68, 68, 759, 68, 68, 68, 68, 68, 68, 508, 68, 68, 510, 68, 68, 513, 68, 68, 68, 0, 0, 0, 0, 0, 0, 98, 98, 1614, 98, 98, 98, 98, 98, 847, 98, 98, 98, 98, 853, 98, 98, 98, 98, 98, 353, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 68, 68, 68, 68, 797, 68, 68, 800, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1446, 68, 68, 68, 68, 68, 68, 68, 812, 68, 68, 68, 68, 68, 817, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1589, 68, 68, 68, 68, 68, 68, 25402, 546, 13116, 548, 57893, 0, 0, 54078, 54078, 554, 834, 98, 98, 98, 98, 98, 98, 865, 98, 98, 98, 98, 98, 98, 98, 98, 872, 98, 98, 98, 98, 845, 98, 98, 98, 98, 98, 98, 98, 98, 98, 858, 98, 0, 0, 0, 0, 925, 29319, 0, 0, 0, 0, 46, 46, 46, 46, 46, 46, 1663, 46, 46, 46, 46, 46, 46, 46, 46, 46, 675, 46, 46, 46, 46, 46, 46, 98, 98, 98, 98, 98, 895, 98, 98, 898, 98, 98, 98, 98, 98, 98, 98, 0, 0, 0, 22, 22, 24, 24, 127, 28, 98, 98, 98, 910, 98, 98, 98, 98, 98, 915, 98, 98, 98, 98, 98, 98, 0, 0, 98, 1787, 98, 98, 98, 98, 0, 0, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1017, 68, 68, 1020, 68, 68, 68, 1079, 68, 68, 68, 68, 68, 25402, 1085, 13116, 1089, 54078, 1093, 0, 0, 94243, 0, 0, 0, 39, 102440, 0, 0, 106539, 98348, 0, 46, 46, 46, 46, 381, 46, 46, 46, 390, 46, 46, 46, 46, 46, 46, 46, 1392, 46, 1394, 46, 46, 46, 46, 46, 46, 46, 1545, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1408, 46, 46, 46, 46, 46, 98, 1114, 98, 98, 98, 98, 98, 98, 1122, 98, 98, 98, 98, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 98, 98, 98, 98, 98, 1173, 98, 98, 98, 98, 98, 0, 925, 0, 1179, 0, 0, 94243, 0, 0, 0, 39, 102440, 0, 0, 106539, 98348, 28811, 46, 46, 46, 46, 699, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1002, 46, 46, 1005, 1006, 68, 68, 1255, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 481, 68, 68, 68, 68, 68, 68, 1297, 68, 68, 68, 68, 68, 68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2359583, 2158879, 2158879, 98, 98, 98, 98, 1327, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 925, 0, 0, 0, 1335, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 617, 98, 98, 98, 98, 98, 1368, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1178, 925, 0, 1179, 0, 98, 98, 1377, 98, 98, 98, 98, 98, 98, 0, 1179, 0, 46, 46, 46, 46, 46, 1222, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 689, 46, 46, 46, 46, 46, 68, 68, 1438, 68, 68, 1442, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 1712, 98, 1451, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1458, 68, 68, 68, 68, 0, 0, 0, 1477, 0, 1086, 0, 0, 0, 1479, 0, 1090, 98, 98, 1491, 98, 98, 1495, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1331, 98, 98, 98, 98, 1504, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1513, 98, 98, 98, 98, 0, 46, 46, 46, 46, 46, 1537, 46, 46, 46, 46, 46, 996, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 185, 46, 46, 46, 46, 203, 98, 1648, 98, 98, 98, 98, 98, 98, 98, 98, 0, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1541, 0, 98, 98, 98, 98, 0, 1940, 0, 98, 98, 98, 98, 98, 98, 46, 46, 2011, 46, 46, 46, 2015, 68, 68, 2017, 68, 68, 68, 2021, 98, 68, 68, 68, 68, 813, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 0, 0, 0, 0, 0, 0, 0, 0, 98, 98, 98, 98, 98, 911, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1372, 98, 98, 98, 98, 68, 68, 68, 1244, 68, 68, 68, 68, 1248, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1603, 1605, 68, 68, 68, 1608, 68, 98, 1324, 98, 98, 98, 98, 1328, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 0, 0, 46, 46, 46, 46, 98, 98, 98, 98, 1378, 98, 98, 98, 98, 0, 1179, 0, 46, 46, 46, 46, 46, 1390, 46, 1393, 46, 46, 46, 46, 1398, 46, 46, 46, 68, 68, 1923, 68, 1925, 68, 68, 1927, 68, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 98, 1985, 46, 46, 46, 46, 46, 46, 1391, 46, 46, 1395, 46, 46, 46, 46, 46, 46, 171, 46, 46, 46, 46, 46, 46, 46, 46, 46, 688, 46, 46, 46, 46, 46, 46, 0, 98, 98, 98, 1939, 0, 0, 0, 98, 1943, 98, 98, 1945, 98, 46, 46, 46, 68, 212, 68, 68, 68, 68, 68, 68, 241, 68, 68, 68, 68, 68, 68, 68, 1970, 98, 98, 98, 1974, 0, 0, 0, 98, 68, 68, 258, 68, 68, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 98, 338, 98, 98, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 140, 2158592, 2158592, 2158592, 2158592, 3096576, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2555904, 2158592, 2158592, 2158592, 2158592, 2158592, 377, 46, 46, 46, 46, 46, 46, 46, 46, 391, 46, 396, 46, 46, 400, 46, 46, 46, 731, 733, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1581, 68, 46, 403, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1400, 68, 68, 461, 463, 68, 68, 68, 68, 68, 68, 68, 68, 477, 68, 482, 68, 68, 68, 68, 68, 98, 2038, 0, 98, 98, 98, 98, 98, 2044, 46, 46, 46, 157, 46, 46, 46, 46, 46, 46, 46, 46, 46, 193, 46, 46, 46, 158, 46, 46, 172, 46, 46, 46, 46, 46, 46, 46, 46, 46, 737, 46, 68, 68, 68, 68, 68, 68, 68, 486, 68, 68, 489, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 0, 0, 0, 1306, 0, 98, 98, 558, 560, 98, 98, 98, 98, 98, 98, 98, 98, 574, 98, 579, 98, 0, 0, 0, 0, 925, 29319, 0, 0, 0, 0, 46, 46, 46, 46, 936, 98, 583, 98, 98, 586, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 925, 0, 0, 930, 369, 29319, 371, 0, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 663, 68, 68, 795, 796, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1459, 68, 68, 860, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 889, 873, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 905, 98, 98, 98, 893, 894, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 925, 0, 1179, 0, 46, 993, 994, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 951, 46, 68, 68, 68, 1284, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1607, 68, 68, 98, 1364, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 921, 98, 46, 1556, 1557, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1203, 46, 1596, 1597, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 775, 98, 98, 98, 1621, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 885, 98, 98, 98, 98, 98, 1740, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1549, 46, 46, 46, 46, 46, 68, 98, 98, 98, 98, 98, 98, 1836, 0, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 1984, 98, 46, 46, 46, 46, 46, 46, 1546, 46, 46, 46, 46, 46, 46, 46, 46, 46, 987, 46, 46, 46, 46, 46, 46, 46, 46, 1909, 46, 46, 46, 46, 46, 46, 46, 68, 1917, 68, 1918, 68, 68, 68, 68, 68, 68, 1247, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1447, 68, 68, 1450, 68, 68, 1922, 68, 68, 68, 68, 68, 68, 68, 98, 1930, 98, 1931, 98, 0, 0, 0, 0, 0, 29319, 0, 0, 0, 0, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 457, 46, 0, 98, 98, 1938, 98, 0, 0, 0, 98, 98, 98, 98, 98, 98, 46, 46, 46, 68, 213, 68, 68, 68, 68, 232, 236, 242, 246, 68, 68, 68, 68, 68, 68, 815, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1057, 1058, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 0, 0, 98, 98, 98, 2006, 98, 98, 98, 98, 0, 46, 46, 46, 46, 1536, 46, 46, 46, 46, 1540, 46, 2045, 68, 68, 68, 2047, 0, 0, 98, 98, 98, 2051, 46, 46, 68, 68, 0, 0, 94243, 0, 0, 0, 39, 102440, 0, 0, 106539, 98348, 28811, 46, 46, 142, 1836, 98, 98, 46, 68, 0, 98, 46, 68, 0, 98, 46, 68, 0, 98, 46, 46, 46, 732, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1691, 53533, 98, 98, 98, 98, 98, 98, 98, 98, 98, 317, 98, 98, 98, 98, 98, 98, 896, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1149, 98, 98, 98, 98, 98, 68, 68, 462, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 514, 68, 68, 68, 487, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 500, 98, 98, 559, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 611, 98, 98, 98, 584, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 597, 46, 46, 939, 46, 46, 46, 46, 943, 46, 46, 46, 46, 46, 46, 46, 46, 388, 46, 46, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 1015, 68, 68, 68, 68, 1019, 68, 68, 68, 68, 68, 465, 68, 68, 68, 469, 68, 68, 480, 68, 68, 484, 68, 1077, 68, 68, 68, 68, 68, 68, 68, 25402, 0, 13116, 0, 54078, 0, 0, 0, 46, 46, 46, 46, 1184, 46, 46, 46, 46, 1188, 46, 46, 46, 46, 1389, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 948, 46, 46, 46, 46, 1113, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 922, 1129, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1128, 98, 1169, 98, 1171, 98, 98, 98, 98, 98, 98, 98, 0, 925, 0, 1179, 0, 0, 94243, 0, 0, 0, 39, 102440, 0, 0, 106539, 98348, 28811, 46, 46, 144, 68, 68, 1243, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 537, 68, 68, 1281, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 501, 1323, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1142, 46, 1412, 46, 46, 46, 46, 46, 46, 46, 1418, 46, 46, 46, 46, 46, 46, 446, 46, 46, 46, 46, 46, 46, 46, 46, 46, 671, 46, 46, 46, 46, 46, 46, 46, 46, 46, 961, 46, 46, 46, 46, 965, 46, 98, 98, 98, 98, 98, 1520, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1500, 98, 98, 1503, 98, 98, 98, 98, 1741, 98, 98, 98, 46, 46, 46, 46, 46, 46, 46, 46, 46, 450, 46, 46, 46, 46, 46, 46, 68, 68, 68, 1924, 68, 68, 68, 68, 68, 98, 98, 98, 98, 98, 0, 0, 98, 98, 1983, 98, 98, 46, 46, 1987, 46, 1988, 46, 0, 98, 98, 98, 98, 0, 0, 0, 1942, 98, 98, 98, 98, 98, 46, 46, 46, 68, 1683, 68, 68, 68, 1686, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1274, 68, 68, 68, 68, 68, 68, 148, 46, 154, 46, 46, 167, 46, 177, 46, 182, 46, 46, 189, 192, 197, 46, 46, 46, 940, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1552, 46, 46, 205, 46, 46, 68, 68, 215, 68, 221, 68, 68, 234, 68, 244, 68, 249, 68, 68, 68, 68, 68, 492, 494, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1263, 68, 68, 68, 68, 68, 68, 256, 259, 264, 68, 272, 68, 68, 0, 24852, 12566, 0, 0, 0, 283, 28811, 53533, 98, 98, 98, 295, 98, 301, 98, 98, 314, 98, 324, 98, 329, 98, 98, 0, 0, 1896, 98, 98, 98, 98, 98, 98, 1903, 46, 46, 46, 46, 165, 169, 175, 179, 46, 46, 46, 46, 46, 195, 46, 46, 336, 339, 344, 98, 352, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 141, 2158592, 2158592, 2158592, 0, 2158592, 2158592, 2158592, 0, 2158592, 2899968, 2158592, 2158592, 2158592, 2969600, 2158592, 2158592, 402, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 417, 46, 46, 46, 956, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 414, 46, 46, 46, 68, 68, 68, 488, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1778, 98, 98, 68, 503, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 515, 68, 68, 68, 68, 68, 527, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1700, 68, 68, 68, 541, 68, 68, 24852, 24852, 12566, 12566, 0, 57893, 283, 0, 0, 53533, 53533, 371, 288, 98, 98, 98, 585, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 902, 98, 98, 98, 98, 600, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 612, 98, 0, 0, 0, 0, 925, 29319, 0, 0, 0, 0, 46, 46, 46, 935, 46, 46, 46, 969, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1421, 46, 46, 46, 638, 98, 98, 22, 127, 127, 131431, 0, 642, 0, 0, 0, 0, 366, 0, 0, 0, 46, 46, 46, 1183, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1916, 68, 68, 68, 68, 68, 369, 29319, 371, 0, 652, 46, 654, 46, 655, 46, 657, 46, 46, 46, 661, 46, 46, 46, 981, 982, 46, 46, 46, 46, 46, 46, 989, 46, 46, 46, 46, 46, 1405, 1406, 46, 46, 46, 46, 1409, 46, 46, 46, 46, 46, 1415, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 723, 724, 46, 46, 46, 46, 46, 46, 682, 46, 684, 46, 46, 46, 46, 46, 46, 46, 46, 692, 693, 695, 744, 68, 68, 68, 748, 68, 68, 68, 68, 68, 68, 68, 68, 68, 761, 68, 68, 68, 68, 68, 528, 68, 68, 68, 68, 68, 68, 68, 68, 539, 540, 68, 68, 68, 765, 68, 68, 68, 68, 769, 68, 771, 68, 68, 68, 68, 68, 68, 68, 530, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1262, 68, 68, 68, 68, 68, 68, 68, 68, 68, 779, 780, 782, 68, 68, 68, 68, 68, 68, 789, 790, 68, 68, 68, 68, 68, 68, 1271, 68, 68, 68, 68, 68, 68, 1277, 68, 68, 68, 68, 68, 68, 1287, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1777, 68, 98, 98, 98, 793, 794, 68, 68, 68, 68, 68, 68, 68, 802, 68, 68, 68, 806, 68, 68, 68, 68, 68, 68, 1298, 68, 68, 68, 68, 0, 0, 0, 0, 0, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1111, 98, 25402, 546, 13116, 548, 57893, 0, 0, 54078, 54078, 554, 0, 837, 98, 839, 98, 840, 98, 842, 98, 98, 98, 846, 98, 98, 98, 98, 98, 98, 98, 98, 98, 859, 98, 98, 98, 98, 863, 98, 98, 98, 98, 867, 98, 869, 98, 98, 98, 98, 0, 46, 1533, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1224, 46, 46, 46, 46, 46, 46, 46, 46, 387, 46, 46, 46, 46, 46, 46, 46, 98, 98, 98, 98, 877, 878, 880, 98, 98, 98, 98, 98, 98, 887, 888, 98, 0, 0, 0, 0, 925, 29319, 0, 0, 0, 0, 46, 933, 46, 46, 46, 68, 68, 1684, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 475, 68, 68, 68, 68, 98, 891, 892, 98, 98, 98, 98, 98, 98, 98, 900, 98, 98, 98, 904, 98, 0, 0, 0, 0, 925, 29319, 0, 0, 0, 0, 932, 46, 46, 46, 46, 46, 1953, 46, 1955, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1689, 68, 68, 68, 923, 642, 0, 0, 0, 925, 29319, 0, 0, 0, 0, 46, 46, 46, 46, 46, 46, 1674, 46, 1676, 46, 46, 46, 46, 46, 46, 46, 411, 46, 46, 46, 46, 46, 46, 46, 46, 1810, 46, 46, 46, 46, 46, 46, 68, 46, 46, 955, 46, 957, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 429, 46, 46, 46, 46, 1021, 68, 1023, 68, 68, 68, 68, 68, 68, 1031, 68, 1033, 68, 68, 68, 68, 0, 1476, 0, 0, 0, 0, 0, 1478, 0, 0, 0, 0, 0, 0, 0, 1100, 98, 98, 98, 98, 98, 98, 98, 98, 1380, 0, 0, 0, 46, 46, 46, 46, 68, 68, 1065, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 823, 68, 68, 68, 68, 1078, 68, 68, 1081, 1082, 68, 68, 25402, 0, 13116, 0, 54078, 0, 0, 0, 46, 46, 1182, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1189, 98, 98, 1115, 98, 1117, 98, 98, 98, 98, 98, 98, 1125, 98, 1127, 98, 98, 0, 98, 98, 1796, 98, 98, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 1744, 46, 46, 46, 98, 98, 98, 98, 1159, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 925, 926, 1179, 0, 98, 98, 98, 98, 1172, 98, 98, 1175, 1176, 98, 98, 0, 925, 0, 1179, 0, 0, 94243, 0, 0, 0, 39, 102440, 0, 0, 106539, 98348, 28811, 46, 46, 145, 46, 46, 1218, 46, 46, 46, 1223, 46, 46, 46, 46, 46, 46, 46, 1230, 46, 46, 46, 1206, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1213, 46, 46, 46, 68, 68, 1283, 68, 68, 68, 68, 68, 68, 68, 1290, 68, 68, 68, 68, 68, 68, 68, 768, 68, 68, 68, 68, 68, 68, 68, 68, 68, 532, 68, 68, 68, 68, 68, 68, 68, 68, 1295, 68, 68, 68, 68, 68, 68, 68, 68, 0, 0, 0, 0, 0, 0, 2162688, 0, 98, 98, 98, 1326, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 919, 98, 98, 98, 98, 98, 98, 1338, 98, 1340, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1628, 98, 98, 98, 98, 1363, 98, 98, 98, 98, 98, 98, 98, 1370, 98, 98, 98, 98, 98, 98, 98, 592, 98, 98, 98, 98, 98, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 1799, 98, 98, 46, 46, 46, 1375, 98, 98, 98, 98, 98, 98, 98, 98, 0, 1179, 0, 46, 46, 46, 46, 46, 1427, 46, 46, 68, 68, 68, 68, 68, 68, 68, 1435, 68, 68, 68, 1463, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 758, 68, 68, 68, 98, 98, 98, 1518, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1139, 98, 98, 98, 46, 1542, 46, 46, 46, 46, 46, 46, 46, 1548, 46, 46, 46, 46, 46, 1554, 46, 1570, 1571, 46, 68, 68, 68, 68, 68, 68, 1578, 68, 68, 68, 68, 68, 68, 68, 816, 68, 68, 68, 68, 822, 68, 68, 68, 1582, 68, 68, 68, 68, 68, 68, 68, 1588, 68, 68, 68, 68, 68, 1594, 68, 68, 68, 68, 68, 750, 68, 68, 68, 68, 68, 68, 68, 68, 68, 762, 1610, 1611, 68, 1476, 0, 1478, 0, 1480, 0, 98, 98, 98, 98, 98, 98, 1618, 98, 98, 98, 98, 98, 1622, 98, 98, 98, 98, 98, 98, 98, 1629, 98, 98, 0, 1728, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 46, 1802, 46, 1647, 1649, 98, 98, 98, 1652, 98, 1654, 1655, 98, 0, 46, 46, 46, 1658, 46, 46, 46, 1220, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 708, 709, 46, 46, 1845, 98, 98, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 46, 46, 674, 46, 46, 46, 46, 678, 46, 46, 68, 68, 68, 68, 68, 1881, 98, 98, 98, 98, 98, 0, 0, 0, 98, 98, 98, 98, 98, 1902, 46, 46, 46, 46, 46, 46, 1908, 46, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1921, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 98, 0, 0, 0, 98, 98, 0, 98, 1937, 98, 98, 1940, 0, 0, 98, 98, 98, 98, 98, 98, 1947, 1948, 1949, 46, 46, 46, 1952, 46, 1954, 46, 46, 46, 46, 1959, 1960, 1961, 68, 68, 68, 68, 68, 68, 1443, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 756, 68, 68, 68, 68, 68, 68, 1964, 68, 1966, 68, 68, 68, 68, 1971, 1972, 1973, 98, 0, 0, 0, 98, 98, 46, 68, 0, 98, 46, 68, 0, 98, 2064, 2065, 0, 2066, 46, 98, 1978, 98, 0, 0, 1981, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 686, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1957, 46, 68, 68, 68, 68, 68, 98, 0, 0, 2025, 98, 8192, 98, 98, 2029, 46, 46, 46, 46, 46, 46, 68, 68, 68, 1575, 68, 68, 68, 68, 68, 68, 68, 68, 68, 819, 68, 68, 68, 68, 68, 68, 46, 68, 68, 68, 68, 0, 2049, 98, 98, 98, 98, 46, 46, 68, 68, 0, 0, 94243, 0, 0, 0, 39, 102440, 0, 0, 106539, 98348, 28811, 46, 46, 146, 53533, 98, 98, 289, 98, 98, 98, 98, 98, 98, 318, 98, 98, 98, 98, 98, 98, 912, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 0, 930, 46, 46, 46, 46, 68, 68, 1050, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1034, 68, 1036, 98, 98, 98, 98, 1144, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 570, 98, 98, 98, 98, 98, 98, 98, 98, 1367, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 571, 98, 98, 98, 98, 68, 98, 98, 98, 98, 98, 98, 1837, 0, 98, 98, 98, 98, 98, 0, 0, 0, 1897, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 717, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1420, 46, 46, 46, 46, 98, 2010, 46, 46, 46, 46, 46, 46, 2016, 68, 68, 68, 68, 68, 68, 2022, 46, 2046, 68, 68, 68, 0, 0, 2050, 98, 98, 98, 46, 46, 68, 68, 0, 0, 94243, 0, 0, 0, 2211840, 0, 0, 0, 0, 0, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2572288, 2158592, 2158592, 2158592, 2158592, 2613248, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2691072, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 134, 94243, 0, 0, 0, 39, 102440, 0, 0, 106539, 98348, 28811, 46, 46, 46, 46, 1414, 46, 46, 46, 1417, 46, 1419, 46, 46, 46, 46, 46, 46, 1866, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1699, 68, 68, 68, 68, 369, 29319, 371, 650, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1214, 46, 46, 25402, 546, 13116, 548, 57893, 0, 0, 54078, 54078, 554, 835, 98, 98, 98, 98, 98, 98, 1134, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1344, 98, 98, 98, 1347, 98, 1569, 46, 46, 46, 1572, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 0, 0, 1305, 0, 0, 68, 68, 68, 1598, 68, 68, 68, 68, 68, 68, 68, 68, 1606, 68, 68, 1609, 98, 98, 98, 1650, 98, 98, 1653, 98, 98, 98, 0, 46, 46, 1657, 46, 46, 46, 159, 46, 46, 173, 46, 46, 46, 184, 46, 46, 46, 46, 202, 1703, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 1711, 98, 98, 0, 1794, 1795, 98, 98, 98, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 1745, 46, 46, 46, 1749, 46, 46, 46, 46, 46, 46, 46, 46, 1755, 46, 46, 46, 46, 46, 46, 1808, 46, 46, 46, 46, 46, 46, 46, 46, 68, 1430, 68, 68, 68, 68, 68, 68, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1767, 68, 68, 68, 0, 0, 0, 0, 0, 0, 98, 1613, 98, 98, 98, 98, 98, 98, 1717, 98, 0, 98, 98, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 1858, 46, 68, 68, 68, 68, 68, 1773, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 1886, 0, 0, 0, 98, 98, 68, 2035, 2036, 68, 68, 98, 0, 0, 98, 2041, 2042, 98, 98, 46, 46, 46, 46, 1426, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 252, 46, 152, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1682, 46, 206, 46, 68, 68, 68, 219, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 471, 68, 68, 68, 68, 68, 53533, 98, 98, 98, 98, 299, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 568, 98, 98, 98, 98, 98, 68, 522, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1075, 98, 619, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1141, 98, 46, 1232, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 1759, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1266, 46, 46, 155, 46, 163, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 676, 46, 46, 46, 46, 46, 207, 46, 68, 68, 68, 68, 222, 68, 230, 68, 68, 68, 68, 68, 68, 68, 68, 1273, 68, 68, 68, 68, 68, 68, 68, 68, 496, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 0, 0, 0, 1977, 53533, 98, 98, 98, 98, 98, 302, 98, 310, 98, 98, 98, 98, 98, 98, 98, 627, 98, 98, 98, 98, 98, 98, 98, 98, 849, 850, 98, 98, 98, 98, 857, 98, 98, 46, 404, 46, 46, 46, 46, 46, 46, 46, 412, 46, 46, 46, 46, 46, 46, 718, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1678, 46, 46, 46, 46, 46, 439, 46, 46, 443, 46, 46, 46, 46, 46, 449, 46, 46, 46, 456, 46, 46, 46, 160, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 415, 46, 46, 418, 68, 68, 68, 68, 490, 68, 68, 68, 68, 68, 68, 68, 498, 68, 68, 68, 0, 0, 0, 0, 0, 0, 1612, 98, 98, 98, 98, 98, 98, 0, 1785, 98, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 1789, 98, 98, 0, 0, 68, 68, 68, 525, 68, 68, 529, 68, 68, 68, 68, 68, 535, 68, 68, 68, 0, 1305, 0, 1311, 0, 1317, 98, 98, 98, 98, 98, 98, 98, 913, 98, 98, 98, 98, 98, 98, 98, 98, 593, 98, 98, 98, 98, 98, 98, 98, 542, 68, 68, 24852, 24852, 12566, 12566, 0, 57893, 0, 0, 0, 53533, 53533, 371, 288, 98, 98, 98, 98, 587, 98, 98, 98, 98, 98, 98, 98, 595, 98, 98, 98, 0, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 1646, 98, 98, 98, 622, 98, 98, 626, 98, 98, 98, 98, 98, 632, 98, 98, 98, 0, 98, 98, 98, 0, 98, 98, 98, 98, 1644, 98, 98, 98, 0, 98, 98, 98, 0, 98, 98, 1642, 98, 98, 98, 98, 98, 98, 1146, 1147, 98, 98, 98, 98, 98, 98, 98, 98, 1355, 98, 98, 98, 1358, 98, 98, 98, 639, 98, 98, 22, 127, 127, 131431, 0, 0, 0, 0, 0, 0, 366, 0, 0, 0, 46, 1181, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 690, 46, 46, 46, 46, 46, 46, 714, 46, 46, 46, 46, 46, 46, 722, 46, 46, 46, 46, 46, 46, 958, 46, 960, 46, 46, 46, 46, 46, 46, 46, 972, 46, 46, 46, 46, 46, 46, 46, 46, 46, 738, 739, 68, 741, 68, 742, 68, 890, 98, 98, 98, 98, 98, 98, 98, 98, 899, 98, 98, 98, 98, 98, 98, 98, 1742, 46, 46, 46, 46, 46, 46, 46, 1747, 907, 98, 98, 98, 98, 98, 98, 98, 98, 98, 916, 918, 98, 98, 98, 98, 0, 1532, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1550, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 1012, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 497, 68, 68, 68, 68, 68, 68, 68, 1024, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1048, 68, 68, 68, 68, 68, 68, 1066, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 0, 1303, 0, 0, 0, 68, 68, 68, 68, 1080, 68, 68, 68, 68, 25402, 0, 13116, 0, 54078, 0, 0, 0, 1101, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 884, 98, 98, 98, 98, 98, 98, 98, 98, 1118, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 572, 98, 98, 98, 98, 46, 46, 1219, 46, 46, 46, 46, 46, 46, 1226, 46, 46, 46, 46, 46, 46, 984, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1227, 46, 46, 46, 46, 46, 1241, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 517, 68, 1268, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1279, 68, 68, 68, 68, 68, 767, 68, 68, 68, 68, 68, 68, 68, 68, 774, 68, 68, 68, 68, 68, 798, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 787, 68, 68, 68, 792, 68, 68, 68, 1296, 68, 68, 68, 68, 68, 68, 68, 0, 0, 0, 0, 0, 0, 98, 98, 98, 98, 98, 1617, 98, 98, 98, 98, 1366, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1373, 98, 98, 0, 1895, 0, 98, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 685, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 451, 46, 46, 46, 46, 46, 98, 1376, 98, 98, 98, 98, 98, 98, 98, 0, 0, 0, 46, 46, 1384, 46, 46, 46, 1233, 46, 46, 46, 1236, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 1871, 68, 68, 68, 68, 46, 1423, 46, 46, 46, 46, 46, 46, 68, 68, 1431, 68, 68, 68, 68, 68, 68, 68, 1029, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1056, 68, 68, 68, 68, 68, 68, 1436, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 518, 68, 1452, 1453, 68, 68, 68, 68, 1456, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1825, 68, 68, 68, 68, 68, 1461, 68, 68, 68, 1464, 68, 1466, 68, 68, 68, 68, 68, 68, 1470, 68, 68, 68, 68, 68, 68, 1587, 68, 68, 68, 68, 68, 68, 68, 68, 1595, 1489, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1154, 98, 1505, 1506, 98, 98, 98, 98, 1510, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1148, 98, 98, 98, 98, 98, 98, 1516, 98, 98, 98, 1519, 98, 1521, 98, 98, 98, 98, 98, 98, 1525, 98, 98, 98, 22, 127, 127, 131431, 0, 0, 0, 643, 0, 134, 366, 0, 0, 0, 1313, 0, 0, 0, 1096, 1319, 0, 0, 0, 0, 98, 98, 98, 98, 98, 98, 98, 98, 1110, 98, 98, 98, 68, 68, 68, 68, 68, 1586, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 534, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1600, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 772, 68, 68, 68, 68, 98, 98, 1620, 98, 98, 98, 98, 98, 98, 98, 1627, 98, 98, 98, 98, 98, 98, 1160, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 1179, 0, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 1763, 68, 68, 68, 68, 68, 68, 68, 68, 68, 25402, 0, 13116, 0, 54078, 0, 0, 98, 98, 98, 1781, 98, 98, 0, 0, 98, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 98, 98, 98, 1791, 0, 1860, 46, 1862, 1863, 46, 1865, 46, 68, 68, 68, 68, 68, 68, 68, 68, 1875, 68, 1877, 1878, 68, 1880, 68, 98, 98, 98, 98, 98, 1887, 0, 1889, 98, 98, 98, 22, 127, 127, 131431, 0, 0, 364, 0, 0, 0, 366, 0, 0, 0, 1314, 0, 0, 0, 0, 0, 0, 0, 0, 0, 98, 98, 98, 98, 98, 98, 98, 1488, 98, 1893, 0, 0, 0, 98, 1898, 1899, 98, 1901, 98, 46, 46, 46, 46, 46, 2014, 46, 68, 68, 68, 68, 68, 2020, 68, 98, 1989, 46, 1990, 46, 46, 46, 68, 68, 68, 68, 68, 68, 1996, 68, 1997, 68, 68, 68, 68, 68, 814, 68, 68, 68, 68, 68, 68, 68, 68, 68, 825, 68, 68, 98, 98, 98, 98, 0, 0, 98, 98, 2005, 0, 98, 2007, 98, 98, 98, 22, 127, 127, 131431, 0, 642, 0, 0, 0, 0, 366, 0, 0, 0, 0, 98, 1103, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 852, 98, 98, 98, 98, 98, 0, 98, 98, 2056, 2057, 0, 2059, 46, 68, 0, 98, 46, 68, 0, 98, 46, 46, 46, 1388, 46, 46, 46, 46, 46, 46, 1396, 46, 46, 46, 46, 46, 46, 1913, 46, 46, 1915, 68, 68, 68, 68, 68, 68, 68, 68, 1468, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1929, 98, 98, 98, 98, 0, 0, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 1016, 68, 68, 68, 68, 68, 68, 68, 1054, 68, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 1932, 0, 0, 0, 134, 94243, 0, 0, 0, 39, 102440, 0, 0, 106539, 98348, 28811, 46, 46, 143, 68, 68, 260, 68, 68, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 53533, 98, 98, 290, 98, 98, 98, 304, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1162, 98, 98, 98, 1165, 98, 98, 98, 340, 98, 98, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 372, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 40978, 192512, 22, 258048, 24, 24, 127, 28, 68, 460, 68, 68, 68, 68, 68, 68, 68, 68, 68, 472, 479, 68, 68, 68, 68, 68, 68, 493, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 511, 68, 68, 68, 68, 68, 68, 68, 524, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 538, 68, 68, 68, 68, 68, 1027, 68, 68, 68, 68, 1032, 68, 68, 68, 68, 68, 68, 68, 1272, 68, 68, 68, 68, 68, 68, 68, 68, 68, 754, 68, 68, 68, 68, 68, 68, 98, 557, 98, 98, 98, 98, 98, 98, 98, 98, 98, 569, 576, 98, 98, 98, 0, 98, 98, 1639, 0, 1641, 98, 98, 98, 98, 98, 98, 98, 564, 98, 98, 98, 573, 98, 98, 98, 98, 98, 98, 621, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 635, 98, 0, 0, 0, 0, 925, 29319, 0, 0, 0, 931, 46, 46, 46, 46, 46, 971, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1397, 46, 46, 46, 46, 664, 665, 46, 46, 46, 46, 672, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1562, 46, 1564, 46, 46, 46, 46, 68, 68, 68, 1051, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1062, 98, 98, 98, 98, 98, 1145, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 594, 98, 98, 98, 98, 98, 98, 1156, 98, 98, 98, 98, 98, 98, 1161, 98, 98, 98, 98, 98, 1166, 98, 0, 0, 0, 0, 925, 29319, 0, 0, 930, 0, 46, 46, 46, 46, 46, 941, 46, 46, 944, 46, 46, 46, 46, 46, 46, 952, 68, 68, 68, 68, 1257, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 0, 1304, 0, 0, 0, 98, 98, 1337, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 634, 98, 98, 68, 1474, 68, 68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1320, 0, 835, 98, 98, 98, 98, 1529, 98, 98, 0, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 962, 46, 46, 46, 46, 68, 68, 68, 68, 1707, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 98, 0, 0, 0, 98, 1891, 1739, 98, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 46, 46, 46, 720, 46, 46, 46, 46, 46, 726, 46, 98, 98, 1894, 0, 0, 98, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 1993, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 786, 68, 68, 68, 68, 68, 68, 68, 1965, 68, 1967, 68, 68, 68, 98, 98, 98, 98, 0, 1976, 0, 98, 98, 46, 68, 0, 98, 46, 68, 2062, 98, 46, 68, 0, 98, 46, 98, 98, 1979, 0, 0, 98, 1982, 98, 98, 98, 1986, 46, 46, 46, 46, 46, 382, 46, 46, 46, 46, 46, 46, 397, 46, 46, 46, 68, 68, 2000, 98, 98, 98, 2002, 0, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 1798, 98, 98, 98, 46, 46, 46, 98, 0, 0, 98, 98, 0, 98, 98, 98, 46, 2030, 46, 46, 46, 46, 68, 68, 1574, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1045, 68, 68, 68, 68, 68, 2034, 68, 68, 68, 68, 98, 0, 0, 2040, 98, 98, 98, 98, 46, 46, 46, 46, 1558, 46, 46, 46, 46, 46, 46, 46, 46, 1566, 46, 46, 53533, 98, 98, 98, 98, 98, 98, 305, 98, 98, 319, 98, 98, 98, 98, 98, 98, 1174, 98, 98, 98, 98, 0, 925, 0, 0, 0, 28, 28, 131431, 0, 362, 0, 0, 366, 0, 369, 28811, 371, 141, 46, 46, 46, 46, 1662, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1212, 46, 46, 46, 46, 46, 440, 46, 46, 46, 46, 46, 447, 46, 46, 46, 46, 46, 46, 46, 46, 986, 46, 46, 46, 46, 46, 46, 991, 68, 68, 68, 68, 526, 68, 68, 68, 68, 68, 533, 68, 68, 68, 68, 68, 68, 68, 1068, 68, 68, 68, 1071, 68, 68, 68, 68, 98, 98, 98, 98, 623, 98, 98, 98, 98, 98, 630, 98, 98, 98, 98, 98, 98, 1353, 98, 98, 98, 98, 98, 98, 98, 98, 1362, 46, 46, 666, 46, 46, 46, 46, 46, 46, 46, 46, 46, 677, 46, 46, 46, 46, 1673, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 452, 46, 46, 46, 46, 697, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 764, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1060, 68, 68, 98, 98, 98, 862, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1151, 1152, 98, 98, 68, 1064, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1830, 0, 1098, 0, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1332, 98, 98, 98, 98, 98, 98, 1158, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1359, 98, 98, 98, 1309, 0, 0, 0, 1315, 0, 0, 0, 0, 0, 0, 0, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 598, 46, 46, 1543, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1215, 46, 68, 1583, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 791, 68, 98, 98, 98, 1635, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 98, 1800, 98, 46, 46, 46, 98, 98, 1793, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 46, 46, 46, 1743, 46, 46, 46, 1746, 46, 68, 68, 68, 68, 269, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 53533, 98, 98, 291, 98, 98, 98, 306, 98, 98, 320, 98, 98, 98, 331, 98, 0, 0, 0, 0, 925, 29319, 0, 928, 0, 0, 46, 46, 46, 46, 46, 410, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 395, 46, 46, 46, 46, 46, 98, 98, 98, 349, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 0, 0, 0, 0, 0, 0, 0, 0, 28811, 0, 141, 46, 46, 46, 46, 444, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1228, 46, 46, 46, 46, 369, 29319, 371, 0, 46, 46, 46, 46, 46, 46, 46, 46, 659, 46, 46, 46, 46, 1752, 46, 46, 46, 1753, 1754, 46, 46, 46, 46, 46, 46, 170, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1563, 1565, 46, 46, 46, 1568, 68, 68, 746, 68, 68, 68, 68, 68, 68, 68, 68, 757, 68, 68, 68, 68, 68, 68, 68, 1467, 68, 68, 68, 68, 68, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 283, 28811, 98, 98, 98, 844, 98, 98, 98, 98, 98, 98, 98, 98, 855, 98, 98, 98, 0, 98, 1638, 98, 0, 98, 98, 98, 98, 98, 98, 98, 98, 1523, 98, 98, 98, 98, 98, 98, 98, 46, 46, 980, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1240, 68, 46, 46, 68, 68, 68, 1011, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 804, 68, 68, 68, 68, 1168, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 925, 0, 0, 0, 0, 0, 0, 2170880, 0, 0, 0, 0, 2158592, 2158592, 2158592, 2379776, 2158592, 1190, 46, 46, 1193, 1194, 46, 46, 46, 46, 46, 1199, 46, 1201, 46, 46, 46, 46, 1864, 46, 46, 68, 68, 1869, 68, 68, 68, 68, 1874, 68, 46, 1205, 46, 46, 46, 46, 46, 46, 46, 46, 1211, 46, 46, 46, 46, 46, 700, 46, 46, 46, 705, 46, 46, 46, 46, 46, 46, 942, 46, 46, 46, 46, 46, 46, 46, 46, 46, 945, 46, 947, 46, 46, 46, 46, 46, 1217, 46, 46, 46, 46, 46, 46, 1225, 46, 46, 46, 46, 1229, 46, 46, 46, 161, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1003, 46, 46, 46, 1254, 68, 68, 68, 68, 68, 1259, 68, 1261, 68, 68, 68, 68, 1265, 68, 68, 68, 68, 68, 68, 1696, 68, 68, 68, 68, 68, 68, 68, 1701, 68, 68, 68, 68, 68, 1285, 68, 68, 68, 68, 1289, 68, 68, 68, 68, 68, 68, 68, 68, 1457, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1775, 68, 68, 68, 98, 98, 98, 98, 98, 98, 98, 1339, 98, 1341, 98, 98, 98, 98, 1345, 98, 98, 98, 98, 98, 624, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 46, 1656, 46, 46, 46, 98, 98, 98, 98, 1351, 98, 98, 98, 98, 98, 98, 1357, 98, 98, 98, 98, 98, 625, 98, 98, 98, 98, 98, 98, 98, 98, 636, 637, 98, 98, 1365, 98, 98, 98, 98, 1369, 98, 98, 98, 98, 98, 98, 98, 98, 565, 98, 98, 98, 98, 98, 98, 580, 46, 46, 1403, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1399, 46, 46, 46, 1413, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1669, 46, 1422, 46, 46, 1425, 46, 46, 1428, 46, 1429, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 0, 0, 16384, 98, 68, 68, 1475, 68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 98, 98, 98, 98, 1486, 98, 1487, 98, 98, 98, 1530, 98, 0, 46, 46, 1534, 46, 46, 46, 46, 46, 46, 46, 46, 1197, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 1599, 68, 68, 1601, 68, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 98, 1933, 0, 1632, 98, 1634, 0, 98, 98, 98, 1640, 98, 98, 98, 1643, 98, 98, 1645, 98, 0, 0, 0, 0, 925, 29319, 0, 929, 0, 0, 46, 46, 46, 46, 46, 734, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 1579, 68, 68, 68, 68, 46, 46, 1660, 1661, 46, 46, 46, 46, 1665, 1666, 46, 46, 46, 46, 46, 1670, 1692, 1693, 68, 68, 68, 68, 68, 1697, 68, 68, 68, 68, 68, 68, 68, 1702, 98, 98, 1714, 1715, 98, 98, 98, 98, 0, 1721, 1722, 98, 98, 98, 98, 98, 98, 1496, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1163, 1164, 98, 98, 98, 98, 1726, 98, 0, 0, 98, 98, 98, 0, 98, 98, 98, 1734, 98, 98, 98, 98, 98, 864, 98, 98, 98, 98, 868, 98, 98, 98, 98, 98, 354, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 46, 46, 1750, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1681, 46, 0, 1846, 98, 98, 98, 98, 98, 98, 46, 46, 1854, 46, 46, 46, 46, 1859, 68, 68, 68, 1879, 68, 68, 98, 98, 1884, 98, 98, 0, 0, 0, 98, 98, 46, 68, 0, 98, 46, 68, 0, 98, 46, 68, 0, 98, 46, 1892, 98, 0, 0, 0, 98, 98, 98, 1900, 98, 98, 46, 46, 46, 46, 46, 701, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 946, 46, 46, 950, 46, 46, 68, 68, 68, 68, 68, 1926, 68, 68, 1928, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 1737, 98, 0, 98, 98, 98, 98, 0, 0, 0, 98, 98, 1944, 98, 98, 1946, 46, 46, 46, 162, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1410, 46, 46, 46, 98, 0, 0, 98, 2026, 0, 2027, 98, 98, 46, 46, 46, 46, 46, 46, 68, 1573, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1276, 68, 68, 68, 68, 149, 153, 156, 46, 164, 46, 46, 178, 180, 183, 46, 46, 46, 194, 198, 46, 46, 46, 1672, 46, 46, 46, 46, 46, 1677, 46, 1679, 46, 46, 46, 46, 166, 46, 46, 46, 46, 46, 46, 46, 46, 46, 200, 46, 68, 68, 261, 265, 68, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 53533, 98, 98, 98, 296, 300, 303, 98, 311, 98, 98, 325, 327, 330, 98, 98, 98, 22, 127, 127, 131431, 0, 642, 0, 0, 0, 0, 366, 0, 644, 98, 341, 345, 98, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 0, 0, 0, 0, 0, 0, 367, 0, 28811, 0, 141, 46, 46, 46, 46, 409, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1551, 46, 1553, 46, 46, 421, 46, 46, 46, 46, 46, 46, 46, 46, 46, 430, 46, 46, 437, 46, 46, 46, 1751, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 975, 46, 46, 46, 68, 68, 68, 68, 507, 68, 68, 68, 68, 68, 68, 68, 68, 68, 516, 68, 68, 68, 68, 68, 1246, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 474, 68, 68, 68, 68, 68, 523, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 536, 68, 68, 68, 68, 68, 68, 784, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 803, 68, 68, 68, 808, 68, 98, 98, 98, 98, 604, 98, 98, 98, 98, 98, 98, 98, 98, 98, 613, 98, 0, 0, 0, 0, 925, 29319, 927, 0, 0, 0, 46, 46, 46, 46, 46, 983, 46, 46, 46, 46, 988, 46, 46, 46, 46, 46, 670, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 428, 46, 46, 46, 46, 46, 98, 620, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 633, 98, 98, 98, 0, 1637, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1801, 46, 46, 369, 29319, 371, 0, 46, 653, 46, 46, 46, 46, 46, 658, 46, 46, 46, 46, 46, 1559, 46, 46, 1561, 46, 46, 46, 46, 46, 46, 46, 425, 46, 46, 46, 46, 46, 46, 46, 438, 728, 46, 46, 46, 46, 46, 46, 46, 46, 46, 68, 740, 68, 68, 68, 68, 68, 68, 68, 1774, 68, 68, 68, 68, 68, 98, 98, 98, 98, 0, 0, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 98, 68, 745, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 807, 68, 68, 68, 778, 68, 68, 783, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 821, 68, 68, 68, 68, 25402, 546, 13116, 548, 57893, 0, 0, 54078, 54078, 554, 0, 98, 838, 98, 98, 98, 0, 1980, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 174, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1416, 46, 46, 46, 46, 46, 46, 46, 46, 448, 46, 46, 46, 46, 46, 46, 46, 98, 98, 843, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 856, 98, 98, 98, 98, 98, 876, 98, 98, 881, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1330, 98, 98, 1333, 1334, 98, 978, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 419, 68, 68, 68, 68, 1040, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1264, 68, 68, 68, 1180, 0, 650, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 191, 46, 46, 98, 98, 98, 98, 98, 1379, 98, 98, 98, 0, 0, 0, 46, 1383, 46, 46, 46, 380, 46, 46, 46, 46, 46, 392, 46, 46, 46, 46, 46, 46, 702, 703, 46, 46, 706, 707, 46, 46, 46, 46, 68, 68, 68, 1454, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 773, 68, 68, 68, 98, 98, 98, 1507, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1524, 98, 98, 1527, 1619, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1631, 98, 1633, 98, 0, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 98, 866, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1727, 0, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 98, 914, 98, 98, 98, 98, 920, 98, 98, 46, 46, 1760, 68, 68, 68, 68, 68, 68, 68, 1765, 68, 68, 68, 68, 68, 68, 68, 1288, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1590, 68, 68, 68, 68, 68, 98, 98, 98, 98, 98, 1783, 0, 0, 98, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 98, 1790, 98, 0, 0, 1803, 46, 46, 46, 46, 1807, 46, 46, 46, 46, 46, 1813, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 237, 68, 68, 68, 68, 0, 0, 1305, 0, 0, 0, 0, 0, 1311, 0, 0, 0, 1317, 0, 0, 0, 0, 0, 0, 0, 98, 98, 1322, 68, 68, 1818, 68, 68, 68, 68, 1822, 68, 68, 68, 68, 68, 1828, 68, 68, 68, 68, 68, 68, 1882, 98, 98, 98, 98, 0, 0, 0, 98, 98, 98, 98, 98, 98, 46, 1904, 46, 1905, 46, 68, 98, 98, 98, 1833, 98, 98, 0, 0, 98, 98, 1840, 98, 98, 0, 0, 98, 98, 98, 0, 98, 98, 1733, 98, 1735, 98, 98, 98, 0, 98, 98, 98, 1849, 98, 98, 98, 46, 46, 46, 46, 46, 1857, 46, 46, 46, 407, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1815, 46, 68, 46, 1861, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 1872, 68, 68, 68, 68, 68, 68, 799, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1300, 0, 0, 0, 0, 0, 1876, 68, 68, 68, 68, 68, 98, 98, 98, 98, 98, 0, 0, 0, 1890, 98, 0, 0, 98, 98, 0, 98, 98, 98, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 1576, 68, 68, 68, 68, 1580, 68, 68, 1935, 98, 98, 98, 98, 0, 0, 0, 98, 98, 98, 98, 98, 98, 46, 46, 46, 46, 1906, 46, 68, 68, 68, 68, 2048, 0, 98, 98, 98, 98, 46, 46, 68, 68, 0, 0, 94243, 0, 0, 0, 2211840, 0, 0, 1122304, 0, 0, 0, 2158592, 2158592, 2158592, 2158592, 2700772, 2723840, 2158592, 2158592, 2158592, 2813952, 2819560, 2158592, 2887680, 2158592, 2158592, 2916352, 2158592, 2158592, 2965504, 2158592, 2973696, 2158592, 2158592, 2994176, 2158592, 3039232, 3055616, 3067904, 2158592, 2158592, 2158592, 2158592, 68, 68, 68, 68, 270, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 53533, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 332, 98, 0, 0, 98, 98, 0, 98, 98, 98, 46, 46, 46, 46, 2033, 46, 68, 68, 68, 68, 0, 0, 98, 98, 98, 98, 46, 46, 68, 68, 0, 98, 98, 98, 350, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 0, 0, 0, 0, 0, 0, 368, 0, 0, 0, 141, 2158592, 2158592, 2158592, 2158592, 2433024, 2437120, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2494464, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2572288, 2158592, 28, 28, 131431, 0, 363, 0, 0, 366, 0, 369, 28811, 371, 141, 46, 46, 46, 46, 1911, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 485, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 499, 68, 68, 68, 68, 68, 1258, 68, 1260, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1698, 68, 68, 68, 68, 68, 582, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 596, 98, 0, 0, 98, 98, 0, 98, 98, 98, 46, 46, 2031, 2032, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1769, 68, 967, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 458, 1037, 68, 68, 68, 68, 1041, 68, 1043, 68, 68, 68, 68, 68, 68, 68, 68, 68, 531, 68, 68, 68, 68, 68, 68, 0, 1099, 0, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 631, 98, 98, 98, 98, 98, 98, 1131, 98, 98, 98, 98, 1135, 98, 1137, 98, 98, 98, 98, 98, 98, 563, 98, 98, 98, 98, 98, 575, 98, 98, 98, 1310, 0, 0, 0, 1316, 0, 0, 0, 0, 1100, 0, 0, 0, 98, 98, 98, 98, 0, 0, 0, 98, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 1804, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 1919, 68, 1817, 68, 68, 1819, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 805, 68, 68, 68, 68, 98, 1832, 98, 98, 1834, 98, 0, 0, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 0, 1732, 98, 98, 98, 98, 98, 98, 98, 606, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1329, 98, 98, 98, 98, 98, 98, 0, 98, 98, 98, 98, 0, 0, 1941, 98, 98, 98, 98, 98, 98, 46, 46, 46, 422, 46, 46, 424, 46, 46, 427, 46, 46, 46, 46, 46, 46, 445, 46, 46, 46, 46, 46, 46, 455, 46, 46, 0, 135, 94243, 0, 0, 0, 39, 102440, 0, 0, 106539, 98348, 28811, 46, 46, 46, 68, 68, 68, 68, 68, 225, 68, 68, 239, 68, 68, 68, 68, 68, 68, 68, 1444, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1776, 68, 68, 98, 98, 98, 46, 46, 208, 68, 68, 68, 68, 68, 227, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 1975, 0, 0, 98, 53533, 98, 98, 98, 98, 98, 98, 307, 98, 98, 98, 98, 98, 98, 98, 98, 1343, 98, 98, 98, 98, 98, 98, 1348, 369, 29319, 371, 651, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 431, 46, 46, 46, 25402, 546, 13116, 548, 57893, 0, 0, 54078, 54078, 554, 836, 98, 98, 98, 98, 98, 98, 1509, 98, 98, 98, 98, 98, 98, 98, 98, 98, 0, 0, 0, 1382, 46, 46, 46, 68, 68, 68, 1695, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1047, 68, 68, 68, 150, 46, 46, 46, 46, 168, 46, 46, 46, 46, 186, 188, 46, 46, 199, 46, 46, 46, 1806, 46, 46, 46, 46, 46, 46, 1812, 46, 46, 46, 46, 68, 68, 68, 68, 68, 1577, 68, 68, 68, 68, 68, 68, 68, 509, 68, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 98, 0, 1934, 255, 68, 68, 266, 68, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 53533, 98, 98, 98, 297, 98, 98, 98, 98, 315, 98, 98, 98, 98, 333, 335, 98, 98, 346, 98, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 0, 360, 0, 0, 0, 0, 0, 0, 28811, 0, 141, 46, 46, 46, 46, 669, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1239, 46, 46, 46, 68, 46, 46, 406, 408, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 432, 46, 46, 46, 46, 46, 442, 46, 46, 46, 46, 46, 46, 46, 46, 453, 454, 46, 46, 46, 68, 68, 68, 68, 68, 228, 68, 68, 68, 68, 68, 68, 68, 68, 801, 68, 68, 68, 68, 68, 68, 809, 369, 29319, 371, 0, 46, 46, 46, 46, 46, 656, 46, 46, 46, 46, 46, 46, 997, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1547, 46, 46, 46, 46, 46, 46, 46, 46, 1664, 46, 46, 46, 46, 46, 46, 46, 46, 687, 46, 46, 46, 691, 46, 46, 696, 46, 681, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1758, 46, 729, 46, 46, 46, 46, 735, 46, 46, 46, 68, 68, 68, 68, 68, 743, 841, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1153, 98, 46, 938, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 201, 46, 46, 46, 968, 46, 970, 46, 973, 46, 46, 46, 46, 46, 46, 46, 46, 46, 736, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1770, 46, 979, 46, 46, 46, 46, 46, 985, 46, 46, 46, 46, 46, 46, 46, 46, 959, 46, 46, 46, 46, 46, 46, 46, 46, 389, 46, 46, 46, 46, 399, 46, 46, 46, 1007, 1008, 68, 68, 68, 68, 68, 1014, 68, 68, 68, 68, 68, 68, 68, 68, 468, 68, 68, 68, 68, 68, 68, 483, 68, 68, 1038, 68, 68, 68, 68, 68, 68, 1044, 68, 1046, 68, 1049, 68, 68, 68, 68, 68, 68, 1969, 68, 98, 98, 98, 98, 0, 0, 0, 98, 98, 46, 68, 0, 98, 2060, 2061, 0, 2063, 46, 68, 0, 98, 46, 98, 98, 98, 98, 1132, 98, 98, 98, 98, 98, 98, 1138, 98, 1140, 98, 1143, 1155, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1361, 98, 46, 1191, 46, 46, 46, 46, 46, 1196, 46, 46, 46, 46, 46, 46, 46, 46, 998, 46, 46, 46, 46, 46, 46, 46, 46, 999, 46, 1001, 46, 46, 46, 46, 46, 68, 68, 68, 1256, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1059, 68, 68, 68, 98, 1336, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1374, 98, 98, 98, 98, 98, 98, 1352, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 608, 98, 98, 98, 98, 98, 1386, 46, 1387, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 196, 46, 46, 46, 46, 1424, 46, 46, 46, 46, 46, 68, 68, 68, 68, 1433, 68, 1434, 68, 68, 68, 68, 68, 1286, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1293, 46, 46, 1805, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1814, 46, 46, 1816, 68, 68, 68, 68, 1820, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1829, 68, 68, 68, 68, 68, 1465, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 473, 68, 68, 68, 68, 68, 1831, 98, 98, 98, 98, 1835, 0, 0, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 1731, 98, 98, 98, 98, 98, 98, 98, 98, 98, 851, 98, 98, 98, 98, 98, 98, 0, 98, 98, 98, 98, 1850, 98, 98, 46, 46, 46, 46, 46, 46, 46, 46, 1407, 46, 46, 46, 46, 46, 46, 46, 46, 1956, 46, 46, 68, 68, 68, 68, 68, 1907, 46, 46, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 1920, 0, 1936, 98, 98, 98, 0, 0, 0, 98, 98, 98, 98, 98, 98, 46, 46, 46, 667, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 434, 46, 46, 46, 98, 0, 0, 98, 98, 0, 98, 2028, 98, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 68, 1687, 1688, 68, 68, 68, 68, 68, 68, 68, 1709, 68, 68, 68, 98, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 98, 98, 1843, 0, 46, 68, 68, 68, 68, 0, 0, 98, 98, 98, 98, 46, 46, 68, 68, 2054, 53533, 98, 98, 292, 98, 98, 98, 98, 98, 98, 321, 98, 98, 98, 98, 98, 98, 1784, 0, 98, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 98, 98, 98, 0, 1792, 46, 46, 379, 46, 46, 46, 383, 46, 46, 394, 46, 46, 398, 46, 46, 46, 68, 68, 68, 68, 68, 229, 68, 68, 68, 68, 68, 68, 68, 68, 1055, 68, 68, 68, 68, 68, 1061, 68, 68, 68, 504, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1251, 68, 68, 98, 98, 601, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 871, 98, 98, 98, 0, 364, 0, 0, 925, 29319, 0, 0, 0, 0, 46, 46, 934, 46, 46, 46, 668, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 679, 46, 46, 46, 68, 68, 1010, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1291, 68, 68, 68, 68, 68, 68, 68, 1052, 1053, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1301, 0, 0, 0, 1307, 1063, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1073, 68, 68, 68, 68, 68, 98, 0, 0, 98, 98, 98, 98, 98, 46, 46, 46, 2012, 2013, 46, 46, 68, 68, 68, 2018, 2019, 68, 68, 98, 98, 98, 1157, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1167, 68, 1282, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 824, 68, 46, 1402, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 401, 46, 68, 1462, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1035, 68, 98, 1517, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1515, 98, 98, 98, 98, 1636, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 98, 1511, 98, 98, 98, 98, 98, 98, 98, 68, 68, 1705, 68, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 98, 1842, 0, 0, 46, 46, 68, 68, 68, 1761, 68, 68, 68, 1764, 68, 68, 68, 68, 68, 68, 68, 68, 1602, 68, 1604, 68, 68, 68, 68, 68, 1779, 98, 98, 98, 1782, 98, 0, 0, 98, 98, 98, 98, 98, 98, 0, 0, 98, 98, 1788, 98, 98, 98, 0, 0, 0, 98, 1847, 98, 98, 98, 98, 98, 46, 46, 46, 46, 46, 46, 46, 46, 1675, 46, 46, 46, 46, 46, 46, 46, 46, 1237, 46, 46, 46, 46, 46, 46, 68, 68, 68, 68, 68, 68, 1968, 68, 68, 98, 98, 98, 98, 0, 0, 0, 98, 98, 46, 68, 2058, 98, 46, 68, 0, 98, 46, 68, 0, 98, 46, 68, 68, 98, 98, 2001, 98, 0, 0, 2004, 98, 98, 0, 98, 98, 98, 98, 1797, 98, 98, 98, 98, 98, 46, 46, 46, 68, 68, 262, 68, 68, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 53533, 98, 98, 293, 98, 98, 98, 98, 312, 316, 322, 326, 98, 98, 98, 98, 98, 879, 98, 98, 883, 98, 98, 98, 98, 98, 98, 98, 1121, 98, 98, 98, 98, 1126, 98, 98, 98, 98, 342, 98, 98, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 131431, 0, 0, 0, 0, 366, 0, 369, 28811, 371, 141, 46, 46, 46, 46, 716, 46, 46, 46, 721, 46, 46, 46, 46, 46, 46, 46, 673, 46, 46, 46, 46, 46, 46, 46, 46, 386, 393, 46, 46, 46, 46, 46, 46, 28, 28, 131431, 0, 0, 364, 0, 366, 0, 369, 28811, 371, 141, 373, 46, 46, 46, 683, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 694, 46, 46, 378, 46, 46, 46, 46, 384, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1809, 46, 1811, 46, 46, 46, 46, 46, 68, 46, 405, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 416, 46, 46, 46, 68, 68, 68, 1685, 68, 68, 68, 68, 68, 68, 68, 1690, 68, 420, 46, 46, 46, 46, 46, 46, 46, 426, 46, 46, 46, 433, 435, 46, 46, 46, 715, 46, 46, 46, 719, 46, 46, 46, 46, 46, 46, 46, 727, 459, 68, 68, 68, 464, 68, 68, 68, 68, 470, 68, 68, 68, 68, 68, 68, 68, 68, 1823, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1824, 68, 1826, 68, 68, 68, 68, 68, 68, 68, 68, 491, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 502, 68, 68, 68, 506, 68, 68, 68, 68, 68, 68, 68, 512, 68, 68, 68, 519, 521, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 520, 68, 543, 68, 24852, 24852, 12566, 12566, 0, 57893, 0, 0, 0, 53533, 53533, 371, 288, 556, 98, 98, 98, 561, 98, 98, 98, 98, 567, 98, 98, 98, 98, 98, 98, 590, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 917, 98, 98, 98, 98, 98, 98, 98, 98, 98, 588, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 599, 98, 98, 98, 603, 98, 98, 98, 98, 98, 98, 98, 609, 98, 98, 98, 616, 618, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1526, 98, 98, 640, 98, 22, 127, 127, 131431, 0, 0, 0, 0, 0, 0, 366, 0, 0, 0, 1481, 0, 1094, 0, 0, 98, 1483, 98, 98, 98, 98, 98, 98, 355, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 369, 29319, 371, 0, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 662, 46, 46, 46, 1910, 46, 1912, 46, 46, 1914, 46, 68, 68, 68, 68, 68, 68, 68, 68, 1069, 1070, 68, 68, 68, 68, 68, 68, 68, 68, 1083, 25402, 0, 13116, 0, 54078, 0, 0, 46, 698, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 436, 46, 68, 68, 68, 68, 749, 68, 68, 68, 68, 755, 68, 68, 68, 68, 68, 68, 68, 275, 0, 24852, 12566, 0, 0, 0, 0, 28811, 68, 68, 68, 68, 766, 68, 68, 68, 68, 770, 68, 68, 68, 68, 68, 68, 68, 467, 68, 68, 68, 476, 68, 68, 68, 68, 68, 68, 68, 68, 781, 68, 68, 785, 68, 68, 68, 68, 68, 68, 68, 68, 68, 818, 820, 68, 68, 68, 68, 68, 810, 811, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1074, 68, 98, 908, 909, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 903, 98, 98, 46, 954, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 963, 46, 46, 966, 992, 46, 46, 46, 995, 46, 46, 46, 46, 1000, 46, 46, 46, 46, 46, 46, 1195, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1238, 46, 46, 46, 46, 68, 68, 1022, 68, 68, 1026, 68, 68, 68, 1030, 68, 68, 68, 68, 68, 68, 68, 68, 753, 68, 68, 68, 68, 68, 68, 68, 68, 68, 25402, 1087, 13116, 1091, 54078, 1095, 0, 68, 68, 68, 1039, 68, 68, 1042, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1275, 68, 68, 68, 1278, 68, 1076, 68, 68, 68, 68, 68, 68, 68, 68, 25402, 0, 13116, 0, 54078, 0, 0, 0, 86016, 0, 0, 2211840, 102440, 0, 0, 0, 98348, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 20480, 40978, 0, 22, 22, 24, 24, 127, 28, 98, 98, 98, 1116, 98, 98, 1120, 98, 98, 98, 1124, 98, 98, 98, 98, 98, 562, 98, 98, 98, 566, 98, 98, 577, 98, 98, 581, 98, 98, 98, 98, 98, 1133, 98, 98, 1136, 98, 98, 98, 98, 98, 98, 98, 1342, 98, 98, 98, 98, 98, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 1725, 98, 98, 1170, 98, 98, 98, 98, 98, 98, 98, 98, 0, 925, 0, 0, 0, 0, 0, 2146304, 2146304, 2224128, 2224128, 2224128, 2224128, 2232320, 2232320, 2232320, 2232320, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2158592, 2158592, 2158592, 2158592, 2625536, 2650112, 2732032, 2736128, 2826240, 2940928, 2158592, 2977792, 2158592, 2990080, 2158592, 2158592, 1204, 46, 46, 46, 1207, 46, 46, 1209, 46, 1210, 46, 46, 46, 46, 46, 46, 1235, 46, 46, 46, 46, 46, 46, 46, 46, 68, 68, 68, 1432, 68, 68, 68, 68, 1231, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 68, 1868, 68, 1870, 68, 68, 68, 68, 68, 68, 1242, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1249, 68, 68, 68, 68, 68, 68, 273, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 1267, 68, 68, 1269, 68, 1270, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1280, 98, 1349, 98, 1350, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1360, 98, 98, 98, 22, 127, 127, 131431, 360, 642, 0, 0, 0, 0, 366, 0, 0, 0, 0, 98, 98, 98, 98, 1106, 98, 98, 98, 98, 98, 98, 98, 882, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1356, 98, 98, 98, 98, 98, 98, 1401, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 680, 68, 1437, 68, 1440, 68, 68, 68, 68, 1445, 68, 68, 68, 1448, 68, 68, 68, 68, 68, 68, 1028, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1302, 0, 0, 0, 1308, 1473, 68, 68, 68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 98, 98, 98, 1485, 98, 98, 98, 98, 98, 1490, 98, 1493, 98, 98, 98, 98, 1498, 98, 98, 98, 1501, 98, 98, 98, 22, 127, 127, 131431, 0, 0, 0, 0, 0, 0, 366, 0, 0, 1528, 98, 98, 98, 0, 46, 46, 46, 1535, 46, 46, 46, 46, 46, 46, 46, 1867, 68, 68, 68, 68, 68, 68, 68, 68, 0, 24853, 12567, 0, 0, 0, 0, 28811, 1555, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1567, 46, 46, 46, 1991, 1992, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1998, 98, 98, 98, 98, 1651, 98, 98, 98, 98, 98, 0, 46, 46, 46, 46, 46, 46, 46, 1539, 46, 46, 46, 68, 1704, 68, 1706, 68, 68, 68, 68, 68, 68, 68, 98, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 1841, 98, 0, 1844, 98, 98, 98, 98, 1716, 98, 98, 98, 0, 98, 98, 98, 98, 98, 98, 98, 1354, 98, 98, 98, 98, 98, 98, 98, 98, 1497, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1123, 98, 98, 98, 98, 98, 98, 1748, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1757, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1018, 68, 68, 68, 68, 68, 68, 1455, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1591, 68, 1593, 68, 68, 46, 46, 68, 68, 68, 68, 68, 1762, 68, 68, 68, 1766, 68, 68, 68, 68, 68, 68, 274, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 98, 98, 1780, 98, 98, 98, 0, 0, 1786, 98, 98, 98, 98, 98, 0, 0, 98, 98, 1730, 0, 98, 98, 98, 98, 98, 1736, 98, 1738, 68, 98, 98, 98, 98, 98, 98, 0, 1838, 98, 98, 98, 98, 98, 0, 0, 98, 1729, 98, 0, 98, 98, 98, 98, 98, 98, 98, 98, 1718, 0, 98, 98, 98, 98, 98, 98, 98, 46, 1853, 46, 1855, 46, 46, 46, 46, 46, 1950, 46, 46, 46, 46, 46, 46, 46, 46, 1958, 68, 68, 68, 1962, 68, 68, 68, 68, 68, 1585, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 98, 1710, 98, 98, 98, 1999, 68, 98, 98, 98, 98, 0, 2003, 98, 98, 98, 0, 98, 98, 2008, 2009, 46, 68, 68, 68, 68, 0, 0, 98, 98, 98, 98, 46, 2052, 68, 2053, 0, 0, 94243, 0, 0, 0, 2211840, 0, 1110016, 0, 0, 0, 0, 2158592, 2158733, 2158592, 2158592, 2158592, 3149824, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2207744, 2465792, 2207744, 2207744, 2486272, 0, 98, 2055, 46, 68, 0, 98, 46, 68, 0, 98, 46, 68, 16384, 98, 46, 46, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1768, 68, 68, 68, 68, 68, 68, 1708, 68, 68, 68, 68, 98, 98, 98, 98, 98, 98, 0, 0, 98, 98, 98, 98, 98, 0, 0, 68, 68, 68, 267, 68, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 53533, 98, 98, 98, 98, 98, 98, 98, 313, 98, 98, 98, 98, 98, 98, 98, 1522, 98, 98, 98, 98, 98, 98, 98, 98, 0, 98, 98, 98, 1724, 98, 98, 98, 98, 98, 347, 98, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 131431, 0, 0, 0, 0, 366, 0, 369, 28811, 371, 141, 46, 46, 375, 28, 28, 131431, 0, 0, 0, 365, 366, 0, 369, 28811, 371, 141, 46, 46, 46, 68, 68, 216, 220, 223, 68, 231, 68, 68, 245, 247, 250, 68, 68, 68, 544, 24852, 24852, 12566, 12566, 0, 57893, 0, 0, 0, 53533, 53533, 371, 288, 98, 98, 641, 22, 127, 127, 131431, 0, 0, 0, 0, 0, 0, 366, 0, 0, 0, 2359296, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2424832, 2158592, 2445312, 2453504, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2502656, 712, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 711, 68, 763, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1252, 68, 776, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 788, 68, 68, 68, 68, 68, 68, 466, 68, 68, 68, 68, 68, 478, 68, 68, 68, 98, 98, 861, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1346, 98, 98, 98, 874, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 886, 98, 98, 98, 22, 127, 127, 131431, 0, 0, 0, 0, 0, 0, 366, 221184, 0, 953, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1216, 68, 68, 68, 68, 1245, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1469, 68, 68, 1472, 98, 98, 1325, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1502, 98, 98, 68, 68, 1439, 68, 1441, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1592, 68, 68, 68, 98, 98, 1492, 98, 1494, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 901, 98, 98, 98, 906, 68, 68, 68, 2037, 68, 98, 0, 0, 98, 98, 98, 2043, 98, 46, 46, 46, 68, 68, 217, 68, 68, 68, 68, 235, 68, 68, 68, 68, 253, 53533, 98, 98, 98, 98, 98, 98, 308, 98, 98, 98, 98, 98, 98, 98, 98, 1720, 98, 98, 98, 98, 98, 98, 98, 68, 777, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1460, 68, 98, 98, 875, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1514, 98, 98, 68, 68, 263, 68, 68, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 98, 343, 98, 98, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 131431, 0, 0, 0, 0, 366, 0, 369, 28811, 371, 141, 46, 46, 376, 46, 46, 68, 1009, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1250, 68, 68, 1253, 1294, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 0, 0, 0, 0, 0, 0, 2162970, 0, 53533, 98, 98, 98, 98, 98, 98, 309, 98, 98, 98, 98, 98, 98, 98, 98, 1624, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1626, 98, 98, 98, 98, 98, 28, 28, 131431, 361, 0, 0, 0, 366, 0, 369, 28811, 371, 141, 46, 46, 46, 68, 209, 68, 68, 68, 68, 68, 68, 238, 68, 68, 68, 68, 68, 68, 68, 1299, 68, 68, 68, 0, 0, 0, 0, 0, 0, 98, 98, 98, 98, 1616, 98, 98, 68, 68, 505, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 1292, 68, 68, 98, 98, 602, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 21058, 98, 98, 1097, 0, 0, 0, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1150, 98, 98, 98, 98, 46, 46, 1192, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 964, 46, 46, 68, 68, 68, 268, 68, 68, 68, 68, 0, 24852, 12566, 0, 0, 0, 0, 28811, 98, 98, 348, 98, 98, 98, 98, 0, 40978, 0, 22, 22, 24, 24, 127, 28, 28, 131431, 0, 0, 0, 0, 366, 0, 369, 28811, 371, 141, 46, 374, 46, 46, 46, 1544, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 1004, 46, 46, 98, 1130, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1630, 98, 46, 46, 1671, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 46, 976, 977, 46, 0, 2158592, 2158880, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 3010560, 2158592, 3035136, 2158592, 0, 545, 0, 547, 0, 0, 2170880, 0, 0, 832, 0, 2158592, 2158592, 2158592, 2379776, 2158592, 2158592, 2158592, 3194880, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2465792, 2158592, 2158592, 2486272, 2158592, 2158592, 2158592, 2514944, 2519040, 2158592, 2158592, 2568192, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 68, 68, 68, 24852, 24852, 12566, 12566, 0, 0, 0, 0, 0, 53533, 53533, 0, 288, 0, 546, 0, 548, 57893, 0, 0, 0, 0, 554, 0, 98, 98, 98, 98, 98, 589, 591, 98, 98, 98, 98, 98, 98, 98, 98, 98, 98, 1371, 98, 98, 98, 98, 98, 139264, 139264, 139264, 139264, 139264, 139264, 139264, 139264, 139264, 139264, 139264, 139264, 0, 0, 139264, 0, 0, 94243, 0, 0, 0, 2211840, 102440, 0, 0, 106539, 98348, 0, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 2158592, 0, 40978, 0, 4243812, 4243812, 24, 24, 127, 28
];

XQueryTokenizer.EXPECTED =
[ 291, 299, 303, 294, 365, 308, 304, 312, 347, 317, 329, 325, 295, 320, 335, 331, 313, 341, 323, 345, 351, 355, 362, 369, 337, 373, 358, 377, 381, 385, 389, 393, 397, 401, 405, 443, 922, 625, 411, 778, 912, 625, 453, 516, 625, 904, 808, 625, 416, 677, 511, 625, 625, 626, 625, 625, 421, 625, 625, 625, 625, 625, 625, 625, 412, 450, 426, 417, 625, 430, 775, 780, 625, 645, 431, 625, 435, 711, 625, 441, 447, 465, 624, 460, 464, 463, 469, 473, 639, 477, 753, 545, 481, 485, 689, 489, 493, 498, 502, 509, 505, 504, 534, 515, 622, 527, 911, 633, 597, 625, 520, 522, 578, 526, 674, 636, 585, 584, 881, 531, 538, 542, 549, 553, 557, 561, 565, 569, 573, 940, 951, 960, 607, 606, 577, 686, 723, 625, 582, 746, 533, 589, 1013, 625, 595, 901, 802, 1018, 601, 605, 604, 611, 591, 615, 619, 630, 651, 655, 659, 663, 667, 671, 683, 693, 698, 705, 704, 797, 722, 709, 863, 625, 715, 407, 625, 721, 735, 869, 625, 727, 733, 760, 759, 739, 745, 750, 757, 764, 976, 768, 772, 979, 784, 694, 792, 790, 786, 875, 874, 625, 894, 647, 625, 920, 918, 625, 796, 893, 984, 801, 806, 437, 818, 929, 928, 812, 642, 816, 822, 826, 830, 834, 838, 842, 846, 850, 854, 858, 422, 862, 868, 867, 965, 873, 879, 700, 625, 885, 887, 625, 891, 898, 741, 625, 910, 916, 927, 926, 933, 1001, 937, 944, 948, 955, 964, 625, 625, 625, 969, 973, 983, 958, 456, 455, 625, 988, 906, 625, 994, 679, 625, 1000, 717, 494, 625, 1005, 729, 990, 1007, 1006, 996, 1011, 1017, 625, 625, 625, 625, 625, 625, 625, 443, 1022, 1026, 1030, 1059, 1064, 1064, 1064, 1095, 1063, 1034, 1038, 1042, 1046, 1059, 1059, 1059, 1059, 1118, 1100, 1054, 1058, 1089, 1064, 1064, 1064, 1105, 1076, 1081, 1117, 1076, 1177, 1073, 1099, 1206, 1059, 1059, 1091, 1064, 1087, 1059, 1059, 1059, 1060, 1064, 1075, 1111, 1059, 1059, 1063, 1064, 1109, 1076, 1115, 1122, 1059, 1147, 1064, 1064, 1070, 1077, 1064, 1132, 1136, 1204, 1083, 1074, 1145, 1059, 1091, 1065, 1125, 1059, 1148, 1064, 1064, 1050, 1101, 1116, 1142, 1177, 1152, 1138, 1158, 1154, 1175, 1161, 1165, 1060, 1064, 1172, 1181, 1062, 1185, 1128, 1089, 1066, 1189, 1061, 1193, 1197, 1090, 1201, 1168, 1210, 1214, 1218, 1222, 1226, 1230, 1234, 1239, 1411, 1497, 1238, 1894, 1245, 1331, 1331, 1251, 1421, 1249, 1331, 1331, 1331, 1269, 1239, 1331, 1331, 1331, 1283, 1964, 1331, 1331, 1331, 1294, 1274, 1331, 1331, 1279, 1283, 1331, 1331, 1331, 1307, 1951, 1311, 1331, 1331, 1369, 1824, 1712, 1336, 1331, 1331, 1412, 1331, 1331, 1713, 1337, 1331, 1275, 1862, 1331, 1255, 1331, 1331, 1338, 2055, 1331, 1347, 1331, 1331, 1354, 1348, 1331, 1331, 1331, 1343, 1314, 1360, 1331, 1355, 1352, 1331, 1313, 1359, 1911, 1915, 1324, 1913, 1374, 1321, 1687, 1385, 1241, 1503, 1381, 1655, 1382, 1383, 1398, 1393, 1397, 1331, 1331, 1331, 1376, 1402, 1331, 2039, 1899, 1331, 2038, 1331, 1331, 1417, 1331, 1331, 1413, 1408, 1331, 1331, 1451, 1331, 1426, 1331, 1331, 1331, 1420, 1590, 1461, 1331, 1331, 1470, 1475, 1476, 1331, 1331, 1331, 1437, 1331, 1856, 1502, 1331, 1331, 1331, 1486, 1938, 1495, 1331, 1289, 1293, 1331, 1291, 1331, 1366, 1331, 1322, 1944, 1501, 1331, 1508, 1324, 1871, 1511, 1516, 1869, 1694, 1524, 1697, 1515, 1529, 1522, 1528, 1533, 1539, 1546, 1533, 1553, 1561, 1562, 1464, 1566, 1573, 1577, 1581, 1610, 1331, 1331, 1331, 1471, 1331, 1633, 1331, 1331, 1535, 1491, 1331, 2056, 1641, 1331, 1331, 1569, 1331, 1583, 1654, 1331, 1331, 1606, 1445, 1663, 1331, 1331, 2073, 1323, 1331, 1331, 1331, 1595, 1610, 1669, 1331, 1331, 1676, 1331, 1684, 1331, 2067, 1686, 1331, 1981, 1331, 1433, 1361, 1331, 1331, 1331, 1331, 1263, 1763, 1331, 1971, 1331, 1441, 1987, 1331, 1324, 1490, 1331, 1324, 1913, 1331, 1294, 1843, 1331, 1303, 1331, 1331, 1368, 1805, 1691, 1324, 1331, 1991, 1990, 1328, 1326, 1989, 1325, 1555, 1992, 1988, 1555, 1555, 1328, 1329, 1557, 1327, 1467, 1702, 1330, 1331, 1709, 1331, 1480, 1484, 1331, 1332, 1331, 1331, 1362, 1740, 1331, 1815, 1798, 1331, 1485, 1617, 1331, 1384, 1389, 1240, 1814, 1331, 1331, 1331, 1620, 1549, 1747, 1331, 1331, 1665, 1978, 1331, 1741, 1717, 1331, 1331, 1331, 1732, 1331, 1331, 1705, 1318, 1331, 1754, 1331, 1331, 1735, 1331, 2062, 1723, 1331, 1331, 1331, 1629, 1331, 1772, 1331, 1331, 1757, 1331, 1331, 1779, 1331, 1331, 1767, 1331, 1331, 1825, 1331, 1331, 1775, 2012, 1448, 1331, 1331, 1331, 1637, 1785, 1331, 1786, 1331, 1504, 1671, 1454, 1331, 1784, 1331, 1331, 1780, 1331, 1331, 1785, 1331, 1785, 1613, 1790, 1749, 1749, 1725, 1748, 1724, 1728, 1331, 1542, 1287, 1331, 1270, 1331, 1331, 1324, 1299, 1750, 1726, 1331, 1331, 1795, 1331, 1331, 1838, 1331, 1331, 1839, 1807, 1370, 1331, 1331, 1331, 1643, 1819, 1331, 1331, 1331, 1659, 2006, 1820, 1331, 1331, 1882, 1257, 1830, 1331, 1503, 1836, 1331, 1849, 1331, 1331, 1916, 1829, 1625, 1331, 1623, 1887, 1331, 1624, 1331, 1853, 1331, 1860, 1331, 1860, 1879, 1866, 1698, 1925, 1877, 1881, 1924, 1880, 1886, 1879, 1892, 1898, 1903, 1904, 1650, 1908, 1921, 1457, 1929, 1933, 1429, 1331, 1331, 1518, 1331, 1937, 1517, 1943, 1948, 1331, 1331, 1331, 1745, 1331, 1955, 1331, 1331, 1331, 1768, 1963, 1331, 1331, 1331, 1801, 1331, 1295, 1968, 1331, 1331, 1939, 1496, 1719, 1985, 1331, 1331, 1996, 1361, 2000, 2004, 1331, 1331, 2007, 1612, 1331, 1331, 1774, 2011, 1331, 1584, 1323, 1331, 1411, 1331, 1331, 1339, 1331, 2016, 1987, 1331, 1331, 1331, 1422, 1679, 2020, 1331, 1331, 2021, 1811, 1331, 1331, 1845, 1412, 1331, 1680, 1331, 1331, 1331, 1917, 1830, 1259, 1421, 1331, 1265, 1331, 1832, 1421, 1331, 1588, 1331, 2051, 2031, 1331, 1831, 2032, 1672, 1331, 1873, 1331, 1594, 1331, 1599, 1873, 1964, 1888, 1331, 1600, 1331, 1331, 2045, 1604, 2036, 1331, 1331, 1331, 1959, 1331, 1974, 1331, 2027, 1331, 2050, 2043, 1331, 1613, 1331, 1727, 1791, 1748, 1749, 2049, 1331, 1331, 1331, 2005, 1331, 1738, 1331, 1331, 2060, 1331, 1916, 1762, 1331, 1331, 2066, 1331, 1760, 1331, 1331, 1331, 2025, 1377, 1331, 1331, 1331, 2061, 1331, 1331, 2071, 1331, 1331, 2067, 1647, 1404, 1331, 1331, 1331, 2072, 2084, 2828, 2077, 2081, 2093, 2152, 2104, 2549, 2112, 2121, 2400, 2125, 2133, 2133, 2138, 2147, 2276, 2841, 2845, 2847, 2846, 2308, 2151, 2104, 2362, 2196, 2156, 2126, 2134, 2243, 2161, 2275, 2297, 2185, 2195, 2200, 2157, 2126, 2126, 2126, 2126, 2127, 2133, 2133, 2133, 2133, 2296, 2176, 2242, 2213, 2275, 2174, 2174, 2844, 2174, 2174, 2174, 2174, 2306, 2844, 2174, 2174, 2847, 2845, 2174, 2217, 2230, 2126, 2126, 2128, 2133, 2133, 2133, 2133, 2133, 2241, 2272, 2174, 2846, 2174, 2174, 2174, 2169, 2133, 2133, 2134, 2261, 2266, 2274, 2174, 2174, 2277, 2247, 2306, 2174, 2174, 2174, 2845, 2174, 2174, 2846, 2174, 2847, 2174, 2176, 2174, 2849, 2173, 2289, 2126, 2133, 2260, 2242, 2265, 2273, 2275, 2174, 2174, 2278, 2126, 2134, 2270, 2276, 2174, 2280, 2126, 2126, 2133, 2133, 2133, 2848, 2848, 2174, 2174, 2288, 2174, 2133, 2133, 2294, 2174, 2289, 2126, 2126, 2171, 2174, 2174, 2181, 2126, 2133, 2294, 2296, 2175, 2288, 2849, 2848, 2174, 2174, 2307, 2174, 2173, 2174, 2126, 2126, 2133, 2295, 2175, 2178, 2288, 2850, 2174, 2180, 2133, 2133, 2174, 2286, 2848, 2173, 2180, 2126, 2295, 2176, 2848, 2174, 2304, 2174, 2174, 2279, 2126, 2177, 2172, 2181, 2127, 2133, 2284, 2174, 2181, 2293, 2301, 2289, 2129, 2179, 2312, 2312, 2312, 2321, 2325, 2329, 2333, 2337, 2233, 2575, 2345, 2349, 2484, 2206, 2397, 2366, 2204, 2206, 2206, 2206, 2107, 2201, 2468, 2206, 2397, 2202, 2614, 2203, 2206, 2206, 2099, 2760, 2206, 2506, 2206, 2204, 2206, 2206, 2141, 2955, 2206, 2505, 2206, 2206, 2142, 2939, 2394, 2206, 2206, 2206, 2205, 2206, 2616, 2411, 2206, 2206, 2768, 2593, 2415, 2420, 2206, 2769, 2594, 2416, 2315, 2254, 2206, 2206, 2206, 2969, 2601, 2206, 2206, 2206, 2375, 2919, 2733, 2595, 2317, 2256, 2732, 2981, 2316, 2255, 2978, 2595, 2426, 2432, 2427, 2433, 2206, 2206, 2206, 2977, 2087, 2425, 2431, 2437, 2206, 2108, 2201, 2206, 2206, 2206, 2350, 2206, 2206, 2353, 2206, 2206, 2206, 2206, 2202, 2252, 2449, 2206, 2206, 2206, 2207, 2377, 2730, 2980, 2250, 2431, 2978, 2982, 2448, 2205, 2206, 2693, 2205, 2206, 2206, 2206, 2978, 2088, 2087, 2812, 2548, 2206, 2206, 2206, 2225, 2100, 2461, 2206, 2206, 2207, 2631, 2809, 2825, 2374, 2465, 2206, 2206, 2207, 2974, 2206, 2478, 2206, 2206, 2107, 2206, 2206, 2374, 2478, 2483, 2206, 2206, 2482, 2374, 2206, 2206, 2489, 2374, 2206, 2489, 2206, 2490, 2586, 2503, 2206, 2206, 2209, 2206, 2515, 2520, 2205, 2206, 2203, 2206, 2206, 2206, 2190, 2191, 2516, 2521, 2206, 2205, 2206, 2206, 2206, 2204, 2531, 2540, 2546, 2206, 2206, 2455, 2892, 2554, 2527, 2533, 2542, 2553, 2526, 2532, 2541, 2355, 2708, 2712, 2535, 2532, 2536, 2548, 2206, 2206, 2495, 2206, 2206, 2504, 2206, 2099, 2460, 2201, 2439, 2815, 2888, 2711, 2534, 2546, 2206, 2206, 2620, 2350, 2206, 2352, 2206, 2206, 2704, 2708, 2558, 2558, 2562, 2205, 2206, 2206, 2206, 2706, 2710, 2560, 2564, 2206, 2206, 2206, 2355, 2525, 2708, 2568, 2573, 2206, 2206, 2568, 2584, 2206, 2206, 2206, 2360, 2600, 2373, 2206, 2206, 2206, 2374, 2459, 2206, 2969, 2723, 2206, 2206, 2718, 2607, 2719, 2723, 2206, 2206, 2206, 2421, 2900, 2490, 2722, 2206, 2206, 2350, 2606, 2206, 2720, 2724, 2206, 2350, 2350, 2721, 2206, 2206, 2350, 2708, 2718, 2388, 2723, 2206, 2206, 2731, 2980, 2206, 2718, 2722, 2206, 2206, 2737, 2742, 2605, 2611, 2206, 2206, 2351, 2206, 2206, 2353, 2718, 2222, 2206, 2718, 2220, 2387, 2351, 2386, 2206, 2206, 2779, 2813, 2387, 2389, 2206, 2389, 2388, 2388, 2206, 2386, 2390, 2388, 2206, 2206, 2354, 2674, 2678, 2206, 2626, 2206, 2206, 2354, 2707, 2635, 2206, 2206, 2206, 2444, 2636, 2206, 2206, 2206, 2471, 2645, 2650, 2206, 2206, 2356, 2709, 2641, 2646, 2651, 2206, 2206, 2206, 2497, 2667, 2655, 2373, 2206, 2206, 2784, 2206, 2206, 2854, 2947, 2951, 2206, 2206, 2662, 2669, 2657, 2206, 2661, 2668, 2656, 2206, 2778, 2669, 2116, 2670, 2117, 2206, 2206, 2374, 2747, 2668, 2115, 2574, 2206, 2206, 2878, 2951, 2678, 2201, 2206, 2206, 2476, 2206, 2778, 2676, 2813, 2682, 2201, 2206, 2206, 2374, 2918, 2206, 2690, 2814, 2206, 2206, 2206, 2340, 2354, 2691, 2201, 2206, 2206, 2894, 2944, 2939, 2206, 2777, 2692, 2206, 2206, 2206, 2477, 2206, 2702, 2814, 2206, 2206, 2968, 2096, 2206, 2206, 2206, 2439, 2352, 2351, 2351, 2206, 2206, 2977, 2981, 2206, 2368, 2716, 2206, 2206, 2978, 2595, 2252, 2743, 2205, 2206, 2206, 2374, 2928, 2753, 2206, 2206, 2206, 2492, 2206, 2206, 2206, 2493, 2376, 2749, 2205, 2206, 2224, 2378, 2206, 2225, 2379, 2206, 2206, 2206, 2738, 2375, 2748, 2754, 2206, 2206, 2206, 2491, 2206, 2206, 2374, 2759, 2754, 2206, 2225, 2380, 2206, 2226, 2380, 2206, 2206, 2206, 2697, 2206, 2438, 2764, 2206, 2206, 2773, 2766, 2206, 2206, 2374, 2929, 2935, 2206, 2438, 2775, 2206, 2206, 2206, 2496, 2206, 2206, 2206, 2496, 2206, 2494, 2206, 2206, 2493, 2206, 2797, 2802, 2206, 2236, 2728, 2206, 2207, 2798, 2803, 2809, 2825, 2206, 2206, 2381, 2792, 2808, 2820, 2373, 2206, 2237, 2205, 2206, 2206, 2807, 2819, 2188, 2206, 2206, 2821, 2206, 2206, 2206, 2498, 2807, 2819, 2206, 2206, 2206, 2499, 2955, 2855, 2832, 2206, 2206, 2382, 2793, 2206, 2856, 2833, 2206, 2206, 2386, 2206, 2206, 2838, 2857, 2834, 2206, 2861, 2948, 2206, 2350, 2580, 2569, 2862, 2949, 2206, 2206, 2410, 2206, 2206, 2438, 2868, 2206, 2350, 2970, 2724, 2206, 2206, 2341, 2206, 2869, 2206, 2206, 2866, 2950, 2206, 2206, 2206, 2506, 2867, 2951, 2206, 2206, 2206, 2505, 2438, 2874, 2206, 2206, 2438, 2372, 2873, 2206, 2206, 2206, 2510, 2439, 2950, 2206, 2439, 2950, 2878, 2206, 2879, 2206, 2350, 2979, 2089, 2453, 2206, 2206, 2206, 2226, 2807, 2439, 2201, 2879, 2439, 2869, 2206, 2206, 2439, 2442, 2440, 2883, 2485, 2885, 2885, 2885, 2887, 2899, 2206, 2206, 2206, 2579, 2568, 2900, 2206, 2206, 2206, 2590, 2912, 2904, 2685, 2206, 2350, 2979, 2596, 2909, 2913, 2905, 2686, 2206, 2917, 2921, 2810, 2405, 2206, 2206, 2206, 2615, 2923, 2403, 2205, 2206, 2354, 2698, 2206, 2206, 2961, 2965, 2922, 2811, 2406, 2206, 2354, 2780, 2813, 2164, 2811, 2547, 2206, 2206, 2206, 2352, 2206, 2206, 2206, 2353, 2375, 2929, 2165, 2938, 2206, 2927, 2920, 2810, 2957, 2206, 2206, 2206, 2629, 2807, 2819, 2935, 2956, 2205, 2206, 2206, 2206, 2895, 2933, 2937, 2939, 2206, 2206, 2206, 2630, 2143, 2940, 2206, 2206, 2441, 2206, 2499, 2955, 2205, 2206, 2206, 2206, 2506, 2206, 2206, 2443, 2511, 2206, 2206, 2787, 2206, 2206, 2443, 2640, 2206, 2788, 2206, 2206, 2206, 2636, 2472, 2206, 2206, 2206, 2666, 2206, 2622, 2206, 2206, 2206, 2758, 2207, 2206, 2206, 2206, 2777, 2208, 2206, 2206, 2206, 2778, 2682, 402653184, 554434560, 571736064, 545521856, 268451840, 335544320, 268693630, 256, 512, 1024, 2048, 4096, 16384, 524288, 8388608, 67108864, 0, 512, 512, 1024, 131072, 2097152, 0, 0, 8, 512, 2048, 1073741824, 1073741824, 1073741824, 0, 0, 8, 16384, 67108864, 524288, 537133056, 4194304, 1048576, 16777216, 33554432, 201326592, 268435456, 1073741824, 268435456, 0, 134217728, 16777216, 192, 16384, 16384, 16384, 16384, 67108864, 67108864, 8, 67108864, 67108864, 67108864, 67108864, 32, 16, 32, 4, 0, 0, 8, 1048576, 4194304, 33554432, 8192, 196608, 229376, 80, 512, 0, 2048, 2048, 1073741824, 0, 128, 64, 16384, 16384, 8192, 196608, 131072, 4096, 8192, 262144, 1048576, 6291456, 24584, 24592, 24576, 24576, 2, 24576, 24576, 24576, 24576, 8, 8, 24576, 24576, 16384, 16384, 16384, 1073741824, 1073741824, 0x80000000, 536870912, 0, 0, 0, 7, 2024, 32768, 536870912, 262144, 262144, 262144, 134217728, 262144, 134217728, 0, 0, 0, 0x80000000, 0, 0, 0, 0, 1, 0, 0, 8192, 131072, 131072, 4096, 24576, 536870912, 262144, 0, 0, 512, 2097152, 0, 0, 1, 8, 16, 128, 128, 128, 64, 16384, 0, 67108864, 0, 0, 2744, 57344, 51249152, 67108864, 32, 32, 4, 4, 0, 128, 16384, 16384, 16384, 32768, 524288, 1048576, 4194304, 8388608, 33554432, -872415232, 0, 0, 32, 32, 32, 32, 4, 4, 4, 4, 4, 4096, 32, 4, 4, 4096, 4096, 4096, 4096, 24576, 24576, 24576, 0, 16384, 16384, 16384, 67108864, 24576, 8, 8, 8, 24576, 24576, 24576, 16384, 16384, 67108864, 67108864, 67108864, 24576, 24576, 24576, 2048, 67108864, 8, 8, 24576, 24576, 24576, 24584, 24576, 24576, 24576, 16, 67108864, 8, 24576, 16384, 32768, 917504, 1048576, 4194304, 8388608, 67108864, 24576, 18, 16386, 67108866, 1073741826, 524546, 524547, 10, 34, 50462762, 10, 34, 6291458, 0x80000000, 0x80000000, -1326077970, 0, 16, 0, 0, 4194304, 33554432, 0, 524288, 1, 1, 257, 524289, 0, 0, 0, 2, 0, 0, 0, 3, 4, 8, 0, 896, 0, 0, 0x80000000, 536870912, 0, 14680064, 0, 0, -2096174408, -2096174408, 0, 1073741824, 0, 0, 0, 8, 16, 128, 2048, 0, 0, 0, 31, 155776, 0, 512, 0, 0, 0, 512, 0, 512, -824246498, -824246498, -824246498, 0, 0, 6291456, 0, 0, 33554432, 8388608, 33554432, 67108864, 1610612736, 0x80000000, 0, 0, 3870, 61440, -824311808, 0, 0, 16384, 32768, 1966080, 4194304, -830472192, -830472192, 0, 0, 0, 4728, 32768, 131072, 786432, 1048576, 4194304, 8388608, 4194304, 8388608, 33554432, 201326592, -1073741824, 0, -1073741824, 0, 0, 0, 16384, 131072, 0, 0, 0, 7, 64, 8388608, 33554432, 201326592, 1073741824, 0x80000000, 134217728, 0x80000000, 0, 0, -419548552, -419548552, 512, 2048, 16384, 8388608, 67108864, 134217728, 16384, 67108864, 134217728, 0, 1, 1, 1, 24, 128, 2048, 0, 0, 8, 16384, 134217728, 0, 0, 8, 16384, 0, 0, 0, 131072, 131072, 0, 8, 0, 0, 0, 262144, 0, 0, 0, 393216, 0, 0, 0, 1048576, -151025681, 0, 0, 0, 4194304, 0, 0, 7, 231400, 1996226560, 0x80000000, 0, 32768, 196608, 786432, 3145728, 12582912, 12582912, 33554432, 67108864, 1879048192, 0x80000000, 40, 64, 128, 1792, 32768, 196608, 32768, 196608, 262144, 524288, 3145728, 4194304, 67108864, 268435456, 536870912, 3145728, 4194304, 8388608, 67108864, 268435456, 536870912, 268435456, 536870912, 1073741824, 0x80000000, 0, 0, 2097152, 0, 3, 4, 40, 64, 1792, 196608, 262144, 3145728, 4194304, 67108864, 268435456, 1073741824, 0x80000000, 0, 1792, 196608, 262144, 2097152, 4194304, 4194304, 268435456, 1073741824, 0, 0, 256, 2, 8, 32, 64, 1792, 4194304, 1073741824, 0, 0, -151025681, -151025681, 2, 8, 0, 768, 3072, 4096, 8192, 16384, 32768, 131072, 1024, 196608, 2097152, 4194304, 1073741824, 2, 8, 0, 0, 768, 1024, 0, 512, 131072, 2097152, 4194304, 0, 0, 0, 3870, 2, 512, 0, 0, 1, 2048, 2132782151, 2132782151, 2132782151, 0, 1, 28, 128, 24576, 131072, 0, 1095, 43008, 2132738048, 0, 64, 1024, 2048, 8192, 32768, 32768, 65536, 131072, 262144, 521666560, 521666560, 536870912, 1073741824, 0, 0, 262144, 1048576, 50331648, 469762048, 1073741824, 0, 0, 3, 4, 64, 1024, 3, 64, 1024, 8192, 65536, 262144, 1048576, 16777216, 64, 1024, 8192, 262144, 1048576, 16777216, 33554432, 67108864, 262144, 16777216, 33554432, 67108864, -536870912, 0, 0, 0, 3, 64, 1024, 33554432, 67108864, 134217728, 1073741824, 3, 64, 67108864, 134217728, 0, 3, 64, 0, 0, 2, 4, 8, 32, 64, 128, 1792, 196608, 262144, 524288, -2096174408, 0, 0, 0, 2, 8, 512, 131072, 2097152, 0, 0, 0, 51249152, 0x80000000, 0, 0, 2, 12, 16, 512, 2048, 0, 24, 160, 512, 2048, 2048, 57344, 393216, 524288, 50331648, 16, 128, 512, 57344, 393216, 50331648, 393216, 50331648, 0x80000000, 0, 0, 8, 512, 16384, 32768, 393216, 50331648, 32768, 393216, 33554432, 0, 0, 0, 2, 28, 768, 0, 16384, 32768, 393216, 0, 0, 3, 64, 1024, 0, 0, 2130337951, 2130337951, 2130337951, 0, 1, 152, 2048, 0, 155776, 16252928, 2113929216, 0, 0, 1, 30, 128, 155648, 16252928, 16252928, 33554432, 1006632960, 1073741824, 0, 24576, 131072, 524288, 1048576, 6291456, 8388608, 33554432, 67108864, 134217728, 0, 0, 16384, 6291456, 8388608, 33554432, 469762048, 536870912, 0, 33554432, 469762048, 536870912, 1073741824, 0x80000000, 539754496, 542375936, 4194304, 8388608, 33554432, 402653184, 0, 0, 0, 8, 16, 24576, 24576, 24600, 24576, 24576, 24576, 24578, 24576, 24576, 24576, 2, 2, 2, 0, 16, 24576, 131072, 1048576, 4194304, 8388608, 0, 24576, 131072, 4194304, 8388608, 0, 16384, 131072, 8388608, 134217728, 268435456, 0, 16384, 131072, 134217728, 268435456, 0, 0, 16384, 131072, 134217728, 0, 131072, 0, 131072, 0, 131072, 131072, 0, 0, 16384, -419548552, 0, 0, 0, 8, 32, 64, 4728, 8265728, 109051904, -536870912, 0, 786432, 1048576, 6291456, 41943040, 67108864, 0, 8, 16, 608, 4096, 8192, 131072, 786432, 8, 16, 96, 512, 4096, 8192, 262144, 524288, 1048576, 6291456, 8, 16, 32, 64, 512, 4096, 512, 4096, 262144, 1048576, 4194304, 8388608, 33554432, 67108864, 536870912, 0x80000000, 0, 512, 4096, 1048576, 4194304, 8388608, 33554432, 134217728, 268435456, 0, 0, 0, 4194304, 33554432, 67108864, 536870912, 1073741824, 0x80000000, 0, 155648, 155648, 155648, 2201, 2201, 108697, 0, 2, 8, 768, 1024, 131072, 8, 16, 2048, 0, 2, 12, 512, 2048, 4096, 8192, 16384, 524288
];

XQueryTokenizer.TOKEN =
[
  "(0)",
  "ModuleDecl",
  "Annotation",
  "OptionDecl",
  "Operator",
  "Variable",
  "Tag",
  "EndTag",
  "PragmaContents",
  "DirCommentContents",
  "DirPIContents",
  "CDataSectionContents",
  "AttrTest",
  "Wildcard",
  "EQName",
  "IntegerLiteral",
  "DecimalLiteral",
  "DoubleLiteral",
  "PredefinedEntityRef",
  "'\"\"'",
  "EscapeApos",
  "QuotChar",
  "AposChar",
  "ElementContentChar",
  "QuotAttrContentChar",
  "AposAttrContentChar",
  "NCName",
  "QName",
  "S",
  "CharRef",
  "CommentContents",
  "DocTag",
  "DocCommentContents",
  "EOF",
  "'!'",
  "'\"'",
  "'#)'",
  "''''",
  "'('",
  "'(#'",
  "'(:'",
  "'(:~'",
  "')'",
  "'*'",
  "'*'",
  "','",
  "'-->'",
  "'.'",
  "'/'",
  "'/>'",
  "':'",
  "':)'",
  "';'",
  "'<!--'",
  "'<![CDATA['",
  "'<?'",
  "'='",
  "'>'",
  "'?>'",
  "'NaN'",
  "'['",
  "']'",
  "']]>'",
  "'after'",
  "'all'",
  "'allowing'",
  "'ancestor'",
  "'ancestor-or-self'",
  "'and'",
  "'any'",
  "'append'",
  "'array'",
  "'as'",
  "'ascending'",
  "'at'",
  "'attribute'",
  "'base-uri'",
  "'before'",
  "'boundary-space'",
  "'break'",
  "'by'",
  "'case'",
  "'cast'",
  "'castable'",
  "'catch'",
  "'check'",
  "'child'",
  "'collation'",
  "'collection'",
  "'comment'",
  "'constraint'",
  "'construction'",
  "'contains'",
  "'content'",
  "'context'",
  "'continue'",
  "'copy'",
  "'copy-namespaces'",
  "'count'",
  "'decimal-format'",
  "'decimal-separator'",
  "'declare'",
  "'default'",
  "'delete'",
  "'descendant'",
  "'descendant-or-self'",
  "'descending'",
  "'diacritics'",
  "'different'",
  "'digit'",
  "'distance'",
  "'div'",
  "'document'",
  "'document-node'",
  "'element'",
  "'else'",
  "'empty'",
  "'empty-sequence'",
  "'encoding'",
  "'end'",
  "'entire'",
  "'eq'",
  "'every'",
  "'exactly'",
  "'except'",
  "'exit'",
  "'external'",
  "'first'",
  "'following'",
  "'following-sibling'",
  "'for'",
  "'foreach'",
  "'foreign'",
  "'from'",
  "'ft-option'",
  "'ftand'",
  "'ftnot'",
  "'ftor'",
  "'function'",
  "'ge'",
  "'greatest'",
  "'group'",
  "'grouping-separator'",
  "'gt'",
  "'idiv'",
  "'if'",
  "'import'",
  "'in'",
  "'index'",
  "'infinity'",
  "'inherit'",
  "'insensitive'",
  "'insert'",
  "'instance'",
  "'integrity'",
  "'intersect'",
  "'into'",
  "'is'",
  "'item'",
  "'json'",
  "'json-item'",
  "'key'",
  "'language'",
  "'last'",
  "'lax'",
  "'le'",
  "'least'",
  "'let'",
  "'levels'",
  "'loop'",
  "'lowercase'",
  "'lt'",
  "'minus-sign'",
  "'mod'",
  "'modify'",
  "'module'",
  "'most'",
  "'namespace'",
  "'namespace-node'",
  "'ne'",
  "'next'",
  "'no'",
  "'no-inherit'",
  "'no-preserve'",
  "'node'",
  "'nodes'",
  "'not'",
  "'object'",
  "'occurs'",
  "'of'",
  "'on'",
  "'only'",
  "'option'",
  "'or'",
  "'order'",
  "'ordered'",
  "'ordering'",
  "'paragraph'",
  "'paragraphs'",
  "'parent'",
  "'pattern-separator'",
  "'per-mille'",
  "'percent'",
  "'phrase'",
  "'position'",
  "'preceding'",
  "'preceding-sibling'",
  "'preserve'",
  "'previous'",
  "'processing-instruction'",
  "'relationship'",
  "'rename'",
  "'replace'",
  "'return'",
  "'returning'",
  "'revalidation'",
  "'same'",
  "'satisfies'",
  "'schema'",
  "'schema-attribute'",
  "'schema-element'",
  "'score'",
  "'self'",
  "'sensitive'",
  "'sentence'",
  "'sentences'",
  "'skip'",
  "'sliding'",
  "'some'",
  "'stable'",
  "'start'",
  "'stemming'",
  "'stop'",
  "'strict'",
  "'strip'",
  "'structured-item'",
  "'switch'",
  "'text'",
  "'then'",
  "'thesaurus'",
  "'times'",
  "'to'",
  "'treat'",
  "'try'",
  "'tumbling'",
  "'type'",
  "'typeswitch'",
  "'union'",
  "'unique'",
  "'unordered'",
  "'updating'",
  "'uppercase'",
  "'using'",
  "'validate'",
  "'value'",
  "'variable'",
  "'version'",
  "'weight'",
  "'when'",
  "'where'",
  "'while'",
  "'wildcards'",
  "'window'",
  "'with'",
  "'without'",
  "'word'",
  "'words'",
  "'xquery'",
  "'zero-digit'",
  "'{'",
  "'{{'",
  "'|'",
  "'}'",
  "'}}'"
];
                                                            });
define('ace/mode/behaviour/xquery', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/behaviour', 'ace/mode/behaviour/cstyle', 'ace/mode/behaviour/xml', 'ace/token_iterator'], function(require, exports, module) {


  var oop = require("../../lib/oop");
  var Behaviour = require('../behaviour').Behaviour;
  var CstyleBehaviour = require('./cstyle').CstyleBehaviour;
  var XmlBehaviour = require("../behaviour/xml").XmlBehaviour;
  var TokenIterator = require("../../token_iterator").TokenIterator;

function hasType(token, type) {
    var hasType = true;
    var typeList = token.type.split('.');
    var needleList = type.split('.');
    needleList.forEach(function(needle){
        if (typeList.indexOf(needle) == -1) {
            hasType = false;
            return false;
        }
    });
    return hasType;
}
 
  var XQueryBehaviour = function () {
      
      this.inherit(CstyleBehaviour, ["braces", "parens", "string_dquotes"]); // Get string behaviour
      this.inherit(XmlBehaviour); // Get xml behaviour
      
      this.add("autoclosing", "insertion", function (state, action, editor, session, text) {
        if (text == '>') {
            var position = editor.getCursorPosition();
            var iterator = new TokenIterator(session, position.row, position.column);
            var token = iterator.getCurrentToken();
            var atCursor = false;
            if (!token || !hasType(token, 'meta.tag') && !(hasType(token, 'text') && token.value.match('/'))){
                do {
                    token = iterator.stepBackward();
                } while (token && (hasType(token, 'string') || hasType(token, 'keyword.operator') || hasType(token, 'entity.attribute-name') || hasType(token, 'text')));
            } else {
                atCursor = true;
            }
            var previous = iterator.stepBackward();
            if (!token || !hasType(token, 'meta.tag') || (previous !== null && previous.value.match('/'))) {
                return
            }
            var tag = token.value.substring(1);
            if (atCursor){
                var tag = tag.substring(0, position.column - token.start);
            }

            return {
               text: '>' + '</' + tag + '>',
               selection: [1, 1]
            }
        }
    });

  }
  oop.inherits(XQueryBehaviour, Behaviour);

  exports.XQueryBehaviour = XQueryBehaviour;
});

define('ace/mode/behaviour/cstyle', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/behaviour', 'ace/token_iterator', 'ace/lib/lang'], function(require, exports, module) {


var oop = require("../../lib/oop");
var Behaviour = require("../behaviour").Behaviour;
var TokenIterator = require("../../token_iterator").TokenIterator;
var lang = require("../../lib/lang");

var SAFE_INSERT_IN_TOKENS =
    ["text", "paren.rparen", "punctuation.operator"];
var SAFE_INSERT_BEFORE_TOKENS =
    ["text", "paren.rparen", "punctuation.operator", "comment"];


var autoInsertedBrackets = 0;
var autoInsertedRow = -1;
var autoInsertedLineEnd = "";
var maybeInsertedBrackets = 0;
var maybeInsertedRow = -1;
var maybeInsertedLineStart = "";
var maybeInsertedLineEnd = "";

var CstyleBehaviour = function () {
    
    CstyleBehaviour.isSaneInsertion = function(editor, session) {
        var cursor = editor.getCursorPosition();
        var iterator = new TokenIterator(session, cursor.row, cursor.column);
        if (!this.$matchTokenType(iterator.getCurrentToken() || "text", SAFE_INSERT_IN_TOKENS)) {
            var iterator2 = new TokenIterator(session, cursor.row, cursor.column + 1);
            if (!this.$matchTokenType(iterator2.getCurrentToken() || "text", SAFE_INSERT_IN_TOKENS))
                return false;
        }
        iterator.stepForward();
        return iterator.getCurrentTokenRow() !== cursor.row ||
            this.$matchTokenType(iterator.getCurrentToken() || "text", SAFE_INSERT_BEFORE_TOKENS);
    };
    
    CstyleBehaviour.$matchTokenType = function(token, types) {
        return types.indexOf(token.type || token) > -1;
    };
    
    CstyleBehaviour.recordAutoInsert = function(editor, session, bracket) {
        var cursor = editor.getCursorPosition();
        var line = session.doc.getLine(cursor.row);
        if (!this.isAutoInsertedClosing(cursor, line, autoInsertedLineEnd[0]))
            autoInsertedBrackets = 0;
        autoInsertedRow = cursor.row;
        autoInsertedLineEnd = bracket + line.substr(cursor.column);
        autoInsertedBrackets++;
    };
    
    CstyleBehaviour.recordMaybeInsert = function(editor, session, bracket) {
        var cursor = editor.getCursorPosition();
        var line = session.doc.getLine(cursor.row);
        if (!this.isMaybeInsertedClosing(cursor, line))
            maybeInsertedBrackets = 0;
        maybeInsertedRow = cursor.row;
        maybeInsertedLineStart = line.substr(0, cursor.column) + bracket;
        maybeInsertedLineEnd = line.substr(cursor.column);
        maybeInsertedBrackets++;
    };
    
    CstyleBehaviour.isAutoInsertedClosing = function(cursor, line, bracket) {
        return autoInsertedBrackets > 0 &&
            cursor.row === autoInsertedRow &&
            bracket === autoInsertedLineEnd[0] &&
            line.substr(cursor.column) === autoInsertedLineEnd;
    };
    
    CstyleBehaviour.isMaybeInsertedClosing = function(cursor, line) {
        return maybeInsertedBrackets > 0 &&
            cursor.row === maybeInsertedRow &&
            line.substr(cursor.column) === maybeInsertedLineEnd &&
            line.substr(0, cursor.column) == maybeInsertedLineStart;
    };
    
    CstyleBehaviour.popAutoInsertedClosing = function() {
        autoInsertedLineEnd = autoInsertedLineEnd.substr(1);
        autoInsertedBrackets--;
    };
    
    CstyleBehaviour.clearMaybeInsertedClosing = function() {
        maybeInsertedBrackets = 0;
        maybeInsertedRow = -1;
    };

    this.add("braces", "insertion", function (state, action, editor, session, text) {
        var cursor = editor.getCursorPosition();
        var line = session.doc.getLine(cursor.row);
        if (text == '{') {
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "" && selected !== "{" && editor.getWrapBehavioursEnabled()) {
                return {
                    text: '{' + selected + '}',
                    selection: false
                };
            } else if (CstyleBehaviour.isSaneInsertion(editor, session)) {
                if (/[\]\}\)]/.test(line[cursor.column])) {
                    CstyleBehaviour.recordAutoInsert(editor, session, "}");
                    return {
                        text: '{}',
                        selection: [1, 1]
                    };
                } else {
                    CstyleBehaviour.recordMaybeInsert(editor, session, "{");
                    return {
                        text: '{',
                        selection: [1, 1]
                    };
                }
            }
        } else if (text == '}') {
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar == '}') {
                var matching = session.$findOpeningBracket('}', {column: cursor.column + 1, row: cursor.row});
                if (matching !== null && CstyleBehaviour.isAutoInsertedClosing(cursor, line, text)) {
                    CstyleBehaviour.popAutoInsertedClosing();
                    return {
                        text: '',
                        selection: [1, 1]
                    };
                }
            }
        } else if (text == "\n" || text == "\r\n") {
            var closing = "";
            if (CstyleBehaviour.isMaybeInsertedClosing(cursor, line)) {
                closing = lang.stringRepeat("}", maybeInsertedBrackets);
                CstyleBehaviour.clearMaybeInsertedClosing();
            }
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar == '}' || closing !== "") {
                var openBracePos = session.findMatchingBracket({row: cursor.row, column: cursor.column}, '}');
                if (!openBracePos)
                     return null;

                var indent = this.getNextLineIndent(state, line.substring(0, cursor.column), session.getTabString());
                var next_indent = this.$getIndent(line);

                return {
                    text: '\n' + indent + '\n' + next_indent + closing,
                    selection: [1, indent.length, 1, indent.length]
                };
            }
        }
    });

    this.add("braces", "deletion", function (state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && selected == '{') {
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.end.column, range.end.column + 1);
            if (rightChar == '}') {
                range.end.column++;
                return range;
            } else {
                maybeInsertedBrackets--;
            }
        }
    });

    this.add("parens", "insertion", function (state, action, editor, session, text) {
        if (text == '(') {
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "" && editor.getWrapBehavioursEnabled()) {
                return {
                    text: '(' + selected + ')',
                    selection: false
                };
            } else if (CstyleBehaviour.isSaneInsertion(editor, session)) {
                CstyleBehaviour.recordAutoInsert(editor, session, ")");
                return {
                    text: '()',
                    selection: [1, 1]
                };
            }
        } else if (text == ')') {
            var cursor = editor.getCursorPosition();
            var line = session.doc.getLine(cursor.row);
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar == ')') {
                var matching = session.$findOpeningBracket(')', {column: cursor.column + 1, row: cursor.row});
                if (matching !== null && CstyleBehaviour.isAutoInsertedClosing(cursor, line, text)) {
                    CstyleBehaviour.popAutoInsertedClosing();
                    return {
                        text: '',
                        selection: [1, 1]
                    };
                }
            }
        }
    });

    this.add("parens", "deletion", function (state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && selected == '(') {
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.start.column + 1, range.start.column + 2);
            if (rightChar == ')') {
                range.end.column++;
                return range;
            }
        }
    });

    this.add("brackets", "insertion", function (state, action, editor, session, text) {
        if (text == '[') {
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "" && editor.getWrapBehavioursEnabled()) {
                return {
                    text: '[' + selected + ']',
                    selection: false
                };
            } else if (CstyleBehaviour.isSaneInsertion(editor, session)) {
                CstyleBehaviour.recordAutoInsert(editor, session, "]");
                return {
                    text: '[]',
                    selection: [1, 1]
                };
            }
        } else if (text == ']') {
            var cursor = editor.getCursorPosition();
            var line = session.doc.getLine(cursor.row);
            var rightChar = line.substring(cursor.column, cursor.column + 1);
            if (rightChar == ']') {
                var matching = session.$findOpeningBracket(']', {column: cursor.column + 1, row: cursor.row});
                if (matching !== null && CstyleBehaviour.isAutoInsertedClosing(cursor, line, text)) {
                    CstyleBehaviour.popAutoInsertedClosing();
                    return {
                        text: '',
                        selection: [1, 1]
                    };
                }
            }
        }
    });

    this.add("brackets", "deletion", function (state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && selected == '[') {
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.start.column + 1, range.start.column + 2);
            if (rightChar == ']') {
                range.end.column++;
                return range;
            }
        }
    });

    this.add("string_dquotes", "insertion", function (state, action, editor, session, text) {
        if (text == '"' || text == "'") {
            var quote = text;
            var selection = editor.getSelectionRange();
            var selected = session.doc.getTextRange(selection);
            if (selected !== "" && selected !== "'" && selected != '"' && editor.getWrapBehavioursEnabled()) {
                return {
                    text: quote + selected + quote,
                    selection: false
                };
            } else {
                var cursor = editor.getCursorPosition();
                var line = session.doc.getLine(cursor.row);
                var leftChar = line.substring(cursor.column-1, cursor.column);
                if (leftChar == '\\') {
                    return null;
                }
                var tokens = session.getTokens(selection.start.row);
                var col = 0, token;
                var quotepos = -1; // Track whether we're inside an open quote.

                for (var x = 0; x < tokens.length; x++) {
                    token = tokens[x];
                    if (token.type == "string") {
                      quotepos = -1;
                    } else if (quotepos < 0) {
                      quotepos = token.value.indexOf(quote);
                    }
                    if ((token.value.length + col) > selection.start.column) {
                        break;
                    }
                    col += tokens[x].value.length;
                }
                if (!token || (quotepos < 0 && token.type !== "comment" && (token.type !== "string" || ((selection.start.column !== token.value.length+col-1) && token.value.lastIndexOf(quote) === token.value.length-1)))) {
                    if (!CstyleBehaviour.isSaneInsertion(editor, session))
                        return;
                    return {
                        text: quote + quote,
                        selection: [1,1]
                    };
                } else if (token && token.type === "string") {
                    var rightChar = line.substring(cursor.column, cursor.column + 1);
                    if (rightChar == quote) {
                        return {
                            text: '',
                            selection: [1, 1]
                        };
                    }
                }
            }
        }
    });

    this.add("string_dquotes", "deletion", function (state, action, editor, session, range) {
        var selected = session.doc.getTextRange(range);
        if (!range.isMultiLine() && (selected == '"' || selected == "'")) {
            var line = session.doc.getLine(range.start.row);
            var rightChar = line.substring(range.start.column + 1, range.start.column + 2);
            if (rightChar == selected) {
                range.end.column++;
                return range;
            }
        }
    });

};

oop.inherits(CstyleBehaviour, Behaviour);

exports.CstyleBehaviour = CstyleBehaviour;
});

define('ace/mode/behaviour/xml', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/mode/behaviour', 'ace/mode/behaviour/cstyle', 'ace/token_iterator'], function(require, exports, module) {


var oop = require("../../lib/oop");
var Behaviour = require("../behaviour").Behaviour;
var CstyleBehaviour = require("./cstyle").CstyleBehaviour;
var TokenIterator = require("../../token_iterator").TokenIterator;

function hasType(token, type) {
    var hasType = true;
    var typeList = token.type.split('.');
    var needleList = type.split('.');
    needleList.forEach(function(needle){
        if (typeList.indexOf(needle) == -1) {
            hasType = false;
            return false;
        }
    });
    return hasType;
}

var XmlBehaviour = function () {
    
    this.inherit(CstyleBehaviour, ["string_dquotes"]); // Get string behaviour
    
    this.add("autoclosing", "insertion", function (state, action, editor, session, text) {
        if (text == '>') {
            var position = editor.getCursorPosition();
            var iterator = new TokenIterator(session, position.row, position.column);
            var token = iterator.getCurrentToken();
            var atCursor = false;
            if (!token || !hasType(token, 'meta.tag') && !(hasType(token, 'text') && token.value.match('/'))){
                do {
                    token = iterator.stepBackward();
                } while (token && (hasType(token, 'string') || hasType(token, 'keyword.operator') || hasType(token, 'entity.attribute-name') || hasType(token, 'text')));
            } else {
                atCursor = true;
            }
            if (!token || !hasType(token, 'meta.tag-name') || iterator.stepBackward().value.match('/')) {
                return
            }
            var tag = token.value;
            if (atCursor){
                var tag = tag.substring(0, position.column - token.start);
            }

            return {
               text: '>' + '</' + tag + '>',
               selection: [1, 1]
            }
        }
    });

    this.add('autoindent', 'insertion', function (state, action, editor, session, text) {
        if (text == "\n") {
            var cursor = editor.getCursorPosition();
            var line = session.doc.getLine(cursor.row);
            var rightChars = line.substring(cursor.column, cursor.column + 2);
            if (rightChars == '</') {
                var indent = this.$getIndent(session.doc.getLine(cursor.row)) + session.getTabString();
                var next_indent = this.$getIndent(session.doc.getLine(cursor.row));

                return {
                    text: '\n' + indent + '\n' + next_indent,
                    selection: [1, indent.length, 1, indent.length]
                }
            }
        }
    });
    
}
oop.inherits(XmlBehaviour, Behaviour);

exports.XmlBehaviour = XmlBehaviour;
});

define('ace/mode/folding/cstyle', ['require', 'exports', 'module' , 'ace/lib/oop', 'ace/range', 'ace/mode/folding/fold_mode'], function(require, exports, module) {


var oop = require("../../lib/oop");
var Range = require("../../range").Range;
var BaseFoldMode = require("./fold_mode").FoldMode;

var FoldMode = exports.FoldMode = function() {};
oop.inherits(FoldMode, BaseFoldMode);

(function() {

    this.foldingStartMarker = /(\{|\[)[^\}\]]*$|^\s*(\/\*)/;
    this.foldingStopMarker = /^[^\[\{]*(\}|\])|^[\s\*]*(\*\/)/;

    this.getFoldWidgetRange = function(session, foldStyle, row) {
        var line = session.getLine(row);
        var match = line.match(this.foldingStartMarker);
        if (match) {
            var i = match.index;

            if (match[1])
                return this.openingBracketBlock(session, match[1], row, i);

            return session.getCommentFoldRange(row, i + match[0].length, 1);
        }

        if (foldStyle !== "markbeginend")
            return;

        var match = line.match(this.foldingStopMarker);
        if (match) {
            var i = match.index + match[0].length;

            if (match[1])
                return this.closingBracketBlock(session, match[1], row, i);

            return session.getCommentFoldRange(row, i, -1);
        }
    };

}).call(FoldMode.prototype);

});
