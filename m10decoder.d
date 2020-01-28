/**
 *	this creates a command-line tool to convert m10 to wave files
 */
module m10decoder;

import openbb.io.boxfile;
import openbb.io.m10file;

import std.stdio;
import std.file;
import std.datetime.systime;
import std.datetime.date;

int main(string[] args)
{
	if (args.length != 2)
	{
		writeln("Beasts and Bumpkins .m10 Decoder");
		writeln("Usage: " ~ args[0] ~ " {SPEECHx.BOX}");
		return 1;
	}

	string inputFilename = args[1];

	auto speechbox = new BOXFile(inputFilename);
	if (!exists(inputFilename[0 .. $-4]))
		mkdir(inputFilename[0 .. $-4]);
	chdir(inputFilename[0 .. $-4]);

	for (uint i=0; i<speechbox.numFiles; i++)
	{
		string outFilename = speechbox.entryName(i)[0 .. $-4] ~ ".wav";
		writeln(outFilename);
		auto m10 = new M10File(speechbox[i]);
		std.file.write(outFilename, m10.toWav());
		auto date = speechbox.entryDate(i);
		SysTime modificationTime = SysTime(DateTime(date.year, date.month, date.day,
			date.hour, date.minute, date.second));
		setTimes(outFilename, modificationTime, modificationTime);
	}
	return 0;
}