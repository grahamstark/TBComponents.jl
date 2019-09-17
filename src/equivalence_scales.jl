#
# from: Equivalence scales: rationales, uses and assumptions
# Jenny Chanfreau and Tania Burchardt Table 1 p.5
#

@enum Equivalence_Scale_Type oxford modified_oecd square_root mcclements
@enum Equiv_Person_Type head spouse_of_head other_adult dependent_child

struct EQ_Person
      age::Integer
      ptype::Equiv_Person_Type
end

function get_equivalence_scale(
      people::Vector{EQ_Person},
      scale_type::Equivalence_Scale_Type
)::Real
      eq = 0.0
      # choose someone to be the head of the unit
      pos_of_head = 1
      positions_of_head = findall(p -> (p.ptype == head & p.age >= 16), people)
      num_heads = size(positions_of_head)[1]
      if num_heads > 0
            pos_of_head = positions_of_head[1]
      end
      for person in people


      end
      eq
end
