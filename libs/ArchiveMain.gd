extends Node

var csharp_script = preload("res://libs/ArchiveMain.cs").new()

func ExtracteToDirectory(ZipPath, extractPath) -> bool:
	return csharp_script.ExtracteToDirectory(ZipPath, extractPath)

func Pack(SourcePath, ArchivePath):
	csharp_script.Pack(SourcePath,ArchivePath)

func CreateFolder(Path):
	csharp_script.CreateFolder(Path)

func IsProcessRunning(processId: int) -> bool:
	return csharp_script.IsProcessRunning(processId)

func RemoveDirectory(path: String) -> bool:
	return csharp_script.RemoveDirectory(path)
