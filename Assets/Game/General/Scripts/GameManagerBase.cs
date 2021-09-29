using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;

public class GameManagerBase : MonoBehaviour
{
    public List<PlayerBase> players;
    public static GameManagerBase instance;
    public bool gameHasStarted = false;
    public bool gameIsInProgress = false;
    public bool gameIsFinished = false;
    public UnityEvent gameHasEnded;
    [SerializeField] private GameObject playerPrefab;
    public System.Type AIType;
    public System.Type PlayerType;
    public ConstsAndEnums constsAndEnums;

    protected virtual void Awake()
    {
        instance = this;
    }
    protected virtual void Start()
    {
        if (GeneralGameManager.instance != null)
        {
            GeneralGameManager.instance.gameStartCountdown.CountdownFinished.AddListener(StartGame);
        }
        else
        {
            StartGame();
        }
    }
    protected virtual void StartGame()
    {
        var pNum = 1;
        if (GeneralGameManager.instance != null)
        {
            pNum = GeneralGameManager.instance.numberOfPlayers;
        }
        for (int i = 0; i < pNum; i++)
        {
            if (Gamepad.all.Count > 0)
            {
                players.Add(PlayerInput.Instantiate(playerPrefab, pairWithDevice: Gamepad.all[i]).GetComponent<PlayerBase>());
            }
            else
            {
                players.Add(PlayerInput.Instantiate(playerPrefab, pairWithDevice: Keyboard.current).GetComponent<PlayerBase>());
            }
        }
        if (pNum < 4)
        {
            for (int i = 0; i < 4 - pNum; i++)
            {
                players.Add(Instantiate(playerPrefab).GetComponent<PlayerBase>());
                players.Last().gameObject.AddComponent(AIType);
            }
        }
        SetupPlayers();
    }
    protected virtual void SetupPlayers()
    {
        for (int i = 0; i < players.Count; i++)
        {
        }
    }
}
