var Tamarind;

Tamarind = {
  FRAGMENT_SHADER: 'FRAGMENT_SHADER',
  VERTEX_SHADER: 'VERTEX_SHADER'
};


/*
  Return false if the browser can't handle the awesome.
 */

Tamarind.browserSupportsRequiredFeatures = function() {
  var canvas, ctx;
  if (Tamarind.browserSupportsRequiredFeatures.__cache === void 0) {
    try {
      canvas = document.createElement('canvas');
      ctx = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
    } catch (_error) {}
    Tamarind.browserSupportsRequiredFeatures.__cache = !!(ctx && Object.defineProperty);
  }
  return Tamarind.browserSupportsRequiredFeatures.__cache;
};


/*
  Define a property on a class.

  If the property is `"fooBar"` then this method will require one or both of
  `_getFooBar()` or `_setFooBar(value)` to exist on the class and create a
  read-write, read-only or write-only property as appropriate.

  Additionally, a default value for the property can be provided in the class
  definition alongside the method declarations.

  @example
    class Foo
      prop: 4 # default value, will be set as prototype._prop = 4
      _getProp: -> @_prop
      _setProp: (val) -> @_prop = val

    defineClassProperty Foo, "prop"
 */

Tamarind.defineClassProperty = function(cls, propertyName) {
  var PropertyName, config, getter, initialValue, setter;
  PropertyName = propertyName[0].toUpperCase() + propertyName.slice(1);
  getter = cls.prototype['_get' + PropertyName];
  setter = cls.prototype['_set' + PropertyName];
  if (!(getter || setter)) {
    throw new Error(propertyName + ' must name a getter or a setter');
  }
  initialValue = cls.prototype[propertyName];
  if (initialValue !== void 0) {
    cls.prototype['_' + propertyName] = initialValue;
  }
  config = {
    enumerable: true,
    get: getter || function() {
      throw new Error(propertyName + ' is write-only');
    },
    set: setter || function() {
      throw new Error(propertyName + ' is read-only');
    }
  };
  Object.defineProperty(cls.prototype, propertyName, config);
};
;/*
** Copyright (c) 2012 The Khronos Group Inc.
**
** Permission is hereby granted, free of charge, to any person obtaining a
** copy of this software and/or associated documentation files (the
** "Materials"), to deal in the Materials without restriction, including
** without limitation the rights to use, copy, modify, merge, publish,
** distribute, sublicense, and/or sell copies of the Materials, and to
** permit persons to whom the Materials are furnished to do so, subject to
** the following conditions:
**
** The above copyright notice and this permission notice shall be included
** in all copies or substantial portions of the Materials.
**
** THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
** MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
** CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
** TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
** MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
*/

// Various functions for helping debug WebGL apps.

WebGLDebugUtils = function() {

/**
 * Wrapped logging function.
 * @param {string} msg Message to log.
 */
var log = function(msg) {
  if (window.console && window.console.log) {
    window.console.log(msg);
  }
};

/**
 * Wrapped error logging function.
 * @param {string} msg Message to log.
 */
var error = function(msg) {
  if (window.console && window.console.error) {
    window.console.error(msg);
  } else {
    log(msg);
  }
};


/**
 * Which arguments are enums based on the number of arguments to the function.
 * So
 *    'texImage2D': {
 *       9: { 0:true, 2:true, 6:true, 7:true },
 *       6: { 0:true, 2:true, 3:true, 4:true },
 *    },
 *
 * means if there are 9 arguments then 6 and 7 are enums, if there are 6
 * arguments 3 and 4 are enums
 *
 * @type {!Object.<number, !Object.<number, string>}
 */
var glValidEnumContexts = {
  // Generic setters and getters

  'enable': {1: { 0:true }},
  'disable': {1: { 0:true }},
  'getParameter': {1: { 0:true }},

  // Rendering

  'drawArrays': {3:{ 0:true }},
  'drawElements': {4:{ 0:true, 2:true }},

  // Shaders

  'createShader': {1: { 0:true }},
  'getShaderParameter': {2: { 1:true }},
  'getProgramParameter': {2: { 1:true }},
  'getShaderPrecisionFormat': {2: { 0: true, 1:true }},

  // Vertex attributes

  'getVertexAttrib': {2: { 1:true }},
  'vertexAttribPointer': {6: { 2:true }},

  // Textures

  'bindTexture': {2: { 0:true }},
  'activeTexture': {1: { 0:true }},
  'getTexParameter': {2: { 0:true, 1:true }},
  'texParameterf': {3: { 0:true, 1:true }},
  'texParameteri': {3: { 0:true, 1:true, 2:true }},
  'texImage2D': {
     9: { 0:true, 2:true, 6:true, 7:true },
     6: { 0:true, 2:true, 3:true, 4:true }
  },
  'texSubImage2D': {
    9: { 0:true, 6:true, 7:true },
    7: { 0:true, 4:true, 5:true }
  },
  'copyTexImage2D': {8: { 0:true, 2:true }},
  'copyTexSubImage2D': {8: { 0:true }},
  'generateMipmap': {1: { 0:true }},
  'compressedTexImage2D': {7: { 0: true, 2:true }},
  'compressedTexSubImage2D': {8: { 0: true, 6:true }},

  // Buffer objects

  'bindBuffer': {2: { 0:true }},
  'bufferData': {3: { 0:true, 2:true }},
  'bufferSubData': {3: { 0:true }},
  'getBufferParameter': {2: { 0:true, 1:true }},

  // Renderbuffers and framebuffers

  'pixelStorei': {2: { 0:true, 1:true }},
  'readPixels': {7: { 4:true, 5:true }},
  'bindRenderbuffer': {2: { 0:true }},
  'bindFramebuffer': {2: { 0:true }},
  'checkFramebufferStatus': {1: { 0:true }},
  'framebufferRenderbuffer': {4: { 0:true, 1:true, 2:true }},
  'framebufferTexture2D': {5: { 0:true, 1:true, 2:true }},
  'getFramebufferAttachmentParameter': {3: { 0:true, 1:true, 2:true }},
  'getRenderbufferParameter': {2: { 0:true, 1:true }},
  'renderbufferStorage': {4: { 0:true, 1:true }},

  // Frame buffer operations (clear, blend, depth test, stencil)

  'clear': {1: { 0: { 'enumBitwiseOr': ['COLOR_BUFFER_BIT', 'DEPTH_BUFFER_BIT', 'STENCIL_BUFFER_BIT'] }}},
  'depthFunc': {1: { 0:true }},
  'blendFunc': {2: { 0:true, 1:true }},
  'blendFuncSeparate': {4: { 0:true, 1:true, 2:true, 3:true }},
  'blendEquation': {1: { 0:true }},
  'blendEquationSeparate': {2: { 0:true, 1:true }},
  'stencilFunc': {3: { 0:true }},
  'stencilFuncSeparate': {4: { 0:true, 1:true }},
  'stencilMaskSeparate': {2: { 0:true }},
  'stencilOp': {3: { 0:true, 1:true, 2:true }},
  'stencilOpSeparate': {4: { 0:true, 1:true, 2:true, 3:true }},

  // Culling

  'cullFace': {1: { 0:true }},
  'frontFace': {1: { 0:true }},

  // ANGLE_instanced_arrays extension

  'drawArraysInstancedANGLE': {4: { 0:true }},
  'drawElementsInstancedANGLE': {5: { 0:true, 2:true }},

  // EXT_blend_minmax extension

  'blendEquationEXT': {1: { 0:true }}
};

/**
 * Map of numbers to names.
 * @type {Object}
 */
var glEnums = null;

/**
 * Map of names to numbers.
 * @type {Object}
 */
var enumStringToValue = null;

/**
 * Initializes this module. Safe to call more than once.
 * @param {!WebGLRenderingContext} ctx A WebGL context. If
 *    you have more than one context it doesn't matter which one
 *    you pass in, it is only used to pull out constants.
 */
function init(ctx) {
  if (glEnums == null) {
    glEnums = { };
    enumStringToValue = { };
    for (var propertyName in ctx) {
      if (typeof ctx[propertyName] == 'number') {
        glEnums[ctx[propertyName]] = propertyName;
        enumStringToValue[propertyName] = ctx[propertyName];
      }
    }
  }
}

/**
 * Checks the utils have been initialized.
 */
function checkInit() {
  if (glEnums == null) {
    throw 'WebGLDebugUtils.init(ctx) not called';
  }
}

/**
 * Returns true or false if value matches any WebGL enum
 * @param {*} value Value to check if it might be an enum.
 * @return {boolean} True if value matches one of the WebGL defined enums
 */
function mightBeEnum(value) {
  checkInit();
  return (glEnums[value] !== undefined);
}

/**
 * Gets an string version of an WebGL enum.
 *
 * Example:
 *   var str = WebGLDebugUtil.glEnumToString(ctx.getError());
 *
 * @param {number} value Value to return an enum for
 * @return {string} The string version of the enum.
 */
function glEnumToString(value) {
  checkInit();
  var name = glEnums[value];
  return (name !== undefined) ? ("gl." + name) :
      ("/*UNKNOWN WebGL ENUM*/ 0x" + value.toString(16) + "");
}

/**
 * Returns the string version of a WebGL argument.
 * Attempts to convert enum arguments to strings.
 * @param {string} functionName the name of the WebGL function.
 * @param {number} numArgs the number of arguments passed to the function.
 * @param {number} argumentIndx the index of the argument.
 * @param {*} value The value of the argument.
 * @return {string} The value as a string.
 */
function glFunctionArgToString(functionName, numArgs, argumentIndex, value) {
  var funcInfo = glValidEnumContexts[functionName];
  if (funcInfo !== undefined) {
    var funcInfo = funcInfo[numArgs];
    if (funcInfo !== undefined) {
      if (funcInfo[argumentIndex]) {
        if (typeof funcInfo[argumentIndex] === 'object' &&
            funcInfo[argumentIndex]['enumBitwiseOr'] !== undefined) {
          var enums = funcInfo[argumentIndex]['enumBitwiseOr'];
          var orResult = 0;
          var orEnums = [];
          for (var i = 0; i < enums.length; ++i) {
            var enumValue = enumStringToValue[enums[i]];
            if ((value & enumValue) !== 0) {
              orResult |= enumValue;
              orEnums.push(glEnumToString(enumValue));
            }
          }
          if (orResult === value) {
            return orEnums.join(' | ');
          } else {
            return glEnumToString(value);
          }
        } else {
          return glEnumToString(value);
        }
      }
    }
  }
  if (value === null) {
    return "null";
  } else if (value === undefined) {
    return "undefined";
  } else {
    return value.toString();
  }
}

/**
 * Converts the arguments of a WebGL function to a string.
 * Attempts to convert enum arguments to strings.
 *
 * @param {string} functionName the name of the WebGL function.
 * @param {number} args The arguments.
 * @return {string} The arguments as a string.
 */
function glFunctionArgsToString(functionName, args) {
  // apparently we can't do args.join(",");
  var argStr = "";
  var numArgs = args.length;
  for (var ii = 0; ii < numArgs; ++ii) {
    argStr += ((ii == 0) ? '' : ', ') +
        glFunctionArgToString(functionName, numArgs, ii, args[ii]);
  }
  return argStr;
};


function makePropertyWrapper(wrapper, original, propertyName) {
  //log("wrap prop: " + propertyName);
  wrapper.__defineGetter__(propertyName, function() {
    return original[propertyName];
  });
  // TODO(gmane): this needs to handle properties that take more than
  // one value?
  wrapper.__defineSetter__(propertyName, function(value) {
    //log("set: " + propertyName);
    original[propertyName] = value;
  });
}

// Makes a function that calls a function on another object.
function makeFunctionWrapper(original, functionName) {
  //log("wrap fn: " + functionName);
  var f = original[functionName];
  return function() {
    //log("call: " + functionName);
    var result = f.apply(original, arguments);
    return result;
  };
}

/**
 * Given a WebGL context returns a wrapped context that calls
 * gl.getError after every command and calls a function if the
 * result is not gl.NO_ERROR.
 *
 * @param {!WebGLRenderingContext} ctx The webgl context to
 *        wrap.
 * @param {!function(err, funcName, args): void} opt_onErrorFunc
 *        The function to call when gl.getError returns an
 *        error. If not specified the default function calls
 *        console.log with a message.
 * @param {!function(funcName, args): void} opt_onFunc The
 *        function to call when each webgl function is called.
 *        You can use this to log all calls for example.
 * @param {!WebGLRenderingContext} opt_err_ctx The webgl context
 *        to call getError on if different than ctx.
 */
function makeDebugContext(ctx, opt_onErrorFunc, opt_onFunc, opt_err_ctx) {
  opt_err_ctx = opt_err_ctx || ctx;
  init(ctx);
  opt_onErrorFunc = opt_onErrorFunc || function(err, functionName, args) {
        // apparently we can't do args.join(",");
        var argStr = "";
        var numArgs = args.length;
        for (var ii = 0; ii < numArgs; ++ii) {
          argStr += ((ii == 0) ? '' : ', ') +
              glFunctionArgToString(functionName, numArgs, ii, args[ii]);
        }
        error("WebGL error "+ glEnumToString(err) + " in "+ functionName +
              "(" + argStr + ")");
      };

  // Holds booleans for each GL error so after we get the error ourselves
  // we can still return it to the client app.
  var glErrorShadow = { };

  // Makes a function that calls a WebGL function and then calls getError.
  function makeErrorWrapper(ctx, functionName) {
    return function() {
      if (opt_onFunc) {
        opt_onFunc(functionName, arguments);
      }
      var result = ctx[functionName].apply(ctx, arguments);
      var err = opt_err_ctx.getError();
      if (err != 0) {
        glErrorShadow[err] = true;
        opt_onErrorFunc(err, functionName, arguments);
      }
      return result;
    };
  }

  // Make a an object that has a copy of every property of the WebGL context
  // but wraps all functions.
  var wrapper = {};
  for (var propertyName in ctx) {
    if (typeof ctx[propertyName] == 'function') {
      if (propertyName != 'getExtension') {
        wrapper[propertyName] = makeErrorWrapper(ctx, propertyName);
      } else {
        var wrapped = makeErrorWrapper(ctx, propertyName);
        wrapper[propertyName] = function () {
          var result = wrapped.apply(ctx, arguments);
          return makeDebugContext(result, opt_onErrorFunc, opt_onFunc, opt_err_ctx);
        };
      }
    } else {
      makePropertyWrapper(wrapper, ctx, propertyName);
    }
  }

  // Override the getError function with one that returns our saved results.
  wrapper.getError = function() {
    for (var err in glErrorShadow) {
      if (glErrorShadow.hasOwnProperty(err)) {
        if (glErrorShadow[err]) {
          glErrorShadow[err] = false;
          return err;
        }
      }
    }
    return ctx.NO_ERROR;
  };

  return wrapper;
}

function resetToInitialState(ctx) {
  var numAttribs = ctx.getParameter(ctx.MAX_VERTEX_ATTRIBS);
  var tmp = ctx.createBuffer();
  ctx.bindBuffer(ctx.ARRAY_BUFFER, tmp);
  for (var ii = 0; ii < numAttribs; ++ii) {
    ctx.disableVertexAttribArray(ii);
    ctx.vertexAttribPointer(ii, 4, ctx.FLOAT, false, 0, 0);
    ctx.vertexAttrib1f(ii, 0);
  }
  ctx.deleteBuffer(tmp);

  var numTextureUnits = ctx.getParameter(ctx.MAX_TEXTURE_IMAGE_UNITS);
  for (var ii = 0; ii < numTextureUnits; ++ii) {
    ctx.activeTexture(ctx.TEXTURE0 + ii);
    ctx.bindTexture(ctx.TEXTURE_CUBE_MAP, null);
    ctx.bindTexture(ctx.TEXTURE_2D, null);
  }

  ctx.activeTexture(ctx.TEXTURE0);
  ctx.useProgram(null);
  ctx.bindBuffer(ctx.ARRAY_BUFFER, null);
  ctx.bindBuffer(ctx.ELEMENT_ARRAY_BUFFER, null);
  ctx.bindFramebuffer(ctx.FRAMEBUFFER, null);
  ctx.bindRenderbuffer(ctx.RENDERBUFFER, null);
  ctx.disable(ctx.BLEND);
  ctx.disable(ctx.CULL_FACE);
  ctx.disable(ctx.DEPTH_TEST);
  ctx.disable(ctx.DITHER);
  ctx.disable(ctx.SCISSOR_TEST);
  ctx.blendColor(0, 0, 0, 0);
  ctx.blendEquation(ctx.FUNC_ADD);
  ctx.blendFunc(ctx.ONE, ctx.ZERO);
  ctx.clearColor(0, 0, 0, 0);
  ctx.clearDepth(1);
  ctx.clearStencil(-1);
  ctx.colorMask(true, true, true, true);
  ctx.cullFace(ctx.BACK);
  ctx.depthFunc(ctx.LESS);
  ctx.depthMask(true);
  ctx.depthRange(0, 1);
  ctx.frontFace(ctx.CCW);
  ctx.hint(ctx.GENERATE_MIPMAP_HINT, ctx.DONT_CARE);
  ctx.lineWidth(1);
  ctx.pixelStorei(ctx.PACK_ALIGNMENT, 4);
  ctx.pixelStorei(ctx.UNPACK_ALIGNMENT, 4);
  ctx.pixelStorei(ctx.UNPACK_FLIP_Y_WEBGL, false);
  ctx.pixelStorei(ctx.UNPACK_PREMULTIPLY_ALPHA_WEBGL, false);
  // TODO: Delete this IF.
  if (ctx.UNPACK_COLORSPACE_CONVERSION_WEBGL) {
    ctx.pixelStorei(ctx.UNPACK_COLORSPACE_CONVERSION_WEBGL, ctx.BROWSER_DEFAULT_WEBGL);
  }
  ctx.polygonOffset(0, 0);
  ctx.sampleCoverage(1, false);
  ctx.scissor(0, 0, ctx.canvas.width, ctx.canvas.height);
  ctx.stencilFunc(ctx.ALWAYS, 0, 0xFFFFFFFF);
  ctx.stencilMask(0xFFFFFFFF);
  ctx.stencilOp(ctx.KEEP, ctx.KEEP, ctx.KEEP);
  ctx.viewport(0, 0, ctx.canvas.width, ctx.canvas.height);
  ctx.clear(ctx.COLOR_BUFFER_BIT | ctx.DEPTH_BUFFER_BIT | ctx.STENCIL_BUFFER_BIT);

  // TODO: This should NOT be needed but Firefox fails with 'hint'
  while(ctx.getError());
}

function makeLostContextSimulatingCanvas(canvas) {
  var unwrappedContext_;
  var wrappedContext_;
  var onLost_ = [];
  var onRestored_ = [];
  var wrappedContext_ = {};
  var contextId_ = 1;
  var contextLost_ = false;
  var resourceId_ = 0;
  var resourceDb_ = [];
  var numCallsToLoseContext_ = 0;
  var numCalls_ = 0;
  var canRestore_ = false;
  var restoreTimeout_ = 0;

  // Holds booleans for each GL error so can simulate errors.
  var glErrorShadow_ = { };

  canvas.getContext = function(f) {
    return function() {
      var ctx = f.apply(canvas, arguments);
      // Did we get a context and is it a WebGL context?
      if (ctx instanceof WebGLRenderingContext) {
        if (ctx != unwrappedContext_) {
          if (unwrappedContext_) {
            throw "got different context"
          }
          unwrappedContext_ = ctx;
          wrappedContext_ = makeLostContextSimulatingContext(unwrappedContext_);
        }
        return wrappedContext_;
      }
      return ctx;
    }
  }(canvas.getContext);

  function wrapEvent(listener) {
    if (typeof(listener) == "function") {
      return listener;
    } else {
      return function(info) {
        listener.handleEvent(info);
      }
    }
  }

  var addOnContextLostListener = function(listener) {
    onLost_.push(wrapEvent(listener));
  };

  var addOnContextRestoredListener = function(listener) {
    onRestored_.push(wrapEvent(listener));
  };


  function wrapAddEventListener(canvas) {
    var f = canvas.addEventListener;
    canvas.addEventListener = function(type, listener, bubble) {
      switch (type) {
        case 'webglcontextlost':
          addOnContextLostListener(listener);
          break;
        case 'webglcontextrestored':
          addOnContextRestoredListener(listener);
          break;
        default:
          f.apply(canvas, arguments);
      }
    };
  }

  wrapAddEventListener(canvas);

  canvas.loseContext = function() {
    if (!contextLost_) {
      contextLost_ = true;
      numCallsToLoseContext_ = 0;
      ++contextId_;
      while (unwrappedContext_.getError());
      clearErrors();
      glErrorShadow_[unwrappedContext_.CONTEXT_LOST_WEBGL] = true;
      var event = makeWebGLContextEvent("context lost");
      var callbacks = onLost_.slice();
      setTimeout(function() {
          //log("numCallbacks:" + callbacks.length);
          for (var ii = 0; ii < callbacks.length; ++ii) {
            //log("calling callback:" + ii);
            callbacks[ii](event);
          }
          if (restoreTimeout_ >= 0) {
            setTimeout(function() {
                canvas.restoreContext();
              }, restoreTimeout_);
          }
        }, 0);
    }
  };

  canvas.restoreContext = function() {
    if (contextLost_) {
      if (onRestored_.length) {
        setTimeout(function() {
            if (!canRestore_) {
              throw "can not restore. webglcontestlost listener did not call event.preventDefault";
            }
            freeResources();
            resetToInitialState(unwrappedContext_);
            contextLost_ = false;
            numCalls_ = 0;
            canRestore_ = false;
            var callbacks = onRestored_.slice();
            var event = makeWebGLContextEvent("context restored");
            for (var ii = 0; ii < callbacks.length; ++ii) {
              callbacks[ii](event);
            }
          }, 0);
      }
    }
  };

  canvas.loseContextInNCalls = function(numCalls) {
    if (contextLost_) {
      throw "You can not ask a lost contet to be lost";
    }
    numCallsToLoseContext_ = numCalls_ + numCalls;
  };

  canvas.getNumCalls = function() {
    return numCalls_;
  };

  canvas.setRestoreTimeout = function(timeout) {
    restoreTimeout_ = timeout;
  };

  function isWebGLObject(obj) {
    //return false;
    return (obj instanceof WebGLBuffer ||
            obj instanceof WebGLFramebuffer ||
            obj instanceof WebGLProgram ||
            obj instanceof WebGLRenderbuffer ||
            obj instanceof WebGLShader ||
            obj instanceof WebGLTexture);
  }

  function checkResources(args) {
    for (var ii = 0; ii < args.length; ++ii) {
      var arg = args[ii];
      if (isWebGLObject(arg)) {
        return arg.__webglDebugContextLostId__ == contextId_;
      }
    }
    return true;
  }

  function clearErrors() {
    var k = Object.keys(glErrorShadow_);
    for (var ii = 0; ii < k.length; ++ii) {
      delete glErrorShadow_[k];
    }
  }

  function loseContextIfTime() {
    ++numCalls_;
    if (!contextLost_) {
      if (numCallsToLoseContext_ == numCalls_) {
        canvas.loseContext();
      }
    }
  }

  // Makes a function that simulates WebGL when out of context.
  function makeLostContextFunctionWrapper(ctx, functionName) {
    var f = ctx[functionName];
    return function() {
      // log("calling:" + functionName);
      // Only call the functions if the context is not lost.
      loseContextIfTime();
      if (!contextLost_) {
        //if (!checkResources(arguments)) {
        //  glErrorShadow_[wrappedContext_.INVALID_OPERATION] = true;
        //  return;
        //}
        var result = f.apply(ctx, arguments);
        return result;
      }
    };
  }

  function freeResources() {
    for (var ii = 0; ii < resourceDb_.length; ++ii) {
      var resource = resourceDb_[ii];
      if (resource instanceof WebGLBuffer) {
        unwrappedContext_.deleteBuffer(resource);
      } else if (resource instanceof WebGLFramebuffer) {
        unwrappedContext_.deleteFramebuffer(resource);
      } else if (resource instanceof WebGLProgram) {
        unwrappedContext_.deleteProgram(resource);
      } else if (resource instanceof WebGLRenderbuffer) {
        unwrappedContext_.deleteRenderbuffer(resource);
      } else if (resource instanceof WebGLShader) {
        unwrappedContext_.deleteShader(resource);
      } else if (resource instanceof WebGLTexture) {
        unwrappedContext_.deleteTexture(resource);
      }
    }
  }

  function makeWebGLContextEvent(statusMessage) {
    return {
      statusMessage: statusMessage,
      preventDefault: function() {
          canRestore_ = true;
        }
    };
  }

  return canvas;

  function makeLostContextSimulatingContext(ctx) {
    // copy all functions and properties to wrapper
    for (var propertyName in ctx) {
      if (typeof ctx[propertyName] == 'function') {
         wrappedContext_[propertyName] = makeLostContextFunctionWrapper(
             ctx, propertyName);
       } else {
         makePropertyWrapper(wrappedContext_, ctx, propertyName);
       }
    }

    // Wrap a few functions specially.
    wrappedContext_.getError = function() {
      loseContextIfTime();
      if (!contextLost_) {
        var err;
        while (err = unwrappedContext_.getError()) {
          glErrorShadow_[err] = true;
        }
      }
      for (var err in glErrorShadow_) {
        if (glErrorShadow_[err]) {
          delete glErrorShadow_[err];
          return err;
        }
      }
      return wrappedContext_.NO_ERROR;
    };

    var creationFunctions = [
      "createBuffer",
      "createFramebuffer",
      "createProgram",
      "createRenderbuffer",
      "createShader",
      "createTexture"
    ];
    for (var ii = 0; ii < creationFunctions.length; ++ii) {
      var functionName = creationFunctions[ii];
      wrappedContext_[functionName] = function(f) {
        return function() {
          loseContextIfTime();
          if (contextLost_) {
            return null;
          }
          var obj = f.apply(ctx, arguments);
          obj.__webglDebugContextLostId__ = contextId_;
          resourceDb_.push(obj);
          return obj;
        };
      }(ctx[functionName]);
    }

    var functionsThatShouldReturnNull = [
      "getActiveAttrib",
      "getActiveUniform",
      "getBufferParameter",
      "getContextAttributes",
      "getAttachedShaders",
      "getFramebufferAttachmentParameter",
      "getParameter",
      "getProgramParameter",
      "getProgramInfoLog",
      "getRenderbufferParameter",
      "getShaderParameter",
      "getShaderInfoLog",
      "getShaderSource",
      "getTexParameter",
      "getUniform",
      "getUniformLocation",
      "getVertexAttrib"
    ];
    for (var ii = 0; ii < functionsThatShouldReturnNull.length; ++ii) {
      var functionName = functionsThatShouldReturnNull[ii];
      wrappedContext_[functionName] = function(f) {
        return function() {
          loseContextIfTime();
          if (contextLost_) {
            return null;
          }
          return f.apply(ctx, arguments);
        }
      }(wrappedContext_[functionName]);
    }

    var isFunctions = [
      "isBuffer",
      "isEnabled",
      "isFramebuffer",
      "isProgram",
      "isRenderbuffer",
      "isShader",
      "isTexture"
    ];
    for (var ii = 0; ii < isFunctions.length; ++ii) {
      var functionName = isFunctions[ii];
      wrappedContext_[functionName] = function(f) {
        return function() {
          loseContextIfTime();
          if (contextLost_) {
            return false;
          }
          return f.apply(ctx, arguments);
        }
      }(wrappedContext_[functionName]);
    }

    wrappedContext_.checkFramebufferStatus = function(f) {
      return function() {
        loseContextIfTime();
        if (contextLost_) {
          return wrappedContext_.FRAMEBUFFER_UNSUPPORTED;
        }
        return f.apply(ctx, arguments);
      };
    }(wrappedContext_.checkFramebufferStatus);

    wrappedContext_.getAttribLocation = function(f) {
      return function() {
        loseContextIfTime();
        if (contextLost_) {
          return -1;
        }
        return f.apply(ctx, arguments);
      };
    }(wrappedContext_.getAttribLocation);

    wrappedContext_.getVertexAttribOffset = function(f) {
      return function() {
        loseContextIfTime();
        if (contextLost_) {
          return 0;
        }
        return f.apply(ctx, arguments);
      };
    }(wrappedContext_.getVertexAttribOffset);

    wrappedContext_.isContextLost = function() {
      return contextLost_;
    };

    return wrappedContext_;
  }
}

return {
  /**
   * Initializes this module. Safe to call more than once.
   * @param {!WebGLRenderingContext} ctx A WebGL context. If
   *    you have more than one context it doesn't matter which one
   *    you pass in, it is only used to pull out constants.
   */
  'init': init,

  /**
   * Returns true or false if value matches any WebGL enum
   * @param {*} value Value to check if it might be an enum.
   * @return {boolean} True if value matches one of the WebGL defined enums
   */
  'mightBeEnum': mightBeEnum,

  /**
   * Gets an string version of an WebGL enum.
   *
   * Example:
   *   WebGLDebugUtil.init(ctx);
   *   var str = WebGLDebugUtil.glEnumToString(ctx.getError());
   *
   * @param {number} value Value to return an enum for
   * @return {string} The string version of the enum.
   */
  'glEnumToString': glEnumToString,

  /**
   * Converts the argument of a WebGL function to a string.
   * Attempts to convert enum arguments to strings.
   *
   * Example:
   *   WebGLDebugUtil.init(ctx);
   *   var str = WebGLDebugUtil.glFunctionArgToString('bindTexture', 2, 0, gl.TEXTURE_2D);
   *
   * would return 'TEXTURE_2D'
   *
   * @param {string} functionName the name of the WebGL function.
   * @param {number} numArgs The number of arguments
   * @param {number} argumentIndx the index of the argument.
   * @param {*} value The value of the argument.
   * @return {string} The value as a string.
   */
  'glFunctionArgToString': glFunctionArgToString,

  /**
   * Converts the arguments of a WebGL function to a string.
   * Attempts to convert enum arguments to strings.
   *
   * @param {string} functionName the name of the WebGL function.
   * @param {number} args The arguments.
   * @return {string} The arguments as a string.
   */
  'glFunctionArgsToString': glFunctionArgsToString,

  /**
   * Given a WebGL context returns a wrapped context that calls
   * gl.getError after every command and calls a function if the
   * result is not NO_ERROR.
   *
   * You can supply your own function if you want. For example, if you'd like
   * an exception thrown on any GL error you could do this
   *
   *    function throwOnGLError(err, funcName, args) {
   *      throw WebGLDebugUtils.glEnumToString(err) +
   *            " was caused by call to " + funcName;
   *    };
   *
   *    ctx = WebGLDebugUtils.makeDebugContext(
   *        canvas.getContext("webgl"), throwOnGLError);
   *
   * @param {!WebGLRenderingContext} ctx The webgl context to wrap.
   * @param {!function(err, funcName, args): void} opt_onErrorFunc The function
   *     to call when gl.getError returns an error. If not specified the default
   *     function calls console.log with a message.
   * @param {!function(funcName, args): void} opt_onFunc The
   *     function to call when each webgl function is called. You
   *     can use this to log all calls for example.
   */
  'makeDebugContext': makeDebugContext,

  /**
   * Given a canvas element returns a wrapped canvas element that will
   * simulate lost context. The canvas returned adds the following functions.
   *
   * loseContext:
   *   simulates a lost context event.
   *
   * restoreContext:
   *   simulates the context being restored.
   *
   * lostContextInNCalls:
   *   loses the context after N gl calls.
   *
   * getNumCalls:
   *   tells you how many gl calls there have been so far.
   *
   * setRestoreTimeout:
   *   sets the number of milliseconds until the context is restored
   *   after it has been lost. Defaults to 0. Pass -1 to prevent
   *   automatic restoring.
   *
   * @param {!Canvas} canvas The canvas element to wrap.
   */
  'makeLostContextSimulatingCanvas': makeLostContextSimulatingCanvas,

  /**
   * Resets a context to the initial state.
   * @param {!WebGLRenderingContext} ctx The webgl context to
   *     reset.
   */
  'resetToInitialState': resetToInitialState
};

}();


/*
  Superclass to handle event dispatch
 */
var EventEmitter;

EventEmitter = (function() {
  function EventEmitter() {}

  EventEmitter.prototype.on = function(eventName, callback) {
    var list;
    this._validateEventArgs(eventName, callback);
    list = this._getEventList(eventName);
    if (list.indexOf(callback) === -1) {
      list.push(callback);
    }
  };

  EventEmitter.prototype.off = function(eventName, callback) {
    var index, list;
    this._validateEventArgs(eventName, callback);
    list = this._getEventList(eventName);
    index = list.indexOf(callback);
    if (index !== -1) {
      list.splice(index, 1);
    }
  };

  EventEmitter.prototype.emit = function(eventName, event) {
    var f, _i, _len, _ref;
    this._validateEventArgs(eventName);
    _ref = this._getEventList(eventName);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      f = _ref[_i];
      f.call(this, event);
    }
  };

  EventEmitter.prototype._getEventList = function(eventName) {
    if (!this._events) {
      this._events = {};
    }
    if (!this._events[eventName]) {
      this._events[eventName] = [];
    }
    return this._events[eventName];
  };

  EventEmitter.prototype._validateEventArgs = function(eventName, callback) {
    if (typeof eventName !== 'string') {
      throw new Error('eventName must be a string');
    }
    if (arguments.length > 1 && typeof callback !== 'function') {
      throw new Error('callback must be a function');
    }
  };

  return EventEmitter;

})();
;var ShaderEditor, ToggleBar, mergeObjects, replaceScriptTemplates,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

replaceScriptTemplates = function() {
  var config, configJSON, e, editor, scriptTemplate, _i, _len, _ref;
  _ref = document.querySelectorAll("script[type='application/x-tamarind-editor']");
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    scriptTemplate = _ref[_i];
    configJSON = scriptTemplate.text.trim();
    if (configJSON.length > 0) {
      try {
        config = JSON.parse(configJSON);
      } catch (_error) {
        e = _error;
        console.error('Failed to parse Tamarind config: "' + e + '" in source:\n' + configJSON);
        continue;
      }
    } else {
      config = {};
    }
    editor = new ShaderEditor(scriptTemplate, config);
  }
};

ShaderEditor = (function(_super) {
  var CONFIG, MENU_ITEM_SELECT, NOT_SUPPORTED_HTML, TEMPLATE;

  __extends(ShaderEditor, _super);

  CONFIG = 'config';

  MENU_ITEM_SELECT = 'menu-item-select';

  NOT_SUPPORTED_HTML = '<span class="tamarind-icon-unhappy tamarind-unsupported-icon" title="And lo there shall be no editor, and in that place there shall be wailing and gnashing of teeth."></span>\nYour browser doesn\'t support this feature. Try Internet Explorer 11+ or recent versions of Chrome, Firefox or Safari.';

  TEMPLATE = "<div class=\"tamarind-menu\">\n  <a href=\"javascript:void(0)\" name=\"" + Tamarind.FRAGMENT_SHADER + "\" class=\"tamarind-menu-button tamarind-icon-fragment-shader\" title=\"Fragment shader\"></a>\n  <a href=\"javascript:void(0)\" name=\"" + Tamarind.VERTEX_SHADER + "\" class=\"tamarind-menu-button tamarind-icon-vertex-shader\" title=\"Vertex shader\"></a>\n  <a href=\"javascript:void(0)\" name=\"" + CONFIG + "\" class=\"tamarind-menu-button tamarind-icon-config\" title=\"Scene setup\"></a>\n</div>\n<div class=\"tamarind-editor-panel\">\n  <div class=\"tamarind-editor tamarind-editor-code\">\n    <div class=\"tamarind-program-error\">\n      <span class=\"CodeMirror-lint-marker-error\"></span>\n      <span class=\"tamarind-program-error-message\"></span>\n    </div>\n  </div>\n  <div class=\"tamarind-editor tamarind-editor-config\">\n\n    Render\n    <input type=\"number\" name=\"vertexCount\" min=\"1\" class=\"tamarind-number-input\">\n\n    vertices as\n\n    <select name=\"drawingMode\">\n        <option>POINTS</option>\n        <option>LINES</option>\n        <option>LINE_LOOP</option>\n        <option>LINE_STRIP</option>\n        <option>TRIANGLES</option>\n        <option>TRIANGLE_STRIP</option>\n        <option>TRIANGLE_FAN</option>\n    </select>\n  </div>\n</div>\n<div class=\"tamarind-render-panel\">\n  <canvas class=\"tamarind-render-canvas\"></canvas>\n</div>";

  ShaderEditor.prototype.canvas = null;

  function ShaderEditor(location, config) {
    var createDoc;
    if (config == null) {
      config = {};
    }
    this._addLineWrapIndent = __bind(this._addLineWrapIndent, this);
    this._setProgramError = __bind(this._setProgramError, this);
    this._handleShaderCompile = __bind(this._handleShaderCompile, this);
    this._handleCodeMirrorLint = __bind(this._handleCodeMirrorLint, this);
    this._element = document.createElement('div');
    this._element.className = 'tamarind';
    this._element.editor = this;
    location.parentNode.insertBefore(this._element, location);
    location.parentNode.removeChild(location);
    if (!Tamarind.browserSupportsRequiredFeatures()) {
      this._element.innerHTML = NOT_SUPPORTED_HTML;
      this._element.className += ' tamarind-unsupported';
      return;
    } else {
      this._element.className = 'tamarind';
    }
    this._element.innerHTML = TEMPLATE;
    this._editorCodeElement = this._element.querySelector('.tamarind-editor-code');
    this._editorConfigElement = this._element.querySelector('.tamarind-editor-config');
    this._renderCanvasElement = this._element.querySelector('.tamarind-render-canvas');
    this._menuElement = this._element.querySelector('.tamarind-menu');
    this._vertexCountInputElement = this._element.querySelector('[name="vertexCount"]');
    this._drawingModeInputElement = this._element.querySelector('[name="drawingMode"]');
    new ToggleBar(this._menuElement, this, MENU_ITEM_SELECT);
    this._canvas = new WebGLCanvas(this._renderCanvasElement);
    this._canvas.on(WebGLCanvas.COMPILE, this._handleShaderCompile);
    this._canvas.on(WebGLCanvas.LINK, this._setProgramError);
    this._shaderDocs = {};
    createDoc = (function(_this) {
      return function(shaderType) {
        var doc;
        doc = CodeMirror.Doc(_this._canvas.getShaderSource(shaderType), 'clike');
        doc.shaderType = shaderType;
        _this._shaderDocs[shaderType] = doc;
      };
    })(this);
    createDoc(Tamarind.FRAGMENT_SHADER);
    createDoc(Tamarind.VERTEX_SHADER);
    this._bindInputToCanvas(this._vertexCountInputElement, 'vertexCount', parseInt);
    this._bindInputToCanvas(this._drawingModeInputElement, 'drawingMode');
    this._codemirror = CodeMirror(this._editorCodeElement, {
      value: this._shaderDocs[Tamarind.FRAGMENT_SHADER],
      lineNumbers: true,
      lineWrapping: true,
      gutters: ['CodeMirror-lint-markers'],
      lint: {
        getAnnotations: this._handleCodeMirrorLint,
        async: true,
        delay: 200
      }
    });
    this._codemirror.on('renderLine', this._addLineWrapIndent);
    this._codemirror.refresh();
    this._programErrorElement = this._element.querySelector('.tamarind-program-error');
    this._setProgramError(false);
    this._codemirror.display.wrapper.insertBefore(this._programErrorElement, this._codemirror.display.wrapper.firstChild);
    this.on(MENU_ITEM_SELECT, this._handleMenuItemSelect);
    mergeObjects(config, this);
  }

  ShaderEditor.prototype.reset = function(config) {
    var doc, type, _ref, _results;
    mergeObjects(config, this);
    _ref = this._shaderDocs;
    _results = [];
    for (type in _ref) {
      doc = _ref[type];
      _results.push(doc.setValue(this._canvas.getShaderSource(type)));
    }
    return _results;
  };

  ShaderEditor.prototype._bindInputToCanvas = function(input, propertyName, parseFunction) {
    if (parseFunction == null) {
      parseFunction = String;
    }
    input.value = this._canvas[propertyName];
    input.addEventListener('input', (function(_this) {
      return function() {
        _this._canvas[propertyName] = parseFunction(input.value);
      };
    })(this));
  };

  ShaderEditor.prototype._handleCodeMirrorLint = function(value, callback, options, cm) {
    if (this._codemirror) {
      this._canvas.setShaderSource(this._codemirror.getDoc().shaderType, value);
    }
    this._lintingCallback = callback;
  };

  ShaderEditor.prototype._handleShaderCompile = function(compileEvent) {
    var err, errors;
    if (compileEvent.shaderType === this._activeCodeEditor) {
      errors = (function() {
        var _i, _len, _ref, _results;
        _ref = compileEvent.errors;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          err = _ref[_i];
          _results.push({
            message: err.message,
            from: {
              line: err.line
            },
            to: {
              line: err.line
            }
          });
        }
        return _results;
      })();
      this._lintingCallback(this._codemirror, errors);
    }
  };

  ShaderEditor.prototype._setProgramError = function(error) {
    var msgElement;
    if (error) {
      this._programErrorElement.style.display = '';
      msgElement = this._programErrorElement.querySelector('.tamarind-program-error-message');
      msgElement.innerHTML = '';
      msgElement.appendChild(document.createTextNode('Program error: ' + error));
    } else {
      this._programErrorElement.style.display = 'none';
    }
  };

  ShaderEditor.prototype._addLineWrapIndent = function(cm, line, elt) {
    var basePadding, indentChars, offset;
    if (!this._codeCharWidth) {
      this._codeCharWidth = this._codemirror.defaultCharWidth();
    }
    basePadding = 4;
    indentChars = 2;
    offset = CodeMirror.countColumn(line.text, null, cm.getOption('tabSize')) * this._codeCharWidth;
    elt.style.textIndent = '-' + (offset + this._codeCharWidth * indentChars) + 'px';
    elt.style.paddingLeft = (basePadding + offset + this._codeCharWidth * indentChars) + 'px';
  };

  ShaderEditor.prototype._handleMenuItemSelect = function(item) {
    if (item === CONFIG) {
      this._editorCodeElement.style.display = 'none';
      this._editorConfigElement.style.display = '';
    } else {
      this._editorCodeElement.style.display = '';
      this._editorConfigElement.style.display = 'none';
      this._activeCodeEditor = item;
      this._codemirror.swapDoc(this._shaderDocs[item]);
    }
  };

  ShaderEditor.prototype._getCanvas = function() {
    return this._canvas;
  };

  return ShaderEditor;

})(EventEmitter);

Tamarind.defineClassProperty(ShaderEditor, 'canvas');

ToggleBar = (function() {
  function ToggleBar(_parent, _events, _eventName) {
    this._parent = _parent;
    this._events = _events;
    this._eventName = _eventName;
    this.selectChild = __bind(this.selectChild, this);
    this._parent.addEventListener('click', (function(_this) {
      return function(event) {
        return _this.selectChild(event.target);
      };
    })(this));
    this._children = this._parent.querySelectorAll('a');
    this._selectedChild = null;
    this.selectChild(this._children[0]);
  }

  ToggleBar.prototype.selectChild = function(childToSelect) {
    var child, _i, _len, _ref;
    if (__indexOf.call(this._children, childToSelect) < 0) {
      return;
    }
    if (this._selectedChild === childToSelect) {
      return;
    }
    this._selectedChild = childToSelect;
    _ref = this._children;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      child = _ref[_i];
      if (child === childToSelect) {
        child.classList.add('is-selected');
      } else {
        child.classList.remove('is-selected');
      }
    }
    setTimeout(((function(_this) {
      return function() {
        return _this._events.emit(_this._eventName, _this._selectedChild.name);
      };
    })(this)), 1);
  };

  return ToggleBar;

})();

mergeObjects = function(source, dest) {
  var destType, destValue, prop, sourceType, sourceValue;
  for (prop in source) {
    destValue = dest[prop];
    destType = typeof destValue;
    sourceValue = source[prop];
    sourceType = typeof sourceValue;
    if (sourceType !== destType) {
      throw new Error("Can't merge property '" + prop + "': source is " + sourceType + " destination is " + destType);
    }
    if (typeof destValue === 'object') {
      if (typeof sourceValue !== 'object') {
        throw new Error("Can't merge simple source onto complex destination for property '" + prop + "'");
      }
      mergeObjects(sourceValue, destValue);
    } else {
      dest[prop] = sourceValue;
    }
  }
};
;
/*
  An object associated with a canvas element that manages the WebGL context
  and associated resources.

  THE RESOURCE MANAGEMENT GRAPH


             -- VERT
           /         \
    CONTEXT -- FRAG -- LINK -- RENDER
           \                 /
             -- GEOM --------


  1. CONTEXT:  set up WebGL context
  2. VERT:     compile vertex shader
  3. FRAG:     compile fragment shader
  4. LINK:     link program, look up and cache attribute and uniform locations
  5. GEOM:     generate vertex buffer with geometry
  6. RENDER:   set values for uniforms, update viewport dimensions, render scene

  When the object is first created, each step is performed in dependency order from context creation
  to rendering. Various API methods will invalidate a specific step, requiring that it and all dependent steps
  are cleaned up and done again. For example, changing vertexCount will invalidate the GEOM step which
  requires uniforms to be set again.
 */
var CompileStatus, WebGLCanvas,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

WebGLCanvas = (function(_super) {
  var SET_UNIFORM_FUNCTION_NAMES, VALID_DRAWING_MODES, VERTEX_INDEX_ATTRIBUTE_LOCATION;

  __extends(WebGLCanvas, _super);

  WebGLCanvas.DEFAULT_VSHADER_SOURCE = 'attribute float a_VertexIndex;\nvarying vec2 position;\n\nvoid main() {\n  // this is the default vertex shader. It positions 4 points, one in each corner clockwise from top left, creating a rectangle that fills the whole canvas.\n  if (a_VertexIndex == 0.0) {\n    position = vec2(-1, -1);\n  } else if (a_VertexIndex == 1.0) {\n    position = vec2(1, -1);\n  } else if (a_VertexIndex == 2.0) {\n    position = vec2(1, 1);\n  } else if (a_VertexIndex == 3.0) {\n    position = vec2(-1, 1);\n  } else {\n    position = vec2(0);\n  }\n  gl_Position.xy = position;\n}';

  WebGLCanvas.DEFAULT_FSHADER_SOURCE = 'precision mediump float;\nuniform vec2 u_CanvasSize;\nvarying vec2 position;\n\nvoid main() {\n  gl_FragColor = vec4(position, 1, 1);\n}';

  VERTEX_INDEX_ATTRIBUTE_LOCATION = 0;

  VALID_DRAWING_MODES = 'POINTS,LINES,LINE_LOOP,LINE_STRIP,TRIANGLES,TRIANGLE_STRIP,TRIANGLE_FAN'.split(',');

  SET_UNIFORM_FUNCTION_NAMES = [null, 'uniform1f', 'uniform2f', 'uniform3f', 'uniform4f'];

  WebGLCanvas.COMPILE = 'compile';

  WebGLCanvas.LINK = 'link';

  WebGLCanvas.prototype.vertexCount = 4;

  WebGLCanvas.prototype.drawingMode = 'TRIANGLE_FAN';

  WebGLCanvas.prototype.debugMode = false;

  function WebGLCanvas(canvasElement, debugMode) {
    this.canvasElement = canvasElement;
    this.debugMode = debugMode != null ? debugMode : false;
    this._handleContextRestored = __bind(this._handleContextRestored, this);
    this._handleContextLost = __bind(this._handleContextLost, this);
    this._doFrame = __bind(this._doFrame, this);
    if (!Tamarind.browserSupportsRequiredFeatures()) {
      throw new Error('This browser does not support WebGL');
    }
    this.canvasElement.addEventListener('webglcontextcreationerror', (function(_this) {
      return function(event) {
        _this.trace.error(event.statusMessage);
      };
    })(this));
    this.canvasElement.addEventListener('webglcontextlost', this._handleContextLost);
    this.canvasElement.addEventListener('webglcontextrestored', this._handleContextRestored);
    this._shaders = {};
    this._shaderSources = {};
    this._shaderSources[Tamarind.FRAGMENT_SHADER] = WebGLCanvas.DEFAULT_FSHADER_SOURCE;
    this._shaderSources[Tamarind.VERTEX_SHADER] = WebGLCanvas.DEFAULT_VSHADER_SOURCE;
    this._shaderDirty = {};
    this._createContext();
    if (!this.gl) {
      throw new Error('Could not create WebGL context for canvas');
    }
    this.drawingMode = 'TRIANGLE_FAN';
    this._scheduleFrame();
    return;
  }

  WebGLCanvas.prototype._scheduleFrame = function() {
    if (!this._frameScheduled) {
      this._frameScheduled = true;
      requestAnimationFrame(this._doFrame);
    }
  };

  WebGLCanvas.prototype._doFrame = function() {
    var isNewContext, requiresLink, shaderType, _i, _len, _ref;
    this._frameScheduled = false;
    if (this._contextLost) {
      return false;
    }
    isNewContext = this._contextRequiresSetup;
    if (this._contextRequiresSetup) {
      if (!this._setupContext()) {
        return false;
      }
      this._contextRequiresSetup = false;
    }
    if (this._geometryIsDirty || isNewContext) {
      if (!this._updateGeometry()) {
        return false;
      }
      this._geometryIsDirty = false;
    }
    _ref = [Tamarind.VERTEX_SHADER, Tamarind.FRAGMENT_SHADER];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      shaderType = _ref[_i];
      if (this._shaderDirty[shaderType] || isNewContext) {
        if (!this._compileShader(shaderType)) {
          return false;
        }
        this._shaderDirty[shaderType];
        requiresLink = true;
      }
    }
    if (requiresLink) {
      if (!this._linkProgram()) {
        return false;
      }
    }
    return this._render();
  };

  WebGLCanvas.prototype._createContext = function() {
    var intMode, mode, onFunctionCall, opts, _i, _len;
    opts = {
      premultipliedAlpha: false
    };
    this.nativeContext = this.canvasElement.getContext('webgl', opts) || this.canvasElement.getContext('experimental-webgl', opts);
    onFunctionCall = function(functionName, args) {
      var arg, _i, _len;
      for (_i = 0, _len = args.length; _i < _len; _i++) {
        arg = args[_i];
        if (arg === void 0) {
          throw new Error('undefined passed to gl.' + functionName + '(' + WebGLDebugUtils.glFunctionArgsToString(functionName, args) + ')');
        }
      }
    };
    this.debugContext = WebGLDebugUtils.makeDebugContext(this.nativeContext, null, onFunctionCall, null);
    this._contextRequiresSetup = true;
    this.gl = this._debugMode ? this.debugContext : this.nativeContext;
    this._drawingModeNames = {};
    for (_i = 0, _len = VALID_DRAWING_MODES.length; _i < _len; _i++) {
      mode = VALID_DRAWING_MODES[_i];
      intMode = this.gl[mode];
      if (intMode === void 0) {
        throw new Error(mode + ' is not a valid drawing mode');
      }
      this._drawingModeNames[intMode] = mode;
    }
  };

  WebGLCanvas.prototype._setupContext = function() {
    var gl;
    gl = this.gl;
    if (!(this._program = gl.createProgram())) {
      return false;
    }
    this._shaders = {};
    if (!(this._vertexBuffer = gl.createBuffer())) {
      return false;
    }
    return true;
  };

  WebGLCanvas.prototype._compileShader = function(shaderType) {
    var compiled, error, gl, oldShader, shader, source;
    gl = this.gl;
    source = this._shaderSources[shaderType];
    oldShader = this._shaders[shaderType];
    if (oldShader) {
      gl.detachShader(this._program, oldShader);
      gl.deleteShader(oldShader);
    }
    this._shaders[shaderType] = shader = gl.createShader(gl[shaderType]);
    if (!shader) {
      return false;
    }
    gl.attachShader(this._program, shader);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
    error = compiled ? null : gl.getShaderInfoLog(shader);
    this.emit(WebGLCanvas.COMPILE, new CompileStatus(shaderType, error));
    return compiled;
  };

  WebGLCanvas.prototype._linkProgram = function() {
    var gl, i, linked, numUniforms, uniform, _i, _ref;
    gl = this.gl;
    gl.bindAttribLocation(this._program, VERTEX_INDEX_ATTRIBUTE_LOCATION, 'a_VertexIndex');
    gl.linkProgram(this._program);
    linked = gl.getProgramParameter(this._program, gl.LINK_STATUS);
    if (!linked) {
      this.emit(WebGLCanvas.LINK, gl.getProgramInfoLog(this._program).trim());
      return false;
    }
    this.emit(WebGLCanvas.LINK, false);
    gl.useProgram(this._program);
    numUniforms = gl.getProgramParameter(this._program, gl.ACTIVE_UNIFORMS);
    this._uniformInfoByName = {};
    for (i = _i = 0, _ref = numUniforms - 1; _i <= _ref; i = _i += 1) {
      uniform = gl.getActiveUniform(this._program, i);
      this._uniformInfoByName[uniform.name] = {
        location: gl.getUniformLocation(this._program, i),
        type: uniform.type
      };
    }
    return true;
  };

  WebGLCanvas.prototype._updateGeometry = function() {
    var gl, i, vertices;
    gl = this.gl;
    vertices = new Float32Array(this.vertexCount);
    for (i in vertices) {
      vertices[i] = i;
    }
    gl.bindBuffer(gl.ARRAY_BUFFER, this._vertexBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
    gl.vertexAttribPointer(VERTEX_INDEX_ATTRIBUTE_LOCATION, 1, gl.FLOAT, false, 0, 0);
    gl.enableVertexAttribArray(VERTEX_INDEX_ATTRIBUTE_LOCATION);
    return true;
  };

  WebGLCanvas.prototype._render = function(explicitWidth, explicitHeight) {
    var gl, height, width;
    gl = this.gl;
    width = explicitWidth || Math.round(this.canvasElement.offsetWidth * (window.devicePixelRatio || 1));
    height = explicitHeight || Math.round(this.canvasElement.offsetHeight * (window.devicePixelRatio || 1));
    this._setUniform('u_CanvasSize', width, height);
    if (!(width === this._width && height === this._height)) {
      this._width = this.canvasElement.width = width;
      this._height = this.canvasElement.height = height;
      gl.viewport(0, 0, width, height);
    }
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.drawArrays(this._drawingMode, 0, this.vertexCount);
    return true;
  };

  WebGLCanvas.prototype.captureImage = function(width, height) {
    var image, valid;
    valid = this._doFrame();
    if (valid) {
      this._render(width, height);
    }
    image = this.canvasElement.toDataURL('image/png');
    if (valid) {
      this._render();
    }
    return image;
  };

  WebGLCanvas.prototype._setUniform = function() {
    var args, f, gl, name, uniformInfo;
    name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    gl = this.gl;
    uniformInfo = this._uniformInfoByName[name];
    if (!uniformInfo) {
      return false;
    }
    uniformInfo.location = gl.getUniformLocation(this._program, 'u_CanvasSize');
    f = SET_UNIFORM_FUNCTION_NAMES[args.length];
    if (!f) {
      throw new Error("Can't set uniform with " + args.length + " values");
    }
    gl[f].apply(gl, [uniformInfo.location].concat(__slice.call(args)));
    return true;
  };

  WebGLCanvas.prototype._handleContextLost = function(e) {
    this.trace.log('WebGL context lost, suspending all GL calls');
    this._contextLost = true;
    (e || window.event).preventDefault();
  };

  WebGLCanvas.prototype._handleContextRestored = function() {
    this.trace.log('WebGL context restored, resuming rendering');
    this._contextLost = false;
    this._contextRequiresSetup = true;
    this._scheduleFrame();
  };

  WebGLCanvas.prototype.getShaderSource = function(shaderType) {
    return this._shaderSources[shaderType];
  };

  WebGLCanvas.prototype.setShaderSource = function(shaderType, value) {
    this._shaderSources[shaderType] = value;
    this._shaderDirty[shaderType] = true;
    this._scheduleFrame();
  };

  WebGLCanvas.prototype._getFragmentShaderSource = function() {
    return this.getShaderSource(Tamarind.FRAGMENT_SHADER);
  };

  WebGLCanvas.prototype._setFragmentShaderSource = function(value) {
    this.setShaderSource(Tamarind.FRAGMENT_SHADER, value);
  };

  WebGLCanvas.prototype._getVertexShaderSource = function() {
    return this.getShaderSource(Tamarind.VERTEX_SHADER);
  };

  WebGLCanvas.prototype._setVertexShaderSource = function(value) {
    this.setShaderSource(Tamarind.VERTEX_SHADER, value);
  };

  WebGLCanvas.prototype._getVertexCount = function() {
    return this._vertexCount;
  };

  WebGLCanvas.prototype._setVertexCount = function(value) {
    this._vertexCount = value;
    this._geometryIsDirty = true;
    this._scheduleFrame();
  };

  WebGLCanvas.prototype._getDrawingMode = function() {
    return this._drawingModeNames[this._drawingMode];
  };

  WebGLCanvas.prototype._setDrawingMode = function(value) {
    var intValue;
    intValue = this.gl[value];
    if (intValue === void 0) {
      throw new Error(value + ' is not a valid drawing mode.');
    }
    this._drawingMode = intValue;
    this._scheduleFrame();
  };

  WebGLCanvas.prototype._getDebugMode = function() {
    return this._debugMode;
  };

  WebGLCanvas.prototype._setDebugMode = function(value) {
    value = !!value;
    if (this._debugMode !== value || !this.trace) {
      this._debugMode = value;
      if (this._debugMode) {
        this.trace = new ConsoleTracer;
        this.trace.log('Using WebGL API debugging proxy - turn off debug mode for production apps, it hurts performance');
        this.gl = this.debugContext;
      } else {
        this.trace = new NullTracer;
        this.gl = this.debugContext;
      }
    }
  };

  return WebGLCanvas;

})(EventEmitter);

Tamarind.defineClassProperty(WebGLCanvas, 'debugMode');

Tamarind.defineClassProperty(WebGLCanvas, 'drawingMode');

Tamarind.defineClassProperty(WebGLCanvas, 'vertexCount');

Tamarind.defineClassProperty(WebGLCanvas, 'vertexShaderSource');

Tamarind.defineClassProperty(WebGLCanvas, 'fragmentShaderSource');

CompileStatus = (function() {
  CompileStatus.prototype.errors = [];

  function CompileStatus(shaderType, error) {
    var line, parts, _i, _len, _ref;
    this.shaderType = shaderType;
    this.errors = [];
    if (error) {
      _ref = error.split('\n');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        line = _ref[_i];
        parts = /^ERROR:\s*\d+\s*:\s*(\d+|\?)\s*:\s*(.*)/.exec(line) || /^\((\d+),\s*\d+\):\s*(.*)/.exec(line);
        if (parts) {
          line = parseInt(parts[1]) || 0;
          this.errors.push({
            message: parts[2],
            line: line - 1
          });
        }
      }
    }
  }

  CompileStatus.prototype.toString = function() {
    return "CompileStatus('" + this.shaderType + "', [" + this.errors.length + " errors])";
  };

  return CompileStatus;

})();
;
/*
  Outputs trace messages to the browser console
 */
var ConsoleTracer, NullTracer;

ConsoleTracer = (function() {
  function ConsoleTracer() {}

  ConsoleTracer.prototype.log = function(m) {
    if (window.console) {
      console.log(m);
    }
  };

  ConsoleTracer.prototype.error = function(m) {
    if (window.console) {
      console.error(m);
    }
  };

  return ConsoleTracer;

})();

NullTracer = (function() {
  function NullTracer() {}

  NullTracer.prototype.log = function() {};

  NullTracer.prototype.error = function() {};

  return NullTracer;

})();
;
//# sourceMappingURL=tamarind.js.map