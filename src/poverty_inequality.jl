
const WEIGHT          = 1
const INCOME          = 2
const WEIGHTED_INCOME = 3
const POPN_ACCUM      = 4
const INCOME_ACCUM    = 5
const DEFAULT_FGT_ALPHAS = [ 0.0, 0.50, 1.0, 1.50, 2.0, 2.5 ];



"
internal function that makes a sorted array
with cumulative income and population added
"
function makeaugmented(
    data      :: Array{Float64},
    weightpos :: Integer = 1,
    incomepos :: Integer = 2 ) :: Array{Float64}

    nrows = size( data )[1]
    print( nrows )
    aug = zeros( nrows, 5 )
    for row in 1:nrows
            aug[row,WEIGHT] = data[row,weightpos]
            aug[row,INCOME] = data[row,incomepos]
            aug[row,WEIGHTED_INCOME] = data[row,incomepos]*data[row,weightpos]
    end
    aug = sortslices( aug, dims=1,lt=((x,y)->isless(x[INCOME],y[INCOME])))
    cumulative_weight :: Float64 = 0.0
    cumulative_income :: Float64 = 0.0
    for row in 1:nrows
            cumulative_weight += aug[row,WEIGHT]
            cumulative_income += aug[row,WEIGHTED_INCOME]
            aug[row,POPN_ACCUM] = cumulative_weight
            aug[row,INCOME_ACCUM] = cumulative_income
    end
    return aug
end

"
calculate a Gini coefficient on one of our sorted arrays
"
function makegini( data :: Array{Float64} ) :: Float64
    lorenz :: Float64 = 0.0

    nrows = size( data )[1]
    if nrows == 0
        return 0.0
    end
    lastr = data[nrows,:]
    for row in 1:nrows
        lorenz += data[WEIGHT]*(2.0*data[row,INCOME_ACCUM] - data[row,WEIGHTED_INCOME])
    end
    return 1.0-(lorenz/lastr[INCOME_ACCUM])/lastr[POPN_ACCUM]
end

"
generate a subset of one of our datasets with just the elements whose incomes
are below the line. Probably possible in 1 line, once I get the hang of this
a bit more.
"
function makeallbelowline( data :: Array{Float64}, line :: Float64 ) :: Array{Float64}
    outa = Array{Float64}( undef, 0, 5 )
    nrows = size( data )[1]
    ncols = size( data )[2]
    @assert ncols == 5 "data should have 5 cols"
    for row in 1:nrows
        if data[row,INCOME] < line
            outa = vcat( outa, data[row,:]' )
        end
    end
    return outa
end

"
Create a dictionary of poverty measures.

This is based on the [World Bank's Poverty Handbook](http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality)
by  Haughton and Khandker.

Arguments:
* `rawdata` - each row is an observation; one col should be a weight, another is income;
positions assumed to be 1 and 2 unless weight and incomepos are supplied
* `line` - a poverty line, assumed same for all obs
* `foster_greer_thorndyke_alphas` - coefficients for FGT poverty measures; note that FGT(0)
corresponds to headcount and FGT(1) to gap; count and gap are computed directly anyway
but it's worth checking one against the other.
* `growth` is (e.g.) 1.01 for 1% per period, and is used for 'time to exit' measure.
"
function makepoverty(
    rawdata :: Array{Float64},
    line :: Float64,
    growth :: Float64 = 0.0,
    foster_greer_thorndyke_alphas :: Array{Float64} = DEFAULT_FGT_ALPHAS,
    weightpos :: Integer = 1,
    incomepos :: Integer = 2 ) :: Dict{ Symbol, Any}

    data = makeaugmented( rawdata, weightpos, incomepos )

    pv = Dict{ Symbol, Any}()
    nrows = size( data )[1]
    ncols = size( data )[2]
    population = data[ nrows,POPN_ACCUM]
    total_income = data[ nrows,INCOME_ACCUM]

    nfgs = size( foster_greer_thorndyke_alphas )[1]
    @assert ncols == 5 "data should have 5 cols"
    pv[:fgt_alphas] = foster_greer_thorndyke_alphas
    pv[:headcount] = 0.0
    pv[:gap] = 0.0
    pv[:watts] = 0.0
    pv[:foster_greer_thorndyke] = zeros( Float64, nfgs )
    pv[:time_to_exit] = 0.0

    belowline = makeallbelowline( data, line )
    nbrrows = size( belowline )[1]

    pv[:gini_amongst_poor] = makegini( belowline )
    for row in 1:nbrrows
        inc = belowline[row,INCOME]
        weight = weight
        gap = line - inc
        @assert gap >= 0 "poverty gap must be postive"
        pv[:headcount] += weight
        pv[:gap] += weight*gap/line
        if belowline[row,INCOME ] > 0
            pv[:watts] += weight*log(line/inc)
        end
        for p in 1:nfgs
            fg = foster_greer_thorndyke_alphas[p]
            pv[:foster_greer_thorndyke[p]] += weight*((gap/line)^fg)
        end
    end
    pv[:watts] /= population
    if growth > 0.0
        pv[:time_to_exit] = pv[:watts]/growth
    end
    pv[:gap] /= population
    pv[:headcount] /= population
    for p in 1:npv
        pv[:foster_greer_thorndyke[p]] /= population
    end
    #
    # Gini of poverty gaps; see: WB pp 74-5
    #
    gdata = copy( data ) ## check is changing data directly non-destructive?
    for row in 1:nrows
        gap = max( 0.0, line - gdata[row,INCOME] )
        gdata[row,INCOME] = gap
    end
    gdata = makeaugmented( gdata )
    pv[:poverty_gap_gini] = makegini( gdata )
    pv[:sen] = pv[:headcount]*pv[:gini_amongst_poor]+pv[:gap]*(1.0-pv[:gini_amongst_poor])
    pv[:shorrocks] = pv[:headcount]*pv[:gap]*(1.0-pv[:poverty_gap_gini])
    return pv
end

function binifydata(
    data :: Array{Float64},
    num_bins :: Int64 ) :: Array{Float64}

end
