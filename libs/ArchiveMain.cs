using Godot;
using System;
using System.ComponentModel;
using System.Diagnostics;
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
	
	public bool ExtracteToDirectory(string zipPath, string extractPath)
	{
		try
		{
			ZipFile.ExtractToDirectory(zipPath, extractPath);
			return true;
		}
		catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or InvalidDataException or ArgumentException)
		{
			GD.PushError($"Could not extract archive '{zipPath}': {ex.Message}");
			return false;
		}
	}

	public bool IsProcessRunning(int processId)
	{
		try
		{
			using Process process = Process.GetProcessById(processId);
			return !process.HasExited;
		}
		catch (ArgumentException)
		{
			return false;
		}
		catch (InvalidOperationException)
		{
			return false;
		}
		catch (Win32Exception)
		{
			return true;
		}
	}

	public bool RemoveDirectory(string path)
	{
		try
		{
			if (Directory.Exists(path))
				Directory.Delete(path, recursive: true);
			return true;
		}
		catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or ArgumentException)
		{
			GD.PushError($"Could not remove temporary directory '{path}': {ex.Message}");
			return false;
		}
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
