function write_to_file()
    local addressList = getAddressList()
    if addressList.Count >= 1 then
      
      local mrHealth = addressList.getMemoryRecordByDescription('hp')
      print(mrHealth.Value)
      
      io.output(io.open("output.txt", "w"))
      io.write(mrHealth.Value)
      io.close()
    end
    end
    -- make sure to uncheck show on print show on, show script in output etc
    -- 
    t=createTimer(nil, false)
    timer_onTimer(t, write_to_file)
    timer_setInterval(t, 100)
    -- https://www.cheatengine.org/forum/viewtopic.php?p=5461922#5461922
    --  f3 start , f4 stop 
    createHotkey(function () timer_setEnabled(t,true) end, VK_F3)
    createHotkey(function () timer_setEnabled(t,false) end, VK_F4)