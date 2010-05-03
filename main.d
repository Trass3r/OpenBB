/**
 *	
 */
module main;

import dsfml.system.all;
import dsfml.window.all;
import dsfml.graphics.all;
import dsfml.audio.all;
//import dsfml.network.all;

import openbb.common;
import openbb.dynamicentity;
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
	
	Input input = window.input;

	Shape tileMarker = new Shape();
	tileMarker.addPoint(0, 20, Color(255,0,0,100), Color.WHITE);
	tileMarker.addPoint(77.f/2.f, 40, Color(255,0,0,100), Color.WHITE);
	tileMarker.addPoint(77, 20, Color(255,0,0,100), Color.WHITE);
	tileMarker.addPoint(77.f/2.f, 0, Color(255,0,0,100), Color.WHITE);
	tileMarker.enableFill = true;
	tileMarker.enableOutline = false;
	tileMarker.outlineWidth = 2;
	tileMarker.setPosition(77, 60);
	
	// test ambient sounds
	uint curSound = 0;
	auto bbrbankfat = new FATFile("BBRBANK.FAT");
	auto buffer = new SoundBuffer(bbrbankfat[curSound], 1, 22050);
	auto sound = new Sound(buffer);

	sound.play();
	
	
	auto videobox = new BOXFile("VIDEO.BOX");
	auto mfb = new MFBFile(videobox["maptile.MFB"], true);
	auto tilesheetdata = cast(ubyte[]) mfb[]; // generate a single image with all tiles
	auto tilesheet = new Image(mfb.spriteSheetWidth*mfb.width, mfb.spriteSheetHeight*mfb.height, tilesheetdata);

//	tilesheet.saveToFile("maptile");
	
//	tilesheet.smooth = false; // remove black outlines
	
	auto map = new StaggeredMap(25, 70, window, tilesheet);


	// place a woman as a test
	auto mfb2 = new MFBFile(videobox["woman.MFB"]);
	auto sheet = cast(ubyte[]) mfb2[];
	Image testSpriteSheetImage = new Image(mfb2.spriteSheetWidth*mfb2.width, mfb2.spriteSheetHeight*mfb2.height, sheet);
	auto animation = new Animation(testSpriteSheetImage, mfb2.width, mfb2.height);
	
	auto woman = new DynamicEntity(Vector2f(50f, 100f), animation);
//	woman.walkAnimation = animation;

	// position display
	Text viewPos = new Text(""c);
	viewPos.characterSize = 24;
	viewPos.setPosition(100.f, 200.f);
	viewPos.color = Color.BLACK;
	
	Text worldPos = new Text(""c);
	worldPos.characterSize = 24;
	worldPos.setPosition(100.f, 220.f);
	worldPos.color = Color.BLACK;

	// fps stuff
	float framerate;
	Text fps = new Text(""c);
	fps.characterSize = 30;
	fps.move(50.f, 25.f);
	fps.color = Color.BLACK;
	uint iFps = 0;
	auto fpsClock = new PerformanceCounter();
	while (window.isOpened())
	{
		Event evt;

		while (window.getEvent(evt))
		{
			switch(evt.Type)
			{
				case EventType.KeyPressed:
					if (evt.Key.Code == KeyCode.Left)
					{
						writeln(curSound);
						if (curSound == 0)
							curSound = bbrbankfat.numFiles;
						sound.buffer = new SoundBuffer(bbrbankfat[--curSound], 1, 22050);
						sound.play();
					}
					else if (evt.Key.Code == KeyCode.Right)
					{
						writeln(curSound);
						if (curSound >= bbrbankfat.numFiles-1)
							curSound = -1;
						sound.buffer = new SoundBuffer(bbrbankfat[++curSound], 1, 22050);
						sound.play();
					}
					break;
				case EventType.MouseButtonPressed:
					if (evt.MouseButton.Button == MouseButtons.Left)
					{
						top = window.convertCoords(input.mouseX, input.mouseY);
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
					View view = window.view.zoom(evt.MouseWheel.Delta > 0 ? 0.8f : 1.25f); // * window.frameTime);
					window.view = view;
					break;
				case EventType.MouseMoved:
					if (mousePressed)
					{
						Vector2f bottom = window.convertCoords(input.mouseX, input.mouseY);
						bound = FloatRect(top.x, top.y, bottom.x-top.x, bottom.y-top.y);
						s = Shape.rectangle(top.x, top.y, bottom.x-top.x, bottom.y-top.y, Color(0, 0, 0, 0), 1, Color.WHITE);
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
				window.view = new View(bound);
			s = null;
		}
		if(input.isKeyDown(KeyCode.Escape))
		{
			window.view = window.defaultView;
		}
		if(input.isKeyDown(KeyCode.Left))
		{
			View view = window.view.move(-1000 * window.frameTime, 0);
			window.view = view;
		}
		if(input.isKeyDown(KeyCode.Right))
		{
			View view = window.view.move(1000 * window.frameTime, 0);
			window.view = view;
		}
		if(input.isKeyDown(KeyCode.Up))
		{
			View view = window.view.move(0, -1000 * window.frameTime);
			window.view = view;
		}
		if(input.isKeyDown(KeyCode.Down))
		{
			View view = window.view.move(0, 1000 * window.frameTime);
			window.view = view;
		}

		auto vec = window.convertCoords(input.mouseX, input.mouseY);
		viewPos.text = std.string.format("Window coordinates: (%d %d)", input.mouseX, input.mouseY);
		worldPos.text = std.string.format("World coordinates: (%f %f)", vec.x, vec.y);
		
		window.clear(Color.WHITE);
		map.render();
		auto m = map.convertMapToGlobal(map.convertGlobalToMap(Vector2i(cast(int) vec.x, cast(int) vec.y)));
		tileMarker.position = Vector2f(cast(float) m.x, cast(float) m.y+5);
		window.draw(tileMarker);
		if (s !is null) window.draw(s);

//		window.draw(testSpriteSheetSprite);

		float dt = window.frameTime * 1000; // in ms
		
		woman.update(dt);
		woman.render(window);
		
		fpsClock.stop();
		if(fpsClock.seconds >= 1)
		{
			fps.text = std.string.format("%d fps", iFps);
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