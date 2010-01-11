/**
 *	
 */
module openbb.tile;

import dsfml.graphics.sprite;


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
	Sprite	sprite;
	ushort	resID; /// resource ID
	ushort	flags;
}