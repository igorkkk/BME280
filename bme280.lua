sda = 3
scl = 4
Broker="iot.eclipse.org"
port=1883

local wireisgood
wireisgood = bme280.init(sda, scl)

m = mqtt.Client( "bme280200", 120, "bme280", "superpass")
pu = false

m:lwt("/myhome/bme280/lwt", "bme280", 0, 0)

connectNow = function()
    local tm = tmr.create()
    tm:alarm(5000, 1, function() get() end)
    
    function get()
        if wifi.sta.status() == 5 and wifi.sta.getip() ~= nil then
            tmr.stop(tm)
            tmr.unregister(tm)
            print("Got WiFi!")
            m:connect(Broker, port, 0, function(conn)
                print("Mqtt Connected to: " .. Broker)
                pu = true
            end)
        else
            print("No WiFi!")
        end
    end
    get()
end

m:on("offline", function(con)
    pu = false
    print ("Mqtt Reconnecting.")
    connectNow()
end)

function publish_data()
    print("==========\t\t\tHeap at Start "..node.heap())
    local H = string.format("%.1f", (bme280.humi()/1000))
    local P, T = bme280.baro()
    P = string.format("%.1f", (P/1000*0.75))
    T = string.format("%.2f", T/100) 

    print("Humidity = "..H.." %, \nPressure = "
    ..P.." mm.Hg"
    .."\nTemperatre = "..T.." C")
    
    if pu == true then
        m:publish("/myhome/bme280/temperature/status",T,0,0, function(conn)
            print("Temp "..T.." published!")
            tmr.alarm(3, 1000, 0, function(conn)
                m:publish("/myhome/bme280/humi/status",H,0,0, function(conn)
                    print("Humi "..H.." published!")
                    tmr.alarm(4, 1000, 0, function(conn)
                        m:publish("/myhome/bme280/press/status",H,0,0, function(conn)
                            print("Pressure "..P.." published!")
                            print("==========\t\t\tHeap at Finish "..node.heap())
                        end)
                    end)
    
                end)
            end)
        end)
        collectgarbage()
    end
end 
function run_main_prog()
    print("Main  program")
    publish_data()
    tmr.create():alarm(30000, 1, function() publish_data() end)
end


if wireisgood == 2 then
    connectNow()
    run_main_prog()
else
    print("\n\n\===========\t\t   Error at Wireing or not BME, Balbes!   ===========")
end
   
--end
