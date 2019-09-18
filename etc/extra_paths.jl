## fixme ** should work
# or add_dirs in project
VW_DIR="/home/graham_s/VirtualWorlds/projects/"
push!(LOAD_PATH,joinpath(VW_DIR,"TBComponents.jl","src"))
push!(LOAD_PATH,joinpath(VW_DIR,"DDIMeta.jl","src"))

STB_DIR=pwd() # joinpath(VW_DIR,"stb.jl")
for dr in ["core","web","data_mapping","persist", "general"]
    push!(LOAD_PATH, joinpath(STB_DIR,"src",dr))
end
for dr in ["test","scratch","scripts"]
    push!(LOAD_PATH,joinpath(STB_DIR,dr))
end

# using Revise
