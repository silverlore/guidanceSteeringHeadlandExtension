

HeadlandExt = {}

local RGB_WHITE = { 1, 1, 1 }
local RGB_GREEN = { 0, 0.447871, 0.003697 }
local RGB_BLUE = { 0, 0, 1 }
local RGB_RED = { 1, 0, 0 }

function HeadlandExt.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(GlobalPositioningSystem, specializations)
end

function HeadlandExt.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HeadlandExt)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", HeadlandExt)
end

function HeadlandExt:onLoad(savegame)
    print("guidance steering headland extention: Loaded specialization.")

end

function HeadlandExt:onDraw()
    if not self.isClient
        or not self:getHasGuidanceSystem() then
        return
    end

    if g_currentMission.guidanceSteering:isShowGuidanceLinesEnabled() then
        local spec = self.spec_globalPositioningSystem
        -- draw(spec.guidanceData, spec.guidanceSteeringIsActive, spec.autoInvertOffset)

        local data = spec.guidanceData
        local drawHeadDistanceLines = data.isCreated
        if drawHeadDistanceLines then 
            local x, _, z = unpack(data.driveTarget)
            local lineDirX, lineDirZ = unpack(data.snapDirection)

            local lineXDir = data.snapDirectionMultiplier * lineDirX
            local lineZDir = data.snapDirectionMultiplier * lineDirZ

            local function drawHeadLandMarker( lx, lz, dirX, dirZ, rgb)

                local x1 = lx + dirX
                local z1 = lz + dirZ
                local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + lineOffset

                local x2 = lx + dirX
                local z2 = lz + dirZ
                local y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + lineOffset

                drawDebugLine(x1, y1, z1, rgb[1], rgb[2], rgb[3], x2, y2, z2, rgb[1], rgb[2], rgb[3])
            end

            local rgb = RGB_BLUE

            local beta = data.alphaRad + 1 / 2
            local lineX = x + data.width * lineDirZ * beta
            local lineZ = z - data.width * lineDirX * beta

            drawHeadLandMarker(lineX, lineZ, lineZDir, -lineXDir)


            beta = data.alphaRad - 1 / 2
            lineX = x + data.width * lineDirZ * beta
            lineZ = z - data.width * lineDirX * beta

            drawHeadLandMarker(lineX, lineZ, -lineZDir, lineXDir)

        end



    end
end