/**
 *	
 */
module main;

import dsfml.system.all;
import dsfml.window.all;
import dsfml.graphics.all;
import dsfml.audio.all;

import openbb.common;
import openbb.io.palette;
import openbb.io.boxfile;
import openbb.io.mfbfile;
import openbb.map;
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
	auto mfb = new MFBFile(videobox["maptile.MFB"]);
    
    auto images = new Image[mfb.numSprites];
	for(uint i=0; i<mfb.numSprites; i++)
	{
		images[i] = new Image(mfb.width, mfb.height, cast(ubyte[]) mfb[i]);
	}

	auto map = new Map(10, 15, window, images);

	float framerate;
	Text fps = new Text(std.string.format("%f fps", framerate));
	
    while (window.isOpened())
    {
        Event evt;

//        if (evt.Type == EventType.Closed)
//            window.close();
        
        framerate = 1.f / window.getFrameTime();
        fps.setString(std.string.format("%f fps", framerate));

        window.clear();
        map.render();
        //window.draw(fps);
        if (s !is null) window.draw(s);
        window.display();
    }
}