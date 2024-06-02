

HeadlandExt = {}

function HeadlandExt.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(GlobalPositioningSystem, specializations)
end

function GlobalPositioningSystem.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", GlobalPositioningSystem)
end

function GlobalPositioningSystem:onDraw()
    if not self.isClient
        or not self:getHasGuidanceSystem() then
        return
    end

    if g_currentMission.guidanceSteering:isShowGuidanceLinesEnabled() then
        
    end
end