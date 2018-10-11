using Printf

const WEIGHT          = 1
const INCOME          = 2
const WEIGHTED_INCOME = 3
const POPN_ACCUM      = 4
const INCOME_ACCUM    = 5
const DEFAULT_FGT_ALPHAS = [ 0.0, 0.50, 1.0, 1.50, 2.0, 2.5 ];
const DEFAULT_ATKINSON_ES = [ 0.25, 0.50, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0, 2.25 ];
const DEFAULT_ENTROPIES = [ 1.25, 1.50, 1.75, 2.0, 2.25, 2.5 ];

"
internal function that makes a sorted array
with cumulative income and population added
"
function makeaugmented(
    data      :: Array{Float64},
    weightpos :: Integer = 1,
    incomepos :: Integer = 2,
    sortdata  :: Bool = true ) :: Array{Float64}

    nrows = size( data )[1]
    # print( nrows )
    aug = zeros( nrows, 5 )
    for row in 1:nrows
            aug[row,WEIGHT] = data[row,weightpos]
            aug[row,INCOME] = data[row,incomepos]
            aug[row,WEIGHTED_INCOME] = data[row,incomepos]*data[row,weightpos]
    end
    if sortdata
        aug = sortslices( aug, alg=QuickSort, dims=1,lt=((x,y)->isless(x[INCOME],y[INCOME])))
    end
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
    nrows = size( data )[1]
    ncols = size( data )[2]
    outa = zeros( Float64, nrows, ncols ) # Array{Float64}( undef, 0, 5 )
    @assert ncols == 5 "data should have 5 cols"
    nout = 0
    for row in 1:nrows
        if data[row,INCOME] < line
            nout += 1
            outa[ nout, : ] .= data[row,:]
        end
    end
    return outa[1:nout,:]
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
* `growth` is (e.g.) 0.01 for 1% per period, and is used for 'time to exit' measure.
"
function makepoverty(
    rawdata :: Array{Float64},
    line :: Float64,
    growth :: Float64 = 0.0,
    foster_greer_thorndyke_alphas :: Array{Float64} = DEFAULT_FGT_ALPHAS,
    weightpos :: Integer = 1,
    incomepos :: Integer = 2 ) :: Dict{ Symbol, Any }
    start_t = time_ns()
    data = makeaugmented( rawdata, weightpos, incomepos )

    pv = Dict{ Symbol, Any}()
    nrows = size( data )[1]
    ncols = size( data )[2]
    population = data[ nrows,POPN_ACCUM ]
    total_income = data[ nrows,INCOME_ACCUM ]

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
    initialised_t = time_ns()

    pv[:gini_amongst_poor] = makegini( belowline )
    main_start_t = time_ns()

    for row in 1:nbrrows
        inc :: Float64= belowline[row,INCOME]
        weight :: Float64 = belowline[row,WEIGHT]
        gap :: Float64 = line - inc
        @assert gap >= 0 "poverty gap must be postive"
        pv[:headcount] += weight
        pv[:gap] += weight*gap/line
        if belowline[row,INCOME ] > 0
            pv[:watts] += weight*log(line/inc)
        end
        for p in 1:nfgs
            fg = foster_greer_thorndyke_alphas[p]
            pv[:foster_greer_thorndyke][p] += weight*((gap/line)^fg)
        end
    end # main loop

    main_end_t = time_ns()
    pv[:watts] /= population
    if growth > 0.0
        pv[:time_to_exit] = pv[:watts]/growth
    end
    pv[:gap] /= population
    pv[:headcount] /= population
    pv[:foster_greer_thorndyke] ./= population
    #
    # Gini of poverty gaps; see: WB pp 74-5
    #
    shorr_start_t = time_ns()
    # create a 'Gini of the Gaps'
    # the sort routine in makeaugmented does a really
    # bad job here either because the data
    # is mostly zeros or because it's reverse sorted
    # (smallest income -> biggest gap)
    # we we can just create the dataset in reverse
    # and use that
    gdata = zeros( Float64, nrows, 5 )
    for row in 1:nrows
        gap = max( 0.0, line - data[row,INCOME] )
        gpos = nrows - row + 1
        gdata[gpos,INCOME] = gap;
        gdata[gpos,WEIGHT] = data[row,WEIGHT]
    end
    gdata = makeaugmented( gdata, 1, 2, false )
    shorr_made_data = time_ns()
    pv[:poverty_gap_gini] = makegini( gdata )

    pv[:sen] = pv[:headcount]*pv[:gini_amongst_poor]+pv[:gap]*(1.0-pv[:gini_amongst_poor])
    pv[:shorrocks] = pv[:headcount]*pv[:gap]*(1.0+pv[:poverty_gap_gini])
    shorr_end_t = time_ns()

    elapsed = Float64(initialised_t - start_t)/1_000_000_000.0
    @printf "initialisation time      %0.5f s\n" elapsed

    elapsed = Float64(main_end_t - main_start_t)/1_000_000_000.0
    @printf "main loop time          %0.5f s\n" elapsed

    elapsed = Float64(shorr_start_t - main_end_t)/1_000_000_000.0
    @printf "finalised main calcs   %0.5f s\n" elapsed

    elapsed = Float64(shorr_made_data - shorr_start_t)/1_000_000_000.0
    @printf "shor/sen data creation    %0.5f s\n" elapsed

    elapsed = Float64(shorr_end_t - shorr_made_data)/1_000_000_000.0
    @printf "shor/sen calcs        %0.5f s\n" elapsed

    elapsed = Float64(shorr_end_t - start_t)/1_000_000_000.0
    @printf "total elapsed        %0.5f s\n" elapsed

    return pv
end # makepoverty

"

"
function makeinequality(
    rawdata :: Array{Float64},
    atkinson_es  :: Array{Float64} = DEFAULT_ATKINSON_ES,
    generalised_entropy_alphas :: Array{Float64} = DEFAULT_ENTROPIES,
    weightpos :: Integer = 1,
    incomepos :: Integer = 2 ) :: Dict{ Symbol, Any }
    data = makeaugmented( rawdata, weightpos, incomepos )
    nrows = size( data )[1]
    nats = size( atkinson_es )[1]
    neps = size( generalised_entropy_alphas )[1]
    iq = Dict{ Symbol, Any }()
    # initialise atkinsons; 1 for e = 1 0 otherwise
    iq[:atkinson_es] = atkinson_es
    iq[:atkinson] = zeros( Float64, nats )
    iq[:atkinson] = [i == 1.0 ? 1.0 : 0.0 for i in atkinson_es]
    iq[:generalised_entropy_alphas] = generalised_entropy_alphas
    iq[:generalised_entropy] = zeros( Float64, neps )
    iq[:negative_or_zero_income_flag] = 0
    iq[:hoover] = 0.0
    iq[:theil] = zeros(Float64,2)
    iq[:gini] = makegini( data )

    total_income = data[nrows,INCOME_ACCUM]
    total_population = data[nrows,POPN_ACCUM]
    y_bar = total_income/total_population
    for row in 1:nrows
        income = data[row,INCOME]
        weight = data[row,WEIGHT]
        if income > 0.0
            y_yb  :: Float64 = income/y_bar
            yb_y  :: Float64 = ybar/income
            ln_y_yb :: Float64 = log( y_yb )
            ln_yb_y :: Float64 = log( yb_y )
            iq[:hoover] += weight*abs( income - y_bar )
            iq[:theil][1] += weight*ln_yb_y
            iq[:theil][2] += weight*y_tb*ln_y_tb
            for i in 1:nats
                    e :: Float64 = iq[:atkinson_es][i]
                    if e != 1.0
                        iq[:atkinson][i] += (weight*y_yb)^(1.0-e)
                    else
                        iq[:atkinson][i] *= (income)^(weight/total_population)
                    end # e = 1 case
            end # atkinsons
            for i in 1:neps
                alpha :: Float64 = iq[:generalised_entropy_alphas][i]
                iq[:generalised_entropy][i] += weight*(y_yb^alpha)
            end # entropies

        else
            iq[:negative_or_zero_income_flag] += 1
        end # positive income
    end # main loop
    iq[:hoover] /= 2.0*total_income
    for i in 1:neps
        alpha :: Float64 = iq[:generalised_entropy_alphas][i]
        aq :: Float64 = (1.0/(alpha*(alpha-1.0)))
        iq[:generalised_entropy][i] =
            aq*((iq[:generalised_entropy][i]/total_population)-1.0)
    end # entropies
    for i in 1:nats
        e :: Float64 = iq[:atkinson_es][i]
        if e != 1.0
            iq[:atkinson][i] = 1.0 - ( iq[:atkinson]/total_population )^(1.0/(1.0-e))
        else
            iq[:atkinson][i] = 1.0 - ( iq[:atkinson]/y_bar )
        end # e = 1
    end
    iq[:theil] ./= total_population
    return iq

end # makeinequality

function binify(
    data :: Array{Float64},
    num_bins :: Int64 ) :: Array{Float64}

end
