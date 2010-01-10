/**
 *	
 */
module openbb.layer;

class Layer
{
private:
	QuadTree!(Entity)	_quadtree;
	Entity[]			_entities;
}