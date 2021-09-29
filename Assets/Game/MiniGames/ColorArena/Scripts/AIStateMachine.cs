using Game.MiniGames.ColorArena;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
namespace Game.MiniGames.ColorArena
{
    public class AIStateMachine : AIStateMachineBase
    {
        public Player myPlayer => GetComponent<Player>();
        public List<Tile> currentPath = new List<Tile>();
        public List<Tile> BFS(Tile startTile, Tile targetTile = null)
        {
            Tile currentNode = startTile;
            List<Tile> unsearchedNodes = new List<Tile>();
            List<Tile> shortestPath = new List<Tile>();
            Tile destinationTile = null;
            Dictionary<Tile, Tile> parenting = new Dictionary<Tile, Tile>();
            unsearchedNodes.Add(currentNode);
            parenting.Add(currentNode, null);
            while (unsearchedNodes.Count > 0)
            {
                if (targetTile == null)
                {
                    if (unsearchedNodes[0].tileColor != myPlayer.playerColor && unsearchedNodes[0].playerOnTile == null)
                    {
                        destinationTile = unsearchedNodes[0];
                        break;
                    }
                }
                else
                {
                    if (unsearchedNodes[0] == targetTile)
                    {
                        destinationTile = unsearchedNodes[0];
                        break;
                    }
                }

                unsearchedNodes.AddRange(unsearchedNodes[0].neighbors.Values.ToList().OrderBy(a => Guid.NewGuid()).ToList());
                foreach (var node in unsearchedNodes[0].neighbors.Values.ToList())
                {
                    if (!parenting.ContainsKey(node))
                    {
                        parenting.Add(node, unsearchedNodes[0]);
                    }
                }
                unsearchedNodes.RemoveAt(0);
            }
            Tile currentPartOfThePath = destinationTile;
            while (parenting[currentPartOfThePath] != null)
            {
                shortestPath.Add(currentPartOfThePath);
                currentPartOfThePath = parenting[currentPartOfThePath];
            }
            shortestPath.Reverse();
            return shortestPath;
        }
        private void Update()
        {
            if (myPlayer.currentTile == null || GameManager.instance.gameIsInProgress == false)
            {
                return;
            }
            ScanForPowerups();
            TryUsingBucket();
            TryUsingRocket();
            if (currentPath.Count == 0 || (currentPath.Count > 0 && currentPath[0].playerOnTile != null))
            {
                SearchForNextTarget();
            }
            if (currentPath[0] == myPlayer.currentTile)
            {
                currentPath.RemoveAt(0);
                return;
            }
            myPlayer.SetMovement(FindDirectionForTheNextTile());
        }
        public ConstsAndEnums.Side FindDirectionForTheNextTile()
        {
            return myPlayer.currentTile.neighbors.First(c => c.Value == currentPath[0]).Key;
        }
        public void SearchForNextTarget()
        {
            currentPath = BFS(myPlayer.currentTile);
        }
        public void ScanForPowerups()
        {
            List<Collider> listOfColliders = Physics.OverlapBox(transform.position, Vector3.one).ToList();
            Collider col = listOfColliders.FirstOrDefault(c => c.GetComponent<PowerUp>() != null && c.GetComponent<PowerUp>().myPlayer == null);
            if (col != null)
            {
                Tile targetTile = col.GetComponent<PowerUp>().tile;
                currentPath = BFS(myPlayer.currentTile, targetTile);
            }
        }
        public void TryUsingBucket()
        {
            if (myPlayer.savedPowerup == null || myPlayer.savedPowerup != null && myPlayer.savedPowerup.type != PowerUp.Type.Bucket)
            {
                return;
            }
            List<Tile> tilesToPaint = new List<Tile>();
            Tile currentTile = myPlayer.currentTile;
            while (currentTile != null)
            {

                if (currentTile.neighbors.ContainsKey(myPlayer.lastDirection))
                {
                    tilesToPaint.Add(currentTile.neighbors[myPlayer.lastDirection]);
                    currentTile = currentTile.neighbors[myPlayer.lastDirection];
                }
                else
                {
                    currentTile = null;
                }

            }
            if (tilesToPaint.Count > 5)
            {
                myPlayer.savedPowerup.Activate();
            }
        }
        public void TryUsingRocket()
        {
            if (myPlayer.savedPowerup == null || myPlayer.savedPowerup != null && myPlayer.savedPowerup.type != PowerUp.Type.Rocket)
            {
                return;
            }
            List<Tile> tilesToPaint = new List<Tile>();
            Tile currentTile = myPlayer.currentTile;
            while (currentTile != null)
            {

                if (currentTile.neighbors.ContainsKey(myPlayer.lastDirection))
                {
                    tilesToPaint.Add(currentTile.neighbors[myPlayer.lastDirection]);
                    currentTile = currentTile.neighbors[myPlayer.lastDirection];
                }
                else
                {
                    currentTile = null;
                }

            }
            if (tilesToPaint.Where(c => c.playerOnTile != null).ToList().Count > 0)
            {
                myPlayer.savedPowerup.Activate();
            }
        }
    }
}
