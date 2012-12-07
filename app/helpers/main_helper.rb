module MainHelper

def get_cpu_temperture(measure_type, hostname, user)
  case measure_type
    when "coretemp"
      command = "sensors | grep \"Core 0\" | awk '{print $3}'"
    when "vt1211"
      command = "sensors | grep \"CPU Temp\" | awk '{print $3}'"
    when "tempmonitor"
      command = "/Applications/TemperatureMonitor.app/Contents/MacOS/tempmonitor -a -l -ds | grep \"SMC CPU A HEAT SINK\" | awk '{print $6}'"
    else
      puts "unknown measure type :" + measure_type.to_s
      return nil
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

def get_board_temperture(measure_type, hostname, user)
  case measure_type
    when "openmanage"
      command = "/opt/dell/srvadmin/bin/omreport chassis temps index=0 | grep Reading | awk '{print $3}'"
    when "openmanage5"
      command = "/opt/dell/srvadmin/oma/bin/omreport chassis temps index=0 | grep Reading | awk '{print $3}'"
    when "w83793"
      command = "sensors | grep \"sensor = ther\" | head -n 1 | awk '{print $2}'"
    when "w83792d"
      command = "sensors | grep temp1 | awk '{print $2}'"
    when "tempmonitor"
      command = "/Applications/TemperatureMonitor.app/Contents/MacOS/tempmonitor -a -l -ds | grep \"SMC AMBIENT AIR\" | awk '{print $4}'"
    else
      puts "unknown measure type :" + measure_type.to_s
      return nil
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
