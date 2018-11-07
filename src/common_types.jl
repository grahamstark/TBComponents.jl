"
Do I really need this? This is my hack to allow both DataFrames and Arrays to be passed to
Poverty and Weights routines
"
ArrayOrFrame = Union{ DataFrame, AbstractArray{<:Number,2}}
