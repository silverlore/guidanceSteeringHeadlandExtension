HeadlandUtil = {}

function HeadlandUtil.FindFieldEdge(x,z, dirX, dirZ, maxSearchDistance, currentStep, stepSize)
    if currentStep == nil then 
        currentStep = 0;
    end

    if stepSize == nil then
        stepSize = 1;
    end

    local probePointx = x + dirX * (currentStep+stepSize)
    local probePointz = z + dirZ * (currentStep+stepSize)
    
    

    local b = getDensityAtWorldPos(g_currentMission.terrainDetailId, probePointx, 0, probePointz)
    local probeOnField = b ~= 0

    if probeOnField then
        if currentStep > maxSearchDistance then
            --print("steps " .. currentStep .. " is extending " .. maxSearchDistance)
            return maxSearchDistance
        else
            return HeadlandUtil.FindFieldEdge(x,z, dirX, dirZ, maxSearchDistance, currentStep + stepSize, stepSize)
        end
    else
        if stepSize >= 1 then
            return HeadlandUtil.FindFieldEdge(x,z, dirX, dirZ, maxSearchDistance, currentStep, 0.1)
        else
            return currentStep
        end

    end
end
