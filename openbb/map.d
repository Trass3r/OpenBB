/**
 *	
 */
module openbb.map;

import openbb.layer;
import openbb.tile;

import dsfml.system.vector2;

alias Vector2!(ushort) Vector2s;

///
class Map
{
private:
	Tile[][]		_tiles;
	Entity[uint]	_entities;
	Layer[]			_layers;
	//entrypoint
	
	ushort			_tilewidth;
	ushort			_tileheight;
public:
	
	/// diamond map
	Vector2i convertDiamondToGlobal(Vector2us coords)
	{
		return Vector2i(x * _tilewidth + (y%2 == 1) ? _tilewidth/2 : 0, // each 2nd row is shifted half the tile width
						coords.y * _tileheight / 2); // new row starts after 1/2 the tile height
	}
	
	/// staggered map
	Vector2i convertStaggeredToGlobal(Vector2us coords)
	{
		return Vector2i(x * _tilewidth + (y%2 == 1) ? _tilewidth/2 : 0, // each 2nd row is shifted half the tile width
						coords.y * _tileheight / 2); // new row starts after 1/2 the tile height
	}
	
	Vector2us convertGlobalToDiamond(Vector2i coords)
	{
		
	}
	
	Vector2us convertGlobalToStaggered(Vector2i coords)
	{
		y = coords.y / (_tileheight / 2);
		x = coords.x - ((y%2 == 1) ? _tilewidth/2 : 0) / _tilewidth;
	}
}