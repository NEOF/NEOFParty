using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;
using TMPro;
namespace Game.MiniGames.ColorArena
{
    public class GameManager : GameManagerBase
    {
        public List<Tile> listOfTiles;
        public List<Tile> startingTiles;
        
        public List<GameObject> powerupPrefabs;

        public List<TextMeshProUGUI> listOfScores;
        public List<PowerUp> spawnedPowerups = new List<PowerUp>();


        [Button("Attach Tile Neighbours")]
        public void AttachTileNeighbours()
        {
            foreach(Tile tile in listOfTiles)
            {
                tile.CollectNeighbors();
            }
        }
        protected override void Awake()
        {
            instance = this;
        }
        protected override void StartGame()
        {
            AIType = typeof(AIStateMachine);
            PlayerType = typeof(Player);
            base.StartGame();          
            SpawnPowerups();
        }
        protected override void SetupPlayers()
        {
            for (int i = 0; i < players.Count; i++)
            {
                Player pl = (Player)players[i];
                pl.transform.position = startingTiles[i].transform.position + pl.shift;
                pl.currentTile = startingTiles[i].GetComponent<Tile>();
                pl.playerColor = (ConstsAndEnums.Colors)i;
                pl.coloredPartOnTheCharacter.material.color = constsAndEnums.ColorMap[pl.playerColor];
                pl.currentTile.GetComponent<Renderer>().material.color = constsAndEnums.ColorMap[pl.playerColor];
                pl.currentTile.tileColor = pl.playerColor;
                pl.currentTile.playerOnTile = pl;
                pl.scoreText = listOfScores[i];
                pl.scoreText.color = constsAndEnums.ColorMap[pl.playerColor];
                pl.scoreText.text = "0";
                StartCoroutine(pl.MovePlayer());
            }
        }



        
        
        public void SpawnPowerups()
        {
            StartCoroutine(SpawnPowerUp(10,25,0));
            StartCoroutine(SpawnPowerUp(10,25,3));
            StartCoroutine(SpawnPowerUp(5,10,2));
            StartCoroutine(SpawnPowerUp(10,25,1));
            StartCoroutine(SpawnPowerUp(10,25,4));
        }
        
       
        public IEnumerator SpawnPowerUp(int timeMin, int timeMax, int prefabIndex)
        {
            while (gameIsInProgress)
            {
                yield return new WaitForSeconds(Random.Range(timeMin, timeMax));
                int index;
                do
                {
                    index = Random.Range(0, listOfTiles.Count);
                    yield return null;
                }
                while (listOfTiles[index].playerOnTile != null || listOfTiles[index].powerUpOnTile != null);
                spawnedPowerups.Add(Instantiate(powerupPrefabs[prefabIndex], listOfTiles[index].transform.position + Vector3.up * 0.25f, Quaternion.identity).GetComponent<PowerUp>());
                spawnedPowerups.Last().tile = listOfTiles[index];
                listOfTiles[index].powerUpOnTile = spawnedPowerups.Last();
            }
        }
    }
}
