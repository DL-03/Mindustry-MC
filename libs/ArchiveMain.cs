using Godot;
using System;
using System.IO;
using System.IO.Compression;



public partial class ArchiveMain : Node
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	
	public void ExtracteToDirectory(string zipPath, string extractPath)
	{
		ZipFile.ExtractToDirectory(zipPath, extractPath);
	} 
	public void Pack(string zipPath, string extractPath)
	{
		if (File.Exists(extractPath))
		{
			File.Delete(extractPath);
		}
		ZipFile.CreateFromDirectory(zipPath, extractPath);
	} 
	public void CreateFolder(string Path) {
		
	}
}
