/**
 *	
 */
module openbb.graphics.animation;

import std.perf;

import openbb.log;

import dsfml.system.vector;
import dsfml.graphics.image;
import dsfml.graphics.rect;
import dsfml.graphics.sprite;


/**
 *	this extends Sprite to implement animated sprites
 *	uses a single Image containing all animation frames
 */
class Animation : Sprite
{
private:
	PerformanceCounter _clock;
	float	_fps		= 1;
	bool	_isPlaying	= false;
	uint	_loopStart;
	uint	_loopEnd;
	uint	_curFrame;
	uint	_frameWidth; /// size of a single animation frame in pixels 
	uint	_frameHeight; /// ditto
	uint	_sheetWidth; /// number of frames in a row
	uint	_sheetHeight; /// number of frames in a column

public:

	this(Image image, uint frameWidth, uint frameHeight)
	{
		super(image);
		
		_clock = new PerformanceCounter;

		_frameWidth	= frameWidth;
		_frameHeight= frameHeight;
		
		_sheetWidth	= image.width / frameWidth;
		_sheetHeight= image.height / frameHeight;
	}
	
	~this()
	{
	}
	
	/**
	*	Change the animation framesheet
	*
	*	Params:
	*		img = New image
	*		adjustToNewSize = adjust sprite subrect to new image size
	*/
	override void setImage(Image img, bool adjustToNewSize = false)
	{
		Sprite.setImage(img, adjustToNewSize);

		_sheetWidth	= img.width / _frameWidth;
		_sheetHeight= img.height / _frameHeight;
	}
	
	/// TODO: leave protected?		
	protected IntRect getFrameRect(uint frame)
	{
		uint y = frame / _sheetWidth;
		uint x = frame % _sheetWidth;
		
		return IntRect(	x * _frameWidth,
						y * _frameHeight,
						_frameWidth,
						_frameHeight);
	}
	
	/// play frames [startFrame, endFrame)
	Animation play(uint startFrame = 0, uint endFrame = 0)
	in
	{
		assert(startFrame >= 0 && endFrame < numFrames);
	}
	body
	{
		if(endFrame <= startFrame)
			endFrame = numFrames;
		
		_loopStart	= startFrame;
		_loopEnd	= endFrame;
		_curFrame	= startFrame;
		_isPlaying	= true;
		
		_clock.start();
		
		return this;
	}
	
	Animation stop()
	{
		_isPlaying = false;
		
		return this;
	}
	
	/// TODO: test if this is malicious when play hasn't been called before
	Animation resume()
	{
		_isPlaying = true;
		
		return this;
	}
	
	void update()
	{
		if(_isPlaying)
		{
			uint frameCount		= _loopEnd - _loopStart;
			_clock.stop();
			float timePosition	= _clock.microseconds() * 0.000001 * _fps;
			_curFrame = _loopStart + (cast(uint)timePosition) % frameCount; // correct that way 
			
//			debug logfln("%f:%d\t%d",_clock.getElapsedTime(), _curFrame);
 
			subRect = getFrameRect(_curFrame);
		}
	}
	@property
	{
		uint numFrames()
		{
			return _sheetWidth * _sheetHeight;
		}
		
		float loopSpeed()
		{
			return _fps;
		}
		
		void loopSpeed(float newfps)
		{
			_fps = newfps;
		}
		
		uint curFrame()
		{
			return _curFrame;
		}
		
		void curFrame(uint i)
		in
		{
			assert(i >= 0 && i < numFrames);
		}
		body
		{
			_curFrame = i;
		}
		
		Vector2ui frameSize()
		{
			return Vector2ui(_frameWidth, _frameHeight);
		}
		
		void frameSize(Vector2ui newsize)
		{
			_frameWidth	= newsize.x;
			_frameHeight= newsize.y;

			_sheetWidth	= image().width / _frameWidth;
			_sheetHeight= image().height / _frameHeight;
		}
	}
}