module openbb.theapp;
//import TileSystem;


///
enum SEASON
{
	SPRING=0,
	SUMMER,
	AUTUMN,
	WINTER,
	PALETTE
}

///
class TheApp
{
private:
	SEASON _curSeason;
//	TileManager _tileManager;

public:
	///
	this()
	{
		_curSeason = SEASON.SUMMER;
	}
	SEASON	curSeason()				{return _curSeason;}/// getter
	void	curSeason(SEASON rhs)	{_curSeason=rhs;}	/// setter

	/// the main game loop
	int gameLoop()
	{
		return 0;
	}
}
