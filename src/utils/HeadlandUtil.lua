HeadlandUtil = {}

function HeadlandUtil.FindFieldEdge(x,z, dirX, dirZ, maxSearchDistance, currentStep)
    if currentStep == nil then 
        currentStep = 0;
    end

    local probePointx = x + dirX * currentStep
    local probePointz = z - dirZ * currentStep
    
    if currentStep > maxSearchDistance then
        -- print("steps " .. currentStep .. " is extending " .. maxSearchDistance)
        -- print("Target point " .. x .. ";" .. z)
        -- print("extend point " .. probePointx .. ";" .. probePointz)
        return maxSearchDistance
    end

    local b = getDensityAtWorldPos(g_currentMission.terrainDetailId, probePointx, 0, probePointz)
    local probeOnField = b ~= 0

    if probeOnField then
        return HeadlandUtil.FindFieldEdge(x,z, dirX, dirZ, maxSearchDistance, currentStep + 1)
    else
        --print("found edge backtrack to improve presision")
        return HeadlandUtil.FindFieldEdgeBackTrack(x,z, dirX, dirZ, currentStep-0.1)
    end
end

function HeadlandUtil.FindFieldEdgeBackTrack(x,z, dirX, dirZ, currentStep)
    if currentStep == nil then 
        currentStep = 0;
    end

    local probePointx = x + dirX * currentStep
    local probePointz = z - dirZ * currentStep

    local b = getDensityAtWorldPos(g_currentMission.terrainDetailId, probePointx, 0, probePointz)
    local probeOnField = b ~= 0

    if probeOnField then
        --print("found presion edge ")
        return currentStep
    else
        return HeadlandUtil.FindFieldEdgeBackTrack(x,z, dirX, dirZ, currentStep-0.1)
    end
end