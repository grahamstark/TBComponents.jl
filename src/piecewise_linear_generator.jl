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

const BudgetConstraint = Array{Line2DG}

const VERTICAL   = 9999999999.9999;
const TOLERANCE  = 0.0001;
const INCREMENT  = 0.0001;
const MAX_DEPTH  = 500;
const MAX_INCOME = 20000.0;
const MIN_INCOME = 0.0;

const ROUND_OUTPUT = false;

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

function censor!( bc :: BudgetConstraint )
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
