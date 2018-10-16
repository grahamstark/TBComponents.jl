"
   Implements the micro data weighting procedures from:
   * Creedy 2003 http://www.treasury.govt.nz/publications/research-policy/wp/2003/03-17/twp03-17.pdf
   * Creedy 2003  http://www.business.curtin.edu.au/files/creedy2.pdf
   * Jean-Claude Deville and Carl-Erik Sarndal http://www.jstor.org/stable/2290268
"
@enum DistanceFunctionType chi_square d_and_s_type_a d_and_s_type_b constrained_chi_square d_and_s_constrained

const ITERATIONS_EXCEEDED = -1

#
# THIS top-level version of my crude (but effective) solver DOESN'T WORK:
# as soon as you modify x in this, it fails
# because the system no longer recognises `thefunc` if it has different
# values for the x parameter..
# Replaced with a nested version with x as a semi-global.
# I also struggled with the Julia native versions in the Optim
# need to come back to those ..
#
function solve_non_linear_equation_system(
    thefunc,
    x         :: Vector,
    numtrials :: Integer = 50,
    tolx      :: Real = 0.000001,
    tolf      :: Real = 0.000001 ) :: Dict{Symbol,Any}
    xs = size( x )[1]
    deltas = zeros( xs )
    error = 0
    iterations = 0
    # this works around a weird error
    # in Julia 1.0 where if you change a value
    # in this call-line
    # .. but it doesn't
    lx = copy( x )
    for k in 1:numtrials
        iterations += 1
        errf = 0.0
        errx = 0.0
        outx :: Dict{Symbol, Any} = thefunc( lx )
        gradient = outx[:gradient]
        hessian = outx[:hessian]
        for i in 1:xs
            errf += abs( gradient[i])
        end
        if errf <= tolf
            break
        end
        deltas = hessian \ gradient
        lx += deltas
        for i in 1:xs
            errx += abs( deltas[i])
        end
        if errx <= tolx
            break
        end
        if iterations == numtrials
            error = ITERATIONS_EXCEEDED
            break
        end
    end
    return Dict( :x=>lx, :iterations=>iterations, :error=>error )
end

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
    data               :: AbstractArray{ <:Real, 2 },
    initial_weights    :: AbstractArray{ <:Real, 1 }, # a column
    target_populations :: AbstractArray{ <:Real, 1 }, # a row
    functiontype       :: DistanceFunctionType,
    ru                 :: Real = 0.0,
    rl                 :: Real = 0.0,
    tolx               :: Real = 0.000001,
    tolf               :: Real = 0.000001 ) :: Dict{ Symbol, Any }

    nrows = size( data )[1]
    ncols = size( data )[2]
    @assert ncols == size( target_populations )[1]
    @assert nrows == size( initial_weights )[1]
    a = target_populations - (initial_weights'*data)'
    lamdas = zeros( Float64, ncols )

    ##
    ## horror cpde: document problem with calling func with
    ## variable input in J1.0. Hence this version
    ## where lamdas is a semi-global so we don't modify it
    ## before we call `thefunc`.
    ##
    function local_solve_non_linear_equation_system(
        thefunc,
        numtrials :: Integer = 50 ) :: Dict{Symbol,Any}

        deltas = zeros( ncols )
        error = 0
        iterations = 0
        for k in 1:numtrials
            iterations += 1
            errf = 0.0
            errx = 0.0
            outx :: Dict{Symbol, Any} = thefunc()
            gradient = outx[:gradient]
            hessian = outx[:hessian]
            for i in 1:ncols
                 errf += abs( gradient[i])
            end
            if errf <= tolf
                 break
            end
            deltas = hessian \ gradient
            lamdas += deltas
            for i in 1:ncols
                 errx += abs( deltas[i])
            end
            if errx <= tolx
                 break
            end
        end
        if iterations == numtrials
             error = ITERATIONS_EXCEEDED
        end
        return Dict( :iterations=>iterations, :error=>error )
    end

    function compute_lamdas_and_hessian()  :: Dict{ Symbol, Any }
        gradient = zeros( Float64, ncols, 1 )
        hessian = zeros( Float64, ncols, ncols )
        z = zeros( Float64, ncols, 1 )
        # hessian[:,:] .= 0.0
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
        d = Dict(:lamdas=>lamdas,:gradient=>gradient,:hessian=>hessian )
        return d
    end # nested function

    rc = local_solve_non_linear_equation_system(
        compute_lamdas_and_hessian )

    # fixme: my failed attempt to use Optim code.
    # this has to be better once I get the hang of it.
    # =================================================
    # print( rc )
    # lamdas = zeros( Float64, ncols )
    # df = TwiceDifferentiable( getLamdas, getGradients!, getHessian!, lamdas )
    #
    # lx = fill(-Inf, ncols); ux = fill(Inf, ncols )
    # dfc = TwiceDifferentiableConstraints(lx, ux )
    # # rc = optimize( df, dfc, lamdas, IPNewton() )
    #
    # rc = optimize(
    #         getLamdas,
    #         getGradients!,
    #         getHessian!,
    #         lamdas,
    #         Newton() )
    # rc = optimize( only_fj!( fj! ), lamdas )
    # converge = converged( rc )
    # ==============================================

    new_weights = copy(initial_weights)
    # construct the new weights from the lamdas
    if rc[:error] == 0
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
    return Dict(:lamdas=>lamdas, :rc => rc, :weights=>new_weights ) # , :converged => converge )
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
