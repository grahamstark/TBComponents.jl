"

"
@enum DistanceFunctionType chi_square d_and_s_type_a d_and_s_type_b constrained_chi_square d_and_s_constrained


function doreweighting()
    data             :: AbstractArray{ <:Real, 2 },
    initial_weights  :: AbstractArray{ <:Real, 1 }, # a column
    target_populations :: AbstractArray{ <:Real, 1 }, # a row
    functiontype     :: DistanceFunctionType,
    ru               :: Real = 0.0,
    rl               :: Real = 0.0 ) :: Dict{ Symbol, Any }
    nrows = size( data )[1]
    ncols = size( data )[2]
    @assert ncols == size( target_populations )[2]
    @assert nrows == size( initial_weights )[1]
    a = target_populations - ( initial_weights'*data)
    hessian = zeros( Float64, ncols, ncols )
    lambdas = zeros( Float64, ncols )

    function lamdasandhessian()
        z = zeros( Float64, ncols )
        hessian[:,:] .= 0.0
        for row in 1:nrows
            rv = data[row,:]
            u = rv * lamdas'
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
               g_m1 = ( 1.0- u ) ** (-1 )
               d_g_m1 = ( 1.0 - u ) ** ( -2 )
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
                   zz : Float64 = initial_weights[row]*data[row,col]*data[row,c2]
                   hessian[col,c2] += zz*d_g_m1
               end
           end
        end # obs loop

        lambdas = a - z
    end # nested function






    function dochisquarereweighting()

    end



end # do reweighting
