/**
 *	
 */
module openbb.exceptions;


/// Exception thrown when there is a problem with B&B loading files
class IOException : Exception
{
	this(string msg)
	{
		super(msg);
	}
}