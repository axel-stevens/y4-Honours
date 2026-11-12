-- RC switch output script

local TEST_CHANNEL = 15
local OUTPUT = 94

function update()

    local pwm = rc:get_pwm(TEST_CHANNEL)

    if pwm and pwm > 1700 then
        SRV_Channels:set_output_pwm(OUTPUT, 2000)
    else
        SRV_Channels:set_output_pwm(OUTPUT, 1000)
    end

    return update, 100
end

return update, 100