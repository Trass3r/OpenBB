module openbb.io.mfbfile;

import core.stdc.math;
import std.file;
import std.string;
import std.stdio;

import openbb.common;
import openbb.io.palette;

///
final class MFBFile
{
private:
	enum EntryFlags : ushort
	{
		Transparent = 1,
		Compressed = 2,
		Unknown = 4
	}

	struct Header
	{
		align(1):
		char[3] magic; // MFB
		char[3] ver; // version, should be 101d (= 65h)
		ushort width;  // width of a single image
		ushort height; // height of a single image
		ushort offsetx; // not used?
		ushort offsety; // not used?
		EntryFlags flags; // some kind of flag byte
		ushort numSprites;
		
		string toString() const
		{
			return std.string.format("{%s,%s,%d,%d,%d,%d,%b,%d}", magic, ver, width, height, offsetx, offsety, flags, numSprites);
		}
	}
	Header _header;
	string _filename;
	ubyte[][] _spriteData;
	ubyte _transparencyColor; // the color used for transparency

	uint _spriteSheetWidth; // used temporarily for opSlice
	uint _spriteSheetHeight;
	
	void checkHeader()
	{
		if (_header.magic != "MFB")
			throw new Exception("Invalid MFB header");
	}

public:
	/// load MFB from file
	this(string filename, bool isMaptile = false)
	{
		_filename = filename;
		
		scope data = cast(ubyte[]) std.file.read(filename);
		this(data, isMaptile);
	}
	
	/**
	 *	load MFB from memory
	 *	
	 *	Params:
	 *		isMaptile	= first 5 rows are cut off if the mfb file is maptile.mfb
	 */
	this(const ubyte[] data, bool isMaptile = false)
	{
		_header = *cast(Header*) data;

		uint pos = Header.sizeof;
		
		//if (isMaptile)
		//	_header.height -= 5; // first 5 rows in maptile images are empty
		
		uint spriteSize = _header.width * _header.height;
		
		_spriteData = new ubyte[][](_header.numSprites, spriteSize);
		for(uint i=0; i<_header.numSprites; i++)
		{
			if((_header.flags & EntryFlags.Compressed) == 0) // not compressed
			{
				_transparencyColor = data[pos];
				
				// if it's maptile.mfb, skip the first 5 rows since they are empty
				//if (isMaptile)
				//	pos += 5*_header.width;
				_spriteData[i][] = data[pos .. pos + spriteSize];
				pos += spriteSize;
			}
			else // RLE compressed
			{
				uint size = *cast(uint*) (data.ptr + pos); pos += 4;
				_transparencyColor = data[pos];
				unRLE(data[pos .. pos + size], _spriteData[i]);
				pos += size;
			}
		} // for numSprites
	}

	/// returns sprite at index i as RGBA data
	// TODO: call opSlice(index, index+1) here?
	RGBA[] opIndex(size_t index, Palette paletteIdx = Palette.Main)
	in
	{
		assert(index < _header.numSprites);
	}
	body
	{
		usePalette(paletteIdx);
		RGBA[] buffer;
		buffer.length = _header.width*_header.height;
		for (uint i = 0; i < buffer.length; ++i)
		{
			if ((_header.flags & EntryFlags.Transparent) && _spriteData[index][i] == _transparencyColor)
				buffer[i] = RGBA(0,0,0,0);
			else
				buffer[i] = palette[_spriteData[index][i]];
		}
		return buffer;
	}

	/// return all sprites in a single image
	RGBA[] opSlice()
	{
		// FIXME: respect the range
		/*
		return opSlice(0, _header.numSprites);
	}
	
	/// return sprites s .. e in a single image with height rows and width columns
	RGBA[] opSlice(size_t s, size_t e)
	{*/
		uint width	= cast(uint) (sqrtf(cast(float) _header.numSprites) + 0.5); // round(sqrt(x))
		uint height	= cast(uint) ceilf((cast(float) _header.numSprites) / width); // round up
		//height = 1;
		//width = _header.numSprites;

		// FIXME: return this in a proper way
		_spriteSheetWidth = width;
		_spriteSheetHeight = height;

		auto buffer = new RGBA[_header.width*_header.height * width*height]; // need the full image even if numSprites < width*height 

		uint bufIndex = 0;
		for(uint j=0; j<height; j++)
		{
			for(uint y=0; y<_header.height; y++)
			{
				for(uint i=0; i<width; i++)
				{
					for(uint x=0; x<_header.width; x++)
					{
						const spriteIdx = j*width+i;
						if (spriteIdx >= _header.numSprites)
						{
							buffer[bufIndex++] = RGBA(255, 0, 255, 255); // use something salient to detect when this sprite is accidentally used
							continue;
						}

						const pixelIdx = y * _header.width + x;
						if ((_header.flags & EntryFlags.Transparent) && _spriteData[spriteIdx][pixelIdx] == _transparencyColor)
							buffer[bufIndex++] = RGBA(0,0,0,0);
						else
							buffer[bufIndex++] = palette[_spriteData[spriteIdx][pixelIdx]];
					}
				}
			}
		}
		return buffer;
	}
	
	/**
	 *	uncompress animations
	 *	it's a simple run-length encoding variant
	 */
	void unRLE(const ubyte[] input, ubyte[] output)
	{
		uint inPos = 0, outPos = 0;
		ubyte copyByte = input[0];
				
		while (outPos < output.length)
		{
			if (input[inPos] == copyByte)
			{
				ubyte count = input[++inPos];
				++inPos;

				while (count--)
					output[outPos++] = copyByte;
			}
			else
			{
				output[outPos++] = input[inPos++];
			}
		}
	}
	
	@property
	{
		uint spriteSheetWidth()	{return _spriteSheetWidth;}
		uint spriteSheetHeight(){return _spriteSheetHeight;}
		ushort width()			{return _header.width;} /// width property
		ushort height()			{return _header.height;} /// height property
		ushort numSprites()		{return _header.numSprites;} /// getter
		ushort flags()			{return _header.flags;} /// flags getter
	}
}