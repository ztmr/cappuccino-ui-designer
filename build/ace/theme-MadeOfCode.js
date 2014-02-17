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

define('ace/theme/MadeOfCode', ['require', 'exports', 'module' , 'ace/lib/dom'], function(require, exports, module) {

exports.isDark = true;
exports.cssClass = "ace--made-of-code";
exports.cssText = "/* THIS THEME WAS AUTOGENERATED BY Theme.tmpl.css (UUID: B087ABC0-D89D-11DE-8A39-0800200C9A66) */\
.ace--made-of-code .ace_gutter {\
background: #e8e8e8;\
color: #333;\
}\
.ace--made-of-code .ace_print-margin {\
width: 1px;\
background: #e8e8e8;\
}\
.ace--made-of-code .ace_scroller {\
background-color: rgba(9, 10, 27, 0.95);\
}\
.ace--made-of-code .ace_text-layer {\
color: #F8F8F8;\
}\
.ace--made-of-code .ace_cursor {\
border-left: 2px solid #00FFFF;\
}\
.ace--made-of-code .ace_overwrite-cursors .ace_cursor {\
border-left: 0px;\
border-bottom: 1px solid #00FFFF;\
}\
.ace--made-of-code .ace_marker-layer .ace_selection {\
background: rgba(0, 125, 255, 0.50);\
}\
.ace--made-of-code.ace_multiselect .ace_selection.ace_start {\
box-shadow: 0 0 3px 0px rgba(9, 10, 27, 0.95);\
border-radius: 2px;\
}\
.ace--made-of-code .ace_marker-layer .ace_step {\
background: rgb(198, 219, 174);\
}\
.ace--made-of-code .ace_marker-layer .ace_bracket {\
margin: -1px 0 0 -1px;\
border: 1px solid rgba(202, 226, 251, 0.24);\
}\
.ace--made-of-code .ace_marker-layer .ace_active-line {\
background: rgba(0, 0, 0, 0.0);\
}\
.ace--made-of-code .ace_gutter-active-line {\
background-color: rgba(0, 0, 0, 0.0);\
}\
.ace--made-of-code .ace_marker-layer .ace_selected-word {\
border: 1px solid rgba(0, 125, 255, 0.50);\
}\
.ace--made-of-code .ace_fold {\
background-color: #FF3854;\
border-color: #F8F8F8;\
}\
.ace--made-of-code .ace_keyword{color:#FF3854;}.ace--made-of-code .ace_constant{color:#0A9CFF;}.ace--made-of-code .ace_support{color:#00FFBC;}.ace--made-of-code .ace_support.ace_function{color:#F1D950;}.ace--made-of-code .ace_support.ace_constant{color:#CF6A4C;}.ace--made-of-code .ace_storage{color:#99CF50;}.ace--made-of-code .ace_invalid.ace_illegal{color:#FD5FF1;\
background-color:rgba(86, 45, 86, 0.75);}.ace--made-of-code .ace_invalid.ace_deprecated{text-decoration:underline;\
font-style:italic;\
color:#FD5FF1;}.ace--made-of-code .ace_string{color:#8FFF58;\
background-color:rgba(16, 38, 34, 0.98);}.ace--made-of-code .ace_string.ace_regexp{color:#E9C062;}.ace--made-of-code .ace_comment{font-style:italic;\
color:#C050C2;\
background-color:#000000;}.ace--made-of-code .ace_variable{color:#588AFF;}.ace--made-of-code .ace_meta.ace_tag{color:#45C1EA;}.ace--made-of-code .ace_markup.ace_heading{color:#FEDCC5;\
background-color:#632D04;}.ace--made-of-code .ace_markup.ace_list{color:#E1D4B9;}";

var dom = require("../lib/dom");
dom.importCssString(exports.cssText, exports.cssClass);
});
