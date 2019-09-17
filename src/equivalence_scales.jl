#
# from: Equivalence scales: rationales, uses and assumptions
# Jenny Chanfreau and Tania Burchardt Table 1 p.5
#

@enum Equivalence_Scale_Type oxford modified_oecd eq_square_root mcclements eq_per_capita
@enum Equiv_Person_Type eq_head eq_spouse_of_head eq_other_adult eq_dependent_child

struct EQ_Person
      age::Integer
      ptype::Equiv_Person_Type
end

function get_equivalence_scales( people::Vector{EQ_Person} )::Dict{Equivalence_Scale_Type,Real}
      eq = 0.0
      scales = Dict{Equivalence_Scale_Type,Real}()
      np = size( people )[1]
      # choose someone to be the head of the unit
      pos_of_head = 1
      positions_of_head = findall((p -> (p.ptype == eq_head) & (p.age >= 16)), people)
      num_heads = size(positions_of_head)[1]
      if num_heads > 0
            pos_of_head = positions_of_head[1]
      end
      scales[eq_square_root] = sqrt( np )
      scales[eq_per_capita] = np
      ox = 0.0
      oecd = 0.0
      mclem = 0.0
      n_extra_adults = 0
      for pno in 1:np
            if pno == pos_of_head
                  ox += 1
                  oecd += 1
                  mclem += 1
            else
                  if people[pno].age <= 14
                        ox += 0.5
                        oecd += 0.3
                  else
                        ox += 0.7
                        oecd += 0.5
                  end
                  if people[pno].ptype == eq_dependent_child
                        if people[pno].age in 0:1
                              mclem += 0.148
                        elseif people[pno].age in 2:4
                              mclem += 0.295
                        elseif people[pno].age in 5:7
                              mclem += 0.344
                        elseif people[pno].age in 8:10
                              mclem += 0.377
                        elseif people[pno].age in 11:12
                              mclem += 0.410
                        elseif people[pno].age in 13:15
                              mclem += 0.443
                        else
                              mclem += 0.590
                        end
                  elseif people[pno].ptype ==  eq_spouse_of_head
                        mclem += 0.640
                  else # other adult
                        n_extra_adults += 1
                        if n_extra_adults == 1
                              mclem += 0.75
                        else
                              mclem += 0.59
                        end
                  end
            end # person not the head
      end # person loop
      @assert mclem > 0
      @assert oecd > 0
      @assert ox > 0
      scales[oxford] = ox
      scales[modified_oecd] = oecd
      scales[mcclements] = mclem
      scales
end # get_equivalence_scales
