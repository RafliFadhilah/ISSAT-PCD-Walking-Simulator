using Godot;

public partial class MainMenu : Node2D
{
	private Button _startButton;
	private Button _settingsButton;
	private Button _guideButton;
	private Button _aboutButton;
	private Button _quitButton;
	private bool _isLoading = false;

	public override void _Ready()
	{
		_startButton = GetNode<Button>("VBoxContainer/StartButton");
		_settingsButton = GetNode<Button>("VBoxContainer/SettingsButton");
		_guideButton = GetNode<Button>("VBoxContainer/GuideButton");
		_aboutButton = GetNode<Button>("VBoxContainer/AboutButton");
		_quitButton = GetNode<Button>("VBoxContainer/QuitButton");

		_startButton.Pressed += OnStartPressed;
		_settingsButton.Pressed += OnSettingsPressed;
		_guideButton.Pressed += OnGuidePressed;
		_quitButton.Pressed += OnQuitPressed;
	}

	private void OnStartPressed()
	{
		if (_isLoading) return;
		_isLoading = true;
		GD.Print("Loading Map...");
		GetTree().CallDeferred(SceneTree.MethodName.ChangeSceneToFile, "res://Scenes/Main Menu/Map.tscn");
	}

	private void OnSettingsPressed()
	{
		if (_isLoading) return;
		_isLoading = true;
		GD.Print("Go to Settings Menu");
		GetTree().CallDeferred(SceneTree.MethodName.ChangeSceneToFile, "res://Scenes/Main Menu/Settings.tscn");
	}

	private void OnGuidePressed()
	{
		if (_isLoading) return;
		_isLoading = true;
		GD.Print("Go to Guide Menu");
		GetTree().CallDeferred(SceneTree.MethodName.ChangeSceneToFile, "res://Scenes/Main Menu/Guide.tscn");
	}


	private void OnQuitPressed()
	{
		GD.Print("Exit From Game");
		GetTree().Quit();
	}
}
