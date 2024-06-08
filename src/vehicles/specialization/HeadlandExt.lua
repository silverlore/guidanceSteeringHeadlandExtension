

HeadlandExt = {}

local RGB_WHITE = { 1, 1, 1 }
local RGB_GREEN = { 0, 0.447871, 0.003697 }
local RGB_BLUE = { 0, 0, 1 }
local RGB_RED = { 1, 0, 0 }

function HeadlandExt.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FS22_guidanceSteering.GlobalPositioningSystem, specializations)
end

function HeadlandExt.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HeadlandExt)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", HeadlandExt)
end

function HeadlandExt:onLoad(savegame)
    print("guidance steering headland extention: Loaded specialization.")

    local spec = self["spec_" .. HeadlandExt.modName .. ".headlandExt"]

    spec.positivFieldBorder = nil
    spec.positivRightFieldBorder = nil
    spec.positivLeftFieldBorder = nil
    spec.negativFieldBorder = nil
    spec.negativRightFieldBorder = nil
    spec.negativLeftFieldBorder = nil
    

end

function HeadlandExt:onDraw()
    if not self.isClient
        or not self:getHasGuidanceSystem() then
            --print("guidance steering headland extention: No GuidanceSystem")
        return
    end

    if g_currentMission.guidanceSteering:isShowGuidanceLinesEnabled() then
        --print("guidance steering headland extention: GuidanceLines Enabled")
        local global_spec = self.spec_globalPositioningSystem
        -- draw(spec.guidanceData, spec.guidanceSteeringIsActive, spec.autoInvertOffset)

        local data = global_spec.guidanceData
        local drawHeadDistanceLines = data.isCreated
        if drawHeadDistanceLines then 

            local spec = self["spec_" .. HeadlandExt.modName .. ".headlandExt"]

            local x, _, z = unpack(data.driveTarget)
            local lineDirX, lineDirZ = unpack(data.snapDirection)

            local lineXDir = data.snapDirectionMultiplier * lineDirX
            local lineZDir = data.snapDirectionMultiplier * lineDirZ

            local lineOffset = g_currentMission.guidanceSteering:getLineOffset()

            local headlandDistance = global_spec.headlandActDistance

            local function drawHeadLandMarker( lx, lz, dirX, dirZ, rgb)

                local x1 = lx
                local z1 = lz
                local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + lineOffset

                local x2 = lx + dirX
                local z2 = lz + dirZ
                local y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + lineOffset

                drawDebugLine(x1, y1, z1, rgb[1], rgb[2], rgb[3], x2, y2, z2, rgb[1], rgb[2], rgb[3])
            end

            local color = RGB_BLUE

            local betaRight = data.alphaRad + 1 / 2
            local lineRightX = x + data.width * lineDirZ * betaRight
            local lineRightZ = z - data.width * lineDirX * betaRight

            drawHeadLandMarker(lineRightX, lineRightZ, lineZDir, -lineXDir, color)

            local lineRightHeadlandX = x + data.width * lineDirZ * betaRight - headlandDistance * lineXDir
            local lineRightHeadlandZ = z - data.width * lineDirX * betaRight + headlandDistance * lineZDir

            drawHeadLandMarker(lineRightHeadlandX, lineRightHeadlandZ, lineZDir, -lineXDir, color)
            
            local betaLeft = data.alphaRad - 1 / 2
            local lineLeftX = x + data.width * lineDirZ * betaLeft
            local lineLeftZ = z - data.width * lineDirX * betaLeft

            drawHeadLandMarker(lineLeftX, lineLeftZ, -lineZDir, lineXDir, color)

            local lineLeftHeadlandX = x + data.width * lineDirZ * betaLeft - headlandDistance * lineXDir
            local lineLeftHeadlandZ = z - data.width * lineDirX * betaLeft + headlandDistance * lineZDir

            drawHeadLandMarker(lineLeftHeadlandX, lineLeftHeadlandZ, -lineZDir, lineXDir, color)

            if spec.positivFieldBorder == nil then
                --print("Edge point is missing")
            
                local bits = getDensityAtWorldPos(g_currentMission.terrainDetailId, x, 0, z)
                local targetOnField = bits ~= 0

                if targetOnField then
                    --print("Target is on field")
                    local centerBorderDistance = HeadlandUtil.FindFieldEdge(x, z, lineDirX, lineDirZ, 1000)
                    if centerBorderDistance < 1000 then
                        spec.positivFieldBorder = {
                            x+(centerBorderDistance - headlandDistance)*lineDirX,
                            z-(centerBorderDistance - headlandDistance)*lineDirZ
                        }
                        --print("Edge found at " .. spec.positivFieldBorder[1] .. ";" .. spec.positivFieldBorder[2] )

                    end

                    local rightSideDistance = HeadlandUtil.FindFieldEdge(x, z, lineDirZ, lineDirX, data.width/2)
                    local rightSideX = x + rightSideDistance * lineDirZ
                    local rightSideZ = z - rightSideDistance * lineDirX
                    local rightBorderDistance = HeadlandUtil.FindFieldEdge(rightSideX, rightSideZ, lineDirX, lineDirZ, 1000)
                    if rightBorderDistance < 1000 then
                        spec.positivRightFieldBorder= {
                            rightSideX+(rightBorderDistance - headlandDistance)*lineDirX,
                            rightSideZ-(rightBorderDistance - headlandDistance)*lineDirZ
                        }

                        --print("Right Edge found at " .. spec.positivFieldBorder[1] .. ";" .. spec.positivFieldBorder[2] )
                    end

                    local leftSideDistance = HeadlandUtil.FindFieldEdge(x, z, -lineDirZ, -lineDirX, data.width/2)
                    local leftSideX = x - leftSideDistance * lineDirZ
                    local leftSideZ = z + leftSideDistance * lineDirX
                    local leftBorderDistance = HeadlandUtil.FindFieldEdge(leftSideX, leftSideZ, lineDirX, lineDirZ, 1000)
                    if rightBorderDistance < 1000 then
                        spec.positivLeftFieldBorder= {
                            leftSideX+(leftBorderDistance - headlandDistance)*lineDirX,
                            leftSideZ-(leftBorderDistance - headlandDistance)*lineDirZ
                        }

                        --print("Right Edge found at " .. spec.positivFieldBorder[1] .. ";" .. spec.positivFieldBorder[2] )
                    end
                else
                    --print("Target is not on field")
                end

            end

            if spec.positivFieldBorder ~= nil then
                drawHeadLandMarker(spec.positivFieldBorder[1], spec.positivFieldBorder[2], -lineDirZ, lineDirX, RGB_RED)
                drawHeadLandMarker(spec.positivFieldBorder[1], spec.positivFieldBorder[2], lineDirZ, -lineDirX, RGB_RED)
            end

            if spec.positivRightFieldBorder ~= nil then
                drawHeadLandMarker(spec.positivRightFieldBorder[1], spec.positivRightFieldBorder[2], lineDirZ, -lineDirX, { 1, 1, 0 })
            end

            if spec.positivLeftFieldBorder ~= nil then
                drawHeadLandMarker(spec.positivLeftFieldBorder[1], spec.positivLeftFieldBorder[2], -lineDirZ, lineDirX, { 0, 1, 1 })
            end

        end
    end

end