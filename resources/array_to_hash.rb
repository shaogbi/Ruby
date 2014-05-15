=begin
convert an array to formatted hash
usage:
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

len = 3
slices = [:fc, :st, :pl]

h = ArrayToHash.get_formatted_hash(raw, [:fc, :st, :pl], len)
# => {"fc2"=>{"st3"=>{"pl2"=>[1, 1, 5]}, "st2"=>{"pl2"=>[2, 9, 3], "pl1"=>[3, 3, 3]}, "st1"=>{"pl2"=>[6, 2, 8], "pl1"=>[2, 3, 4]}}, "fc1"=>{"st3"=>{"pl1"=>[6, 5, 4]}, "st2"=>{"pl2"=>[6, 3, 5], "pl1"=>[2, 3, 3]}, "st1"=>{"pl2"=>[7, 5, 4], "pl1"=>[1, 3, 4]}}}

h = ArrayToHash.get_formatted_hash(raw, slices, len, {:mode=>'total',:format=>'delimiter'})
# => {"fc2"=>{"st3"=>{"pl2"=>[1, 1, 5], "[Total]"=>[1.0, 1.0, 5.0]}, "st2"=>{"pl2"=>[2, 9, 3], "pl1"=>[3, 3, 3], "[Total]"=>[5.0, 12.0, 6.0]}, "st1"=>{"pl2"=>[6, 2, 8], "pl1"=>[2, 3, 4], "[Total]"=>[8.0, 5.0, 12.0]}, "[Total]"=>[14.0, 18.0, 23.0]}, "fc1"=>{"st3"=>{"pl1"=>[6, 5, 4], "[Total]"=>[6.0, 5.0, 4.0]}, "st2"=>{"pl2"=>[6, 3, 5], "pl1"=>[2, 3, 3], "[Total]"=>[8.0, 6.0, 8.0]}, "st1"=>{"pl2"=>[7, 5, 4], "pl1"=>[1, 3, 4], "[Total]"=>[8.0, 8.0, 8.0]}, "[Total]"=>[22.0, 19.0, 20.0]}, "[Total]"=>[36.0, 37.0, 43.0]}

slices = [:fc, :pl]

h = ArrayToHash.get_formatted_hash(raw, slices, 3, {:mode=>'total'})
# => {"fc2"=>{"pl2"=>[9, 12, 16], "pl1"=>[5, 6, 7], "[Total]"=>[14.0, 18.0, 23.0]}, "fc1"=>{"pl2"=>[13, 8, 9], "pl1"=>[9, 11, 11], "[Total]"=>[22.0, 19.0, 20.0]}, "[Total]"=>[36.0, 37.0, 43.0]}

h = ArrayToHash.get_formatted_hash(raw, slices, 3, {:mode=>'percentage'})
# => {"fc2"=>{"pl2"=>["60.00%", "70.97%", "70.59%"], "pl1"=>["40.00%", "29.03%", "29.41%"], "[Total]"=>["35.71%", "50.82%", "51.52%"]}, "fc1"=>{"pl2"=>["52.78%", "36.67%", "43.75%"], "pl1"=>["47.22%", "63.33%", "56.25%"], "[Total]"=>["64.29%", "49.18%", "48.48%"]}, "[Total]"=>["100.00%", "100.00%", "100.00%"]}
=end

module ArrayToHash
  # 87.621 -> 87.62%
  def get_percentage_str(num)
    return format("%0.2f", num).to_s + "%"
  end
  
  # 25436 -> 25,436
  def get_delimiter_str(num)
    str = num.to_s
    nil while str.gsub!(/(.*\d)(\d\d\d)/, "\1,\2")
    return str
  end
  
  def is_hash(h)
    return h.class == Hash
  end

  def get_formatted_number_res(res, mode)
    if !is_hash(res)
      res.map! { |e| eval "get_#{mode}_str(e)" }
    else
      res.each_pair { |k, dp| res[k] = get_formatted_number_res(dp, mode) }
    end
    return res
  end

  def get_initial_hash(depth)
    return [] if depth == 0
    return Hash.new { |h, k| h[k] = get_initial_hash(depth-1) }
  end
  
  def get_sub_percentage_mode(h, total)
    total_arr = h[total]
    h.each_pair do |k, dp|
      next if k == total
      if !is_hash(dp)
        dp.each_with_index { |v, i| h[k][i] = (total_arr[i] != 0 ? v.to_f/total_arr[i].to_f*100 : 0.0) }
      else
        h[k] = get_sub_percentage_mode(dp, total)
        dp[total].each_with_index { |v, i| h[k][total][i] = (total_arr[i] != 0 ? v.to_f/total_arr[i].to_f*100 : 0.0) }
      end
    end
    return h
  end
  private :get_sub_percentage_mode 

  def get_percentage_mode(h, total)
    return h if h.empty?
    h = get_sub_percentage_mode(h, total)
    h[total].map! { |e| 100.0 }
    return h
  end
  
  def get_total_mode(h, len, total)
    return h if !is_hash(h)
    h.each_pair { |k, dp| h[k] = get_total_mode(dp, len, total) if is_hash(dp) }
    arr = Array.new(len, 0.0)
    h.each_pair do |k, dp|
      if is_hash(dp)
        dp[total].each_with_index { |val, i| arr[i] += val }
      else
        dp.each_with_index { |val, i| arr[i] += val }
      end
    end
    h[total] = arr
    return h
  end

  def get_formatted_hash(raw_data_arr, slice_arr, ts_len, opts = {})
    len = slice_arr.length
    res = get_initial_hash(len)
    str = (0 ... len).reduce("") { |curr, val| curr += "[dp[slice_arr[#{val}]]]" }
    raw_data_arr.each do |dp|
      if eval("res#{str}").length == 0
        eval("res#{str} = dp[:v]")
      else
        dp[:v].each_with_index { |e, i| eval("res#{str}")[i] += e }
      end
    end
    raise "Invalid options, options should be a Hash like {:mode=>'total',:format=>'delimiter'}" if !is_hash(opts)
    total = opts[:total] || "[Total]"
    res = get_total_mode(res, ts_len, total) if ["total", "percentage"].include?(opts[:mode])
    if opts[:mode] == "percentage"
      res = get_percentage_mode(res, total)
      res = get_formatted_number_res(res, "percentage")
    end
    return res
  end
end
