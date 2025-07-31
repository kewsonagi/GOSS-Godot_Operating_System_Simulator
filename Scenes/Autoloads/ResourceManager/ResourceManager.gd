extends Node
class_name ResourceManager

class ResourceHolder:
	var refs: int
	var index: int
	var path: String
	var resource: Resource

	func _init(res: Resource, indx: int):
		resource = res
		refs = 0
		path = res.resource_path
		index = indx

	func GetResource() -> Resource:
		refs += 1
		if (!resource):
			resource = ResourceLoader.load(path)
		return resource

	func ReturnResource() -> void:
		refs -= 1
		if (refs > 0): return
		Unload(true)

	func Unload(force: bool) -> void:
		if (refs < 1 and !force): return
		if (resource):
			#resource.free()
			resource = null
		refs = 0


# static var instance: ResourceManager = null

static var registeredAssets: Dictionary
static var registeredAssetsByResource: Dictionary
static var assetList: Array[ResourceHolder]

static func RegisterResource(key: String, resource: Resource) -> void:
	if (!registeredAssets.has(key)):
		#if this item is already registered under a different name, assign it that index and dont make a new one
		if (registeredAssetsByResource.has(resource.resource_path)):
			registeredAssets[key] = registeredAssetsByResource[resource.resource_path]
			return

		assetList.append(ResourceHolder.new(resource, assetList.size()))
		registeredAssets[key] = assetList.size() - 1
		registeredAssetsByResource[resource.resource_path] = assetList.size() - 1

static func GetResource(key: String) -> Resource:
	var indx: int = 0
	if(registeredAssets.has(key)):
		indx = registeredAssets[key]
	return assetList[indx].GetResource()

static func ReturnResourceByResource(res: Resource) -> void:
	if(!res):
		return
	if(registeredAssetsByResource.has(res.resource_path)):
		var indx: int = registeredAssetsByResource[res.resource_path]
		assetList[indx].ReturnResource()

static func ReturnResource(key: String) -> void:
	var indx: int = 0
	if(registeredAssets.has(key)):
		indx = registeredAssets[key]
	assetList[indx].ReturnResource()

static func DeregisterResource(key: String) -> void:
	if (registeredAssets.has(key)):
		var indx: int = registeredAssets[key]
		registeredAssets.erase(key)
		assetList[indx].Unload(false)

		#registeredAssetsByResource.erase(assetList[indx].resource.resource_path)

static func DeregisterResourceByResource(resource: Resource) -> void:
	if (registeredAssetsByResource.has(resource.resource_path)):
		var indx: int = registeredAssetsByResource[resource.resource_pathkey]
		assetList[indx].Unload(false)
