using Godot;
using System;

public partial class FileOperations : Node
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	
	public void rename(string Old, string New) 
	{
		System.IO.File.Move(Old, New); // Rename the file
	}
	public void Copy(string Old, string New) 
	{
		System.IO.File.Copy(Old, New); // Rename the file
		
	}
	public void Delete(string FilePath)
	{
		System.IO.File.Delete(FilePath); 
	}
}
