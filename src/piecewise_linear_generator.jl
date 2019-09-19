#
#
"""
A piecewise_linear_generator. Used for generating budget constraints used in
conventional microeconomics. See Stark and Duncan 1992 in the biblio.
"""

struct Point2DG{T<:Real}
      x::T
      y::T
end

const Point2D = Point2DG{Float64}

struct Line2DG{T<:Real}
      a::T
      b::T
end

const Line2D = Line2DG{Float64}

const BudgetConstraint = Array{Point2DG,1}
const PointsSet = Set{Point2DG}

const VERTICAL   = 9_999_999_999.9999;
const TOLERANCE  = 0.0001;
const INCREMENT  = 0.0001;
const MAX_DEPTH  = 50;
const MAX_INCOME = 20000.0;
const MIN_INCOME = 0.0;

const ROUND_OUTPUT = false;

struct BCSettings
    mingross :: Float64
    maxgross :: Float64
    increment :: Float64
    tolerance :: Float64
    round_output :: Bool
    maxdepth :: Integer
end

const DEFAULT_SETTINGS = BCSettings( MIN_INCOME, MAX_INCOME, INCREMENT, TOLERANCE, true, MAX_DEPTH )


function makeline( point_1 :: Point2D, point_2 :: Point2D )::Line2D
    a :: Float64 = 0.0
    b :: Float64 = 0.0
    if point_1.x == point_2.x # ?? never taken??
        b = point_1.x;
        a = VERTICAL;
    else
        b = (point_1.y - point_2.y)/(point_1.x - point_2.x );
        b = min( b, VERTICAL );
        a = ( point_1.y - point_1.x*b );
    end
    return Line2D( a, b );
end

function findintersection( line_1::Line2D, line_2 :: Line2D ) :: Point2D
    x :: Float64 = 0.0
    y :: Float64 = 0.0
    if !( line_1.b ≈ line_2.b )
        x = (line_2.a - line_1.a) / (line_1.b - line_2.b);
        y = line_1.a + (x * line_1.b );
    else
        x = 0.0;
        y = line_1.a;
    end
    return Point2D( x, y );
end

function comparepoints( point_1 :: Point2DG, point_2 :: Point2DG ) :: Integer
    if( point_1.x > point_2.x )
        return 1;
    end
    if( point_1.x < point_2.x )
        return -1;
    end
    if( point_1.y > point_2.y )
        return 1;
    end
    if( point_1.y < point_2.y )
        return -1;
    end
    return 0;
end

# sorting for points
import Base.isless

function isless( point_1 :: Point2DG, point_2 :: Point2DG ) :: Bool
    return comparepoints( point_1, point_2 ) < 0
end

function marginalrate( point_1 :: Point2D, point_2 :: Point2D )::Float64
    mr :: Float64 = 0.0
    if !( point_2.x ≈ point_1.x )
        mr = 100.0 * (1-(point_2.y-point_1.y) / (point_2.x - point_1.x));
    else
        mr = VERTICAL;
        if( point_2.y < point_1.y )
            mr *= -1;
        end
    end
    return mr;
end

# approximate equality for points and lines
import Base.≈

function ≈(left :: Point2D, right::Point2D )::Bool
   (left.x ≈ right.x) && ( left.y ≈ right.y )
end

function ≈(left :: Line2D, right::Line2D )::Bool
   # return (left.a ≈ right.a) && ( left.b ≈ right.b )
   #  FIXME this uses the global tolerance even
   # if the user overrides it in settings
   return ((( abs(left.a-right.a)) <= TOLERANCE ) && (( abs(left.b-right.b)) <= TOLERANCE ));
end

# round a float to 2dps
function round2pl( x::Float64 )::Float64
    x *= 100.0
    i = trunc(x)
    x = Float64(i/100)
end

function round2pl!( bc :: BudgetConstraint )
    nbc = size( bc )[1]
    for i in 1:nbc
        p = Point2D( round2pl( bc[i].x ), round2pl( bc[i].y))
        bc[i] = p
    end
end


function toarray( ps :: PointsSet ) :: BudgetConstraint
    bc = BudgetConstraint();
    for p in ps
        push!( bc, p )
    end
    sort!( bc ) # , lt=isless
    bc
end

function censor( ps :: PointsSet, round :: Bool=true ) :: BudgetConstraint
    # println( "censor; ps=$ps")
    bc = toarray( ps )
    sort!( bc )
    nbc = size( bc )[1]
    first = bc[1]
    last = bc[nbc]
    if( nbc < 3 )
        return bc
    end
    i = 2
    while i < (nbc - 1)
        p1 = bc[i-1]
        p2 = bc[i]
        p3 = bc[i+1]
        l1 = makeline( p1, p2 )
        l2 = makeline( p2, p3 )
        if l1 ≈ l2
            deleteat!( bc, i )
            nbc -= 1
        else
            i += 1
        end
    end # while
    i = 1
    if round
        round2pl!( bc )
    end
    # 1 liner which sorts and removes dups
    bc = BudgetConstraint( toarray( PointsSet( bc )))
    if bc[1] != first
        # bc = vcat(first,bc)
    end
    if bc[nbc] != last
        # bc = vcat(bc,last)
    end
    return bc
end


function generate!(
    bc       :: PointsSet,
    data     :: Dict,
    getnet,  # TODO give this a signature ( Float64 ) :: Float64
    depth    :: Integer,
    startpos :: Float64,
    endpos   :: Float64,
    settings :: BCSettings ) :: Integer
    diff = abs( startpos - endpos )
    tolerance = settings.tolerance
    if( diff < settings.tolerance )
        return depth
    end
    if depth > settings.maxdepth
        throw( "max depth exceeded $depth"  )
    end
    p1 = Point2D( startpos, getnet( data, startpos) )
    p2 = Point2D( startpos+settings.increment, getnet(data, startpos+settings.increment))
    p4 = Point2D( endpos, getnet(data, endpos) )
    p3 = Point2D( endpos-settings.increment, getnet(data, endpos-settings.increment) )

    line1 = makeline( p1, p2 )
    line2 = makeline( p3, p4 )

    if line1 ≈ line2
        push!( bc, p1 )
        push!( bc, p4 )

        return depth
    end
    p5 = findintersection( line1, line2 )
    if( p5.x <= startpos ) || ( p5.x >= endpos )
        anchor = startpos + (( endpos - startpos)/2.0)
    else
        anchor = p5.x
    end
    depth += 1
    #
    # expore to the left
    #
    depth = generate!( bc, data, getnet, depth, startpos, anchor, settings )
    #
    # then the right
    #
    depth = generate!( bc, data, getnet, depth, anchor, endpos, settings )
    return depth - 1
end

"""
Make a budget constraint using function `getnet` to extract net incomes and `settings` (see above on this struct).
getnet should be a function of the form `net=f(gross)`. See the testcase for an example.
"""
function makebc( data :: Dict, getnet, settings :: BCSettings = DEFAULT_SETTINGS ) :: BudgetConstraint
    bc = BudgetConstraint()
    ps = PointsSet()
    depth = 0
    try
        depth = generate!( ps, data, getnet, depth, settings.mingross, settings.maxgross, settings )
        bc = censor( ps, settings.round_output )
    catch e
        ## FIXME print a fuller stack trace here
        println( "failed! $e")
        println(stacktrace())
    end
    bc;
end

function pointstoarray( bc :: BudgetConstraint ) :: Array{Float64,2}
    sz = size( bc, 1 )
    pts = zeros( Float64, sz, 2 )
    for b in 1:sz
        pts[b,1] = bc[b].x
        pts[b,2] = bc[b].y
    end
    pts
end
