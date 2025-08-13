-- GLOBAL INIT
GAME_LIBS = {}

-- Function to read 32-bit integer from memory
function ReadInt32(addr)
    local from = {{address = addr, flags = 4}}
    local values = gg.getValues(from)
    if not values or not values[1] or not values[1].value then
        gg.alert("त्रुटि: मेमोरी पढ़ने में असफल - पता: " .. tostring(addr))
        return nil
    end
    return values[1].value
end

-- Function to convert number to hex string
function Num2HexStr(num, uppercase)
    if not num then return "0" end
    if not uppercase or uppercase == 0 then
        return string.format("%x", num)
    end
    return string.format("%X", num)
end

-- Check if string exists in table
function alreadyHave(compare_t, str)
    for _, element in ipairs(compare_t) do
        if element == str then
            return true
        end
    end
    return false
end

-- Get the last section of a library
function getLastSection(lib_name)
    local temp_t = gg.getRangesList("/data/*" .. lib_name)
    if not temp_t or #temp_t == 0 then
        gg.alert("त्रुटि: " .. lib_name .. " के लिए कोई मेमोरी सेक्शन नहीं मिला")
        return nil
    end
    return temp_t[#temp_t]['end'] - 1
end

-- Get sorted list of game libraries
function getSortedGameLibs()
    local return_t = {}
    local packageName = gg.getTargetInfo().packageName
    if not packageName then
        gg.alert("त्रुटि: टारगेट ऐप की जानकारी नहीं मिली")
        return {}
    end
    local lib_maps = gg.getRangesList("/data/*" .. packageName .. "*lib*.so")
    if not lib_maps or #lib_maps == 0 then
        gg.alert("त्रुटि: कोई लाइब्रेरी नहीं मिली")
        return {}
    end
    for _, element in ipairs(lib_maps) do
        if element.state == 'Xa' or element.state == 'Cd' then
            local org_name = element.internalName:match("lib[^/]+%.so$") or element.internalName
            if org_name and not alreadyHave(return_t, org_name) then
                local lastSec = getLastSection(org_name)
                if lastSec then
                    element.lastSec = lastSec
                    element.org_name = org_name
                    table.insert(GAME_LIBS, element)
                    table.insert(return_t, org_name)
                end
            end
        end
    end
    return return_t
end

-- Dump ELF file
function dumpELF(data)
    if not data or not data.start or not data.lastSec or not data.org_name then
        gg.alert("त्रुटि: अमान्य डेटा")
        return
    end

    -- Check ELF header
    local elfHeader = ReadInt32(data.start)
    if elfHeader ~= 1179403647 then
        gg.alert("त्रुटि: वैध ELF फाइल नहीं - पता: " .. Num2HexStr(data.start, 1))
        return
    end

    -- Use app's data directory for compatibility with Scoped Storage
    local packageName = gg.getTargetInfo().packageName
    local save_path = "/data/data/" .. packageName .. "/dump/"
    os.execute("mkdir -p " .. save_path) -- Create directory if it doesn't exist

    -- Dump memory
    local success = gg.dumpMemory(data.start, data.lastSec, save_path)
    if not success then
        gg.alert("त्रुटि: मेमोरी डंप करने में असफल")
        return
    end

    -- Rename dumped file
    local old_name = packageName .. "-" .. Num2HexStr(data.start) .. "-" .. Num2HexStr(data.lastSec + 1) .. ".bin"
    local new_name = "[" .. Num2HexStr(data.start, 1) .. "-" .. Num2HexStr(data.lastSec + 1, 1) .. "]_" .. data.org_name
    local rename_success = os.rename(save_path .. old_name, save_path .. new_name)
    if not rename_success then
        gg.alert("त्रुटि: फाइल का नाम बदलने में असफल")
        return
    end

    gg.alert("फाइल सेव की गई: " .. save_path .. new_name)
    print("स्क्रिप्ट का उपयोग करने के लिए धन्यवाद!")
end

-- Main entry point
function entrypoint()
    -- Create dump directory if it doesn't exist
    local packageName = gg.getTargetInfo().packageName
    if not packageName then
        gg.alert("त्रुटि: टारगेट ऐप की जानकारी नहीं मिली")
        os.exit()
    end
    local save_path = "/data/data/" .. packageName .. "/dump/"
    os.execute("mkdir -p " .. save_path)

    -- Get list of libraries
    local libs_t = getSortedGameLibs()
    if #libs_t == 0 then
        gg.alert("कोई लाइब्रेरी नहीं मिली!")
        os.exit()
    end

    -- Show menu to select library
    local point = gg.choice(libs_t, nil, "डंप करने के लिए लाइब्रेरी चुनें:")
    if not point then
        print("धन्यवाद! शुभ दिन!")
        os.exit()
    end

    -- Dump selected library
    dumpELF(GAME_LIBS[point])
end

-- Start the script
entrypoint()--set GAME_LIBS and return table of strings for UI
--in a sync order to GAME_LIBS
function getSortedGameLibs()
    local return_t = {}
    local lib_maps = gg.getRangesList(("/data/*" .. gg.getTargetInfo().packageName .. "*lib*.so"));       
    for index, element in ipairs(lib_maps) do
        if(element.state == 'Xa' or element.state == 'Cd') then
            org_name = element.internalName:match("/.*/(lib.*%.so)");
            if( not alreadyHave(return_t, org_name) ) then
                element.lastSec = getLastSection(org_name);
                element.org_name = org_name;
                table.insert(GAME_LIBS, element);
                table.insert(return_t, org_name);
            end
            
        end
    end --forloop end
    return return_t;
end

--Dump Elf file (libs)
function dumpELF(data)
    --checking elf header just in case
    if( ReadInt32(data.start) ~= 1179403647) then
        print("Something is wrong !")
        os.exit();
    end
    gg.dumpMemory(data.start, data.lastSec, '/sdcard/dump')
    local old_name = gg.getTargetInfo().packageName .. "-" .. Num2HexStr(data.start) .. "-" .. Num2HexStr(data.lastSec+1) .. ".bin";     
    local new_name = "[" .. Num2HexStr(data.start,1) .. "-" .. Num2HexStr(data.lastSec+1,1) .. "]_" .. data.org_name;
    local save_path = "/sdcard/dump/";
    os.rename((save_path .. old_name), (save_path .. new_name));
    
    gg.alert("Saved Loaction :" .. save_path .. new_name);
    print("Thanks For using the script !");
    os.exit();
end

function entrypoint()
    --show list of libs as menu
    libs_t = getSortedGameLibs();
    if(#libs_t ==0) then
        print("No libs found in this target!");
        os.exit()
    end
    point = gg.choice(libs_t , nil, 'Select Lib to Dump:')
    if not point then print("Thanks! have goood day!") os.exit() end;
    dumpELF(GAME_LIBS[point]);
end


entrypoint();
