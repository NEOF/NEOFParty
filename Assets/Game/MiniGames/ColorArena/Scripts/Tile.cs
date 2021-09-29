using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;
using Sirenix.Serialization;
using System.Linq;
using System;

namespace Game.MiniGames.ColorArena
{
    public class Tile : SerializedMonoBehaviour
    {

        public Player playerOnTile;
        public Dictionary<ConstsAndEnums.Side, Tile> neighbors;
        public ConstsAndEnums.Colors tileColor;
        public PowerUp powerUpOnTile;
        public void CollectNeighbors()
        {
            RaycastHit[] hitsForward = Physics.RaycastAll(transform.position, Vector3.forward,0.5f);
            RaycastHit[] hitsRight = Physics.RaycastAll(transform.position, Vector3.right, 0.5f);
            RaycastHit[] hitsBack = Physics.RaycastAll(transform.position, Vector3.back, 0.5f);
            RaycastHit[] hitsLeft = Physics.RaycastAll(transform.position, Vector3.left, 0.5f);
            if (hitsForward.Length>0 && hitsForward[0].transform.name=="Tile")
            {
                neighbors[ConstsAndEnums.Side.North] = hitsForward[0].transform.GetComponent<Tile>();
            }
            if (hitsRight.Length > 0 && hitsRight[0].transform.name == "Tile")
            {
                neighbors[ConstsAndEnums.Side.East] = hitsRight[0].transform.GetComponent<Tile>();
            }
            if (hitsBack.Length > 0 && hitsBack[0].transform.name == "Tile")
            {
                neighbors[ConstsAndEnums.Side.South] = hitsBack[0].transform.GetComponent<Tile>();
            }
            if (hitsLeft.Length > 0 && hitsLeft[0].transform.name == "Tile")
            {
                neighbors[ConstsAndEnums.Side.West] = hitsLeft[0].transform.GetComponent<Tile>();
            }
        }
    }
}
