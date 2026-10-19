extends Node

var csharp_script = preload("res://libs/ArchiveMain.cs").new()

func ExtracteToDirectory(ZipPath,extractPath):
	csharp_script.ExtracteToDirectory(ZipPath,extractPath)

func Pack(SourcePath, ArchivePath):
	csharp_script.Pack(SourcePath,ArchivePath)

func CreateFolder(Path):
	csharp_script.CreateFolder(Path)
