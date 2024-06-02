local directory = g_currentModDirectory
local modName = g_currentModName

local function validateVehicleTypes(typeManager)

    -- for specializationName, spec in pairs(g_specializationManager:getSpecializations()) do
    --     print(specializationName .. " -> " .. spec.className)
    -- end

    print(typeManager.typeName)
    if typeManager.typeName == "vehicle" then
        print("guidance steering headland extention: start vehicleTypesValidation.")
        HeadlandExt.modName = modName

        for typeName, typeEntry in pairs(g_vehicleTypeManager:getTypes()) do 
            if SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) and
                not SpecializationUtil.hasSpecialization(SplineVehicle, typeEntry.specializations) and
                not SpecializationUtil.hasSpecialization(HeadlandExt, typeEntry.specializations) then
                    typeManager:addSpecialization(typeName, modName .. ".headlandExt")
            end
        end
    end
end

local function init()
    print("guidance steering headland extention: started mod.")
    TypeManager.validateTypes = Utils.appendedFunction(TypeManager.validateTypes, validateVehicleTypes)
end

init()