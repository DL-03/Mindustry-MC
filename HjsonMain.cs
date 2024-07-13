using Godot;
using System;
using Hjson;

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
}
