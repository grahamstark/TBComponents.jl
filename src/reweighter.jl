"

"
@enum DistanceFunctionType chi_square d_and_s_type_a d_and_s_type_b constrained_chi_square d_and_s_constrained


function doreweighting()
    data             :: AbstractArray{ <:Real },
    initial_weights  :: AbstractArray{ <:Real },
    functiontype     :: DistanceFunctionType,
    ru               :: Real = 0.0,
    rl               :: Real = 0.0 ) :: Dict{ Symbol, Any }
    a = target_populations - ( initial_weights*data)
    nrows = size( data )[1]
    ncols = size( data )[2]
    hessian = zeros( ncols, ncols )

    function lamdasandhessian!( lamdas :: AbstractArray{ <:Real } )
        z = zeros( Float64, ncols )
        hessian[:,:] .= 0.0
        for row in 1:nrows
            rv = data[row,:]
            u = rv * lamdas


        end
    end # nested function



end # do reweighting
