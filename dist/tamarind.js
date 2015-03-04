var browserSupportsRequiredFeatures,defineClassProperty;browserSupportsRequiredFeatures=function(){var e,t;if(void 0===browserSupportsRequiredFeatures.__cache){try{e=document.createElement("canvas"),t=e.getContext("webgl")||e.getContext("experimental-webgl")}catch(r){}browserSupportsRequiredFeatures.__cache=!(!t||!Object.defineProperty)}return browserSupportsRequiredFeatures.__cache},defineClassProperty=function(e,t){var r,n,o,i,a;if(r=t[0].toUpperCase()+t.slice(1),o=e.prototype["_get"+r],a=e.prototype["_set"+r],!o&&!a)throw new Error(t+" must name a getter or a setter");return i=e.prototype[t],void 0!==i&&(e.prototype["_"+t]=i),n={enumerable:!0,get:o||function(){throw new Error(t+" is write-only")},set:a||function(){throw new Error(t+" is read-only")}},Object.defineProperty(e.prototype,t,n)},WebGLDebugUtils=function(){function e(e){if(null==d){d={},g={};for(var t in e)"number"==typeof e[t]&&(d[e[t]]=t,g[t]=e[t])}}function t(){if(null==d)throw"WebGLDebugUtils.init(ctx) not called"}function r(e){return t(),void 0!==d[e]}function n(e){t();var r=d[e];return void 0!==r?"gl."+r:"/*UNKNOWN WebGL ENUM*/ 0x"+e.toString(16)}function o(e,t,r,o){var i=h[e];if(void 0!==i){var i=i[t];if(void 0!==i&&i[r]){if("object"==typeof i[r]&&void 0!==i[r].enumBitwiseOr){for(var a=i[r].enumBitwiseOr,s=0,u=[],f=0;f<a.length;++f){var c=g[a[f]];0!==(o&c)&&(s|=c,u.push(n(c)))}return s===o?u.join(" | "):n(o)}return n(o)}}return null===o?"null":void 0===o?"undefined":o.toString()}function i(e,t){for(var r="",n=t.length,i=0;n>i;++i)r+=(0==i?"":", ")+o(e,n,i,t[i]);return r}function a(e,t,r){e.__defineGetter__(r,function(){return t[r]}),e.__defineSetter__(r,function(e){t[r]=e})}function s(t,r,i,u){function f(e,t){return function(){i&&i(t,arguments);var n=e[t].apply(e,arguments),o=u.getError();return 0!=o&&(c[o]=!0,r(o,t,arguments)),n}}u=u||t,e(t),r=r||function(e,t,r){for(var i="",a=r.length,s=0;a>s;++s)i+=(0==s?"":", ")+o(t,a,s,r[s]);l("WebGL error "+n(e)+" in "+t+"("+i+")")};var c={},h={};for(var d in t)if("function"==typeof t[d])if("getExtension"!=d)h[d]=f(t,d);else{var g=f(t,d);h[d]=function(){var e=g.apply(t,arguments);return s(e,r,i,u)}}else a(h,t,d);return h.getError=function(){for(var e in c)if(c.hasOwnProperty(e)&&c[e])return c[e]=!1,e;return t.NO_ERROR},h}function u(e){var t=e.getParameter(e.MAX_VERTEX_ATTRIBS),r=e.createBuffer();e.bindBuffer(e.ARRAY_BUFFER,r);for(var n=0;t>n;++n)e.disableVertexAttribArray(n),e.vertexAttribPointer(n,4,e.FLOAT,!1,0,0),e.vertexAttrib1f(n,0);e.deleteBuffer(r);for(var o=e.getParameter(e.MAX_TEXTURE_IMAGE_UNITS),n=0;o>n;++n)e.activeTexture(e.TEXTURE0+n),e.bindTexture(e.TEXTURE_CUBE_MAP,null),e.bindTexture(e.TEXTURE_2D,null);for(e.activeTexture(e.TEXTURE0),e.useProgram(null),e.bindBuffer(e.ARRAY_BUFFER,null),e.bindBuffer(e.ELEMENT_ARRAY_BUFFER,null),e.bindFramebuffer(e.FRAMEBUFFER,null),e.bindRenderbuffer(e.RENDERBUFFER,null),e.disable(e.BLEND),e.disable(e.CULL_FACE),e.disable(e.DEPTH_TEST),e.disable(e.DITHER),e.disable(e.SCISSOR_TEST),e.blendColor(0,0,0,0),e.blendEquation(e.FUNC_ADD),e.blendFunc(e.ONE,e.ZERO),e.clearColor(0,0,0,0),e.clearDepth(1),e.clearStencil(-1),e.colorMask(!0,!0,!0,!0),e.cullFace(e.BACK),e.depthFunc(e.LESS),e.depthMask(!0),e.depthRange(0,1),e.frontFace(e.CCW),e.hint(e.GENERATE_MIPMAP_HINT,e.DONT_CARE),e.lineWidth(1),e.pixelStorei(e.PACK_ALIGNMENT,4),e.pixelStorei(e.UNPACK_ALIGNMENT,4),e.pixelStorei(e.UNPACK_FLIP_Y_WEBGL,!1),e.pixelStorei(e.UNPACK_PREMULTIPLY_ALPHA_WEBGL,!1),e.UNPACK_COLORSPACE_CONVERSION_WEBGL&&e.pixelStorei(e.UNPACK_COLORSPACE_CONVERSION_WEBGL,e.BROWSER_DEFAULT_WEBGL),e.polygonOffset(0,0),e.sampleCoverage(1,!1),e.scissor(0,0,e.canvas.width,e.canvas.height),e.stencilFunc(e.ALWAYS,0,4294967295),e.stencilMask(4294967295),e.stencilOp(e.KEEP,e.KEEP,e.KEEP),e.viewport(0,0,e.canvas.width,e.canvas.height),e.clear(e.COLOR_BUFFER_BIT|e.DEPTH_BUFFER_BIT|e.STENCIL_BUFFER_BIT);e.getError(););}function f(e){function t(e){return"function"==typeof e?e:function(t){e.handleEvent(t)}}function r(e){var t=e.addEventListener;e.addEventListener=function(r,n){switch(r){case"webglcontextlost":y(n);break;case"webglcontextrestored":C(n);break;default:t.apply(e,arguments)}}}function n(){for(var e=Object.keys(x),t=0;t<e.length;++t)delete x[e]}function o(){++b,p||v==b&&e.loseContext()}function i(e,t){var r=e[t];return function(){if(o(),!p){var t=r.apply(e,arguments);return t}}}function s(){for(var e=0;e<m.length;++e){var t=m[e];t instanceof WebGLBuffer?l.deleteBuffer(t):t instanceof WebGLFramebuffer?l.deleteFramebuffer(t):t instanceof WebGLProgram?l.deleteProgram(t):t instanceof WebGLRenderbuffer?l.deleteRenderbuffer(t):t instanceof WebGLShader?l.deleteShader(t):t instanceof WebGLTexture&&l.deleteTexture(t)}}function f(e){return{statusMessage:e,preventDefault:function(){E=!0}}}function c(e){for(var t in e)"function"==typeof e[t]?h[t]=i(e,t):a(h,e,t);h.getError=function(){if(o(),!p)for(var e;e=l.getError();)x[e]=!0;for(var e in x)if(x[e])return delete x[e],e;return h.NO_ERROR};for(var r=["createBuffer","createFramebuffer","createProgram","createRenderbuffer","createShader","createTexture"],n=0;n<r.length;++n){var s=r[n];h[s]=function(t){return function(){if(o(),p)return null;var r=t.apply(e,arguments);return r.__webglDebugContextLostId__=_,m.push(r),r}}(e[s])}for(var u=["getActiveAttrib","getActiveUniform","getBufferParameter","getContextAttributes","getAttachedShaders","getFramebufferAttachmentParameter","getParameter","getProgramParameter","getProgramInfoLog","getRenderbufferParameter","getShaderParameter","getShaderInfoLog","getShaderSource","getTexParameter","getUniform","getUniformLocation","getVertexAttrib"],n=0;n<u.length;++n){var s=u[n];h[s]=function(t){return function(){return o(),p?null:t.apply(e,arguments)}}(h[s])}for(var f=["isBuffer","isEnabled","isFramebuffer","isProgram","isRenderbuffer","isShader","isTexture"],n=0;n<f.length;++n){var s=f[n];h[s]=function(t){return function(){return o(),p?!1:t.apply(e,arguments)}}(h[s])}return h.checkFramebufferStatus=function(t){return function(){return o(),p?h.FRAMEBUFFER_UNSUPPORTED:t.apply(e,arguments)}}(h.checkFramebufferStatus),h.getAttribLocation=function(t){return function(){return o(),p?-1:t.apply(e,arguments)}}(h.getAttribLocation),h.getVertexAttribOffset=function(t){return function(){return o(),p?0:t.apply(e,arguments)}}(h.getVertexAttribOffset),h.isContextLost=function(){return p},h}var l,h,d=[],g=[],h={},_=1,p=!1,m=[],v=0,b=0,E=!1,S=0,x={};e.getContext=function(t){return function(){var r=t.apply(e,arguments);if(r instanceof WebGLRenderingContext){if(r!=l){if(l)throw"got different context";l=r,h=c(l)}return h}return r}}(e.getContext);var y=function(e){d.push(t(e))},C=function(e){g.push(t(e))};return r(e),e.loseContext=function(){if(!p){for(p=!0,v=0,++_;l.getError(););n(),x[l.CONTEXT_LOST_WEBGL]=!0;var t=f("context lost"),r=d.slice();setTimeout(function(){for(var n=0;n<r.length;++n)r[n](t);S>=0&&setTimeout(function(){e.restoreContext()},S)},0)}},e.restoreContext=function(){p&&g.length&&setTimeout(function(){if(!E)throw"can not restore. webglcontestlost listener did not call event.preventDefault";s(),u(l),p=!1,b=0,E=!1;for(var e=g.slice(),t=f("context restored"),r=0;r<e.length;++r)e[r](t)},0)},e.loseContextInNCalls=function(e){if(p)throw"You can not ask a lost contet to be lost";v=b+e},e.getNumCalls=function(){return b},e.setRestoreTimeout=function(e){S=e},e}var c=function(e){window.console&&window.console.log&&window.console.log(e)},l=function(e){window.console&&window.console.error?window.console.error(e):c(e)},h={enable:{1:{0:!0}},disable:{1:{0:!0}},getParameter:{1:{0:!0}},drawArrays:{3:{0:!0}},drawElements:{4:{0:!0,2:!0}},createShader:{1:{0:!0}},getShaderParameter:{2:{1:!0}},getProgramParameter:{2:{1:!0}},getShaderPrecisionFormat:{2:{0:!0,1:!0}},getVertexAttrib:{2:{1:!0}},vertexAttribPointer:{6:{2:!0}},bindTexture:{2:{0:!0}},activeTexture:{1:{0:!0}},getTexParameter:{2:{0:!0,1:!0}},texParameterf:{3:{0:!0,1:!0}},texParameteri:{3:{0:!0,1:!0,2:!0}},texImage2D:{9:{0:!0,2:!0,6:!0,7:!0},6:{0:!0,2:!0,3:!0,4:!0}},texSubImage2D:{9:{0:!0,6:!0,7:!0},7:{0:!0,4:!0,5:!0}},copyTexImage2D:{8:{0:!0,2:!0}},copyTexSubImage2D:{8:{0:!0}},generateMipmap:{1:{0:!0}},compressedTexImage2D:{7:{0:!0,2:!0}},compressedTexSubImage2D:{8:{0:!0,6:!0}},bindBuffer:{2:{0:!0}},bufferData:{3:{0:!0,2:!0}},bufferSubData:{3:{0:!0}},getBufferParameter:{2:{0:!0,1:!0}},pixelStorei:{2:{0:!0,1:!0}},readPixels:{7:{4:!0,5:!0}},bindRenderbuffer:{2:{0:!0}},bindFramebuffer:{2:{0:!0}},checkFramebufferStatus:{1:{0:!0}},framebufferRenderbuffer:{4:{0:!0,1:!0,2:!0}},framebufferTexture2D:{5:{0:!0,1:!0,2:!0}},getFramebufferAttachmentParameter:{3:{0:!0,1:!0,2:!0}},getRenderbufferParameter:{2:{0:!0,1:!0}},renderbufferStorage:{4:{0:!0,1:!0}},clear:{1:{0:{enumBitwiseOr:["COLOR_BUFFER_BIT","DEPTH_BUFFER_BIT","STENCIL_BUFFER_BIT"]}}},depthFunc:{1:{0:!0}},blendFunc:{2:{0:!0,1:!0}},blendFuncSeparate:{4:{0:!0,1:!0,2:!0,3:!0}},blendEquation:{1:{0:!0}},blendEquationSeparate:{2:{0:!0,1:!0}},stencilFunc:{3:{0:!0}},stencilFuncSeparate:{4:{0:!0,1:!0}},stencilMaskSeparate:{2:{0:!0}},stencilOp:{3:{0:!0,1:!0,2:!0}},stencilOpSeparate:{4:{0:!0,1:!0,2:!0,3:!0}},cullFace:{1:{0:!0}},frontFace:{1:{0:!0}},drawArraysInstancedANGLE:{4:{0:!0}},drawElementsInstancedANGLE:{5:{0:!0,2:!0}},blendEquationEXT:{1:{0:!0}}},d=null,g=null;return{init:e,mightBeEnum:r,glEnumToString:n,glFunctionArgToString:o,glFunctionArgsToString:i,makeDebugContext:s,makeLostContextSimulatingCanvas:f,resetToInitialState:u}}();var EventEmitter;EventEmitter=function(){function e(){this._events={}}return e.prototype.on=function(e,t){return this._validateEventArgs(e,t),this._getEventList(e).push(t)},e.prototype.off=function(e,t){var r,n;this._validateEventArgs(e,t),n=this._getEventList(e),r=n.indexOf(t),-1!==r&&n.splice(r,1)},e.prototype.emit=function(e,t){var r,n,o,i,a;for(this._validateEventArgs(e),i=this._getEventList(e),a=[],n=0,o=i.length;o>n;n++)r=i[n],a.push(r.call(this,t));return a},e.prototype._getEventList=function(e){return this._events[e]||(this._events[e]=[]),this._events[e]},e.prototype._validateEventArgs=function(e,t){if("string"!=typeof e)throw new Error("eventName must be a string");if(arguments.length>1&&"function"!=typeof t)throw new Error("callback must be a function")},e}();var WebGLCanvas,__bind=function(e,t){return function(){return e.apply(t,arguments)}},__hasProp={}.hasOwnProperty,__extends=function(e,t){function r(){this.constructor=e}for(var n in t)__hasProp.call(t,n)&&(e[n]=t[n]);return r.prototype=t.prototype,e.prototype=new r,e.__super__=t.prototype,e},__slice=[].slice;WebGLCanvas=function(e){function t(e,r){if(this.canvas=e,this.debugMode=null!=r?r:!1,this._doFrame=__bind(this._doFrame,this),t.__super__.constructor.call(this),!browserSupportsRequiredFeatures())throw new Error("This browser does not support WebGL");if(this._uniformInfoByName={},this.canvas.addEventListener("webglcontextcreationerror",function(e){return function(t){return e.trace.error(t.statusMessage)}}(this)),this.canvas.addEventListener("webglcontextlost",function(e){return function(){return e._handleContextLost()}}(this)),this.canvas.addEventListener("webglcontextrestored",function(e){return function(){return e._handleContextRestored()}}(this)),this._createContext(),!this.gl)throw new Error("Could not create WebGL context for canvas");this.drawingMode="TRIANGLE_FAN",this._scheduleFrame()}var r,n,o,i,a,s,u;return __extends(t,e),u="attribute float a_VertexIndex;",n="void main() {\n  // 4 points, one in each corner, clockwise from top left\n  if (a_VertexIndex == 0.0) {\n    gl_Position.xy = vec2(-1, -1);\n  } else if (a_VertexIndex == 1.0) {\n    gl_Position.xy = vec2(1, -1);\n  } else if (a_VertexIndex == 2.0) {\n    gl_Position.xy = vec2(1, 1);\n  } else if (a_VertexIndex == 3.0) {\n    gl_Position.xy = vec2(-1, 1);\n  }\n}",o="precision mediump float;\nuniform vec2 u_CanvasSize;",r="void main() {\n  gl_FragColor.r = u_CanvasSize.x;\n  gl_FragColor = vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1);\n}",s=0,a="POINTS,LINES,LINE_LOOP,LINE_STRIP,TRIANGLES,TRIANGLE_STRIP,TRIANGLE_FAN".split(","),i=[null,"uniform1f","uniform2f","uniform3f","uniform4f"],t.COMPILE_ERROR="compileError",t.prototype.vertexCount=4,t.prototype.fragmentShaderSource=r,t.prototype.vertexShaderSource=n,t.prototype._scheduleFrame=function(){return this._frameScheduled?void 0:(this._frameScheduled=!0,requestAnimationFrame(this._doFrame))},t.prototype._doFrame=function(){var e;if(this._frameScheduled=!1,!this._contextLost){if(this._contextRequiresSetup){if(!this._setupContext())return;this._contextRequiresSetup=!1,this._vertexShaderIsDirty=this._fragmentShaderIsDirty=this._geometryIsDirty=!0}if(this._geometryIsDirty){if(!this._updateGeometry())return;this._geometryIsDirty=!1}if(e=this._vertexShaderIsDirty||this._fragmentShaderIsDirty,this._vertexShaderIsDirty){if(!this._compileShader(this._vertexShader,u+this.vertexShaderSource))return;this._vertexShaderIsDirty=!1}if(this._fragmentShaderIsDirty){if(!this._compileShader(this._fragmentShader,o+this.fragmentShaderSource))return;this._fragmentShaderIsDirty=!1}if(!e||this._linkProgram())return this._render()}},t.prototype._createContext=function(){var e,t,r,n,o,i;for(this.nativeContext=this.canvas.getContext("webgl")||this.canvas.getContext("experimental-webgl"),r=function(e,t){var r,n,o;for(n=0,o=t.length;o>n;n++)if(r=t[n],void 0===r)throw new Error("undefined passed to gl."+e+"("+WebGLDebugUtils.glFunctionArgsToString(e,t)+")")},this.debugContext=WebGLDebugUtils.makeDebugContext(this.nativeContext,null,r,null),this._contextRequiresSetup=!0,this.gl=this._debugMode?this.debugContext:this.nativeContext,this._drawingModeNames={},i=[],n=0,o=a.length;o>n;n++){if(t=a[n],e=this.gl[t],void 0===e)throw new Error(t+" is not a valid drawing mode");this._drawingModeNames[t]=e,i.push(this._drawingModeNames[e]=t)}return i},t.prototype._setupContext=function(){var e;return e=this.gl,(this._vertexBuffer=e.createBuffer())&&(this._program=e.createProgram())&&(this._vertexShader=e.createShader(e.VERTEX_SHADER))&&(this._fragmentShader=e.createShader(e.FRAGMENT_SHADER))?(e.attachShader(this._program,this._vertexShader),e.attachShader(this._program,this._fragmentShader),!0):!1},t.prototype._compileShader=function(e,r){var n,o,i;return i=this.gl,i.shaderSource(e,r),i.compileShader(e),n=i.getShaderParameter(e,i.COMPILE_STATUS),n?!0:(o=i.getShaderInfoLog(e).trim(),this.emit(t.COMPILE_ERROR,o),!1)},t.prototype._linkProgram=function(){var e,t,r,n,o,i,a,u;if(t=this.gl,t.bindAttribLocation(this._program,s,"a_VertexIndex"),t.linkProgram(this._program),n=t.getProgramParameter(this._program,t.LINK_STATUS),!n)return e=t.getProgramInfoLog(this._program),this.trace.log("Failed to link program: "+e),!1;for(t.useProgram(this._program),o=t.getProgramParameter(this._program,t.ACTIVE_UNIFORMS),this._uniformInfoByName={},r=a=0,u=o-1;u>=a;r=a+=1)i=t.getActiveUniform(this._program,r),this._uniformInfoByName[i.name]={location:t.getUniformLocation(this._program,r),type:i.type};return!0},t.prototype._updateGeometry=function(){var e,t,r;e=this.gl,r=new Float32Array(this.vertexCount);for(t in r)r[t]=t;return e.bindBuffer(e.ARRAY_BUFFER,this._vertexBuffer),e.bufferData(e.ARRAY_BUFFER,r,e.STATIC_DRAW),e.vertexAttribPointer(s,1,e.FLOAT,!1,0,0),e.enableVertexAttribArray(s),!0},t.prototype._render=function(){var e,t,r;return e=this.gl,r=Math.round(this.canvas.offsetWidth*(window.devicePixelRatio||1)),t=Math.round(this.canvas.offsetHeight*(window.devicePixelRatio||1)),this._setUniform("u_CanvasSize",r,t),(r!==this._width||t!==this._height)&&(this._width=this.canvas.width=r,this._height=this.canvas.height=t,e.viewport(0,0,r,t)),e.clearColor(0,0,0,0),e.clear(e.COLOR_BUFFER_BIT),e.drawArrays(this._drawingMode,0,this.vertexCount),!0},t.prototype._setUniform=function(){var e,t,r,n,o;if(n=arguments[0],e=2<=arguments.length?__slice.call(arguments,1):[],r=this.gl,o=this._uniformInfoByName[n],!o)return!1;if(o.location=r.getUniformLocation(this._program,"u_CanvasSize"),t=i[e.length],!t)throw new Error("Can't set uniform with "+e.length+" values");return r[t].apply(r,[o.location].concat(__slice.call(e))),!0},t.prototype._handleContextLost=function(e){return this.trace.log("WebGL context lost, suspending all GL calls"),this._contextLost=!0,(e||window.event).preventDefault()},t.prototype._handleContextRestored=function(){return this.trace.log("WebGL context restored, resuming rendering"),this._contextLost=!1,this._contextRequiresSetup=!0,this._scheduleFrame()},t.prototype._getFragmentShaderSource=function(){return this._fragmentShaderSource},t.prototype._setFragmentShaderSource=function(e){return this._fragmentShaderSource=e,this._fragmentShaderIsDirty=!0,this._scheduleFrame()},t.prototype._getVertexShaderSource=function(){return this._vertexShaderSource},t.prototype._setVertexShaderSource=function(e){return this._vertexShaderSource=e,this._vertexShaderIsDirty=!0,this._scheduleFrame()},t.prototype._getVertexCount=function(){return this._vertexCount},t.prototype._setVertexCount=function(e){return this._vertexCount=e,this._geometryIsDirty=!0,this._scheduleFrame()},t.prototype._getDrawingMode=function(){return this._drawingModeNames[this._drawingMode]},t.prototype._setDrawingMode=function(e){var t;if(t=this.gl[e],void 0===t)throw new Error(e+" is not a valid drawing mode.");return this._drawingMode=t,this._scheduleFrame()},t.prototype._getDebugMode=function(){return this._debugMode},t.prototype._setDebugMode=function(e){return e=!!e,this._debugMode!==e?(this._debugMode=e,this._debugMode?(this.trace=new ConsoleTracer,this.trace.log("Using WebGL API debugging proxy - turn off debug mode for production apps, it hurts performance"),this.gl=this.debugContext):(this.trace=new NullTracer,this.gl=this.debugContext)):void 0},t}(EventEmitter),defineClassProperty(WebGLCanvas,"debugMode"),defineClassProperty(WebGLCanvas,"drawingMode"),defineClassProperty(WebGLCanvas,"vertexCount"),defineClassProperty(WebGLCanvas,"vertexShaderSource"),defineClassProperty(WebGLCanvas,"fragmentShaderSource");var ConsoleTracer,NullTracer;ConsoleTracer=function(){function e(){}return e.prototype.log=function(e){return window.console?console.log(e):void 0},e.prototype.error=function(e){return window.console?console.error(e):void 0},e}(),NullTracer=function(){function e(){}return e.prototype.log=function(){},e.prototype.error=function(){},e}();
//# sourceMappingURL=dist/tamarind.js.map
//# sourceMappingURL=tamarind.js.map