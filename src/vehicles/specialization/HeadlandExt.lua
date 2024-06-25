

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
    spec.lastHeadlandDistance = nil
    spec.lastlaneWidth = nil
    spec.lastSnapDirection = nil
    spec.lastLane = nil


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
            local lineDirX, lineDirZ, lineX, lineZ = unpack(data.snapDirection)

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

            local lineRightHeadlandX = x + data.width * lineDirZ * betaRight + headlandDistance * lineXDir
            local lineRightHeadlandZ = z - data.width * lineDirX * betaRight + headlandDistance * lineZDir

            drawHeadLandMarker(lineRightHeadlandX, lineRightHeadlandZ, lineZDir, -lineXDir, color)
            
            local betaLeft = data.alphaRad - 1 / 2
            local lineLeftX = x + data.width * lineDirZ * betaLeft
            local lineLeftZ = z - data.width * lineDirX * betaLeft

            drawHeadLandMarker(lineLeftX, lineLeftZ, -lineZDir, lineXDir, color)

            local lineLeftHeadlandX = x + data.width * lineDirZ * betaLeft + headlandDistance * lineXDir
            local lineLeftHeadlandZ = z - data.width * lineDirX * betaLeft + headlandDistance * lineZDir

            drawHeadLandMarker(lineLeftHeadlandX, lineLeftHeadlandZ, -lineZDir, lineXDir, color)

            if (spec.lastHeadlandDistance ~= nil and spec.lastHeadlandDistance ~= headlandDistance)
            then
                --print("Resetting field border lastHeadland distance")
                spec.positivFieldBorder = nil
                spec.negativFieldBorder = nil
            end

            if (spec.lastlaneWidth ~= nil and spec.lastlaneWidth ~= data.width)
            then
                --print("Resetting field border lastLaneWidth")
                spec.positivFieldBorder = nil
                spec.negativFieldBorder = nil
            end

            if spec.lastSnapDirection ~= nil and (
                    spec.lastSnapDirection[1] ~= lineDirX or 
                    spec.lastSnapDirection[2] ~= lineDirZ or
                    spec.lastSnapDirection[3] ~= lineX or
                    spec.lastSnapDirection[4] ~= lineZ) 
            then
                --print("Resetting field border base on snap")
                spec.positivFieldBorder = nil
                spec.negativFieldBorder = nil
            end

            if spec.lastLane ~= nil and spec.lastLane ~= data.currentLane then
                --print("Resetting field border base on Lane")
                spec.positivFieldBorder = nil
                spec.negativFieldBorder = nil
            end

            spec.lastHeadlandDistance = headlandDistance
            spec.lastlaneWidth = data.width
            spec.lastSnapDirection = {lineDirX, lineDirZ, lineX, lineZ}
            spec.lastLane = data.currentLane

            local targetLineX = x + data.width * lineDirZ * data.alphaRad
            local targetLineZ = z - data.width * lineDirX * data.alphaRad

            if data.alphaRad > -0.5 and data.alphaRad < 0.5 then

                if spec.positivFieldBorder == nil then
                    --print("Edge point is missing")

                    local bits = getDensityAtWorldPos(g_currentMission.terrainDetailId, targetLineX, 0, targetLineZ)
                    local targetOnField = bits ~= 0

                    if targetOnField then
                        --print("Target is on field")
                        local centerBorderDistance = HeadlandUtil.FindFieldEdge(targetLineX, targetLineZ, lineDirX, lineDirZ, 1000)
                        if centerBorderDistance < 1000 then
                            spec.positivFieldBorder = {
                                targetLineX+(centerBorderDistance - headlandDistance)*lineDirX,
                                targetLineZ-(centerBorderDistance - headlandDistance)*lineDirZ
                            }
                            --print("Edge found at " .. spec.positivFieldBorder[1] .. ";" .. spec.positivFieldBorder[2] )

                        end

                        local rightSideDistance = HeadlandUtil.FindFieldEdge(targetLineX, targetLineZ, lineDirZ, lineDirX, data.width/2)
                        local rightSideX = targetLineX + rightSideDistance * lineDirZ
                        local rightSideZ = targetLineZ - rightSideDistance * lineDirX
                        local rightBorderDistance = HeadlandUtil.FindFieldEdge(rightSideX, rightSideZ, lineDirX, lineDirZ, 1000)
                        if rightBorderDistance < 1000 then
                            spec.positivRightFieldBorder= {
                                rightSideX+(rightBorderDistance - headlandDistance)*lineDirX,
                                rightSideZ-(rightBorderDistance - headlandDistance)*lineDirZ
                            }

                            --print("Right Edge found at " .. spec.positivFieldBorder[1] .. ";" .. spec.positivFieldBorder[2] )
                        end

                        local leftSideDistance = HeadlandUtil.FindFieldEdge(targetLineX, targetLineZ, -lineDirZ, -lineDirX, data.width/2)
                        local leftSideX = targetLineX - leftSideDistance * lineDirZ
                        local leftSideZ = targetLineZ + leftSideDistance * lineDirX
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

                if spec.negativFieldBorder == nil then
                    --print("Edge point is missing")

                    local bits = getDensityAtWorldPos(g_currentMission.terrainDetailId, targetLineX, 0, targetLineZ)
                    local targetOnField = bits ~= 0

                    if targetOnField then
                        --print("Target is on field")
                        local centerBorderDistance = HeadlandUtil.FindFieldEdge(targetLineX, targetLineZ, -lineDirX, -lineDirZ, 1000)
                        if centerBorderDistance < 1000 then
                            spec.negativFieldBorder = {
                                targetLineX-(centerBorderDistance - headlandDistance)*lineDirX,
                                targetLineZ+(centerBorderDistance - headlandDistance)*lineDirZ
                            }
                            --print("Edge found at " .. spec.positivFieldBorder[1] .. ";" .. spec.positivFieldBorder[2] )

                        end

                        local rightSideDistance = HeadlandUtil.FindFieldEdge(targetLineX, targetLineZ, lineDirZ, lineDirX, data.width/2)
                        local rightSideX = targetLineX + rightSideDistance * lineDirZ
                        local rightSideZ = targetLineZ - rightSideDistance * lineDirX
                        local rightBorderDistance = HeadlandUtil.FindFieldEdge(rightSideX, rightSideZ, -lineDirX, -lineDirZ, 1000)
                        if rightBorderDistance < 1000 then
                            spec.negativRightFieldBorder= {
                                rightSideX-(rightBorderDistance - headlandDistance)*lineDirX,
                                rightSideZ+(rightBorderDistance - headlandDistance)*lineDirZ
                            }

                            --print("Right Edge found at " .. spec.positivFieldBorder[1] .. ";" .. spec.positivFieldBorder[2] )
                        end

                        local leftSideDistance = HeadlandUtil.FindFieldEdge(targetLineX, targetLineZ, -lineDirZ, -lineDirX, data.width/2)
                        local leftSideX = targetLineX - leftSideDistance * lineDirZ
                        local leftSideZ = targetLineZ + leftSideDistance * lineDirX
                        local leftBorderDistance = HeadlandUtil.FindFieldEdge(leftSideX, leftSideZ, -lineDirX, -lineDirZ, 1000)
                        if rightBorderDistance < 1000 then
                            spec.negativLeftFieldBorder= {
                                leftSideX-(leftBorderDistance - headlandDistance)*lineDirX,
                                leftSideZ+(leftBorderDistance - headlandDistance)*lineDirZ
                            }

                            --print("Right Edge found at " .. spec.positivFieldBorder[1] .. ";" .. spec.positivFieldBorder[2] )
                        end
                    else
                        --print("Target is not on field")
                    end

                end
            end

            local function DrawSegmentedLine(x1, z1, x2, z2, rgb, steps, currentStep)
                if steps == nil then
                    steps = 10
                end
                if currentStep == nil then
                    currentStep = 0;
                end

                --print("steps: " .. steps .. " currentStep: " .. currentStep)
                if currentStep > steps then
                    return
                end

                local directX = (x2-x1)/(steps*2)
                local directZ = (z2-z1)/(steps*2)

                local px1 = x1 + directX * currentStep * 2
                local pz1 = z1 + directZ * currentStep * 2
                local py1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, px1, 0, pz1) + lineOffset

                local px2 = x1 + directX * ((currentStep * 2)+1)
                local pz2 = z1 + directZ * ((currentStep * 2)+1)
                local py2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, px2, 0, pz2) + lineOffset

                drawDebugLine(px1, py1, pz1, rgb[1], rgb[2], rgb[3], px2, py2, pz2, rgb[1], rgb[2], rgb[3])

                DrawSegmentedLine(x1, z1, x2, z2, rgb, steps, currentStep + 1)
            end

            -- if spec.positivLeftFieldBorder ~= nil then
            --     drawHeadLandMarker(spec.positivLeftFieldBorder[1], spec.positivLeftFieldBorder[2], -lineDirZ, lineDirX, { 0, 1, 1 })
            -- end

            -- if spec.positivFieldBorder ~= nil then
            --     drawHeadLandMarker(spec.positivFieldBorder[1], spec.positivFieldBorder[2], -lineDirZ, lineDirX, RGB_RED)
            --     drawHeadLandMarker(spec.positivFieldBorder[1], spec.positivFieldBorder[2], lineDirZ, -lineDirX, RGB_RED)
            -- end

            -- if spec.positivRightFieldBorder ~= nil then
            --     drawHeadLandMarker(spec.positivRightFieldBorder[1], spec.positivRightFieldBorder[2], lineDirZ, -lineDirX, { 1, 1, 0 })
            -- end

            -- if spec.negativLeftFieldBorder ~= nil then
            --     drawHeadLandMarker(spec.negativLeftFieldBorder[1], spec.negativLeftFieldBorder[2], -lineDirZ, lineDirX, { 0, 1, 1 })
            -- end

            -- if spec.negativFieldBorder ~= nil then
            --     drawHeadLandMarker(spec.negativFieldBorder[1], spec.negativFieldBorder[2], -lineDirZ, lineDirX, RGB_RED)
            --     drawHeadLandMarker(spec.negativFieldBorder[1], spec.negativFieldBorder[2], lineDirZ, -lineDirX, RGB_RED)
            -- end

            -- if spec.negativRightFieldBorder ~= nil then
            --     drawHeadLandMarker(spec.negativRightFieldBorder[1], spec.negativRightFieldBorder[2], lineDirZ, -lineDirX, { 1, 1, 0 })
            -- end
            
            if spec.positivLeftFieldBorder ~= nil and spec.positivFieldBorder ~= nil then
                local length = 0;
                if lineDirX == 0 then
                    local borderVectorZ = targetLineZ - spec.positivFieldBorder[2]
                    length = borderVectorZ / lineDirZ
                else
                    local borderVectorX = targetLineX - spec.positivFieldBorder[1]
                    length = borderVectorX / lineDirX
                end
                if math.abs(length) < (headlandDistance + 5) then
                    DrawSegmentedLine(spec.positivLeftFieldBorder[1], spec.positivLeftFieldBorder[2], spec.positivFieldBorder[1], spec.positivFieldBorder[2], RGB_BLUE)
                end
            end
            
            if spec.positivFieldBorder ~= nil and spec.positivRightFieldBorder ~= nil then
                local length = 0;
                if lineDirX == 0 then
                    local borderVectorZ = targetLineZ - spec.positivFieldBorder[2]
                    length = borderVectorZ / lineDirZ
                else
                    local borderVectorX = targetLineX - spec.positivFieldBorder[1]
                    length = borderVectorX / lineDirX
                end
                if math.abs(length) < (headlandDistance + 5) then
                    DrawSegmentedLine(spec.positivFieldBorder[1], spec.positivFieldBorder[2], spec.positivRightFieldBorder[1], spec.positivRightFieldBorder[2], RGB_BLUE)
                end
            end

            if spec.negativLeftFieldBorder ~= nil and spec.negativFieldBorder ~= nil then
                local length = 0;
                if lineDirX == 0 then
                    local borderVectorZ = targetLineZ - spec.negativFieldBorder[2]
                    length = borderVectorZ / lineDirZ
                else
                    local borderVectorX = targetLineX - spec.negativFieldBorder[1]
                    length = borderVectorX / lineDirX
                end
                if math.abs(length) < (headlandDistance + 5) then
                    DrawSegmentedLine(spec.negativLeftFieldBorder[1], spec.negativLeftFieldBorder[2], spec.negativFieldBorder[1], spec.negativFieldBorder[2], RGB_BLUE)
                end
            end
            
            if spec.negativFieldBorder ~= nil and spec.negativRightFieldBorder ~= nil then
                local length = 0;
                if lineDirX == 0 then
                    local borderVectorZ = targetLineZ - spec.negativFieldBorder[2]
                    length = borderVectorZ / lineDirZ
                else
                    local borderVectorX = targetLineX - spec.negativFieldBorder[1]
                    length = borderVectorX / lineDirX
                end
                if math.abs(length) < (headlandDistance + 5) then
                    DrawSegmentedLine(spec.negativFieldBorder[1], spec.negativFieldBorder[2], spec.negativRightFieldBorder[1], spec.negativRightFieldBorder[2], RGB_BLUE)
                end
            end
        end
    end

end