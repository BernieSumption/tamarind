'use strict';
var Call;

Call = (function() {
  function Call() {}

  Call.spy = function() {
    var call;
    call = new Call;
    spyOn(call, 'back');
    return call;
  };

  Call.prototype.back = function() {};

  return Call;

})();

describe('EventEmitter', function() {
  it('should register callbacks with the off() method', function() {
    var call1, call2, call3, ee;
    ee = new EventEmitter;
    call1 = Call.spy();
    call2 = Call.spy();
    call3 = Call.spy();
    ee.on('foo', call1.back);
    ee.on('foo', call2.back);
    ee.on('bar', call3.back);
    ee.emit('foo', 100);
    expect(call1.back).toHaveBeenCalledWith(100);
    expect(call2.back).toHaveBeenCalledWith(100);
    expect(call3.back).not.toHaveBeenCalledWith(100);
  });
  it('should deregister callbacks with the off() method', function() {
    var call1, call2, ee;
    ee = new EventEmitter;
    call1 = Call.spy();
    call2 = Call.spy();
    ee.on('foo', call1.back);
    ee.on('foo', call2.back);
    ee.off('foo', call2.back);
    ee.emit('foo');
    expect(call1.back).toHaveBeenCalled();
    expect(call2.back).not.toHaveBeenCalled();
  });
  it('should a callback to be registered multiple times without multiple calls', function() {
    var call1, ee;
    ee = new EventEmitter;
    call1 = Call.spy();
    ee.on('foo', call1.back);
    ee.on('foo', call1.back);
    ee.emit('foo');
    expect(call1.back.calls.count()).toEqual(1);
  });
  it('should throw an error when passed arguments of the wrong type', function() {
    var callback, ee;
    ee = new EventEmitter;
    callback = function() {};
    ee.on('foo', callback);
    expect(function() {
      return ee.on(3, callback);
    }).toThrowError();
    expect(function() {
      return ee.on(null, callback);
    }).toThrowError();
    expect(function() {
      return ee.on('foo');
    }).toThrowError();
    expect(function() {
      return ee.on('foo', null);
    }).toThrowError();
    expect(function() {
      return ee.on('foo', 5);
    }).toThrowError();
    ee.emit('foo');
    ee.emit('foo', 4);
    expect(function() {
      return ee.emit(null);
    }).toThrowError();
    expect(function() {
      return ee.emit(4);
    }).toThrowError();
    ee.off('foo', callback);
    ee.off('bar', callback);
    expect(function() {
      return ee.off(4, callback);
    }).toThrowError();
    expect(function() {
      return ee.off('bar', null);
    }).toThrowError();
  });
});
;describe('mergeObjects', function() {
  it('should should recursively copy values from source to dest', function() {
    var dest, source;
    source = {
      a: 'foo',
      b: {
        c: 'lala'
      }
    };
    dest = {
      a: '1',
      b: {
        c: '2',
        f: '3'
      },
      d: null
    };
    mergeObjects(source, dest);
    expect(dest.a).toEqual('foo');
    expect(dest.b.c).toEqual('lala');
    expect(dest.b.f).toEqual('3');
    expect(dest.d).toEqual(null);
    expect(function() {
      return mergeObjects({
        notThere: 4
      }, dest);
    }).toThrow(new Error("Can't merge property 'notThere': source is number destination is undefined"));
    expect(function() {
      return mergeObjects({
        b: 4
      }, dest);
    }).toThrow(new Error("Can't merge property 'b': source is number destination is object"));
  });
});
;var FSHADER_HEADER, VSHADER_HEADER, compareAgainstReferenceImage;

VSHADER_HEADER = 'attribute float a_VertexIndex;';

FSHADER_HEADER = 'precision mediump float;\nuniform vec2 u_CanvasSize;';

compareAgainstReferenceImage = function(webglCanvas, referenceImageUrl, done) {
  var actual, expected, handleLoad, imageToDataUrl, loaded;
  imageToDataUrl = function(imageElement) {
    var canvasElement, ctx;
    canvasElement = document.createElement('canvas');
    canvasElement.width = imageElement.width;
    canvasElement.height = imageElement.height;
    ctx = canvasElement.getContext('2d');
    ctx.drawImage(imageElement, 0, 0);
    return canvasElement.toDataURL('image/png');
  };
  loaded = 0;
  handleLoad = function() {
    var actualData, expectedData;
    ++loaded;
    if (loaded === 2) {
      expectedData = imageToDataUrl(expected);
      actualData = imageToDataUrl(actual);
      if (expectedData !== actualData) {
        window.focus();
        console.log('EXPECTED DATA: ' + expectedData);
        console.log('ACTUAL DATA: ' + actualData);
        if (document.location.href.indexOf('bad-images') !== -1) {
          window.open(expectedData);
          window.open(actualData);
        } else {
          console.log('PRO TIP: append ?bad-images to the Karma runner URL and reload to view these images');
        }
        expect(false).toBeTruthy();
      }
      done();
    }
  };
  actual = new Image();
  actual.onload = handleLoad;
  actual.src = webglCanvas.captureImage(100, 100);
  expected = new Image();
  expected.onload = handleLoad;
  expected.onerror = function() {
    throw new Error("Couldn't load " + referenceImageUrl);
  };
  expected.src = referenceImageUrl;
};

describe('WebGLCanvas', function() {
  var expectErrorCountFromSource, oldError;
  oldError = console.error;
  beforeEach(function() {
    console.error = function(message) {
      if (message !== 'this error is expected') {
        oldError.call(console, message);
      }
      throw new Error(message);
    };
  });
  afterEach(function() {
    console.error = oldError;
  });
  it('should throw an exception on console errors', function() {
    expect(function() {
      return console.error('this error is expected');
    }).toThrow(new Error('this error is expected'));
  });
  it('should render a test image', function(done) {
    var canvas;
    canvas = new WebGLCanvas(document.createElement('canvas'), true);
    canvas.vertexShaderSource = VSHADER_HEADER + 'void main() {\n  // 4 points, one in each corner, clockwise from top left\n  if (a_VertexIndex == 0.0) {\n    gl_Position.xy = vec2(-1, -1);\n  } else if (a_VertexIndex == 1.0) {\n    gl_Position.xy = vec2(1, -1);\n  } else if (a_VertexIndex == 2.0) {\n    gl_Position.xy = vec2(1, 1);\n  } else if (a_VertexIndex == 3.0) {\n    gl_Position.xy = vec2(-1, 1);\n  }\n}';
    canvas.fragmentShaderSource = FSHADER_HEADER + 'void main() {\n  gl_FragColor = vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1);\n}';
    compareAgainstReferenceImage(canvas, '/base/build/test/reference-images/plain-shader.png', done);
  });
  it('test image rendering should work even if the scene is invalid', function() {
    var canvas, image;
    canvas = new WebGLCanvas(document.createElement('canvas'), true);
    canvas.vertexShaderSource = VSHADER_HEADER + 'void main() {\n  blarty foo\n}';
    canvas.fragmentShaderSource = FSHADER_HEADER + 'void main() {\n  gl_FragColor = nark;\n}';
    image = canvas.captureImage(100, 100);
    expect(image).toContain('image/png');
  });
  expectErrorCountFromSource = function(done, expectedErrorLines, fragmentShaderSource) {
    var canvas;
    canvas = new WebGLCanvas(document.createElement('canvas'));
    canvas.fragmentShaderSource = fragmentShaderSource;
    canvas.on(WebGLCanvas.COMPILE, function(event) {
      var actualErrorLines, err;
      if (event.shaderType === Tamarind.FRAGMENT_SHADER) {
        actualErrorLines = (function() {
          var _i, _len, _ref, _results;
          _ref = event.errors;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            err = _ref[_i];
            _results.push(err.line);
          }
          return _results;
        })();
        expect(actualErrorLines).toEqual(expectedErrorLines);
        done();
      }
    });
  };
  it('should dispatch CompileStatus events on sucessful compilation', function(done) {
    expectErrorCountFromSource(done, [], FSHADER_HEADER + 'void main() {\n  gl_FragColor = vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1);\n}');
  });
  it('should have one error if there is a syntax problem', function(done) {
    expectErrorCountFromSource(done, [2], FSHADER_HEADER + 'void main() {\n  gl_FragColor vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1); // error: missing equals\n}');
  });
  it('should have multiple errors if there are multiple validation problems', function(done) {
    expectErrorCountFromSource(done, [2, 4], FSHADER_HEADER + 'void main() {\n  foo = 1.0; // first error\n  gl_FragColor = vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1);\n  bar = 2.0; // second error\n}');
  });
  it('should dispatch a link event on sucessful linking', function(done) {
    var canvas;
    canvas = new WebGLCanvas(document.createElement('canvas'), true);
    canvas.fragmentShaderSource = FSHADER_HEADER + 'void main() {\n  gl_FragColor = vec4(gl_FragCoord.xy / u_CanvasSize, 1, 1);\n}';
    canvas.vertexShaderSource = VSHADER_HEADER + 'void main() {\n  gl_Position = vec4(0);\n}';
    canvas.on(WebGLCanvas.LINK, function(error) {
      expect(error).toBeFalsy();
      done();
    });
  });
  it('should dispatch a link error message event on failed linking', function(done) {
    var canvas;
    canvas = new WebGLCanvas(document.createElement('canvas'), true);
    canvas.fragmentShaderSource = FSHADER_HEADER + 'varying vec4 doesntExist; // not present in vertex shader, that\'s a link error\nvoid main() {\n  gl_FragColor = doesntExist;\n}';
    canvas.vertexShaderSource = VSHADER_HEADER + 'void main() {\n  gl_Position = vec4(0);\n}';
    canvas.on(WebGLCanvas.LINK, function(error) {
      expect(error).toContain('doesntExist');
      done();
    });
  });
});
;
//# sourceMappingURL=tamarind.tests.js.map