/**
 *	
 */
module openbb.graphics.animation;

import openbb.log;
import dsfml.system.clock;
import dsfml.system.vector2;
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
	Clock	_clock;
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
	this()
	{
		
	}
	this(Image image, uint frameWidth, uint frameHeight)
	{
		super(image);
		
		_sheetWidth	= image.getWidth() / _frameWidth;
		_sheetHeight= image.getHeight() / _frameHeight;
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
	void setImage(Image img, bool adjustToNewSize = false)
	{
		Sprite.setImage(img, adjustToNewSize);

		_sheetWidth	= img.getWidth() / _frameWidth;
		_sheetHeight= img.getHeight() / _frameHeight;
	}
	
	/// TODO: leave protected?		
	protected IntRect getFrameRect(uint frame)
	{
		uint y = frame / _sheetWidth;
		uint x = frame % _sheetHeight;
		
		return IntRect(	x * _frameWidth,
						y * _frameHeight,
					(x+1) * _frameWidth,
					(y+1) * _frameHeight);
	}
	
	Animation play(uint startFrame, uint endFrame)
	{
		_loopStart	= startFrame;
		_loopEnd	= endFrame;
		_curFrame	= startFrame;
		_isPlaying	= true;
		
		_clock.reset();
		
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
			float timePosition	= _clock.getElapsedTime() * _fps;
			_curFrame = _loopStart + (cast(uint)timePosition) % frameCount; // TODO: or should it be cast(uint)(timePosition % frameCount) 
			
			debug logfln("%f:%d",_clock.getElapsedTime(),_curFrame);
 
			setSubRect(getFrameRect(_curFrame));
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

			_sheetWidth	= getImage().getWidth() / _frameWidth;
			_sheetHeight= getImage().getHeight() / _frameHeight;
		}
	}
}