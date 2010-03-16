/**
 *	
 */
module openbb.entity;

import openbb.graphics.animation;
import dsfml.graphics.irendertarget;
import dsfml.system.vector2;

abstract class Entity
{
protected:
	uint		_id;
	Vector2f	_pos;
	Vector2i	_size;
	uint		_layer; // that contains it
	Animation	_idleAnimation;
public:
	
	this()
	{
		_id = 0;
		_pos = Vector2f(0.f, 0.f);
		_size = Vector2i(0, 0);
		_layer = 0;
	}
	
	this(Vector2f pos)
	{
		_pos = pos;
//		_size = size;
	}
	
	Entity move(Vector2f delta)
	{
		_pos = _pos + delta;

		return this;
	}
	
	/**
	 *	update the entity's state
	 *
	 *	Params:
	 *		dt = time that has passed since last update, in milliseconds
	 */
	Entity update(float dt)
	{
		return this;
	}

	/// separate function since every entity needs to be updated but not necessarily rendered
	Entity render(IRenderTarget rendertarget)
	{
		return this;
	}

	@property
	{
		Vector2f	position()	{return _pos;}
		uint		layer()		{return layer;}
		uint		id()		{return _id;}
		
		void position(Vector2f pos)	{_pos = pos;}
		void layer(uint l)			{_layer = l;}
		void id(uint id)			{_id = id;}
	}
}