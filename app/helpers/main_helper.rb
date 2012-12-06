module MainHelper

def get_cpu_temperture(hostname, user)
  if user != nil
    output = `ssh #{user}@#{hostname} sensors | grep "Core 0" | awk '{print $3}'`
  else
    output = `ssh #{hostname} sensors | grep "Core 0" | awk '{print $3}'`
  end
  puts output
  return output
end

def get_board_temperture(hostname, user)
  if user != nil
    output = `ssh #{user}@#{hostname} /opt/dell/srvadmin/bin/omreport chassis temps index=0 | grep Reading | awk '{print $3}'`
  else
    output = `ssh #{hostname} /opt/dell/srvadmin/bin/omreport chassis temps index=0 | grep Reading | awk '{print $3}'`
  end
  puts output
  return output
end

end
