extends Resource

class_name  SaveDataBasic

@export var data: Dictionary = {}

var extension: String = ".tres"
var savePath: String  = "user://save/"

func _init() -> void:
    data = {}

    data["DEBUG_OS_NAME"] = OS.get_name()
    data["DEBUG_OS_VERSION"] = OS.get_version()
    data["DEBUG_OS_LOCAL"] = OS.get_locale()
    data["DEBUG_OS_MODELNAME"] = OS.get_model_name()
    data["DEBUG_EXE_PATH"] = OS.get_executable_path()
    data["DEBUG_IS_DEBUG_BUILD"] = OS.is_debug_build()

#returns true if it loads an old save, false if it has to create a new save file
func Load(filename: String) -> bool:
    var newlyCreated: bool = false
    if(filename.get_extension().is_empty()):
        filename = "%s.%s" % [filename, extension]
    extension = ".tres"#filename.get_extension()
    savePath = UtilityHelper.GetCleanFileString(ResourceManager.GetPathToSave(), filename, extension)
    print("loading savefile: %s" % savePath)

    if(!FileAccess.file_exists(savePath)):
        if(!DirAccess.dir_exists_absolute(savePath.get_base_dir())):
            DirAccess.make_dir_recursive_absolute(savePath.get_base_dir())
        FileAccess.open(savePath, FileAccess.WRITE)
        ResourceManager.SaveResource(self, savePath)
        newlyCreated = true
        print("creating new save at: %s" % savePath)
    var newRes: SaveDataBasic = ResourceLoader.load(savePath)
    data = newRes.data.duplicate(true)

    return !newlyCreated

func Save() -> void:
    data["DEBUG_DATETIME"] = Time.get_datetime_dict_from_system()
    ResourceManager.SaveResource(self, savePath)
    #ResourceSaver.save(self, savePath)

func Get(dataKey: String, v: Variant) -> Variant:
    if(data.has(dataKey)):
        return data[dataKey]
    return v