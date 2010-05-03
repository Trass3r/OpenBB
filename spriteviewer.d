module spriteviewer;

import dsfml.system.all;
import dsfml.window.all;
import dsfml.graphics.all;

import openbb.common;
import openbb.io.palette;
import openbb.io.boxfile;
import openbb.io.mfbfile;

import std.stdio;
import std.string;
import std.stream;

void main()
{
    RenderWindow window = new RenderWindow(VideoMode(1024, 768), "MFB Sprite Viewer");
//	window.framerateLimit = 60;
	window.useVerticalSync = true;
    
    Input input = window.input;
    Vector2f top;
    FloatRect bound;
    Shape s;
    bool mousePressed;
    
    auto videobox = new BOXFile("VIDEO.BOX");
    /+
    videobox.dump("boxdump.txt");
    {
    auto f = new std.stream.File("videoboxdump.txt", FileMode.Out);
    scope(exit) f.close();
    f.write(cast(ubyte[]) "size\t#Sprites\tFlags\tfilename\tdescription\n");
    for(uint i=0; i < videobox.numFiles; i++)
    {
    	auto mfb = new MFBFile(videobox[i]);
    	f.write(cast(ubyte[]) std.string.format("%dx%d\t\t%d\t\t%b\t\t%s\t\t\n", mfb.width, mfb.height, mfb.numSprites, mfb.flags, videobox.entryName(i)));
    }
    }
    +/
	auto mfb = new MFBFile(videobox[0]);
	
	uint curSprite, curSpriteFrame;
	ubyte curPalette;
	
    Sprite sprite = new Sprite(new Image(mfb.width, mfb.height, cast(ubyte[]) mfb[0]));
//	writefln(mfb[0]);
    
    Font f = new Font("Dungeon Keeper.ttf");
	Text txtBoxPos = new Text(std.string.format("Sprite %d/%d (%s)", curSprite+1, videobox.numFiles, videobox.entryName(curSprite)), f, 16);
	Text txtSpriteInfo = new Text(std.string.format("Size: %dx%d\tFlags: %d", mfb.width, mfb.height, mfb.flags), f, 16);
	Text txtSpritePos = new Text(std.string.format("Frame %d/%d", curSpriteFrame+1, mfb.numSprites), f, 16);

	txtBoxPos.position = Vector2f(0.f, 100.f);
	txtBoxPos.color = Color.BLACK;
	txtSpriteInfo.position = Vector2f(0.f, 125.f);
	txtSpriteInfo.color = Color.BLACK;
	txtSpritePos.position = Vector2f(0.f, 150.f);
	txtSpritePos.color = Color.BLACK;
	
    Text txt = new Text("To zoom in create a selection of the background with your mouse and press Enter.\nPress Escape to return to the default view.\nUse up and down to switch through the mfb files. Use left and right to switch through the frames.\nF1-5 changes the palette used."c, f, 16);
    
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
        	                    window.view = new View(bound);
        	                s = null;
        	                break;
        				case KeyCode.Escape:
        	                window.view = window.defaultView;   
        	                break;
        				case KeyCode.Left:
        					if (curSpriteFrame <= 0)
        						curSpriteFrame = mfb.numSprites;

        					sprite.image = new Image(mfb.width, mfb.height, cast(ubyte[]) mfb[--curSpriteFrame, curPalette]);
        					break;
        				case KeyCode.Right:
        					if (curSpriteFrame >= mfb.numSprites-1)
        						curSpriteFrame = -1;

        					sprite.image = new Image(mfb.width, mfb.height, cast(ubyte[]) mfb[++curSpriteFrame, curPalette]);
        					break;
        				case KeyCode.Up:
        					if (curSprite >= videobox.numFiles-1)
        						curSprite = -1;

        					mfb = new MFBFile(videobox[++curSprite]);

        					if (curSpriteFrame < 0)
        						curSpriteFrame = mfb.numSprites-1;
        					if (curSpriteFrame > mfb.numSprites-1)
        						curSpriteFrame = 0;

        					sprite.setImage(new Image(mfb.width, mfb.height, cast(ubyte[]) mfb[curSpriteFrame, curPalette]), true);
        					break;
        				case KeyCode.Down:
        					if (curSprite <= 0)
        						curSprite = videobox.numFiles;

        					mfb = new MFBFile(videobox[--curSprite]);

        					if (curSpriteFrame < 0)
        						curSpriteFrame = mfb.numSprites-1;
        					if (curSpriteFrame > mfb.numSprites-1)
        						curSpriteFrame = 0;

        					sprite.setImage(new Image(mfb.width, mfb.height, cast(ubyte[]) mfb[curSpriteFrame, curPalette]), true);
        					break;
        					
        				case KeyCode.F1:
        					curPalette = 0;
        					break;
        				case KeyCode.F2:
        					curPalette = 1;
        					break;
        				case KeyCode.F3:
        					curPalette = 2;
        					break;
        				case KeyCode.F4:
        					curPalette = 3;
        					break;
        				case KeyCode.F5:
        					curPalette = 4;
        					break;
        					
        				default:
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
					
        		default:
        	}
            if (evt.Type == EventType.MouseMoved && mousePressed)
            {
                Vector2f bottom = window.convertCoords(input.mouseX, input.mouseY);
				bound = FloatRect(top.x, top.y, bottom.x-top.x, bottom.y-top.y);
				s = Shape.rectangle(top.x, top.y, bottom.x-top.x, bottom.y-top.y, Color(0, 0, 0, 0), 1, Color.WHITE);
            }
            else if (evt.Type == EventType.Closed)
                window.close();
        }
        sprite.position = Vector2f(50.f, 250.f);
		txtSpritePos.text = std.string.format("Frame %d/%d", curSpriteFrame+1, mfb.numSprites);
		txtSpriteInfo.text = std.string.format("Size: %dx%d\tFlags: %s | %s | %s", mfb.width, mfb.height, mfb.flags & FLAG_1 ? "FLAG_1":"-", mfb.flags & FLAG_COMPRESSED ? "COMPRESSED":"-", mfb.flags & FLAG_4 ? "FLAG_4":"-");
		txtBoxPos.text = std.string.format("Sprite %d/%d (%s)", curSprite+1, videobox.numFiles, videobox.entryName(curSprite));
		window.clear(Color.WHITE);
        window.draw(txt);
		window.draw(txtSpritePos);
		window.draw(txtSpriteInfo);
		window.draw(txtBoxPos);
        window.draw(sprite);
        if (s !is null) window.draw(s);
        window.display();
    }
}