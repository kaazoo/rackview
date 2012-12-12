module MainHelper

def call_ssh(command)
  require 'timeout'

  pipe = "foo"
  output = "bar"

  begin
    Timeout.timeout(5) {
      pipe = IO.popen(command)
      pid = pipe.pid
      Process.wait pipe.pid
      output = pipe.read
      puts "output of pipe.read(): " + output.to_s
  }
  rescue Timeout::Error
    Process.kill 9, pipe.pid
    Process.wait pipe.pid # we need to collect status so it doesn't stick around as zombie process
    output = nil
  end

  return output

end


def get_cpu_temperture(measure_type, hostname, user)
  case measure_type
    when "coretemp"
      command = "sensors | grep \"Core 0\" | awk '{print $3}'"
    when "vt1211"
      command = "sensors | grep \"CPU Temp\" | awk '{print $3}'"
    when "vt1211_sio"
      command = "sensors | grep \"SIO Temp\" | awk '{print $3}'"
    when "tempmonitor"
      command = "/Applications/TemperatureMonitor.app/Contents/MacOS/tempmonitor -a -l -ds | grep \"SMC CPU A HEAT SINK\" | awk '{print $6}'"
    else
      puts "unknown measure type :" + measure_type.to_s
      return nil
  end

  if user != nil
    ssh_command = "ssh #{user}@#{hostname} #{command}"
  else
    ssh_command = "ssh #{hostname} #{command}"
  end

  output = call_ssh(ssh_command)

  # replace +°C
  output = output.to_f

  puts "output of call_ssh(): " + output.to_s

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
    ssh_command = "ssh #{user}@#{hostname} #{command}"
  else
    ssh_command = "ssh #{hostname} #{command}"
  end

  output = call_ssh(ssh_command)

  # replace +°C
  output = output.to_f

  puts "output of call_ssh(): " + output.to_s

  # do not return false results
  if (output == 0.0) || (output < 0) || (output > 120)
    return nil
  else
    return output
  end
end


def get_sanbox_temperture(hostname, user)
  require 'greenletters'

  log = ""
  telnet = Greenletters::Process.new("telnet -l #{user} #{hostname}", :transcript => log, :timeout => 5)

  # Install a handler which may be triggered at any time
  telnet.on(:output, /Password/i) do |process, match_data|
    telnet << File.read(File.expand_path("../../../config/sanbox_pw", __FILE__))
  end

  puts "Starting Telnet ..."
  telnet.start!

  # wait for prompt
  begin
    telnet.wait_for(:output, /#{hostname} #>/i)
  rescue NotImplementedError
    return nil
  end

  # show temperature
  telnet << "show chassis\n"
  telnet.wait_for(:output, /#{hostname} #>/i)

  # quit session
  telnet << "exit\n"
  telnet.wait_for(:output, /Good bye./i)
  puts "Telnet has exited."

  lines = log.split("\n")

  lines.each do |line|
    if line.include?("BoardTemp")
	  temp = line.split(" ")
	  return temp[6].to_f
    end
  end
end


def get_easyraid_temperture(hostname, user, firmware_version)
  require 'greenletters'

  log = ""
  ssh = Greenletters::Process.new("ssh #{user}@#{hostname}", :transcript => log, :timeout => 5)

  # Install a handler which may be triggered at any time
  ssh.on(:output, /Please input passwd:/i) do |process, match_data|
    ssh << File.read(File.expand_path("../../../config/easyraid_pw", __FILE__))
  end

  puts "Starting SSH ..."
  ssh.start!

  case firmware_version
    when 1.43
      prompt = "ACSCLI"
      enclosure = "enc0"
      sensor = "BP_TEMP1"

    when 1.09
      prompt = "CLI"
      enclosure = "enca"
      sensor = "[BP]TEMP1"

    else
      puts "unknown version :" + version.to_s
      return nil
  end

  # wait for prompt
  begin
    ssh.wait_for(:output, /#{prompt}>/i)
  rescue NotImplementedError
    return nil
  end

  # show temperature
  ssh << "enclist #{enclosure} all\n"
  ssh.wait_for(:output, /#{prompt}>/i)

  # quit session
  ssh << "quit\n"
#  ssh.wait_for(:output, /Done/i)
  puts "SSH has exited."

  lines = log.split("\n")

  lines.each do |line|
    if line.include?(sensor)
      puts line
	  temp = line.split(" ")[1].split("/")
	  return temp[0].to_f
    end
  end
end


def get_force10_temperture(hostname, user)
  require 'greenletters'

  log = ""
  ssh = Greenletters::Process.new("ssh #{user}@#{hostname}", :transcript => log, :timeout => 5)

  # Install a handler which may be triggered at any time
  ssh.on(:output, /password:/i) do |process, match_data|
    ssh << File.read(File.expand_path("../../../config/force10_pw", __FILE__))
  end

  puts "Starting SSH ..."
  ssh.start!

  # wait for prompt
  begin
    ssh.wait_for(:output, /#{hostname}>/i)
  rescue NotImplementedError
    return nil
  end

  # show temperature
  ssh << "show system stack-unit 0 | grep Temp\n"
  ssh.wait_for(:output, /#{hostname} #>/i)

  # quit session
  ssh << "quit\n"
#  ssh.wait_for(:output, /Good bye./i)
  puts "SSH has exited."

  lines = log.split("\n")

  lines.each do |line|
    if line.include?("Temperature")
      puts line
	  temp = line.split(" ")
	  return temp[2].to_f
    end
  end
end


def get_color_for_temperature(temp, temp_min, temp_max)

  puts temp
  warn_temp = ((temp_max - temp_min) * 0.67) + temp_min
  puts warn_temp
  crit_temp = ((temp_max - temp_min) * 0.9) + temp_min
  puts crit_temp

  if (temp_min..warn_temp).include?(temp)
    return "green"
  elsif (warn_temp..crit_temp).include?(temp)
    return "orange"
  else
    return "red"
  end

end


end
