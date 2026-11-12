function update()

    if arming:is_armed() then
        SRV_Channels:set_output_pwm(94, 1800)
    else
        SRV_Channels:set_output_pwm(94, 1200)
    end

    return update, 100
end

return update, 100