/**
 *	
 */
module openbb.staticentity;

import dsfml.system.vector;
import openbb.entity;


///
class StaticEntity : Entity
{
private:
public:
	/// constructor
	this(Vector2f pos, Vector2i size)
	{
		super(pos, size);
	}
}