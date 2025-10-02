using Godot;
using System;
using System.Collections.Generic;

public partial class Map : Node3D
{
	private MeshInstance3D _level1Marker;
	private MeshInstance3D _level2Marker;
	private Camera3D _mapCamera;
	private Vector3 _initialCameraPosition = new Vector3(0, 300, 0);
	private Vector3 _targetCameraPosition = new Vector3(-147.491f, 16.461f, 29.413f);
	private Vector3 _level2CameraPosition = new Vector3(50f, 16.461f, -50f);
	private Vector3 _targetCameraRotation; // Initialized in _Ready
	private bool _isCameraMovingAutomatically = true;
	private float _cameraMoveSpeed = 0.5f;
	private float _cameraZoomSpeed = 2.0f;
	private int _currentLevelIndex = 0; // Tracks which level's position the camera is currently moving towards

	private List<Dictionary<string, object>> _levels = new List<Dictionary<string, object>>
	{
		new Dictionary<string, object>
		{
			{ "Name", "Palembang" },
			{ "Recipe", "Pempek" },
			{ "ScenePath", "res://Scenes/Levels/Level1.tscn" },
			{ "TimeLimit", 300f } // 5 minutes
		},
		new Dictionary<string, object>
		{
			{ "Name", "Bangka" },
			{ "Recipe", "LempahKuning" },
			{ "ScenePath", "res://Scenes/Levels/Level2.tscn" },
			{ "TimeLimit", 400f } // Example time limit
		}
	};

	private GameManager _gameManager; // Reference to GameManager

	public override void _Ready()
	{
		_level1Marker = GetNode<MeshInstance3D>("Level1Marker");
		_level2Marker = GetNodeOrNull<MeshInstance3D>("Level2Marker"); // Null check in case Level2Marker doesn't exist yet
		_mapCamera = GetNode<Camera3D>("MapCamera");
		_gameManager = GetTree().Root.GetNodeOrNull<GameManager>("/root/GameManager");
		if (_gameManager == null) GD.PrintErr("GameManager not found in Map!");

		float degToRad = (float)(Math.PI / 180);
		_targetCameraRotation = new Vector3(0, 19.4f * degToRad, 0); // Example target rotation

		_mapCamera.GlobalPosition = _initialCameraPosition;
		_mapCamera.Rotation = new Vector3(-(float)Math.PI / 2, 0, 0); // Look straight down initially

		SetupMarkerInteraction(_level1Marker, () => OnLevelPressed(0));
		if (_level2Marker != null)
		{
			SetupMarkerInteraction(_level2Marker, () => OnLevelPressed(1));
		}
		UpdateMarkers(); // Update marker visibility based on unlock status
	}

	public override void _Process(double delta)
	{
		HandleUserInput();

		if (_isCameraMovingAutomatically)
		{
			Vector3 targetPos = _currentLevelIndex == 0 ? _targetCameraPosition : _level2CameraPosition;
			_mapCamera.GlobalPosition = _mapCamera.GlobalPosition.Lerp(targetPos, (float)delta * _cameraMoveSpeed);
			
			// For camera rotation, you might want to lerp Euler angles directly or use a Quat for smooth interpolation
			// This is a simple lerp that might have issues with wrapping angles (e.g., 350 to 10 degrees)
			_mapCamera.Rotation = new Vector3(
				Mathf.Lerp(_mapCamera.Rotation.X, _targetCameraRotation.X, (float)delta * _cameraMoveSpeed),
				LerpAngle(_mapCamera.Rotation.Y, _targetCameraRotation.Y, (float)delta * _cameraMoveSpeed),
				Mathf.Lerp(_mapCamera.Rotation.Z, _targetCameraRotation.Z, (float)delta * _cameraMoveSpeed)
			);

			// Stop auto-movement if close enough to target
			if (_mapCamera.GlobalPosition.DistanceTo(targetPos) < 0.1f &&
				Mathf.Abs(LerpAngle(_mapCamera.Rotation.Y, _targetCameraRotation.Y, 1.0f)) < 0.01f) // Check rotation as well
			{
				_isCameraMovingAutomatically = false;
			}
		}
	}

	// Helper function for smooth angle interpolation (handles wrap-around)
	private float LerpAngle(float from, float to, float t)
	{
		from = Mathf.Wrap(from, -(float)Math.PI, (float)Math.PI);
		to = Mathf.Wrap(to, -(float)Math.PI, (float)Math.PI);
		float delta = to - from;
		if (delta > (float)Math.PI) delta -= (float)(2 * Math.PI);
		else if (delta < -(float)Math.PI) delta += (float)(2 * Math.PI);
		return from + delta * t;
	}

	private void HandleUserInput()
	{
		// Disable auto-movement if player tries to control camera
		if (Input.IsActionJustPressed("ui_scroll_up") || Input.IsActionJustPressed("ui_scroll_down") ||
			Input.IsActionPressed("left") || Input.IsActionPressed("right") ||
			Input.IsActionPressed("forward") || Input.IsActionPressed("backward"))
		{
			_isCameraMovingAutomatically = false;
		}

		// Camera zoom
		if (Input.IsActionJustPressed("ui_scroll_up"))
		{
			_mapCamera.GlobalPosition -= new Vector3(0, _cameraZoomSpeed, 0);
		}
		if (Input.IsActionJustPressed("ui_scroll_down") && _mapCamera.GlobalPosition.Y >= 0)
		{
			_mapCamera.GlobalPosition += new Vector3(0, _cameraZoomSpeed, 0);
		}

		// Camera pan (using player movement actions for simplicity)
		float panSpeed = 10.0f;
		Vector3 panDirection = Vector3.Zero;
		if (Input.IsActionPressed("left")) panDirection.X -= 1;
		if (Input.IsActionPressed("right")) panDirection.X += 1;
		if (Input.IsActionPressed("forward")) panDirection.Z -= 1;
		if (Input.IsActionPressed("backward")) panDirection.Z += 1;

		if (panDirection != Vector3.Zero)
		{
			panDirection = panDirection.Normalized() * panSpeed * (float)GetProcessDeltaTime();
			_mapCamera.GlobalPosition += panDirection;
		}
	}

	private void SetupMarkerInteraction(MeshInstance3D marker, System.Action action)
	{
		var staticBody = marker.GetNode<StaticBody3D>("StaticBody3D");
		if (staticBody != null)
		{
			// Connect InputEvent to handle clicks
			staticBody.InputEvent += (camera, eventObj, position, normal, shapeIdx) =>
			{
				if (eventObj is InputEventMouseButton mouseButton && mouseButton.Pressed && mouseButton.ButtonIndex == MouseButton.Left)
				{
					action?.Invoke(); // Execute the action defined for this marker
				}
			};
		}
		else
		{
			GD.PrintErr($"StaticBody3D not found for marker: {marker.Name}");
		}
	}

	public void UpdateMarkers()
	{
		// Make markers visible/invisible based on GameManager's unlock status
		if (_level1Marker != null)
		{
			_level1Marker.Visible = _gameManager?.IsLevelUnlocked("Level1") ?? true; // Default to true if no GM
		}
		if (_level2Marker != null)
		{
			_level2Marker.Visible = _gameManager?.IsLevelUnlocked("Level2") ?? false; // Default to false
		}
	}

	private void OnLevelPressed(int index)
	{
		string levelName = _levels[index]["ScenePath"].ToString().GetFile().Replace(".tscn", "");
		
		if (_gameManager?.IsLevelUnlocked(levelName) ?? true) // Always unlocked for now as per request
		{
			_currentLevelIndex = index;
			_isCameraMovingAutomatically = true;
			
			// Use GameManager to start the level, passing level name and time limit
			string currentLevelName = _levels[index]["ScenePath"].ToString().GetFile().Replace(".tscn", "");
			float timeLimit = (float)_levels[index]["TimeLimit"];
			_gameManager.StartLevel(currentLevelName, timeLimit);
			
			GD.Print($"Loading Level {index + 1}: {_levels[index]["Name"]}");
		}
		else
		{
			GD.Print($"Level {index + 1} ({_levels[index]["Name"]}) is locked!");
			// Optional: Show a UI message to the player that the level is locked
			var ui = GetTree().Root.GetNodeOrNull<UI>("UI");
			ui?.ShowTutorialMessage($"Level {_levels[index]["Name"]} masih terkunci!", 2.0f);
		}
	}

	// This method can be called by GameManager when a level is successfully completed
	public void UnlockNextLevel()
	{
		// Find the currently highest unlocked level
		int highestUnlockedIndex = -1;
		for (int i = _levels.Count - 1; i >= 0; i--)
		{
			string levelName = _levels[i]["ScenePath"].ToString().GetFile().Replace(".tscn", "");
			if (_gameManager?.IsLevelUnlocked(levelName) ?? false)
			{
				highestUnlockedIndex = i;
				break;
			}
		}

		// Unlock the next level if available
		if (highestUnlockedIndex != -1 && highestUnlockedIndex < _levels.Count - 1)
		{
			string nextLevelName = _levels[highestUnlockedIndex + 1]["ScenePath"].ToString().GetFile().Replace(".tscn", "");
			_gameManager?.UnlockLevel(nextLevelName);
			UpdateMarkers(); // Update markers on the map
			GD.Print($"Unlocked Level {highestUnlockedIndex + 2}: {_levels[highestUnlockedIndex + 1]["Name"]}");
		}
		else
		{
			GD.Print("No next level to unlock or all levels are already unlocked.");
		}
	}
}
