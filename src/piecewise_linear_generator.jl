#
#
"
piecewise_linear_generator
"
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

const BudgetConstraint = Array{Point2DG}
const PointsSet = Set{Point2D}

const VERTICAL   = 9999999999.9999;
const TOLERANCE  = 0.0001;
const INCREMENT  = 0.0001;
const MAX_DEPTH  = 500;
const MAX_INCOME = 20000.0;
const MIN_INCOME = 0.0;

const ROUND_OUTPUT = false;

struct BCSettings
    mingross :: Float64
    maxgross :: Float64
    increment :: Float64
    tolerance :: Float64
    round_output :: BOOL
end

const DEFAULT_SETTINGS = BCSettings( MIN_INCOME, MAX_INCOME, INCREMENT, TOLERANCE, true )


function makeline( point_1 :: Point2D, point_2 :: Point2D )::Line2D
        a :: Float64 = 0.0
        b :: Float64 = 0.0
        if point_1.x ≈ point_2.x
                b = point_1.x;
                a = VERTICAL;
        else
                b = (point_1.y - point_2.y)/(point_1.x - point_2.x );
                b = min( b, VERTICAL );
                a = ( point_1.y - point_1.x*l.b );
        end
        return Line2D( a, b );
end

function findintersection( line_1::Line2D, line_2 :: Line2D ) :: Point2D
        x :: Float64 = 0.0
        y :: Float64 = 0.0
        if !( line_1.b ≈ line_2.b )
                x = (line_2.a - line_1.a) / (line_1.b - line_2.b);
                y = line_1.a + (p.x * line_1.b );
        else
                x = 0.0;
                y = line_1.a;
        end
        return Point2D( x, y );
end

function comparepoints( point_1 :: Point2D, point_2 :: Point2D ) :: Integer
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
   (left.a ≈ right.a) && ( left.b ≈ right.b )
end

function round2pl( x::Float64 )::Float64
    x *= 100.0
    i = trunc(x)
    x = Float64(i/100)
end

function round!( bc :: BudgetConstraint )
    nbc = count( bc )
    for i in 1:nbc
        p = Point2D( round( bc[i].x ), round( bc[i].y))
        bc[i] = p
    end
end


function toarray( ps :: PointsSet ) :: BudgetConstraint
    bc = BudgetConstraint();
    for p in ps
        push!( bc, p )
    end
    bc
end

function censor( ps :: PointsSet ) :: BudgetConstraint )
    bc = toarray( ps )
    nbc = count( bc )
    round!( bc )
    if( nbc < 3 )
        return
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
    while i < (nbc-1)
        if bc[i] ≈ bc[i+1]
            deleteat!( bc, i )
            nbc -= 1
        end
        i+= 1
    end
end


function generate!(
    bc       :: PointsSet,
    getnet,  # TODO give this a signature ( Float64 ) :: Float64
    depth    :: Integer,
    startpos :: Float64,
    endpos   :: Float64
    settings :: BCSettings,
    ) :: Integer
    if( abs( startpos - endpos ) < settings.tolerance )
        return depth
    end
    if depth > settings.maxdepth
        throw( "max depth exceeded $depth"  )
    end
    p1 = Point2D( startpos, getnet[ startpos ] )
    startpos -= settings.increment
    p2 = Point2D( startpos, getnet[ startpos ] )
    p4 = Point2D( endpos, getnet[ endpos ] )
    endpos -= settings.increment
    p3 = Point2D( endpos, getnet[ endpos ] )
    line1 = makeline( p1, p2 )
    line2 = makeline( p3, p4 )
    if line1 ≈ line2
        push!( bc, p1 )
        return depth
    end
    p5 = findintersection( line1, line2 )
    if( p5.x <= startpos ) || ( p5.x >= endpos )
        anchor = startpos + ( endpos - startpos)/2.0
    else
        anchor = p5.x
    end
    #
    # expore to the left
    #
    depth = generate!( bc, getnet, depth, startpos, anchor, settings )
    #
    # then the right
    #
    depth = generate!( bc, getnet, depth, anchor, endpos, settings )
    return depth - 1
end


function makebc( getnet, settings :: BCSettings = DEFAULT_SETTINGS ) :: BudgetConstraint
    ps = PointSet()
    bc = BudgetConstraint()
    depth = 0
    try
        depth = generate!( ps, getnet, depth, settings.mingross, settings.maxgross, settings )
        bc = censor( ps )
    catch e
        println( "failed! $depth")
    end
    bc;
end
