"

"
@enum DistanceFunctionType chi_square d_and_s_type_a d_and_s_type_b constrained_chi_square d_and_s_constrained

const INTERATIONS_EXCEEDED = -1


function solve_non_linear_equation_system(
    thefunc,
    x         :: Vector,
    numtrials :: Integer = 50,
    tolx      :: Real = 0.000001,
    tolf      :: Real = 0.000001 )
    print( "x $x" )
    xs = size( x )[1]
    deltas = zeros( xs )
    error = 0
    iterations = 0
    for k in 1:numtrials
        iterations += 1
        errf = 0.0
        errx = 0.0
        out :: Dict{Symbol, Any} = thefunc( x )
        gradient = out[:gradient]
        hessian = out[:hessian]
        for i in 1:xs
            errf += abs( gradient[i])
        end
        if errf <= tolf
            break
        end
        # deltas = solve( hessian, gradient )
        deltas = hessian \ gradient
        x += deltas
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
    return Dict( :x=>x, :iterations=>iterations, :error=>error )
end

function doreweighting(
    data               :: AbstractArray{ <:Real, 2 },
    initial_weights    :: AbstractArray{ <:Real, 1 }, # a column
    target_populations :: AbstractArray{ <:Real, 1 }, # a row
    functiontype       :: DistanceFunctionType,
    ru                 :: Real = 0.0,
    rl                 :: Real = 0.0 ) :: Dict{ Symbol, Any }
    nrows = size( data )[1]
    ncols = size( data )[2]
    @assert ncols == size( target_populations )[1]
    @assert nrows == size( initial_weights )[1]
    a = target_populations - (initial_weights'*data)'
    gradient = zeros( Float64, ncols, 1 )
    hessian = zeros( Float64, ncols, ncols )

    function computelamdasandhessian( lamdas::Vector )
        print( "ncols $ncols")
        print( "lamdas $lamdas" )
        z = zeros( Float64, ncols, 1 )
        hessian[:,:] .= 0.0
        for row in 1:nrows
            rv = data[row,:]
            u = (rv' * lamdas)[1]
            # println( "rv = $rv ")
            # println( "lamdas = $lamdas ")
            # println( "u = $u")
            d_g_m1 = 0.0
            g_m1 = 0.0
            if functiontype == chi_square
                d_g_m1 = 1.0;
                g_m1 = 1.0 + u;
            elseif functiontype == constrained_chi_square
                if( u < ( rl - 1.0 ))
                   g_m1 = rl
                   d_g_m1 = 0.0
                elsif( u > ( ru - 1.0 ))
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
               # println( "g_m1 $g_m1 initial_weights[row]=$initial_weights[row] data[row,col]=$data[row,col]")
               z[col] += initial_weights[row]*data[row,col]*(g_m1-1.0)
               ## the hessian
               for c2 in 1:ncols
                   zz :: Float64 = initial_weights[row]*data[row,col]*data[row,c2]
                   hessian[col,c2] += zz*d_g_m1
               end
           end
        end # obs loop
        print( "A" );println( a )
        print( "Z" );println( z )
        gradient = a - z
        print( "Gradient $gradient")
        return Dict(:x=>lamdas,:gradient=>gradient,:hessian=>hessian )
    end # nested function

    lamdas = zeros( Float64, ncols )
    rc = solve_non_linear_equation_system( computelamdasandhessian, lamdas )
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

    new_weights = copy(initial_weights)
    # converge = converged( rc )
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
    return Dict(:lamdas=>lamdas, :rc => rc, :weights=>new_weights, :converged => converge )
end # do reweighting



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


# function getGradients!( out_gradient :: Vector, lamdas::Vector )
#     out_gradient = gradient
# end
#
# function getHessian!( out_hessian::Matrix, lamdas::Vector  )
#     out_hessian = hessian
# end
