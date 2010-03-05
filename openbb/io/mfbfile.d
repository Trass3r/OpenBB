module openbb.io.mfbfile;

import core.stdc.math;
import std.stream;
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
	this(string filename)
	{
		_filename = filename;
		readMFB();
	}
	
	/// load MFB from memory
	this(const ubyte[] data)
	{
		_header = *cast(Header*) data;

		uint pos = Header.sizeof;
		
		_spriteData = new ubyte[][](_header.numSprites, _header.width*_header.height);
		for(uint i=0; i<_header.numSprites; i++)
		{
			if((_header.flags & FLAG_COMPRESSED) == 0) // not compressed
			{
				_transparencyColor = data[pos];
				foreach(j; 0 .. _header.width * _header.height)
					_spriteData[i][j] = data[pos + j];
				// _spriteData[i] = data[pos .. pos + _header.width*_header.height].dup;
				
				pos += _header.width * _header.height;
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
		usePalette(0);
		auto buffer = new RGBA[_header.width*_header.height * _header.numSprites];
		
		uint width	= cast(uint) (sqrtf(cast(float) _header.numSprites) + 0.5); // round(sqrt(x))
		uint height	= cast(uint) ceilf((cast(float) _header.numSprites) / width); // round up
//		uint height = 1;
//		uint width = _header.numSprites;
		
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
	
	/// read an MFB file
	void readMFB()
	{
		auto hFile = new std.stream.File;
		try
		{
			hFile.open(_filename, FileMode.In);
			hFile.readExact(&_header, Header.sizeof);

			_spriteData = new ubyte[][](_header.numSprites, _header.width*_header.height);
			for(uint i=0; i<_header.numSprites; i++)
			{
				if((_header.flags & FLAG_COMPRESSED) == 0) // not compressed
				{
//					_spriteData[i].length = _header.width*_header.height;
					hFile.readExact(_spriteData[i].ptr, _spriteData[i].length);
/*
					_rgbData.length=_buffer.length;

					for(uint i=0; i<_buffer.length; i++)
					{
						_rgbData[i] = palette[_buffer[i]];
						//debug printf("%.*s\n", EightBitToRGBA(palette[0][_buffer[i]]).toString);
					}
*/
				}
				else
				{
					int size;
					hFile.read(size);
					ubyte[] buffer = new ubyte[size];
					hFile.readExact(buffer.ptr, buffer.length);
					
					unRLE(buffer, _spriteData[i]);
				}
			} // for numSprites
		}
		catch(Exception e)
		{
			writefln("Error reading MFB file: %s", e);
		}
		finally
		{
			hFile.close();
		}
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
	//	void width(ushort rhs)	{_header.width=rhs;} /// ditto
		ushort height()			{return _header.height;} /// height property
	//	void height(ushort rhs)	{_header.height=rhs;} /// ditto
		ushort numSprites()			{return _header.numSprites;} /// getter
	//	void numSprites(ushort rhs)	{_header.numS
		ushort flags()			{return _header.flags;} /// flags getter
	}
}