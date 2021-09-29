using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GeneralGameManager : MonoBehaviour
{
    public static GeneralGameManager instance;
    public MenuManager menuManager;
    private void Awake()
    {
        instance = this;
    }
    public string currentSceneName;
    public int numberOfPlayers;
    public List<string> miniGameNames;
    public ConstsAndEnums.GameMode modeSelected;
    public List<string> miniGameSequence;
    public GameStartCountdown gameStartCountdown;
    public void SetNumberOfPlayers(int number)
    {
        numberOfPlayers = number;
    }
    public void SetGameMode(int gameMode)
    {
        modeSelected = (ConstsAndEnums.GameMode)gameMode;
    }

    public void StartGameWithSelectedMode()
    {
        GenerateMiniGameSequence();
        switch (modeSelected)
        {
            case ConstsAndEnums.GameMode.BoardGame:
                break;
            case ConstsAndEnums.GameMode.MiniGames:
                StartNextGame();
                break;
            case ConstsAndEnums.GameMode.StoryMode:
                break;
        }
    }

    public void GenerateMiniGameSequence()
    {
        miniGameSequence = miniGameNames.OrderBy(a => Guid.NewGuid()).ToList();
    }
    public void StartNextGame()
    {
        if (currentSceneName != "")
        {
            SceneManager.UnloadSceneAsync(currentSceneName);
        }
        SceneManager.LoadSceneAsync(miniGameSequence[0]);
        currentSceneName = miniGameSequence[0];
        miniGameSequence.RemoveAt(0);
    }
}
