local directory = g_currentModDirectory
local modName = g_currentModName

local function validateVehicleTypes(typeManager)
    print(typeManager.typeName)
    if typeManager.typeName == "vehicle" then
        print("guidance steering headland extention: start vehicleTypesValidation.")
        FrontBackControl.modName = modName

        for typeName, typeEntry in pairs(g_vehicleTypeManager:getTypes()) do 
            if SpecializationUtil.hasSpecialization(GlobalPositioningSystem, typeEntry.specializations) and
                not SpecializationUtil.hasSpecialization(HeadlandExt, typeEntry.specializations) then
                    typeManager:addSpecialization(typeName, modName .. ".HeadlandExt")
            end
        end
    end
end

local function init()
    print("guidance steering headland extention: started mod.")
    TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, validateVehicleTypes)
end

init()