do
	local yoursFunction = function()
		-- what to do
	end
	local tm = tmr.create() 
	tm:alarm(5000, 1, function()
        getConnect(yoursFunction)
    end)
	
	local count = 0  
    local getConnect = function(call)    
		if wifi.sta.status() == 5 then 
           tmr.stop(tm)
		   tmr.unregister(tm)
		   if call then call() end
        else
            count = count + 1
            if count > 20 then node.restart() end
        end
    end
	getConnect(yoursFunction)
end