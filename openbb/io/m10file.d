/**
 *	
 */
module openbb.io.m10file;

import std.stdio;

private
{

//Wave 'fmt ' chunk
struct SWaveFmtChunk
{
	ushort	FormatTag;
	ushort	Channels;
	uint	SampleRate;
	uint	BytesPerSec;
	ushort	BlockAlign;
	ushort	BitsPerSample;
}

void PrepareWaveHeader(ubyte[] Output)
{
	WriteWaveHeader(Output, 0, 0, 0, 0);
	return;
}

void WriteWaveHeader(ubyte[] Output, uint SampleRate,
					 ubyte BitsPerSample, ubyte Channels,
					 uint NumberSamples)
{
	// Write some RIFF information
	Output[0..4]	= cast(ubyte[]) "RIFF";
	uint Temp		= NumberSamples*(BitsPerSample/8)+36;
	Output[4..8]	= (cast(ubyte*) &Temp)[0..4];
	Output[8..12]	= cast(ubyte[]) "WAVE";
	Output[12..16]	= cast(ubyte[]) "fmt ";
	Temp = 16;
	Output[16..20]	= (cast(ubyte*) &Temp)[0..4];

	// Write the format chunk
	SWaveFmtChunk Fmt;
	Fmt.FormatTag=1;
	Fmt.Channels=Channels;
	Fmt.SampleRate=SampleRate;
	Fmt.BitsPerSample=BitsPerSample;
	Fmt.BytesPerSec=Fmt.BitsPerSample/8*Fmt.SampleRate*Fmt.Channels;
	Fmt.BlockAlign=cast(ushort) (Fmt.BitsPerSample/8*Fmt.Channels);
	Output[20..36] = (cast(ubyte*) &Fmt)[0..Fmt.sizeof];

	// Write the data information
	Output[36..40] = cast(ubyte[]) "data";
	Temp = NumberSamples*(BitsPerSample/8);
	Output[40..44] = (cast(ubyte*) &Temp)[0..4];
	return;
}

static uint readBytes(const(ubyte)[] input)
{
	uint result;

	result = 0L;
	for (ubyte i = 0; i < input.length; i++)
	{
		result = (result<<8) | input[i];
	}
	return result;
}
} // of private

class M10File
{
protected:
	uint parsePTHeader(const(ubyte)[] input)
	{
		// check magic
		if (input[0..2] != "PT")
			throw new Exception("No PT file!");

		uint idx = 4; // seek 2 from current

		// Data offset
		uint DataOffset;
		DataOffset = *cast(uint*) input[idx..idx+4];
		idx += 4;

		// Read in the header (code borrowed from Valery V. Anisimovsky (samael@avn.mccme.ru) )
		uint CompressionType;
		ubyte b;
		bool bInHeader;
		bool bInSubHeader;

		bInHeader = true;
		while (bInHeader)
		{
			b = input[idx++];

			switch (b) // parse header code
			{
			case 0xFF: // end of header
				bInHeader = false;
			case 0xFE: // skip
			case 0xFC: // skip
				break;
			case 0xFD: // subheader starts...
				bInSubHeader = true;
				while (bInSubHeader)
				{
					b = input[idx++];
					switch (b) // parse subheader code
					{
					case 0x83:
						b = input[idx++];
						CompressionType = readBytes(input[idx..idx+b]);
						idx += b;
						break;
					case 0x85:
						b = input[idx++];
						_TotalSampleCount = readBytes(input[idx..idx+b]);
						idx += b;
						break;
					case 0xFF:
						break;
					case 0x8A: // end of subheader
						bInSubHeader = false;
					default: // ???
						b = input[idx++];
						idx += b; // seek cur
					}
				}
				break;
			default:
				b = input[idx++];
				if (b == 0xFF)
					idx += 4;
				idx += b;
			}
		}

		// Print some things out
		writefln("Compression: %d", CompressionType);

		// Seek to the data offset
		return DataOffset;
	}

private:
	uint	_SampleBufferOffset; // TODO: size_t was c++ size_t
	uint	_SamplesDecodedSoFar;
	uint	_TotalSampleCount;

public:
	this(const(ubyte)[] input)
	{
//		Clear();

		uint idx;

		if (input.length < 1)
		{
			writeln("Empty file.");
			return;
		}

		// Read the PT header
		idx = parsePTHeader(input);

		// Load the file in
		size_t DataSize;
		DataSize = input.length - idx;
		
		writefln("Total sample count: %d", _TotalSampleCount);

		// Initialize the decoder
		try
		{
			_currentBits	= input[idx];
			_compressedData = input.ptr+idx+1;
			_bitCount		= 8;
			
			_firstBit		= getBits(1);
			_second4Bits	= 32 - getBits(4);
			
			_floatTable[0] = (getBits(4) + 1) * 8.0;

			float ST1 = 1.04 + (getBits(6) * 0.001);
			
			for (uint i = 0; i < 63; i++)
				_floatTable[i+1] = _floatTable[i] * ST1;
			
			_table1 = 0;
			_table2 = 0;
			_bigTable = 0;
		}
		catch (Exception e)
		{
			writefln("The decoder could not be initialized (bug in program). %s", e.toString());
		}
		_SampleBufferOffset = 432;
		_SamplesDecodedSoFar = 0;
		return;
	}
	
	//! returns content as wav
	ubyte[] toWav()
	{
		auto Output = new ubyte[4_000_000];
		
		PrepareWaveHeader(Output);

		short[4096] Samples;
		uint Decoded;
		int SampleCount;
		SampleCount = 0;
		uint idx = 44; // size of WAV headers
		do
		{
			Decoded = Decode(Samples);

			Output[idx..idx+Decoded*2] = (cast(ubyte*) Samples)[0.. Decoded * 2];
			idx += Decoded*2;
			SampleCount += Decoded;
		} while (Decoded == 4096);

		WriteWaveHeader(Output, 22050, 16, 1, SampleCount);
		return Output[0 .. idx];
	}
	
	union mtFloatInt
	{
		float Float;
		uint Int;
	}
	//! decodes a block, returns number of samples written
	size_t Decode(short[] OutputBuffer)
	{
		if (!_TotalSampleCount)
		{
			return 0;
		}

		for (size_t i = 0; i < OutputBuffer.length; i++)
		{
			mtFloatInt Sample;
			Sample.Int = 0x4B400000; // 12582912.0f

			if (_SampleBufferOffset >= 432)
			{
				try
				{
					mtDecodeBlock();
				}
				catch (Exception e)
				{
					writeln("The decoder encountered a problem (bug in program). " ~ e.toString());
					return i;
				}
				_SampleBufferOffset = 0;
			}

			Sample.Float += _sampleBuffer[_SampleBufferOffset];
			_SampleBufferOffset++;
			_SamplesDecodedSoFar++;

			uint Clipped = Sample.Int & 0x1FFFF; // get 21 bits of the mantissa
			
			if (Clipped > 0x7FFF && Clipped < 0x18000)
			{
				if (Clipped >= 0x10000)
				{
					Clipped = 0x8000;
				}
				else
				{
					Clipped = 0x7FFF;
				}
			}

			OutputBuffer[i] = cast(short)Clipped;

			if (_SamplesDecodedSoFar >= _TotalSampleCount)
			{
				return i + 1;
			}
		}
		return OutputBuffer.length;
	}

private:
	const(ubyte)*_compressedData;// 0
	uint		_currentBits;	// 4
	uint		_bitCount;		// 8
	uint		_firstBit;		// C
	uint		_second4Bits;	// 10
	float[64]	_floatTable;	// 14
	float[12]	_table1;		// 114
	float[12]	_table2;		// 144
	float[324]	_bigTable;		// 174
	float[432]	_sampleBuffer;	// 684

	void mtDecodeBlock()
	{
		float[12] tableA = 0;
		float[118] tableB = 0;

		uint Bits = getBits(6);

		int Flag = Bits < _second4Bits ? 1 : 0;

		tableA[0] = (flt_4D3A68[Bits] - _table1[0]) * 0.25f;

		for (uint i = 1; i < 4; i++)
		{
			Bits = getBits(6);

			tableA[i] = (flt_4D3A68[Bits] - _table1[i]) * 0.25f;
		}

		for (uint i = 4; i < 12; i++)
		{
			Bits = getBits(5);

			tableA[i] = (flt_4D3A68[Bits + 16] - _table1[i]) * 0.25f;
		}

		float* curSampleBufPtr = _sampleBuffer.ptr;

		for (uint i = 216; i < 648; i += 108)
		{
			uint BigTableIndex = i - getBits(8);

			float someFloat = getBits(4) * 2.0f / 30.0f; // * 0.0666666666666666666
			float someOtherFloat = _floatTable[getBits(6)];

			if (!_firstBit)
			{
				function3(Flag, tableB.ptr + 5, 1);
			}
			else
			{
				uint IndexAdjust = getBits(1);
				Bits = getBits(1);

				function3(Flag, tableB.ptr + 5 + IndexAdjust, 2);

				if (Bits)
				{
					for (uint j = 0; j < 108; j += 2)
					{
						tableB[j + 6 - IndexAdjust] = 0;
					}
				}
				else
				{
					for (ubyte j = 0; j < 5; j++)
					{
						tableB[j] = 0;
						tableB[j + 113] = 0;
					}

					function1(&tableB[6 - IndexAdjust]);
					someOtherFloat *= 0.5;
				}
			}

			float* BigTablePtr = _bigTable.ptr + BigTableIndex;
			
			for (ubyte k = 0; k < 108; k++)
			{
				*curSampleBufPtr = someOtherFloat * tableB[k + 5] + someFloat * BigTablePtr[k];
				curSampleBufPtr++;
			}

			/*
			for (uint k = 0; k < 108; k++)
			{
				float tmp = someOtherFloat * tableB[k + 5];
				float tmp2 = someFloat * _bigTable[BigTableIndex + k];
				*curSampleBufPtr = tmp + tmp2;
				curSampleBufPtr++;
			}*/
		}

		_bigTable[0 .. 324] = _sampleBuffer[108 .. 432];

		_table1[] += tableA[];
		function4(0, 1);

		_table1[] += tableA[];
		function4(12, 1);

		_table1[] += tableA[];
		function4(24, 1);

		_table1[] += tableA[];
		function4(36, 33);
		return;
	}

	//! 
	static void function1(float* buffer)
	{
		for (ubyte i = 0; i < 108; i+=2)
		{
			
			buffer[i] = (buffer[i-3] + buffer[i+3]) * -0.11459156
					  + (buffer[i-5] + buffer[i+5]) * 0.01803268
					  + (buffer[i-1] + buffer[i+1]) * 0.59738597;
		}
		return;
	}

	//! 
	static void function2(float* innerTable1, float* arg2)
	{
		float[24] table;

		for (ubyte i = 0; i < 11; i++)
		{
			table[11 - i] = innerTable1[10 - i];
		}

		table[0] = 1.0;

		for (uint i = 0; i < 12; i++)
		{
			double previous;
			previous = -table[11] * innerTable1[11];

			for (uint k = 0; k < 11; k++)
			{
				float* ptrA = &table[10 - k];
				float* ptrB = &innerTable1[10 - k];

				previous -= (*ptrA) * (*ptrB);
				table[11 - k] = previous * (*ptrB) + (*ptrA);
			}

			table[0] = previous;
			table[i + 12] = previous;

			if (i > 0)
			{
				for (uint j = 0; j < i; j++)
				{
					previous -= table[11 + i - j] * arg2[j];
				}
			}

			arg2[i] = previous;
		}
	}

	//! 
	void function3(int flag, float* outArray, uint countInt)
	{
		if (flag != 0)
		{
			uint Index = 0;
			uint HighBits = 0;

			do
			{
				ubyte LookedUpValue;
				uint Bits = _currentBits & 0xFF;;

				LookedUpValue = byte_4D3B68[(HighBits << 8) + Bits];
				HighBits = LookupTable[LookedUpValue].HighBits;

				skipBits(LookupTable[LookedUpValue].SkipBits);

				if (LookedUpValue > 3)
				{
					outArray[Index] = LookupTable[LookedUpValue].Float;
					Index += countInt;
				}
				else if (LookedUpValue > 1)
				{
					uint Bits2 = getBits(6) + 7;

					if (Bits2 * countInt + Index > 108)
					{
						Bits2 = (108 - Index) / countInt;
					}

					if (Bits2 > 0)
					{
						float* Ptr;
						Ptr = outArray + Index;
						Index += Bits2 * countInt;

						for (uint i = 0; i < Bits2; i++)
						{
							*Ptr = 0;
							Ptr += countInt;
						}
					}
				}
				else
				{
					int Count = 7;

					while (getBits(1) == 1)
					{
						Count++;
					}

					if (getBits(1))
					{
						outArray[Index] = Count;
					}
					else
					{
						outArray[Index] = -Count;
					}

					Index += countInt;
				}
			} while (Index < 108);
		}
		else
		{
			uint Index = 0;

			do
			{
				switch (_currentBits & 0x3)
				{
				case 1:
					outArray[Index] = -2.0;
					skipBits(2);
					break;
				case 3:
					outArray[Index] = 2.0;
					skipBits(2);
					break;
				case 2:
				case 0:
					outArray[Index] = 0;
					skipBits(1);
					break;
				default:
					break;
				}
				Index += countInt;
			} while (Index < 108);
		}
		return;
	}

	//! 
	void function4(uint sampleBufferIdx, uint count)
	{
		float[12] buffer;
		function2(_table1.ptr, buffer.ptr);

		for (uint i = 0; i < 12*count; i+=12)
		{
			for (uint j = 0; j < 12; j++)
			{
				double Summation = 0.0;
				for (uint k = 0; k < 12; k++)
				{
					Summation += _table2[k] * buffer[(k + j) % 12];
				}

				double Result = _sampleBuffer[sampleBufferIdx + i + j] + Summation;
				_table2[11 - j] = Result;
				_sampleBuffer[sampleBufferIdx + i + j] = Result;
			}
		}
		return;
	}

	static __gshared immutable uint[9] bitmask_lookup_table = [0, 1, 3, 7, 0x0F, 0x1F, 0x3F, 0x7F, 0x0FF];

	//! reads count bits from the input stream (the _compressedData member) and returns them
	uint getBits(uint count)
	{
		uint res = _currentBits & bitmask_lookup_table[count];
		_bitCount -= count;
		_currentBits >>= count; // note: count only byte!
		
		if (_bitCount < 8)
		{
			_currentBits |= _compressedData[0] << _bitCount;
			_compressedData++;
			_bitCount += 8;
		}
		return res;
	}

	//! skip count bits
	void skipBits(uint count)
	{
		_bitCount -= count;
		_currentBits >>= count;

		if (_bitCount < 8)
		{
			_currentBits |= _compressedData[0] << _bitCount;
			_compressedData++;
			_bitCount += 8;
		}
		return;
	}
} // class M10File

private __gshared immutable
{
float[64] flt_4D3A68 = [0.0,	-0.99677598,	-0.990327,	-0.98387903,	-0.977431,
	-0.97098202,	-0.96453398,	-0.958085,		-0.95163703,
	-0.93075401,	-0.90495998,	-0.87916702,	-0.85337299,
	-0.82757902,	-0.80178601,	-0.77599198,	-0.75019801,
	-0.72440499,	-0.69861102,	-0.67063498,	-0.619048,
	-0.56746,		-0.51587301,	-0.464286,		-0.412698,
	-0.36111099,	-0.309524,		-0.25793701,	-0.206349,
	-0.154762,		-0.103175,		-5.1587e-2,		0.0, 		5.1587e-2,
	0.103175,		0.154762,		0.206349,		0.25793701,	0.309524,
	0.36111099,		0.412698,		0.464286,		0.51587301,
	0.56746,		0.619048,		0.67063498,		0.69861102,	0.72440499,
	0.75019801,		0.77599198,		0.80178601,		0.82757902,
	0.85337299,		0.87916702,		0.90495998,		0.93075401,
	0.95163703,		0.958085,		0.96453398,		0.97098202,
	0.977431,		0.98387903,		0.990327,		0.99677598];

ubyte[512] byte_4D3B68 = [
	4, 6, 5, 9, 4, 6, 5, 0x0D, 4, 6, 5, 0x0A, 4, 6, 5, 0x11,
	4, 6, 5, 9, 4, 6, 5, 0x0E, 4, 6, 5, 0x0A, 4, 6, 5, 0x15,
	4, 6, 5, 9, 4, 6, 5, 0x0D, 4, 6, 5, 0x0A, 4, 6, 5, 0x12,
	4, 6, 5, 9, 4, 6, 5, 0x0E, 4, 6, 5, 0x0A, 4, 6, 5, 0x19,
	4, 6, 5, 9, 4, 6, 5, 0x0D, 4, 6, 5, 0x0A, 4, 6, 5, 0x11,
	4, 6, 5, 9, 4, 6, 5, 0x0E, 4, 6, 5, 0x0A, 4, 6, 5, 0x16,
	4, 6, 5, 9, 4, 6, 5, 0x0D, 4, 6, 5, 0x0A, 4, 6, 5, 0x12,
	4, 6, 5, 9, 4, 6, 5, 0x0E, 4, 6, 5, 0x0A, 4, 6, 5, 0,
	4, 6, 5, 9, 4, 6, 5, 0x0D, 4, 6, 5, 0x0A, 4, 6, 5, 0x11,
	4, 6, 5, 9, 4, 6, 5, 0x0E, 4, 6, 5, 0x0A, 4, 6, 5, 0x15,
	4, 6, 5, 9, 4, 6, 5, 0x0D, 4, 6, 5, 0x0A, 4, 6, 5, 0x12,
	4, 6, 5, 9, 4, 6, 5, 0x0E, 4, 6, 5, 0x0A, 4, 6, 5, 0x1A,
	4, 6, 5, 9, 4, 6, 5, 0x0D, 4, 6, 5, 0x0A, 4, 6, 5, 0x11,
	4, 6, 5, 9, 4, 6, 5, 0x0E, 4, 6, 5, 0x0A, 4, 6, 5, 0x16,
	4, 6, 5, 9, 4, 6, 5, 0x0D, 4, 6, 5, 0x0A, 4, 6, 5, 0x12,
	4, 6, 5, 9, 4, 6, 5, 0x0E, 4, 6, 5, 0x0A, 4, 6, 5, 2,
	4, 0x0B, 7, 0x0F, 4, 0x0C, 8, 0x13, 4, 0x0B, 7, 0x10, 4, 0x0C,
	8, 0x17, 4, 0x0B, 7, 0x0F, 4, 0x0C, 8, 0x14, 4, 0x0B, 7, 0x10,
	4, 0x0C, 8, 0x1B, 4, 0x0B, 7, 0x0F, 4, 0x0C, 8, 0x13, 4, 0x0B,
	7, 0x10, 4, 0x0C, 8, 0x18, 4, 0x0B, 7, 0x0F, 4, 0x0C, 8, 0x14,
	4, 0x0B, 7, 0x10, 4, 0x0C, 8, 1, 4, 0x0B, 7, 0x0F, 4, 0x0C,
	8, 0x13, 4, 0x0B, 7, 0x10, 4, 0x0C, 8, 0x17, 4, 0x0B, 7, 0x0F,
	4, 0x0C, 8, 0x14, 4, 0x0B, 7, 0x10, 4, 0x0C, 8, 0x1C, 4, 0x0B,
	7, 0x0F, 4, 0x0C, 8, 0x13, 4, 0x0B, 7, 0x10, 4, 0x0C, 8, 0x18,
	4, 0x0B, 7, 0x0F, 4, 0x0C, 8, 0x14, 4, 0x0B, 7, 0x10, 4, 0x0C,
	8, 3, 4, 0x0B, 7, 0x0F, 4, 0x0C, 8, 0x13, 4, 0x0B, 7, 0x10,
	4, 0x0C, 8, 0x17, 4, 0x0B, 7, 0x0F, 4, 0x0C, 8, 0x14, 4, 0x0B,
	7, 0x10, 4, 0x0C, 8, 0x1B, 4, 0x0B, 7, 0x0F, 4, 0x0C, 8, 0x13,
	4, 0x0B, 7, 0x10, 4, 0x0C, 8, 0x18, 4, 0x0B, 7, 0x0F, 4, 0x0C,
	8, 0x14, 4, 0x0B, 7, 0x10, 4, 0x0C, 8, 1, 4, 0x0B, 7, 0x0F,
	4, 0x0C, 8, 0x13, 4, 0x0B, 7, 0x10, 4, 0x0C, 8, 0x17, 4, 0x0B,
	7, 0x0F, 4, 0x0C, 8, 0x14, 4, 0x0B, 7, 0x10, 4, 0x0C, 8, 0x1C,
	4, 0x0B, 7, 0x0F, 4, 0x0C, 8, 0x13, 4, 0x0B, 7, 0x10, 4, 0x0C,
	8, 0x18, 4, 0x0B, 7, 0x0F, 4, 0x0C, 8, 0x14, 4, 0x0B, 7, 0x10,
	4, 0x0C, 8, 3];

struct LookupEntry
{
	uint HighBits;
	uint SkipBits;
	float Float;
}
LookupEntry[29] LookupTable = [
	{1, 8, 0.0f},
	{1, 7, 0.0f},
	{0, 8, 0.0f},
	{0, 7, 0.0f},
	{0, 2, 0.0f},
	{0, 2, -1.0f},
	{0, 2, 1.0f},
	{0, 3, -1.0f},
	{0, 3, 1.0f},
	{1, 4, -2.0f},
	{1, 4, 2.0f},
	{1, 3, -2.0f},
	{1, 3, 2.0f},
	{1, 5, -3.0f},
	{1, 5, 3.0f},
	{1, 4, -3.0f},
	{1, 4, 3.0f},
	{1, 6, -4.0f},
	{1, 6, 4.0f},
	{1, 5, -4.0f},
	{1, 5, 4.0f},
	{1, 7, -5.0f},
	{1, 7, 5.0f},
	{1, 6, -5.0f},
	{1, 6, 5.0f},
	{1, 8, -6.0f},
	{1, 8, 6.0f},
	{1, 7, -6.0f},
	{1, 7, 6.0f}
];
} // private immutable __gshared