/**
 *	
 */
module openbb.map;

import openbb.layer;
import openbb.tile;
import openbb.entity;

import dsfml.graphics.renderwindow;
import dsfml.graphics.image;
import dsfml.graphics.sprite;
import dsfml.system.vector2;

import std.random;

alias Vector2!(ushort) Vector2us;

///
class Map
{
private:
	Tile[]			_tiles;
	Entity[uint]	_entities;
	Layer[]			_layers;
	RenderWindow	_rendertarget;
	Image[]			_images;
	//entrypoint
	
	ushort			_tilewidth;
	ushort			_tileheight;
	ushort			_mapwidth;
	ushort			_mapheight;
public:
	
	this(ushort width, ushort height, RenderWindow window, Image[] images)
	{
		_mapwidth = width;
		_mapheight = height;
		_tilewidth = cast(ushort) images[0].getWidth();
		_tileheight = cast(ushort) (images[0].getHeight()-5);
		_rendertarget = window;
		_images = images;
		_tiles = new Tile[width*height];
		for(uint i=0; i<width*height; i++)
		{
			auto r = cast(ushort) uniform(0, images.length);
			_tiles[i] = Tile(new Sprite(images[r]), r, 0);
		}
		
		for(ushort x=0; x<width; x++)
			for(ushort y=0; y<height; y++)
			{
				auto v = convertDiamondToGlobal(Vector2us(x, y));
				_tiles[y*width+x].sprite.setPosition(v.x, v.y);
			}
	}
	
	/// render the map
	void render()
	{
		for(uint i; i<_mapwidth; i++)
		{
			for(uint j=0; j<_mapheight; j++)
			{
				_tiles[i*_mapwidth+j].sprite.render(_rendertarget);
			}
		}
	}
	
	/// diamond map
	Vector2i convertDiamondToGlobal(Vector2us coords)
	{
//		return Vector2i((coords.x + coords.y) * _tilewidth / 4, (coords.x - coords.y) * _tileheight / 4);
		return Vector2i((coords.x + coords.y) * _tilewidth / 2, (coords.x - coords.y) * _tileheight / 2 + 300);
	}
	
	/// staggered map
	Vector2i convertStaggeredToGlobal(Vector2us coords)
	{
		return Vector2i(coords.x * _tilewidth + (coords.y%2 == 1 ? _tilewidth/2 +1: 0), // each 2nd row is shifted half the tile width
						coords.y * (_tileheight / 2)); // new row starts after 1/2 the tile height
	}
	/*
	Vector2us convertGlobalToDiamond(Vector2i coords)
	{
		
	}
	*/
	Vector2us convertGlobalToStaggered(Vector2i coords)
	{
		ushort y = cast(ushort) (coords.y / (_tileheight / 2));
		ushort x = cast(ushort) (coords.x - ((y%2 == 1) ? _tilewidth/2 : 0) / _tilewidth);
		return Vector2us(x,y);
	}
}