module openbb.io.mfbfile;

import core.stdc.math;
import std.file;
import std.string;
import std.stdio;

import openbb.common;
import openbb.io.palette;

const FLAG_COMPRESSED = 0x2;
const FLAG_1 = 0x1;
const FLAG_4 = 0x4;

///
class MFBFile
{
private:
	struct Header
	{
		align(1):
		char[3] magic; // MFB
		char[3] ver; // version, should be 101d (= 65h)
		ushort width; // is the width of a single image
		ushort height; // is the height of a single image
		ushort uk3; // not used?
		ushort uk4; // not used?
		ushort flags; // some kind of flag byte
		ushort numSprites;
		
		string toString()
		{
			return std.string.format("{%s,%s,%d,%d,%d,%d,%b,%d}", magic, ver, width, height, uk3, uk4, flags, numSprites);
		}
	}
	Header _header;
	string _filename;
	ubyte[][] _spriteData;
	ubyte _transparencyColor; // the color used for transparency TODO: do this better

	uint _spriteSheetWidth; // used temporarily for opSlice
	uint _spriteSheetHeight;
	
	void checkHeader()
	{
//		if(_header.magic!="MFB")
//			MessageBoxA(NULL, toStringz("magic doesn't match!"), toStringz("magic error"),MB_OK);
	}

public:
	/// load MFB from file
	this(string filename, bool isMaptile = false)
	{
		_filename = filename;
		
		ubyte[] data = cast(ubyte[]) read(filename);
		this(data, isMaptile);
		delete data;
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
		
		uint spriteSize = _header.width * (_header.height - isMaptile?5:0);
		
		_spriteData = new ubyte[][](_header.numSprites, spriteSize);
		for(uint i=0; i<_header.numSprites; i++)
		{
			if((_header.flags & FLAG_COMPRESSED) == 0) // not compressed
			{
				_transparencyColor = data[pos];
				
				// if it's maptile.mfb, skip the first 5 rows since they are empty
				if (isMaptile)
					pos += 5*_header.width;
				
				foreach(j; 0 .. spriteSize)
					_spriteData[i][j] = data[pos + j];
				// _spriteData[i] = data[pos .. pos + _header.width*_header.height].dup;
				
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

	~this()
	{
		delete _spriteData;
	}
	
	/// returns sprite at index i as RGBA data
	RGBA[] opIndex(size_t index, ubyte paletteIdx = 0)
	in
	{
		assert(index>=0 && index<_header.numSprites);
	}
	body
	{
		usePalette(paletteIdx);
		RGBA[] buffer;
		buffer.length = _header.width*_header.height;
		for(uint i=0; i<buffer.length; i++)
		{
//			buffer[i] = palette[_spriteData[index][i]];
			buffer[i] = _spriteData[index][i] == _transparencyColor ? RGBA(0,0,0,0) : palette[_spriteData[index][i]];
		}
		return buffer;
	}

	/// return all sprites in a single image
	RGBA[] opSlice()
	{
		return opSlice(0, _header.numSprites);
	}
	
	/// return sprites s .. e in a single image with height rows and width columns
	RGBA[] opSlice(size_t s, size_t e)
	{
		uint width	= cast(uint) (sqrtf(cast(float) _header.numSprites) + 0.5); // round(sqrt(x))
		uint height	= cast(uint) ceilf((cast(float) _header.numSprites) / width); // round up
//		uint height = 1;
//		uint width = _header.numSprites;

		usePalette(0);
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
						buffer[bufIndex++] = palette[_spriteData[j*width+i][y*_header.width+x]];
					}
				}
					
			}
		}
		_spriteSheetWidth = width;
		_spriteSheetHeight = height;
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