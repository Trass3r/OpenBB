/**
 *	
 */
module openbb;

import dsfml.system.all;
import dsfml.window.all;
import dsfml.graphics.all;
//import dsfml.audio.all;

import openbb.common;
import openbb.io.palette;
import openbb.io.boxfile;
import openbb.io.mfbfile;
import openbb.theapp;
import std.stdio;
import std.string;

void main()
{
    RenderWindow window = new RenderWindow(VideoMode(800, 600), "OpenBB");
    window.setFramerateLimit(60);
    Input input = window.getInput();
    Vector2f top;
    FloatRect bound;
    Shape s;
    bool mousePressed;
    
    auto videobox = new BOXFile("VIDEO.BOX");
    
	auto mfb = new MFBFile(videobox[videobox.fileList[2]]);
	theApp = new TheApp;
	updatePalette();
	
	uint curSprite, curSpriteFrame;
	
	Sprite background = new Sprite(new Image(1024,768,Color.BLACK));
    Sprite sprite = new Sprite(new Image(mfb.width, mfb.height, cast(ubyte[]) mfb[0]));
//	writefln(mfb[0]);
    
    Font f = new Font("Dungeon Keeper.ttf");
	Text txtSpritePos = new Text(std.string.format("Sprite %d/%d", curSprite+1, mfb.numSprites), f);
	txtSpritePos.setPosition(150.f, 150.f);
    Text txt = new Text("Create a selection of the background with your mouse.\nPress Enter to zoom to this selection.\nPress Escape to return to the default view.\nUse left and right to switch through the sprites."c, f);
    
    while (window.isOpened())
    {
        Event evt;
        
        while (window.getEvent(evt))
        {
            if (        evt.Type == Event.EventType.MOUSEBUTTONPRESSED &&
                        evt.MouseButton.Button == MouseButtons.LEFT)
            {
                top = window.convertCoords(input.getMouseX(), input.getMouseY());
                mousePressed = true;
                
            }
            else if (   evt.Type == Event.EventType.MOUSEBUTTONRELEASED &&
                        evt.MouseButton.Button == MouseButtons.LEFT)
            {
                mousePressed = false;   
            }
            else if (   evt.Type == Event.EventType.MOUSEMOVED &&
                        mousePressed)
            {
                Vector2f bottom = window.convertCoords(input.getMouseX(), input.getMouseY());
                bound = FloatRect(top.x, top.y, bottom.x, bottom.y);
                s = Shape.rectangle(top.x, top.y, bottom.x, bottom.y, Color(0, 0, 0, 0), 1, Color.BLACK);
            }
            else if (   evt.Type == Event.EventType.KEYPRESSED &&
                        evt.Key.Code == KeyCode.RETURN)
            {
                if (bound != FloatRect())
                    window.setView(new View(bound));
                s = null;
            }
            else if (   evt.Type == Event.EventType.KEYPRESSED &&
                        evt.Key.Code == KeyCode.ESCAPE)
            {
                window.setView(window.getDefaultView());   
            }
			else if (   evt.Type == Event.EventType.KEYPRESSED &&
						evt.Key.Code == KeyCode.LEFT)
			{
				if (curSpriteFrame > 0)
					curSpriteFrame--;

				sprite = new Sprite(new Image(mfb.width, mfb.height, cast(ubyte[]) mfb[curSpriteFrame]));
			}
			else if (   evt.Type == Event.EventType.KEYPRESSED &&
						evt.Key.Code == KeyCode.RIGHT)
			{
				if (curSpriteFrame < mfb.numSprites()-1)
					curSpriteFrame++;

				sprite = new Sprite(new Image(mfb.width, mfb.height, cast(ubyte[]) mfb[curSpriteFrame]));
			}
            else if (   evt.Type == Event.EventType.CLOSED)
                window.close();
            
        }
        sprite.setPosition(250.f, 250.f);
		txtSpritePos.setString(std.string.format("Sprite %d/%d", curSpriteFrame+1, mfb.numSprites));
		window.draw(background);
        window.draw(txt);
		window.draw(txtSpritePos);
        window.draw(sprite);
        if (s !is null) window.draw(s);
        window.display();
    }
}