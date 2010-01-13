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
abstract class Map
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
		
		for(uint x=0; x<width; x++)
			for(uint y=0; y<height; y++)
			{
				auto v = convertMapToGlobal(Vector2i(x, y));
				_tiles[y*width+x].sprite.setPosition(v.x, v.y);
			}
	}
	
	/// render the map
	void render();
	
	/// diamond map
	Vector2i convertMapToGlobal(Vector2i coords);

	/// 
	Vector2i convertGlobalToMap(Vector2i coords);
}

/// 
class StaggeredMap : Map
{
	///
	this(ushort width, ushort height, RenderWindow window, Image[] images)
	{
		super(width, height, window, images);
	}
	
	/// render the map
	override void render()
	{
		for(uint y=0; y<_mapheight; y++)
		{
			for(uint x=0; x<_mapwidth; x++)
			{
				_tiles[y*_mapwidth+x].sprite.render(_rendertarget);
			}
		}
	}
	
	/// staggered map
	override Vector2i convertMapToGlobal(Vector2i coords)
	{
		return Vector2i(coords.x * _tilewidth + (coords.y%2 == 1 ? _tilewidth/2: 0), // each 2nd row is shifted half the tile width
						coords.y * (_tileheight / 2-1)); // new row starts after 1/2 the tile height
	}
	
	/// 
	override Vector2i convertGlobalToMap(Vector2i coords)
	{
		int y = (coords.y / (_tileheight / 2));
		int x = (coords.x - ((y%2 == 1) ? _tilewidth/2 : 0)) / _tilewidth;
		return Vector2i(x,y);
	}
}

/// 
class DiamondMap : Map
{
	///
	this(ushort width, ushort height, RenderWindow window, Image[] images)
	{
		super(width, height, window, images);
	}

	/// render the map
	void render()
	{
		for(uint i; i<_mapwidth; i++)
		{
			for(int j=_mapheight-1; j>=0; j--)
			{
				_tiles[i*_mapwidth+j].sprite.render(_rendertarget);
			}
		}
	}
	
	/// diamond map
	override Vector2i convertMapToGlobal(Vector2i coords)
	{
//		return Vector2i((coords.x + coords.y) * _tilewidth / 4, (coords.x - coords.y) * _tileheight / 4);
		return Vector2i((coords.x + coords.y) * _tilewidth / 2, (coords.x - coords.y) * _tileheight / 2);
	}

	/// 
	override Vector2i convertGlobalToMap(Vector2i coords)
	{
		return Vector2i((coords.y * _tilewidth + coords.x * _tileheight)/(_tilewidth*_tileheight), (coords.y * _tilewidth + - coords.x * _tileheight)/(_tilewidth*_tileheight));
	}
}