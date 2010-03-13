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
import openbb.graphics.animation;
import openbb.graphics.gui;
import openbb.io.palette;
import openbb.io.boxfile;
import openbb.io.fatfile;
import openbb.io.mfbfile;
import openbb.map;
//import openbb.lua;
import std.perf;
import openbb.quadtree;
import std.stdio;
import std.string;

void main()
{
	RenderWindow window = new RenderWindow(VideoMode(1024, 768), "OpenBB", Style.Default, ContextSettings(24,8,0,3,1));
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
	
	auto bbrbankfat = new FATFile("BBRBANK.FAT");
	auto buffer = new SoundBuffer(bbrbankfat[40], 1, 22050);
	auto sound = new Sound(buffer);

	sound.play();
	
	auto videobox = new BOXFile("VIDEO.BOX");
	auto mfb = new MFBFile(videobox["maptile.MFB"], true);
	auto tilesheetdata = cast(ubyte[]) mfb[]; // generate a single image with all tiles
	auto tilesheet = new Image(mfb.spriteSheetWidth*mfb.width, mfb.spriteSheetHeight*mfb.height, tilesheetdata);

	auto map = new StaggeredMap(25, 70, window, tilesheet);

	auto mfb2 = new MFBFile(videobox["woman.MFB"]);
	auto sheet = cast(ubyte[]) mfb2[];
	Image testSpriteSheetImage = new Image(mfb2.spriteSheetWidth*mfb2.width, mfb2.spriteSheetHeight*mfb2.height, sheet);
	auto animation = new Animation(testSpriteSheetImage, mfb2.width, mfb2.height);
	animation.setPosition(100.f, 70.f);
	animation.loopSpeed = 10;
	animation.play();
	Sprite testSpriteSheetSprite = new Sprite(testSpriteSheetImage);
	testSpriteSheetSprite.setPosition(100.f, 150.f);
	
	// position display
	Text viewPos = new Text(""c);
	viewPos.setCharacterSize(24);
	viewPos.setPosition(100.f, 200.f);
	viewPos.setColor(Color.BLACK);
	
	Text worldPos = new Text(""c);
	worldPos.setCharacterSize(24);
	worldPos.setPosition(100.f, 220.f);
	worldPos.setColor(Color.BLACK);

	// fps stuff
	float framerate;
	Text fps = new Text(""c);
	fps.setCharacterSize(30);
	fps.move(50.f, 25.f);
	fps.setColor(Color.BLACK);
	uint iFps = 0;
	auto fpsClock = new PerformanceCounter();
	while (window.isOpened())
	{
		Event evt;

		while (window.getEvent(evt))
		{
			switch(evt.Type)
			{
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

		if(input.isKeyDown(KeyCode.Return))
		{
			if (bound != FloatRect())
				window.setView(new View(bound));
			s = null;
		}
		if(input.isKeyDown(KeyCode.Escape))
		{
			window.setView(window.getDefaultView());
		}
		if(input.isKeyDown(KeyCode.Left))
		{
			View view = window.getView().move(-1000 * window.getFrameTime(), 0);
			window.setView(view);
		}
		if(input.isKeyDown(KeyCode.Right))
		{
			View view = window.getView().move(1000 * window.getFrameTime(), 0);
			window.setView(view);
		}
		if(input.isKeyDown(KeyCode.Up))
		{
			View view = window.getView().move(0, -1000 * window.getFrameTime());
			window.setView(view);
		}
		if(input.isKeyDown(KeyCode.Down))
		{
			View view = window.getView().move(0, 1000 * window.getFrameTime());
			window.setView(view);
		}

		auto vec = window.convertCoords(input.getMouseX(), input.getMouseY());
		viewPos.setString(std.string.format("Window coordinates: (%d %d)", input.getMouseX(), input.getMouseY()));
		worldPos.setString(std.string.format("World coordinates: (%f %f)", vec.x, vec.y));
		
		window.clear(Color.WHITE);
		map.render();
		auto m = map.convertMapToGlobal(map.convertGlobalToMap(Vector2i(cast(int) vec.x, cast(int) vec.y)));
		tileMarker.setPosition(Vector2f(cast(float) m.x, cast(float) m.y+5));
		window.draw(tileMarker);
		if (s !is null) window.draw(s);

//		window.draw(testSpriteSheetSprite);
		window.draw(animation);
		animation.update();
		
		fpsClock.stop();
		if(fpsClock.seconds >= 1)
		{
			fps.setString(std.string.format("%d fps", iFps));
			iFps = 0;
			fpsClock.start();
		}
		++iFps;
		window.draw(fps);

//		window.draw(viewPos);
//		window.draw(worldPos);
		
		window.display();
	}
}