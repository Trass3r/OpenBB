/**
 *	
 */
module openbb.io.boxfile;

import openbb.common;

import core.stdc.string;

import std.file;
import std.string;
import std.stdio;
import std.datetime.systime;
import std.datetime.date;

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
    string toString() const
    {
    	return std.string.format("%2d.%2d.%4d %02d:%02d:%02d", day, month, year, hour, minute, second);
    }
}

/// Header structure
private struct BoxHeader
{
align(1):
	char[3] magic; // "BOX"
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

	string toString() const
	{
		return std.string.format("filename: %s\tpath: %s\ttimestamp: %s\tfilesize: %d", fromStringz(cast(ichar*)filename), fromStringz(cast(ichar*)path), timestamp, size);
	}
}

/// Archive file format used by B&B
final class BOXFile
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
		try
		{
			auto _hIn = new File(_filename, "rb");
			scope(exit) _hIn.close();

			_hIn.rawRead((&_header)[0..1]);

			if (_header.magic != "BOX"c)
				throw new Exception("No valid BOX file!");
			if (_header.uk2 != 65536)
				writeln("Warning: BOX might have an unexpected format!");
			debug writefln("BOX byte: %d", _header.uk1);

			Entry curEntry;

			// do until end of file is reached
			// file.eof() is useless as it only returns true after the next read after EOF
			uint i; // for counting entry index
			while (true)
			{
				writeln(_hIn.tell);
				auto actuallyRead = _hIn.rawRead((&curEntry)[0..1]);
				if (actuallyRead.empty)
					break;
				_entryHeaders ~= curEntry;

				_filenameTable[fromStringz(cast(ichar*) curEntry.filename)] = i; // filename -> index hash table

				//debug writeln(curEntry);

				ubyte[] buffer = new ubyte[curEntry.size];
				_hIn.rawRead(buffer);
				_entryData ~= buffer; // this actually isn't that inefficient cause only references are copied

				++i;
			}
		}
		catch (Exception e)
		{
			writeln(e);
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
	const(ubyte)[] opIndex(size_t index)
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
		if (exists(_filename[0..$-4])==0)
			mkdir(_filename[0..$-4]);
		chdir(_filename[0..$-4]);
		writeln("extracting...");
		foreach (size_t idx, ref Entry curEntry; _entryHeaders)
		{
			writeln(curEntry);
			try
			{
				auto hOut = new File(cast(string) curEntry.filename[0..strlen(curEntry.filename.ptr)], "wb");
				{
				scope(exit) hOut.close();
				hOut.rawWrite(this[idx]);
				}
				SysTime modificationTime = SysTime(DateTime(curEntry.timestamp.year, curEntry.timestamp.month, curEntry.timestamp.day,
					curEntry.timestamp.hour, curEntry.timestamp.minute, curEntry.timestamp.second));
				setTimes(hOut.name, modificationTime, modificationTime);
			}
			catch(Exception e)
			{
				writeln(e);
			}
		}
	}
	
	/// sort the file list by filename
	void sort()
	{
		assert(0, "not implemented yet");
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

	auto entryDate(uint idx) const
	{
		return _entryHeaders[idx].timestamp;
	}

	/// dump archive directory information
	void dump(string filename)
	{
		auto hIn = new File(filename, "wb");
		scope(exit) hIn.close();
		
		for(uint i=0; i<_entryHeaders.length; i++)
		{
			hIn.write(cast(ubyte[]) _entryHeaders[i].toString() ~ '\n');
		}
	}

	@property
	{
		/// number of files in the archive
		size_t numFiles()
		{
			return _entryHeaders.length;
		}
	}
}