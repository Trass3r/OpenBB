module mfbdecoder;

import openbb.io.boxfile;
import openbb.io.mfbfile;
import openbb.io.palette;

import std.stdio;
import std.file;
import std.datetime.systime;
import std.datetime.date;

import png;

int main(string[] args)
{
	writeln("Beasts and Bumpkins .mfb Decoder");

	string inputFilename = "VIDEO.BOX";

	auto boxfile = new BOXFile(inputFilename);
	if (!exists(inputFilename[0 .. $-4]))
		mkdir(inputFilename[0 .. $-4]);
	chdir(inputFilename[0 .. $-4]);

	for (uint i = 0; i < boxfile.numFiles; ++i)
	{
		const entryFilename = boxfile.entryName(i)[0 .. $-4];
		switch (entryFilename)
		{
		case "m1back":
		case "m2back":
		case "m3back":
		case "m4back":
		case "m5back":
		case "m7back":
		case "m9back":
		case "m11back":
		case "loading":
		case "credits":
		case "yakoff":
			usePalette(Palette.Loading);
			break;
		case "mission":
			usePalette(Palette.Mission);
			break;
		default:
			usePalette(Palette.Main);
		}
		string outFilename = entryFilename ~ ".png";
		writeln(outFilename);
		scope mfb = new MFBFile(boxfile[i]);
		//ubyte[] pngdata = toPNG(mfb.width, mfb.height, mfb[0, 0]);
		auto spritesheet = mfb[];
		ubyte[] pngdata = toPNG(mfb.spriteSheetWidth * mfb.width, mfb.spriteSheetHeight * mfb.height, spritesheet);
		std.file.write(outFilename, pngdata);
		auto date = boxfile.entryDate(i);
		SysTime modificationTime = SysTime(DateTime(date.year, date.month, date.day, date.hour, date.minute, date.second));
		setTimes(outFilename, modificationTime, modificationTime);
	}
	return 0;
}