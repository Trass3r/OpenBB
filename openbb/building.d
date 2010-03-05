/**
 *	
 */
module openbb.building;

import dsfml.graphics.renderwindow;
import dsfml.system.vector2;
import openbb.graphics.animation;
import openbb.staticentity;

///
class Building : StaticEntity
{
private:
	Animation	_buildAnim;
	Vector2ub	_buildsize;
public:
	///
	this(Vector2f pos, Vector2i size, Animation buildAnim, Vector2ub buildsize)
	in
	{
		assert(buildAnim !is null);
	}
	body
	{
		super(pos, size);
		_buildsize = buildsize;
		_buildAnim = buildAnim;
		
		// set up construction site
	}
	
	/// the building is ready for topping out
	void prepareTopOut()
	{
		_buildAnim.curFrame = 0;
	}
	
	void buildFinished()
	{
		_buildAnim.curFrame = 1;
	}
	
	void render(RenderWindow target)
	{
		_buildAnim.render(target);
	}
}