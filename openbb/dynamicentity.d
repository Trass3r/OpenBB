/**
 *	
 */
module openbb.dynamicentity;

import dsfml.graphics.irendertarget;
import dsfml.system.vector;
import openbb.graphics.animation;
import openbb.map;
import openbb.entity;


/// defines the indices where certain animations start
struct WalkAnimations
{
align(1):
	ushort North;
	ushort NorthEast;
	ushort East;
	ushort SouthEast;
	ushort South;
	ushort SouthWest;
	ushort West;
	ushort NorthWest;
}

/// dynamic entity's state - esp. used to choose the correct animation
enum State
{
	Idle = 0,
	Walking,
	InBuilding,
	Fighting,
}

/// an entity that can walk around
class DynamicEntity : Entity
{
protected:
	Vector2f	_velocity;
	Vector2f	_headDirection; /// direction the entity is currently facing
	Vector2f	_target;	/// this entity's walking target
	Animation	_walkAnim;
	State		_state;		/// entity's current state

public:
	
	this(Vector2f pos, Animation walkAnim)
	{
		super(pos);
		
		walkAnim.position = pos;
		walkAnim.loopSpeed = 10;
		walkAnim.play(); // TODO: this needs to be done in walking handling code

		_walkAnim = walkAnim;
	}
	
	/// absolute target coordinates
	/// TODO: make relative?
	DynamicEntity walk(Vector2f target)
	{
		_target = target;
		_state	= State.Walking;
		// TODO: path planning
		return this;
	}

	//
	override DynamicEntity update(float dt)
	{
		//_pos = 
/*			uint frameCount		= _loopEnd - _loopStart;
		float timePosition	= _clock.getElapsedTime() * _fps;
		_curFrame = _loopStart + (cast(uint)timePosition) % frameCount; // correct that way 
*/
		return this;
	}

	override DynamicEntity render(IRenderTarget rendertarget)
	{
		_walkAnim.update();
		rendertarget.draw(_walkAnim);

		return this;
	}

	@property
	{
		Vector2f	velocity()				{return _velocity;}
		void		velocity(Vector2f vel)	{_velocity = vel;}
		
		Animation	walkAnimation()				{return _walkAnim;}
		void		walkAnimation(Animation a)	{_walkAnim = a;}
	}
}