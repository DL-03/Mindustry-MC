using Godot;
using System;
using System.IO;

[GlobalClass]
public partial class CustomFileWatcher : Node
{
	[Signal]
	public delegate void OnCreatedEventHandler(string filePath);
	[Signal]
	public delegate void OnChangedEventHandler(string filePath);
	[Signal]
	public delegate void OnDeletedEventHandler(string filePath);
	[Signal]
	public delegate void OnRenamedEventHandler(string oldFilePath, string newFilePath);
	[Signal]
	public delegate void OnErrorEventHandler(string errorMessage);

	public string WatchedPath { get; private set; } = string.Empty;
	
	private FileSystemWatcher? _watcher;

	/// <summary>
	/// Устанавливает или обновляет отслеживаемый путь.
	/// Поддерживает форматы Godot (res://, user://) и стандартные пути ОС.
	/// </summary>
	public void setPath(string path)
	{
		StopWatcher();

		if (string.IsNullOrWhiteSpace(path))
			return;

		// Преобразуем res:// или user:// в реальный абсолютный путь ОС
		string globalPath = ProjectSettings.GlobalizePath(path);

		if (!Directory.Exists(globalPath))
		{
			GD.PrintErr($"[CustomFileWatcher] Директория не существует: {globalPath}");
			return;
		}

		WatchedPath = globalPath;

		try
		{
			_watcher = new FileSystemWatcher(WatchedPath)
			{
				// Исключаем LastAccess, чтобы не спамить событиями при каждом чтении файлов
				NotifyFilter = NotifyFilters.FileName
							 | NotifyFilters.DirectoryName
							 | NotifyFilters.LastWrite
							 | NotifyFilters.CreationTime
							 | NotifyFilters.Size,
				Filter = "*",
				IncludeSubdirectories = true,
				EnableRaisingEvents = true
			};

			_watcher.Changed += _OnChanged;
			_watcher.Created += _OnCreated;
			_watcher.Deleted += _OnDeleted;
			_watcher.Renamed += _OnRenamed;
			_watcher.Error += _OnError;
		}
		catch (Exception ex)
		{
			GD.PrintErr($"[CustomFileWatcher] Ошибка инициализации watcher: {ex.Message}");
		}
	}

	/// <summary>
	/// Очистка ресурсов при удалении ноды из дерева сцены.
	/// </summary>
	public override void _ExitTree()
	{
		StopWatcher();
		base._ExitTree();
	}

	private void StopWatcher()
	{
		if (_watcher != null)
		{
			_watcher.EnableRaisingEvents = false;
			_watcher.Changed -= _OnChanged;
			_watcher.Created -= _OnCreated;
			_watcher.Deleted -= _OnDeleted;
			_watcher.Renamed -= _OnRenamed;
			_watcher.Error -= _OnError;
			_watcher.Dispose();
			_watcher = null;
		}
	}

	private void _OnChanged(object sender, FileSystemEventArgs e)
	{
		if (e.ChangeType != WatcherChangeTypes.Changed)
			return;

		string fullPath = e.FullPath;
		Callable.From(() => EmitSignal(SignalName.OnChanged, fullPath)).CallDeferred();
	}

	private void _OnCreated(object sender, FileSystemEventArgs e)
	{
		string fullPath = e.FullPath;
		Callable.From(() => EmitSignal(SignalName.OnCreated, fullPath)).CallDeferred();
	}

	private void _OnDeleted(object sender, FileSystemEventArgs e)
	{
		string fullPath = e.FullPath;
		Callable.From(() => EmitSignal(SignalName.OnDeleted, fullPath)).CallDeferred();
	}

	private void _OnRenamed(object sender, RenamedEventArgs e)
	{
		string oldPath = e.OldFullPath;
		string newPath = e.FullPath;
		Callable.From(() => EmitSignal(SignalName.OnRenamed, oldPath, newPath)).CallDeferred();
	}

	private void _OnError(object sender, ErrorEventArgs e)
	{
		Exception? ex = e.GetException();
		string message = ex?.Message ?? "Неизвестная ошибка FileSystemWatcher";
		
		GD.PrintErr($"[CustomFileWatcher] Ошибка: {message}");
		if (ex?.StackTrace != null)
		{
			GD.PrintErr(ex.StackTrace);
		}

		Callable.From(() => EmitSignal(SignalName.OnError, message)).CallDeferred();
	}
}
