module png;
import openbb.common;

T swapBytes(T)(T b)
{
	import core.bitop;

	static if (b.sizeof == 1)
		return b;
	else
	static if (b.sizeof == 2)
		return cast(T)((b >> 8) | (b << 8));
	else
	static if (b.sizeof == 4)
	{
		uint x = *cast(uint*)&b;
		x = bswap(x);
		return *cast(T*)&x;
	}
	else
		static assert(false, "Don't know how to bswap " ~ T.stringof);
}

enum ulong SIGNATURE = 0x0a1a0a0d474e5089;

struct PNGChunk
{
	char[4] type;
	const(void)[] data;

	uint crc32()
	{
		import std.digest.crc;

		CRC32 crc;
		crc.put(cast(ubyte[])(type[]));
		crc.put(cast(ubyte[])data);
		ubyte[4] hash = crc.finish();
		return *cast(uint*)hash.ptr;
	}

	this(string type, const(void)[] data)
	{
		this.type[] = type[];
		this.data = data;
	}
}

enum PNGColourType : ubyte { G, RGB = 2, PLTE, GA, RGBA = 6 }
enum PNGCompressionMethod : ubyte { DEFLATE }
enum PNGFilterMethod : ubyte { ADAPTIVE }
enum PNGInterlaceMethod : ubyte { NONE, ADAM7 }
enum PNGFilterAdaptive : ubyte { NONE, SUB, UP, AVERAGE, PAETH }

struct PNGHeader
{
align(1):
	uint  width, height;
	ubyte colourDepth;
	PNGColourType colourType;
	PNGCompressionMethod compressionMethod;
	PNGFilterMethod filterMethod;
	PNGInterlaceMethod interlaceMethod;
}
static assert(PNGHeader.sizeof == 13);

/// Creates a PNG file.
/// Only basic PNG features are supported
/// (no filters, interlacing, palettes etc.)
ubyte[] toPNG(uint width, uint height, RGBA[] rgbaData)
{
	import std.digest.crc;
	import std.zlib : compress;

	alias Pixel = RGBA;
	enum COLOUR_TYPE = PNGColourType.RGBA;

	PNGChunk[] chunks;
	PNGHeader header = {
		width : swapBytes(width),
		height : swapBytes(height),
		colourDepth : 8,
		colourType : COLOUR_TYPE,
		compressionMethod : PNGCompressionMethod.DEFLATE,
		filterMethod : PNGFilterMethod.ADAPTIVE,
		interlaceMethod : PNGInterlaceMethod.NONE,
	};
	chunks ~= PNGChunk("IHDR", cast(void[])[header]);
	uint idatStride = cast(uint)(width * Pixel.sizeof+1);
	ubyte[] idatData = new ubyte[height * idatStride];
	for (uint y=0; y<height; ++y)
	{
		idatData[y*idatStride] = PNGFilterAdaptive.NONE;
		auto rowPixels = cast(Pixel[])idatData[y*idatStride + 1 .. (y+1)*idatStride];
		//img.copyScanline(y, rowPixels);
		for (uint x = 0; x < width; ++x)
			rowPixels[x] = rgbaData[y * width + x];

		/* TODO: this is incorrect, needs to check the sample size of a single color instead
		static if (Pixel.sizeof > 1)
			foreach (ref p; cast(Pixel[])rowPixels)
				p = swapBytes(p);
		*/
	}
	chunks ~= PNGChunk("IDAT", compress(idatData, 5));
	chunks ~= PNGChunk("IEND", null);

	uint totalSize = 8;
	foreach (chunk; chunks)
		totalSize += 8 + chunk.data.length + 4;
	ubyte[] data = new ubyte[totalSize];

	*cast(ulong*)data.ptr = SIGNATURE;
	uint pos = 8;
	foreach(chunk; chunks)
	{
		uint i = pos;
		uint chunkLength = cast(uint)chunk.data.length;
		pos += 12 + chunkLength;
		*cast(uint*)&data[i] = swapBytes(chunkLength);
		(cast(char[])data[i+4 .. i+8])[] = chunk.type[];
		data[i+8 .. i+8+chunk.data.length] = (cast(ubyte[])chunk.data)[];
		*cast(uint*)&data[i+8+chunk.data.length] = swapBytes(chunk.crc32());
		assert(pos == i+12+chunk.data.length);
	}

	return data;
}
