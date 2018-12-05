
## TEST of HBAI inequality - comment this out
using ReadStat
using StatFiles
using DataFrames

hbai_2003_4 = DataFrame( load( "/mnt/data/hbai/UKDA-5828-stata11/stata11/hbai0304_g4.dta" ))
iter = IteratorInterfaceExtensions.getiterator( hbai_2003_4 )
fieldnames( eltype( iter ))

povline = hbai_2003_4[1,:MDOEAHC]*0.6 # The median of S_OE_AHC see if we can replicate this
growth = 0.023


pov_2003_4 = makepoverty( hbai_2003_4, povline, growth, :G_NEWPP, :S_OE_AHC )

print( "Poverty 2003/4\n")
print( pov_2003_4 )
print( "\n\n")

ineq_2003_4 = makeinequality( hbai_2003_4, :G_NEWPP, :S_OE_AHC )

print( "Inequality 2003/4\n")
print( ineq_2003_4 )
print( "\n\n")


deciles = binify( hbai_2003_4, 10, :G_NEWPP,  :S_OE_AHC )
print( "Deciles $deciles ")

quintiles = binify( hbai_2003_4, 20, :G_NEWPP,  :S_OE_AHC )
print( "Quintiles $quintiles ")

percentiles = binify( hbai_2003_4, 100, :G_NEWPP,  :S_OE_AHC )
print( "Percentiles $percentiles ")
