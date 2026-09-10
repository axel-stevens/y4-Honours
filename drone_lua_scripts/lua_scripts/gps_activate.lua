-- GPS output script

local OUTPUT = 94

function update()

    if gps:status(0) >= GPS.GPS_OK_FIX_3D then
        SRV_Channels:set_output_pwm(OUTPUT, 1800)
    else
        SRV_Channels:set_output_pwm(OUTPUT, 1200)
    end

    return update, 100
end

return update, 100