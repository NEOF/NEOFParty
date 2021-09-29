using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.Users;

namespace Game.MiniGames.BombardIsland
{
    public class GameManager : GameManagerBase
    {
        public new static GameManager instance;
        [SerializeField] private List<GameObject> spawnMarkers;
        protected override void Awake()
        {
            instance = this;
            gameHasEnded.AddListener(GameFinished);
        }
        protected override void SetupPlayers()
        {
            for (int i = 0; i < players.Count; i++)
            {
                Player pl = (Player)players[i];
                pl.transform.position = spawnMarkers[i].transform.position;
            }
        }
        private  void GameFinished()
        {
        }
        protected override void StartGame()
        {
            AIType = typeof(AIStateMachineBase);
            PlayerType = typeof(Player);
            base.StartGame();
        }

    }  
}
