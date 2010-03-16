/**
 *	
 */
module openbb.io.fatfile;

import openbb.exceptions;
import std.file;

import openbb.common;


private struct Header
{
align(1):
	char[4]	magic;
	uint	numFiles;
}

//! directory entry
private struct Entry
{
	uint offset;
	uint size;
	uint type;
	uint flag;
}

//! ambient audio bank
class FATFile
{
private:
	uint	_numFiles;
	Entry[]	_directory;
	ubyte[]	_data;
public:

	this(string filename)
	{
		_data = cast(ubyte[]) read(filename);
		
		char[4] magic = cast(char[]) _data[0 .. 4];
		
		if (magic != "0.30")
			throw new IOException("Not a B&B FAT file!");
		
		_numFiles = *cast(uint*) _data[4 .. 8];
		
		_directory = cast(Entry[]) _data[8 .. 8 + _numFiles * Entry.sizeof];
	}
	
	const(short)[] opIndex(size_t i)
	in
	{
		assert(i < _numFiles);
	}
	body
	{
		return cast(short[]) _data[_directory[i].offset .. _directory[i].offset + _directory[i].size];
	}
	
@property
{
	uint numFiles()
	{
		return _numFiles;
	}
}
/*
	string toString()
	{
		std.string.format("numFiles: %s\t")
	}
*/
}