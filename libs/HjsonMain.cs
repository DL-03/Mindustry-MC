using Godot;
using System;
using System.Linq;
using Hjson;
using System.Text.Json;

public partial class HjsonMain : Node
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
	
	

	

	public string parse_string(String text)
	{
		var jsonObject = HjsonValue.Parse(text).Qo();
		return jsonObject.ToString();
		
	}
	public Godot.Collections.Dictionary try_parse_string(String text)
	{
		try
		{
			var jsonObject = HjsonValue.Parse(text).Qo();
			return new Godot.Collections.Dictionary
			{
				["success"] = true,
				["json"] = jsonObject.ToString()
			};
		}
		catch (Exception exception)
		{
			return new Godot.Collections.Dictionary
			{
				["success"] = false,
				["error"] = exception.Message
			};
		}
	}

	public Godot.Collections.Dictionary merge_and_stringify(
		String originalText,
		String updatedJson,
		bool preserveWhitespaceAndComments
	)
	{
		try
		{
			var sourceOptions = new HjsonOptions
			{
				KeepWsc = preserveWhitespaceAndComments
			};
			var original = HjsonValue.Parse(originalText, sourceOptions);
			var updated = HjsonValue.Parse(updatedJson);
			if (original.JsonType != JsonType.Object || updated.JsonType != JsonType.Object)
			{
				return new Godot.Collections.Dictionary
				{
					["success"] = false,
					["error"] = "Both source and updated content must be objects."
				};
			}

			var merged = (JsonObject)MergePreservingStructure(original, updated);
			var serialized = preserveWhitespaceAndComments
				? merged.ToString(sourceOptions)
				: merged.ToString(Stringify.Formatted);
			return new Godot.Collections.Dictionary
			{
				["success"] = true,
				["text"] = serialized
			};
		}
		catch (Exception exception)
		{
			return new Godot.Collections.Dictionary
			{
				["success"] = false,
				["error"] = exception.Message
			};
		}
	}

	private static JsonValue MergePreservingStructure(JsonValue original, JsonValue updated)
	{
		if (original.JsonType != updated.JsonType)
			return updated;

		if (original.JsonType == JsonType.Object)
		{
			var originalObject = (JsonObject)original;
			var updatedObject = (JsonObject)updated;
			foreach (var key in originalObject.Keys.ToList())
			{
				if (updatedObject.ContainsKey(key))
					continue;

				originalObject.Remove(key);
				if (originalObject is WscJsonObject formattedObject)
				{
					formattedObject.Order.Remove(key);
					formattedObject.Comments.Remove(key);
				}
			}

			foreach (var key in updatedObject.Keys)
			{
				if (originalObject.ContainsKey(key))
				{
					originalObject[key] = MergePreservingStructure(
						originalObject[key],
						updatedObject[key]
					);
				}
				else
				{
					originalObject.Add(key, updatedObject[key]);
				}
			}
			return originalObject;
		}

		if (original.JsonType == JsonType.Array)
		{
			var originalArray = (JsonArray)original;
			var updatedArray = (JsonArray)updated;
			var sharedCount = Math.Min(originalArray.Count, updatedArray.Count);
			for (var index = 0; index < sharedCount; index++)
			{
				originalArray[index] = MergePreservingStructure(
					originalArray[index],
					updatedArray[index]
				);
			}

			while (originalArray.Count > updatedArray.Count)
				originalArray.RemoveAt(originalArray.Count - 1);
			for (var index = originalArray.Count; index < updatedArray.Count; index++)
				originalArray.Add(updatedArray[index]);

			if (originalArray is WscJsonArray formattedArray)
			{
				while (formattedArray.Comments.Count > originalArray.Count + 1)
					formattedArray.Comments.RemoveAt(formattedArray.Comments.Count - 1);
				while (formattedArray.Comments.Count < originalArray.Count + 1)
					formattedArray.Comments.Add("");
			}
			return originalArray;
		}

		return updated;
	}

	public string stringify(String text) {
		var jsonObject = HjsonValue.Parse(text);
		return jsonObject.ToString(Stringify.Plain);
	}
}
