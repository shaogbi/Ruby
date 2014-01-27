module ArrayToHash
  attr_accessor :res

  def get_initial_hash(depth)
    return [] if depth == 0
    return Hash.new { |h, k| h[k] = get_initial_hash(depth-1) }
  end

  def get_formatted_hash(raw_data_arr, slice_arr)
    len = slice_arr.length
    res = get_initial_hash(len)
    str = ""
    (0 ... len).each { |i| str += "[dp[slice_arr[#{i}]]]" }
    raw_data_arr.each do |dp|
      if eval("res#{str}").length == 0
        eval("res#{str} = dp[:v]")
      else
      print "plus "
      puts eval("res#{str}").inspect
        dp[:v].each_with_index { |e, i| eval("res#{str}")[i] += e }
      end
    end
    return res
  end
end

include ArrayToHash

raw = [
  {:pl=>"pl1",:fc=>"fc1",:st=>"st1",:v=>[1,3,4]},
  {:pl=>"pl1",:fc=>"fc1",:st=>"st2",:v=>[2,3,3]},
  {:pl=>"pl1",:fc=>"fc1",:st=>"st3",:v=>[6,5,4]},
  {:pl=>"pl1",:fc=>"fc2",:st=>"st1",:v=>[2,3,4]},
  {:pl=>"pl1",:fc=>"fc2",:st=>"st2",:v=>[3,3,3]},
  {:pl=>"pl2",:fc=>"fc1",:st=>"st1",:v=>[7,5,4]},
  {:pl=>"pl2",:fc=>"fc1",:st=>"st2",:v=>[6,3,5]},
  {:pl=>"pl2",:fc=>"fc2",:st=>"st1",:v=>[6,2,8]},
  {:pl=>"pl2",:fc=>"fc2",:st=>"st2",:v=>[2,9,3]},
  {:pl=>"pl2",:fc=>"fc2",:st=>"st3",:v=>[1,1,5]}
]

slices = [:fc,:st,:pl]
puts ArrayToHash.get_formatted_hash(raw, slices).inspect
# {"fc2"=>{"st3"=>{"pl2"=>[1, 1, 5]}, "st2"=>{"pl2"=>[2, 9, 3], "pl1"=>[3, 3, 3]}, "st1"=>{"pl2"=>[6, 2, 8], "pl1"=>[2, 3, 4]}}, "fc1"=>{"st3"=>{"pl1"=>[6, 5, 4]}, "st2"=>{"pl2"=>[6, 3, 5], "pl1"=>[2, 3, 3]}, "st1"=>{"pl2"=>[7, 5, 4], "pl1"=>[1, 3, 4]}}}

slices = [:pl]
puts ArrayToHash.get_formatted_hash(raw, slices).inspect
# {"pl2"=>[22, 20, 25], "pl1"=>[14, 17, 18]}

slices = [:fc, :pl]
puts ArrayToHash.get_formatted_hash(raw, slices).inspect
# {"fc2"=>{"pl2"=>[9, 12, 16], "pl1"=>[5, 6, 7]}, "fc1"=>{"pl2"=>[28, 23, 30], "pl1"=>[22, 25, 25]}}
