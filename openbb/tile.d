/**
 *	
 */
module openbb.tile;


enum TileFlags
{
	Blocked		= 1 << 0, // completely blocked
	Buildable	= 1 << 1, // no buildings possible, humans can walk
	Fertile		= 1 << 2, // crop etc.
}

///
struct Tile
{
align(1):
	ushort	resID; /// resource ID
	ushort	flags;
}