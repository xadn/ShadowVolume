// ===========================================================================
// Molehill 3d Template
// ===========================================================================
// Please note: Molehill will only compile if you target "Flash Player 11"
// And copy the proper SWC and XML files to your CS5 Install Folder
// ===========================================================================
// The demo will only run if you are using the beta "incubator" Flash Plugin
// when viewing it in an HTML document rather than the built-in CS5 debugger
// ===========================================================================
// You can get the Flash 11 incubator plugin here:
// http://labs.adobe.com/downloads/flashplatformruntimes_incubator.html
// ===========================================================================
package
{
	// [SWF(width="640", height="480", frameRate="60", backgroundColor="#FFFFFF")]	
	
	import com.adobe.utils.*;
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	import flash.net.FileReference;
 
	public class ShadowVolume extends Sprite
	{
		// constants used during inits
		private const swf_width:int = 640;
		private const swf_height:int = 480;
		private const texture_size:int = 512;
		
		// the 3d graphics window on the stage
		private var context3D:Context3D;
		// the compiled shader used to render our mesh
		private var shaderProgram:Program3D;
		// the uploaded verteces used by our mesh
		private var vertexBuffer:VertexBuffer3D;
		// the uploaded indeces of each vertex of the mesh
		private var indexBuffer:IndexBuffer3D;
		// the data that defines our 3d mesh model
		private var meshVertexData:Vector.<Number> = new Vector.<Number>;
		// the indeces that define what data is used by each vertex
		private var meshIndexData:Vector.<uint> = new Vector.<uint>;

		// private var meshVertexData2:Vector.<Number> = new Vector.<Number>;
		// // the indeces that define what data is used by each vertex
		// private var meshIndexData2:Vector.<uint> = new Vector.<uint>;
		
		// matrices that affect the mesh location and camera angles
		private var projectionmatrix:PerspectiveMatrix3D = new PerspectiveMatrix3D();
		private var modelmatrix:Matrix3D = new Matrix3D();
		private var viewmatrix:Matrix3D = new Matrix3D();
		private var modelViewProjection:Matrix3D = new Matrix3D();

		// a simple frame counter used for animation
		private var t:Number = 0;

		/* TEXTURE: Pure AS3 and Flex version:
		 * if you are using Adobe Flash CS5 comment out the next two lines of code */
		[Embed (source = "texture.jpg")] private var myTextureBitmap:Class;
		private var myTextureData:Bitmap = new myTextureBitmap();
					
		/* TEXTURE: Flash CS5 version:
		 * add the jpg to your library (F11)
		 * right click it and edit the advanced properties so
		 * it is exported for use in Actionscript and call it myTextureBitmap
		 * if using Flex/FlashBuilder/FlashDevlop comment out the next two lines of code */
		// private var myBitmapDataObject:myTextureBitmapData = new myTextureBitmapData(texture_size, texture_size);
		// private var myTextureData:Bitmap = new Bitmap(myBitmapDataObject);
							
		// The Molehill Texture that uses the above myTextureData
		private var myTexture:Texture;

		public function ShadowVolume() 
		{
			// class constructor - sets up the stage
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			// and request a context3D from Molehill
			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
			stage.stage3Ds[0].requestContext3D();
			// stage.stage3Ds[0].viewPort = new Rectangle(0,0,swf_width,swf_height);

			// selectInputFile();
		}

		// private function selectInputFile() : void {
		// 	var inputFile:FileReference = new FileReference();
		// 	inputFile.browse();
		// 	inputFile.addEventListener(Event.SELECT, function():void {
		// 		inputFile.load();
		// 		inputFile.addEventListener(Event.COMPLETE, function():void {
		// 			// Split the lines in the file
		// 			var lines:Array = inputFile.data.toString().split("\n").map( function(line:String, index:int, array:Array) : Array {
		// 				return line.split(" ");
		// 			});

		// 			var triCount:int = lines[0][0];
		// 			var vertCount:int = lines[0][1];

		// 			trace("triangles "+triCount, "verticies "+vertCount);

		// 			// Read in the triangles
		// 			lines.slice(2, 2+triCount).map( function(line:Array, index:int, array:Array) : void {
		// 				meshIndexData2.push(line[0], line[1], line[2]);
		// 			});

		// 			// Read in the vertices
		// 			lines.slice(4+triCount, 4+triCount+vertCount).map( function(line:Array, index:int, array:Array) : void {
		// 				meshVertexData2.push(line[0], line[1], line[2], 0, 0, 0, 0, 1);
		// 			});

		// 			// upload the mesh indexes
		// 			indexBuffer = context3D.createIndexBuffer(meshIndexData2.length);
		// 			indexBuffer.uploadFromVector(meshIndexData2, 0, meshIndexData2.length);
					
		// 			// upload the mesh vertex data
		// 			// since our particular data is 
		// 			// x, y, z, u, v, nx, ny, nz
		// 			// each vertex uses 8 array elements
		// 			vertexBuffer = context3D.createVertexBuffer(meshVertexData2.length/8, 8); 
		// 			vertexBuffer.uploadFromVector(meshVertexData2, 0, meshVertexData2.length/8);

		// 		});
		// 	});
		// }
		
	private function onContext3DCreate(event:Event):void 
	{
		// Remove existing frame handler. Note that a context
		// loss can occur at any time which will force you
		// to recreate all objects we create here.
		// A context loss occurs for instance if you hit
		// CTRL-ALT-DELETE on Windows.			
		// It takes a while before a new context is available
		// hence removing the enterFrame handler is important!

		removeEventListener(Event.ENTER_FRAME,enterFrame);
		
		// Obtain the current context
		var t:Stage3D = event.target as Stage3D;					
		context3D = t.context3D; 	

		if (context3D == null) 
		{
			// Currently no 3d context is available (error!)
			return;
		}
		
		// Disabling error checking will drastically improve performance.
		// If set to true, Flash will send helpful error messages regarding
		// AGAL compilation errors, uninitialized program constants, etc.
		context3D.enableErrorChecking = true;
		
		// Initialize our mesh data
		initData();
		
		// The 3d back buffer size is in pixels
		context3D.configureBackBuffer(swf_width, swf_height, 0, true);

		// A simple vertex shader which does a 3D transformation
		var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
		vertexShaderAssembler.assemble
		( 
			Context3DProgramType.VERTEX,
			// 4x4 matrix multiply to get camera angle	
			"m44 op, va0, vc0\n" +
			// tell fragment shader about XYZ
			"mov v0, va0\n" +
			// tell fragment shader about UV
			"mov v1, va1\n"
		);			
		
		// A simple fragment shader which will use the vertex position as a color
		var fragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
		fragmentShaderAssembler.assemble
		( 
			Context3DProgramType.FRAGMENT,	
			// grab the texture color from texture 0	
			"tex ft0, v0, fs0 <2d,repeat,miplinear>\n" +	
			// move this value to the output color
			"mov oc, ft0\n"									
		);
		
		// combine shaders into a program which we then upload to the GPU
		shaderProgram = context3D.createProgram();
		shaderProgram.upload(vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);

		// upload the mesh indexes
		indexBuffer = context3D.createIndexBuffer(meshIndexData.length);
		indexBuffer.uploadFromVector(meshIndexData, 0, meshIndexData.length);
		
		// upload the mesh vertex data
		// since our particular data is 
		// x, y, z, u, v, nx, ny, nz
		// each vertex uses 8 array elements
		vertexBuffer = context3D.createVertexBuffer(meshVertexData.length/8, 8); 
		vertexBuffer.uploadFromVector(meshVertexData, 0, meshVertexData.length/8);
		
		// Generate mipmaps (this is likely to break on non-square textures, non-power of two, etc)
		myTexture = context3D.createTexture(texture_size, texture_size, Context3DTextureFormat.BGRA, false);
		myTexture.uploadFromBitmapData(myTextureData.bitmapData, 0);
		var mip:BitmapData = myTextureData.bitmapData;
		var texwidth:int = myTextureData.bitmapData.width;
		var n:int = 0;
		while (texwidth > 1) {
			texwidth /= 2;
			n++;
			var tex2:BitmapData = new BitmapData(texwidth, texwidth, true, 0);
			var mat:Matrix = new Matrix();
			mat.scale(0.5, 0.5);
			tex2.draw(mip, mat, null, null, null, true);
			myTexture.uploadFromBitmapData(tex2, n);
			mip = tex2;
		}
		
		// create projection matrix for our 3D scene
		projectionmatrix.identity();
		// 45 degrees FOV, 640/480 aspect ratio, 0.1=near, 100=far
		projectionmatrix.perspectiveFieldOfViewRH(45.0, swf_width / swf_height, 0.01, 100.0);
		
		// create a matrix that defines the camera location
		viewmatrix.identity();
		// move the camera back a little so we can see the mesh
		viewmatrix.appendTranslation(0,0,-4);
		
		// start animating
		addEventListener(Event.ENTER_FRAME,enterFrame);
	}
		
		private function enterFrame(e:Event):void 
		{
			// clear scene before rendering is mandatory
			context3D.clear(0,0,0); 
			
			context3D.setProgram ( shaderProgram );
	
			// create the various transformation matrices
			modelmatrix.identity();
			modelmatrix.appendRotation(t*0.7, Vector3D.Y_AXIS);
			modelmatrix.appendRotation(t*0.6, Vector3D.X_AXIS);
			modelmatrix.appendRotation(t*1.0, Vector3D.Y_AXIS);
			modelmatrix.appendTranslation(0.0, 0.0, 0.0);
			modelmatrix.appendRotation(90.0, Vector3D.X_AXIS);

			// rotate more next frame
			t += 2.0;
			
			// clear the matrix and append new angles
			modelViewProjection.identity();
			modelViewProjection.append(modelmatrix);
			modelViewProjection.append(viewmatrix);
			modelViewProjection.append(projectionmatrix);
			
			// pass our matrix data to the shader program
			context3D.setProgramConstantsFromMatrix(
				Context3DProgramType.VERTEX, 
				0, modelViewProjection, true );

			// associate the vertex data with current shader program
			// position
			context3D.setVertexBufferAt(0, vertexBuffer, 0, 
				Context3DVertexBufferFormat.FLOAT_3);
			// tex coord
			context3D.setVertexBufferAt(1, vertexBuffer, 3, 
				Context3DVertexBufferFormat.FLOAT_3);

			// which texture should we use?
			context3D.setTextureAt(0, myTexture);
			
			// finally draw the triangles
			context3D.drawTriangles(indexBuffer, 0, meshIndexData.length/3);
			
			// present/flip back buffer
			context3D.present();
		}
		
		private function initData():void 
		{
			meshIndexData = InitData.meshIndexData;
			meshVertexData = InitData.meshVertexData;
			
			// Defines which vertex is used for each polygon
			// In this example a square is made from two triangles
			// meshIndexData = Vector.<uint> 
			// ([
			// 	0, 1, 2, 		0, 2, 3,
			// ]);
			
			// // Raw data used for each of the 4 verteces
			// // // Position XYZ, texture coordinate UV, normal XYZ
			// meshVertexData = Vector.<Number> 
			// ([
			// 	// X,  Y,  Z,   U, V,   nX, nY, nZ		
			// 	 -1, -1,  1,   0, 0,   0,  0,  1,
			// 	  1, -1,  1,   0, 0,   0,  0,  1,
			// 	  1,  1,  1,   0, 0,   0,  0,  1,
			// 	 -1,  1,  1,   0, 0,   0,  0,  1,
			// ]);

			// meshIndexData = Vector.<uint>
			// ([
			// 	0, 1, 2,
			// 	0, 2, 3,
			// 	1, 3, 2,
			// 	0, 3, 1
			// ]);

			// meshVertexData = Vector.<Number>
			// ([
			// 	 1,  1,  1,  0, 0,   0,  0,  1,
			// 	-1, -1,  1,  0, 0,   0,  0,  1,
			// 	-1,  1, -1,  0, 0,   0,  0,  1,
			// 	 1, -1, -1,  0, 0,   0,  0,  1
			// ]);
		}
	}
}
