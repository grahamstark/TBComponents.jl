#
# DON'T USE THIS (OR FIX IT FOR ME..)
# This is a broken version of reweighter that uses
# julia's standard NLsolve package. I'll return to it when
# I have a free day.
#
using NLsolve

Buffer = Dict{Symbol,Any}

"
   Implements the micro data weighting procedures from:
   * Creedy 2003 http://www.treasury.govt.nz/publications/research-policy/wp/2003/03-17/twp03-17.pdf
   * Creedy 2003  http://www.business.curtin.edu.au/files/creedy2.pdf
   * Jean-Claude Deville and Carl-Erik Sarndal http://www.jstor.org/stable/2290268
"
@enum DistanceFunctionType chi_square d_and_s_type_a d_and_s_type_b constrained_chi_square d_and_s_constrained

"
Make a weights vector which weights the matrix `data`
so when summed the col totals sum to `target_populations`
See the Creedy Paper for `function_type`
If using one of the constrained types,
the output weights should be no more than ru*the initial weight,
no less than rl
Returns a Dict with :=>weights and some extra info on convergence.
data : KxJ matrix where k is num observations and J is num constraints;
see:
Microdata Adjustment by the Minimum Information Loss Principle Joachim Merz; FFB Discussion Paper No. 10 July 1994
for a good discussion on how to lay out the dataset

intial_weights, new_weights : K length vector
target_populations - J length vector;

tolx, tolf, max_iterations : see Solve_Non_Linear_Equation_System in the parent
ru/rl max/min acceptable values of ratio of final_weight/initial_weight (for constrained distance functions)

note: chi-square is just there for checking purposes; use Do_Basic_Reweighting if that's all you need.


"
function doreweighting(
    ;
    data               :: AbstractArray{ <:Real, 2 },
    initial_weights    :: AbstractArray{ <:Real, 1 }, # a column
    target_populations :: AbstractArray{ <:Real, 1 }, # a row
    functiontype       :: DistanceFunctionType,
    upper_multiple     :: Real = 0.0,
    lower_multiple     :: Real = 0.0,
    tolx               :: Real = 0.000001,
    tolf               :: Real = 0.000001 ) :: Buffer

    nrows, ncols = size( data )
    # ncols = size( data )[2]
    @assert ncols == size( target_populations )[1]
    @assert nrows == size( initial_weights )[1]
    a = target_populations - (initial_weights'*data)'
    ru = upper_multiple # shorthand
    rl = lower_multiple

    #
    # instead of minimising the loss function (G) we just need to find the zeros
    # of the 1st derivatives. This computes the derivatives and the hessian
    # of the G function, hence the slightly confusing names (gradient=>1st deriv of G)
    # See table 3 and eqns 25 and 26 in Creedy 2003 http://ideas.repec.org/p/nzt/nztwps/03-17.html
    # This version is in the 'fj' form needed for the NLsolve package if we want to
    # generate the derivative and hessian in one go, as we do since it's a potentially huge loop
    #
    function compute_lamdas_and_hessian!( gradient :: Vector, hessian :: Matrix, lamdas :: Vector ) # :: Tuple{Array{Float64},Array{Float64}}
        # gradient .= 0.0; #zeros( Float64, ncols, 1 )
        hessian .= 0.0 #zeros( Float64, ncols, ncols )
        z = zeros( Float64, ncols, 1 )
        for row in 1:nrows
            rv = data[row,:]
            u = (rv' * lamdas)[1]
            d_g_m1 = 0.0
            g_m1 = 0.0
            if functiontype == chi_square
                d_g_m1 = 1.0;
                g_m1 = 1.0 + u;
            elseif functiontype == constrained_chi_square
                if( u < ( rl - 1.0 ))
                   g_m1 = rl
                   d_g_m1 = 0.0
                elseif( u > ( ru - 1.0 ))
                   g_m1 = ru
                   d_g_m1 = 0.0
                else
                   g_m1 = 1.0 + u
                   d_g_m1 = 1.0
                end
            elseif functiontype == d_and_s_type_a
               g_m1 = ( 1.0 -  u/2.0 ) ^ ( -2 )
               d_g_m1 = ( 1.0 - u/2.0 ) ^ ( -3 )
            elseif functiontype == d_and_s_type_b
               g_m1 = ( 1.0- u ) ^ (-1 )
               d_g_m1 = ( 1.0 - u ) ^ ( -2 )
            elseif functiontype == d_and_s_constrained
               alpha = ( ru - rl ) / (( 1.0 - rl )*( ru - 1.0 ))
               g_m1 = rl*(ru-1.0)+ru*(1.0-rl)*exp( alpha*u )/((ru-1.0)+(1.0-rl)*(exp( alpha*u )))
               d_g_m1 = g_m1 * ( ru - g_m1 ) *
                 ((( 1.0 - rl )*alpha*exp( alpha*u )) /
                  (( ru - 1.0 ) + (( 1.0 - rl ) * exp( alpha*u ))))
           end # function cases
           for col in 1:ncols
               z[col] += initial_weights[row]*data[row,col]*(g_m1-1.0)
               ## the hessian
               for c2 in 1:ncols
                   zz :: Float64 = initial_weights[row]*data[row,col]*data[row,c2]
                   hessian[col,c2] += zz*d_g_m1
               end
           end
        end # obs loop
        gradient = a - z
        println( "gradient $gradient")
        println( "lamdas $lamdas" )
        # println( "hessian $hessian" )
        # return ( gradient, hessian )
    end # nested function

    hessian = zeros( ncols, ncols )
    gradient = zeros( ncols, 1 )
    initial_lamdas = zeros( ncols )
    objective = only_fj!( compute_lamdas_and_hessian! ) # this means: we're providing one function 'fj' which
                                   # computes both the first derivatives value and the hessian
    rc = nlsolve(
        objective,
        gradient,
        hessian,
        initial_lamdas,
        inplace        = false,
        # method         = :newton,
        # autoscale      = true,
        # extended_trace = true )
        xtol           = tolx,
        ftol           = tolf )
    new_weights = copy(initial_weights)
    lamdas = ( rc.zero )

    # construct the new weights from the lamdas
    if converged( rc )
        for r in 1:nrows
            row = data[r,:]
            u = (row'*lamdas)[1]
            g_m1 = 0.0
            if functiontype == chi_square
                g_m1 = 1.0 + u;
            elseif functiontype == constrained_chi_square
                if( u < ( rl - 1.0 ))
                   g_m1 = rl
                elsif( u > ( ru - 1.0 ))
                   g_m1 = ru
                else
                   g_m1 = 1.0 + u
                end
            elseif functiontype == d_and_s_type_a
               g_m1 = ( 1.0 -  u/2.0 ) ^ ( -2 )
            elseif functiontype == d_and_s_type_b
               g_m1 = ( 1.0- u ) ^ (-1 )
            elseif functiontype == d_and_s_constrained
               alpha = ( ru - rl ) / (( 1.0 - rl )*( ru - 1.0 ))
               g_m1 = rl*(ru-1.0)+ru*(1.0-rl)*exp( alpha*u )/((ru-1.0)+(1.0-rl)*(exp( alpha*u )))
           end # function cases
            #
            # Creedy wp 03/17 table 3
            #
            new_weights[r] = initial_weights[r]*g_m1
        end
    end # converged
    return Buffer(:lamdas=>lamdas, :rc => rc, :weights=>new_weights ) # , :converged => converge )
end # do reweighting


"
This is a route-1 approach to Chi-square reweighting.
The iterative main method should produce identical results
when method=chi_square. This is kept here mainly for testing.
Note the weights can be negative.
See the Creedy Papers.
"
function dochisquarereweighting(
    data               :: AbstractArray{ <:Real, 2 },
    initial_weights    :: AbstractArray{ <:Real, 1 }, # a row
    target_populations :: AbstractArray{ <:Real, 1 } ) :: Array{ <:Real }

    nrows = size( data )[1]
    ncols = size( data )[2]

    row = zeros( ncols )
    populations = zeros( ncols, 1 )
    lamdas  = zeros( ncols, 1 )
    weights = zeros( nrows, 1 )
    m = zeros( ncols, ncols )
    for r in 1:nrows
        row = data[r,:]
        m += initial_weights[r]*(row*row')
        for c in 1:ncols
            populations[c] += (row[c]*initial_weights[r])'
        end
    end
    lamdas = (m^-1)*(target_populations-populations)
    for r in 1:nrows
        row = data[r,:]
        weights[r] = initial_weights[r]*(1.0 + (row'*lamdas)[1])
    end
    return weights;
end
