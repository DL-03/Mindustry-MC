using Godot;
using System;
using System.IO;
//using System.IO.SystemFileWatcher;







public partial class CustomFileWathcer : Node
{
	public string NormalizePath(string path)
	{
	return Path.GetFullPath(new Uri(path).LocalPath)
		.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
	}
	
	
	
	public string path = "";
	
	
	public FileSystemWatcher watcher;

	
	[Signal]
	public delegate void OnCreatedEventHandler(string filePath);
	[Signal]
	public delegate void OnChangedEventHandler(string filePath);
	[Signal]
	public delegate void OnDeletedEventHandler(string filePath);
	[Signal]
	public delegate void OnRenamedEventHandler(string oldFilePath,string newFilePath);
	[Signal]
	public delegate void OnErrorEventHandler(string filePath);
	
	public void setPath(string _path) {
		
		if (watcher==null) {
			watcher = new FileSystemWatcher(_path);
			path = _path;

			
			watcher.NotifyFilter = NotifyFilters.Attributes
									| NotifyFilters.CreationTime
									| NotifyFilters.DirectoryName
									| NotifyFilters.FileName
									| NotifyFilters.LastAccess
									| NotifyFilters.LastWrite
									| NotifyFilters.Security
									| NotifyFilters.Size;

			watcher.Changed += _OnChanged;
			watcher.Created += _OnCreated;
			watcher.Deleted += _OnDeleted;
			watcher.Renamed += _OnRenamed;
			watcher.Error += _OnError;

			watcher.Filter = "*";
			watcher.IncludeSubdirectories = true;
			watcher.EnableRaisingEvents = true;
		}
		
		
	}
	
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
//.Dispose();

		
		

	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	
	private void _OnChanged(object sender, FileSystemEventArgs e)
		{
			if (e.ChangeType != WatcherChangeTypes.Changed)
			{
				return;
			}
			Callable.From(() => EmitSignal(CustomFileWathcer.SignalName.OnChanged,Variant.CreateFrom(e.FullPath))).CallDeferred();
			//EmitSignal(SignalName._OnChanged, e.FullPath);
		}

		private void _OnCreated(object sender, FileSystemEventArgs e)
		{
			Callable.From(() => EmitSignal(CustomFileWathcer.SignalName.OnCreated,Variant.CreateFrom(e.FullPath))).CallDeferred();
		}

		private void _OnDeleted(object sender, FileSystemEventArgs e) {
			Callable.From(() => EmitSignal(CustomFileWathcer.SignalName.OnDeleted,Variant.CreateFrom(e.FullPath))).CallDeferred();
		}
		private void _OnRenamed(object sender, RenamedEventArgs e)
		{

			Callable.From(() => EmitSignal(CustomFileWathcer.SignalName.OnRenamed,e.OldFullPath,e.FullPath)).CallDeferred();
			//EmitSignal(SignalName._OnRenamed, e.OldFullPath,e.FullPath);
	
		}

		private void _OnError(object sender, ErrorEventArgs e) =>
			PrintException(e.GetException());

		private void PrintException(Exception? ex)
		{
			if (ex != null)
			{
				Console.WriteLine($"Message: {ex.Message}");
				Console.WriteLine("Stacktrace:");
				Console.WriteLine(ex.StackTrace);
				Console.WriteLine();
				PrintException(ex.InnerException);
				//EmitSignal(SignalName._OnError, ex.Message);
			}
		}
}
