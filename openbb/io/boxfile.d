/**
 *	
 */
module openbb.io.boxfile;

import openbb.common;

import std.stream, std.file;
import std.string;
import std.stdio;

import dsfml.system.stringutil;


private struct SYSTEMTIME
{
    ushort year;
    ushort month;
    ushort dayofweek;
    ushort day;
    ushort hour;
    ushort minute;
    ushort second;
    ushort milliseconds;
    string toString()
    {
    	return std.string.format("%2d.%2d.%4d %02d:%02d:%02d", day, month, year, hour, minute, second);
    }
}

/// Header structure
private struct BoxHeader
{
align(1):
	char magic[3]; // "BOX"
	byte uk1;
	uint uk2; // 65536
}

/// File entry
private struct Entry
{
	char[256] filename; // zero-terminated
    char[256] path;
	SYSTEMTIME timestamp;
	uint size; // of actual data
	
	string toString()
	{
		return std.string.format("filename: %s\tpath: %s\ttimestamp: %s\tfilesize: %d", fromStringz(cast(ichar*)filename), fromStringz(cast(ichar*)path), timestamp, size);
	}
}

/// Archive file format used by B&B
class BOXFile
{
private:
	string		_filename;
	BoxHeader	_header;
	Entry[]		_entryHeaders;
	uint[string]_filenameTable; // hash table
	ubyte[][]	_entryData;

public:
	/// constructor
	this(string filename)
	{
		_filename = filename;
		readArchive();
	}

	invariant()
	{
		assert(_entryHeaders.length == _entryData.length);
	}
	
	/// read in the archive contents
	void readArchive()
	{
		auto _hIn = new std.stream.File();
		try
		{
			_hIn.open(_filename, FileMode.In);
			_hIn.readExact(&_header, BoxHeader.sizeof);

			if (_header.magic != "BOX"c)
				throw new Exception("No valid BOX file!");
			if (_header.uk2 != 65536)
				writeln("Warning: BOX might have an unexpected format!");
			debug writefln("BOX byte: %d", _header.uk1);

			Entry curEntry;
			
			// do until end of file is reached
			uint i; // for counting entry index
			while(!_hIn.eof)
			{
				_hIn.readExact(&curEntry, Entry.sizeof);
				_entryHeaders ~= curEntry;

				_filenameTable[fromStringz(cast(ichar*) curEntry.filename)] = i; // filename -> index hash table
				
				//debug writeln(curEntry);

				ubyte[] buffer = new ubyte[curEntry.size];
				_hIn.readExact(buffer.ptr, buffer.length);
				_entryData ~= buffer; // this actually isn't that inefficient cause only references are copied
				
				++i;
			}
		}
		catch (Exception e)
		{
			writeln(e);
		}
		finally
		{
			_hIn.close();
		}
	}
	
	/// get contents of a file by filename
	const(ubyte)[] opIndex(string filename)
	in
	{
		assert(filename in _filenameTable);
	}
	body
	{
		return _entryData[_filenameTable[filename]];
	}
	
	/// get contents of a file by index
	const(ubyte)[] opIndex(uint index)
	in
	{
		assert(index < _entryData.length);
	}
	body
	{
		return _entryData[index];
	}
	
	/// return a list of filenames contained in the archive
	string[] fileList()
	{
		return _filenameTable.keys;
	}
	
	/// extract all the files to the current directory
	void extractAll()
	{
		ubyte[] buffer;
		
		auto _hIn = new std.stream.File();
		try
		{
			_hIn.open(_filename, FileMode.In);
			_hIn.readExact(&_header, BoxHeader.sizeof);
			debug writeln("reading Box header");
			if (_header.magic != "BOX")
				throw new Exception("No valid BOX file!");
			if (_header.uk2 != 65536)
				writeln("Warning: BOX might have an unexpected format!");
			debug writefln("BOX byte: %d", _header.uk1);

			Entry curEntry;
			if(exists(_filename[0..$-4])==0)
				mkdir(_filename[0..$-4]);
			chdir(_filename[0..$-4]);
			auto hOut = new std.stream.File;
			debug writeln("entering while");
			while(!_hIn.eof)
			{
				_hIn.readExact(&curEntry, Entry.sizeof);
				try
				{
					debug writeln(curEntry);
					hOut.open(cast(string) curEntry.filename[0..stringLength(curEntry.filename.ptr)], FileMode.Out);
					if(buffer.length < curEntry.size)
						buffer.length = curEntry.size;
					_hIn.readExact(buffer.ptr, curEntry.size);
					hOut.writeExact(buffer.ptr, curEntry.size);
				}
				catch(Exception e)
				{
					writeln(e);
				}
				finally
				{
					hOut.close();
				}
				// TODO: set date attribute if possible
			}
		}
		catch (Exception e)
		{
			writeln(e);
		}
		finally
		{
			_hIn.close();
		}
	}
	
	/// sort the file list by filename
	void sort()
	{
	}
	/// get the filename of entry number idx
	string entryName(uint idx)
	in
	{
		assert(idx >= 0 && idx < _entryHeaders.length);
	}
	body
	{
		return fromStringz(cast(ichar*) _entryHeaders[idx].filename);
	}
	
	/// dump archive directory information
	void dump(string filename)
	{
		auto hIn = new std.stream.File(filename, FileMode.Out);
		scope(exit) hIn.close();
		
		for(uint i=0; i<_entryHeaders.length; i++)
		{
			hIn.write(cast(ubyte[]) _entryHeaders[i].toString() ~ '\n');
		}
	}

	@property
	{
		/// number of files in the archive
		uint numFiles()
		{
			return _entryHeaders.length;
		}
	}
}