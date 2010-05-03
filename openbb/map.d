/**
 *	
 */
module openbb.map;

import openbb.layer;
import openbb.tile;
import openbb.entity;

import dsfml.graphics.rect;
import dsfml.graphics.renderwindow;
import dsfml.graphics.image;
import dsfml.graphics.irendertarget;
import dsfml.graphics.sprite;
import dsfml.system.vector2;

import std.random;

// walking directions on the map
const North		= Vector2f(0.0f, -1.0f);
const NorthEast	= Vector2f(1.0f, -0.5f); // sin(30°)
const East		= Vector2f(1.0f, 0.0f);
const SouthEast	= Vector2f(1.0f, 0.5f);
const South		= Vector2f(0.0f, 1.0f);
const SouthWest	= Vector2f(-1.0f, 0.5f);
const West		= Vector2f(-1.0f, 0.0f);
const NorthWest	= Vector2f(-1.0f, -0.5f);


alias Vector2!(ushort) Vector2us;

///
abstract class Map
{
private:
	Tile[]			_tiles;
	Entity[uint]	_entities;
	Layer[]			_layers;
	IRenderTarget	_rendertarget;
	Image			_tilesheet;
	//entrypoint
	
	ushort			_tilewidth;
	ushort			_tileheight;
	ushort			_mapwidth;
	ushort			_mapheight;
public:
	
	/// create a map with width * height tiles from tilesheet, rendered to window
	this(ushort width, ushort height, IRenderTarget window, Image tilesheet, ushort tilewidth = 77, ushort tileheight = 40)
	{
		_mapwidth = width;
		_mapheight = height;
		_tilewidth = tilewidth;
		_tileheight = tileheight;
		_rendertarget = window;
		_tilesheet = tilesheet;
		_tiles = new Tile[width*height];
		
		// calculate how much tiles are in each row and column in tilesheet
		uint sheetWidth = tilesheet.width / tilewidth;
		uint sheetHeight = tilesheet.height / tileheight;
		
		for(uint i=0; i<width*height; i++)
		{
			auto r = cast(ushort) uniform(0, sheetWidth * sheetHeight);
			Sprite spr = new Sprite(_tilesheet);
			uint y = r / sheetWidth;
			uint x = r % sheetWidth;
			
			spr.subRect = IntRect(x * tilewidth, y * tileheight, tilewidth, tileheight);
			_tiles[i] = Tile(spr, r, 0);
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
	this(ushort width, ushort height, IRenderTarget target, Image tilesheet, ushort tilewidth = 77, ushort tileheight = 40)
	{
		super(width, height, target, tilesheet, tilewidth, tileheight);
	}
	
	/// render the map
	override void render()
	{
		// the following is 28 microseconds faster than the width-height double loop version :D
		for(uint i=0; i<_tiles.length; i++)
		{
			_tiles[i].sprite.render(_rendertarget);
		}
	}
	
	/// staggered map
	override Vector2i convertMapToGlobal(Vector2i coords)
	{
		return Vector2i(coords.x * _tilewidth + (coords.y%2 == 1 ? _tilewidth/2: 0), // each 2nd row is shifted half the tile width
						coords.y * (_tileheight/2 - 1)); // new row starts after 1/2 the tile height
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
	this(ushort width, ushort height, IRenderTarget target, Image tilesheet, ushort tilewidth = 77, ushort tileheight = 40)
	{
		super(width, height, target, tilesheet, tilewidth, tileheight);
	}

	/// render the map
	override void render()
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