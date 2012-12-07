module MainHelper

def get_cpu_temperture(measure_type, hostname, user)
  if user != nil
    output = `ssh #{user}@#{hostname} sensors | grep "Core 0" | awk '{print $3}'`
  else
    output = `ssh #{hostname} sensors | grep "Core 0" | awk '{print $3}'`
  end

  # replace +°C
  output = output.to_f

  puts output

  # do not return false results
  if (output == 0.0) || (output < 0) || (output > 120)
    return nil
  else
    return output
  end
end

def get_board_temperture(measure_type, hostname, user)
  case measure_type
    when "openmanage"
      command = "/opt/dell/srvadmin/bin/omreport chassis temps index=0 | grep Reading | awk '{print $3}'"
    else
      command = "sensors | grep temp1 | awk '{print $2}'"
  end

  if user != nil
    output = `ssh #{user}@#{hostname} #{command}`
  else
    output = `ssh #{hostname} #{command}`
  end

  # replace +°C
  output = output.to_f

  puts output

  # do not return false results
  if (output == 0.0) || (output < 0) || (output > 120)
    return nil
  else
    return output
  end
end

end
