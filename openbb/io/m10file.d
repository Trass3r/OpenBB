/**
 *	
 */
module openbb.io.m10file;

import std.stdio;
import std.file;

int main(string[] args)
{
	if (args.length < 3)
	{
		writeln("Beasts and Bumpkins .m10 Decoder");
		writeln("Usage: " ~ args[0] ~ " {input} {output}");
		return 1;
	}

	string inputFilename;
	string outputFilename;
	inputFilename = args[1];
	outputFilename = args[2];

	auto input = cast(ubyte[]) read(inputFilename);


	auto Output = new ubyte[4_000_000];
	
	PrepareWaveHeader(Output);

	mtDecoder Decoder = new mtDecoder;
	Decoder.Initialize(input);

	short Samples[4096];
	uint Decoded;
	int SampleCount;
	SampleCount = 0;
	uint idx = 44; // size of WAV headers
	do
	{
		Decoded = Decoder.Decode(Samples, 4096u);

		Output[idx..idx+Decoded*2] = (cast(ubyte*) Samples)[0.. Decoded * 2];
		idx += Decoded*2;
		SampleCount += Decoded;
	} while (Decoded == 4096);

	WriteWaveHeader(Output, 22050, 16, 1, SampleCount);
	std.file.write(outputFilename, Output[0..idx]);
	return 0;
}

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

static uint ReadBytes(ubyte[] input)
{
	uint result;

	result = 0L;
	for (ubyte i = 0; i < input.length; i++)
	{
		result = (result<<8) | input[i];
	}
	return result;
}

class mtDecoder
{
protected:
	uint ParsePTHeader(ubyte[] input)
	{
		// Signature
		char[2] Sig;
		if (input[0..2] != "PT")
			throw new Exception("No PT header!");

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
						CompressionType = ReadBytes(input[idx..idx+b]);
						idx += b;
						break;
					case 0x85:
						b = input[idx++];
						_TotalSampleCount = ReadBytes(input[idx..idx+b]);
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
	uint				_SampleBufferOffset; // TODO: size_t was c++ size_t
	uint				_SamplesDecodedSoFar;
	uint				_TotalSampleCount;

public:
	void Initialize(ubyte[] input)
	{
//		Clear();

		uint idx;

		if (input.length < 1)
		{
			writeln("Empty file.");
			return;
		}

		// Read the PT header
		idx = ParsePTHeader(input);

		// Load the file in
		size_t DataSize;
		DataSize = input.length - idx;
		
		writefln("Total sample count: %d", _TotalSampleCount);

		// Initialize the decoder
		try
		{
			__mtInitializeDecoder(input[idx .. $].ptr);
			/*ofstream Output;
			Output.open("log", ios_base::out | ios_base::binary);
			Output.write((char*)_input, sizeof(S_inner_file_data));*/
		}
		catch (Exception e)
		{
			writefln("The decoder could not be initialized (bug in program). %s", e.toString());
		}
		_SampleBufferOffset = 432;
		_SamplesDecodedSoFar = 0;
		return;
	}
	
	union mtFloatInt
	{
		float Float;
		uint Int;
	}
	size_t Decode(short[] OutputBuffer, uint SampleCount)
	{
		if (!_TotalSampleCount)
		{
			return 0;
		}

		for (size_t i = 0; i < SampleCount; i++)
		{
			mtFloatInt Sample;
			Sample.Int = 0x4B400000;

			if (_SampleBufferOffset >= 432)
			{
				try
				{
					__mtDecodeBlock();
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

			uint Clipped;
			Clipped = Sample.Int & 0x1FFFF;
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
		return SampleCount;
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

	void __mtDecodeBlock()
	{
		writeln("__mtDecodeBlock()");
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

		float* CurSampleBufPtr = _sampleBuffer.ptr;

		for (uint i = 216; i < 648; i += 108)
		{
			uint BigTableIndex = i - getBits(8);

			float SomeFloat = getBits(4) * 2.0f / 30.0f; // * 0.0666666666666666666
			float SomeOtherFloat = _floatTable[getBits(6)];

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
					SomeOtherFloat *= 0.5;
				}
			}

			float* BigTablePtr = _bigTable.ptr + BigTableIndex;
			
			for (ubyte k = 0; k < 108; k++)
			{
				*CurSampleBufPtr = SomeOtherFloat * tableB[k + 5] + SomeFloat * BigTablePtr[k];
				CurSampleBufPtr++;
			}

			/*
			for (uint k = 0; k < 108; k++)
			{
				float tmp = SomeOtherFloat * tableB[k + 5];
				float tmp2 = SomeFloat * _bigTable[BigTableIndex + k];
				*CurSampleBufPtr = tmp + tmp2;
				CurSampleBufPtr++;
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
		writeln("function1()");
		for (ubyte i = 0; i < 108; i+=2)
		{
			
			buffer[i] = (buffer[i-3] + buffer[i+3]) * -0.11459156
					  + (buffer[i-5] + buffer[i+5]) * 0.01803268
					  + (buffer[i-1] + buffer[i+1]) * 0.59738597;
		}
		return;
	}

	//! 
	static void function2(float* innerTable1, float* Arg2)
	{
		writeln("function2()");
		float[24] Table;

		for (ubyte i = 0; i < 11; i++)
		{
			Table[11 - i] = innerTable1[10 - i];
		}

		Table[0] = 1.0;

		for (uint i = 0; i < 12; i++)
		{
			double Previous;
			Previous = -Table[11] * innerTable1[11];

			for (uint CounterC = 0; CounterC < 11; CounterC++)
			{
				float* PtrA = &Table[10 - CounterC];
				float* PtrB = &innerTable1[10 - CounterC];

				Previous -= (*PtrA) * (*PtrB);
				Table[11 - CounterC] = Previous * (*PtrB) + (*PtrA);
			}

			Table[0] = Previous;
			Table[i + 12] = Previous;

			if (i > 0)
			{
				uint CounterA = i;
				uint CounterB = i;

				for (uint j = 0; j < i; j++)
				{
					Previous -= Table[11 + i - j] * Arg2[j];
				}
			}

			Arg2[i] = Previous;
		}
	}

	//! 
	void function3(int flag, float* outArray, uint countInt)
	{
		writeln("function3()");
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
	void function4(uint Index, uint Count)
	{
		writeln("function4()");
		float[12] Buffer;
		function2(_table1.ptr, Buffer.ptr);

		for (uint i = 0; i < 12*Count; i+=12)
		{
			for (uint k = 0; k < 12; k++)
			{
				double Summation = 0.0;
				for (uint j = 0; j < 12; j++)
				{
					Summation += _table2[j] * Buffer[(j + k) % 12];
				}

				double Result = _sampleBuffer[Index + i + k] + Summation;
				_table2[11 - k] = Result;
				_sampleBuffer[Index + i + k] = Result;
			}
		}
		return;
	}

	static __gshared immutable uint[9] bitmask_lookup_table = [0, 1, 3, 7, 0x0F, 0x1F, 0x3F, 0x7F, 0x0FF];

	//! reads count bits from the input stream (the CompressedData member of S_inner_file_data) and returns them
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

//	alias SkipBits skipBits;
	void skipBits(uint Count)
	{
		_bitCount -= Count;
		_currentBits >>= Count;

		if (_bitCount < 8)
		{
			_currentBits |= _compressedData[0] << _bitCount;
			_compressedData++;
			_bitCount += 8;
		}
		return;
	}

	void __mtInitializeDecoder(const ubyte* inputBuffer)
	{
		writeln("__mtInitializeDecoder()");
		_currentBits	= inputBuffer[0];
		_compressedData = inputBuffer+1;
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
		writeln("end __mtInit");
	}
} // class mtDecoder

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