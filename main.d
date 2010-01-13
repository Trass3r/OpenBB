/**
 *	
 */
module main;

import dsfml.system.all;
import dsfml.window.all;
import dsfml.graphics.all;
import dsfml.audio.all;
import dsfml.network.all;

import openbb.common;
import openbb.io.palette;
import openbb.io.boxfile;
import openbb.io.mfbfile;
import openbb.map;
//import openbb.lua;
import std.stdio;
import std.string;

void main()
{
	RenderWindow window = new RenderWindow(VideoMode(1024, 768), "OpenBB");//, Style.Fullscreen);
//	window.setFramerateLimit(60);

	// testing lua
//	init();
	
	Vector2f top;
	FloatRect bound;
	Shape s;
	bool mousePressed;
	
	Input input = window.getInput();

	Shape tileMarker = new Shape();
	tileMarker.addPoint(0, 20, Color(255,0,0,100), Color.WHITE);
	tileMarker.addPoint(77.f/2.f, 40, Color(255,0,0,100), Color.WHITE);
	tileMarker.addPoint(77, 20, Color(255,0,0,100), Color.WHITE);
	tileMarker.addPoint(77.f/2.f, 0, Color(255,0,0,100), Color.WHITE);
	tileMarker.enableFill(true);
	tileMarker.enableOutline(false);
	tileMarker.setOutlineWidth(2);
	tileMarker.setPosition(77, 60);
	
	auto videobox = new BOXFile("VIDEO.BOX");
	auto mfb = new MFBFile(videobox["maptile.MFB"]);
	
	auto images = new Image[mfb.numSprites];
	for(uint i=0; i<mfb.numSprites; i++)
	{
		images[i] = new Image(mfb.width, mfb.height, cast(ubyte[]) mfb[i]);
	}

	auto mfb2 = new MFBFile(videobox["woman.MFB"]);
	auto testSpriteSheetImage = new Image(mfb2.numSprites * mfb2.width, mfb2.height, cast(ubyte[]) mfb2[]);
	auto testSpriteSheetSprite = new Sprite(testSpriteSheetImage);
	testSpriteSheetSprite.setPosition(10.f, 15.f);
	
	auto map = new StaggeredMap(30, 60, window, images);

	float framerate;
	Text fps = new Text(std.string.format("%f fps", framerate));
	fps.setPosition(50.f, 50.f);
	
	while (window.isOpened())
	{
		Event evt;

		while (window.getEvent(evt))
		{
			switch(evt.Type)
			{
				case EventType.KeyPressed:
					switch(evt.Key.Code)
					{
						case KeyCode.Return:
							if (bound != FloatRect())
								window.setView(new View(bound));
							s = null;
							break;
						case KeyCode.Escape:
							window.setView(window.getDefaultView());   
							break;
						case KeyCode.Left:
							View view = window.getView().move(-1000 * window.getFrameTime(), 0);
							window.setView(view);
							break;
						case KeyCode.Right:
							View view = window.getView().move(1000 * window.getFrameTime(), 0);
							window.setView(view);
							break;
						case KeyCode.Up:
							View view = window.getView().move(0, -1000 * window.getFrameTime());
							window.setView(view);
							break;
						case KeyCode.Down:
							View view = window.getView().move(0, 1000 * window.getFrameTime());
							window.setView(view);
							break;
						
						default:
					}
					break;
				case EventType.MouseButtonPressed:
					if (evt.MouseButton.Button == MouseButtons.Left)
					{
						top = window.convertCoords(input.getMouseX(), input.getMouseY());
						mousePressed = true;
					}
					break;
				case EventType.MouseButtonReleased:
					if (evt.MouseButton.Button == MouseButtons.Left)
					{
							mousePressed = false;   
					}
					break;
				case EventType.MouseWheelMoved:
					View view = window.getView().zoom(evt.MouseWheel.Delta > 0 ? 0.8f : 1.25f); // * window.getFrameTime());
					window.setView(view);
					break;
				case EventType.MouseMoved:
					if (mousePressed)
					{
						Vector2f bottom = window.convertCoords(input.getMouseX(), input.getMouseY());
						bound = FloatRect(top.x, top.y, bottom.x, bottom.y);
						s = Shape.rectangle(top.x, top.y, bottom.x, bottom.y, Color(0, 0, 0, 0), 1, Color.WHITE);
					}
					break;
				default:
			}
			if (evt.Type == EventType.Closed)
				window.close();
		}

		auto vec = window.convertCoords(input.getMouseX(), input.getMouseY());
		
		window.clear(Color.WHITE);
		map.render();
		auto m = map.convertMapToGlobal(map.convertGlobalToMap(Vector2i(cast(int) vec.x, cast(int) vec.y)));
		tileMarker.setPosition(Vector2f(cast(float) m.x, cast(float) m.y+5));
		window.draw(tileMarker);
		if (s !is null) window.draw(s);

		framerate = 1.f / window.getFrameTime();
		fps.setString(std.string.format("%f fps", framerate));
		window.draw(fps);
		window.draw(testSpriteSheetSprite);
		window.display();
	}
}