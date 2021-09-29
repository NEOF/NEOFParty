using Game.MiniGames.ColorArena;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using DG.Tweening;
public class PowerUp : MonoBehaviour
{
    public enum Type {Magnet, Bomb, Rocket, Bucket, Speed};
    public Type type;
    public Player myPlayer;
    public Tile tile;
    public void Activate()
    {
        switch (type)
        {
            case Type.Bomb:
                Bomb(); break;
            case Type.Magnet:
                Magnet(); break;
            case Type.Speed:
                Speed(); break;
            case Type.Rocket:
                Rocket(); break;
            case Type.Bucket:
                Bucket(); break;
            default: break;
        }
    }
    public void Bomb()
    {
        List<Collider> colliders = Physics.OverlapBox(transform.position, new Vector3(0.5f, 0.5f, 0.5f)).ToList();
        foreach(var obj in colliders)
        {
            if(obj.gameObject.GetComponent<Tile>()!=null)
            {
                obj.gameObject.GetComponent<Tile>().tileColor = myPlayer.playerColor;
                obj.GetComponent<Renderer>().material.color = GameManagerBase.instance.constsAndEnums.ColorMap[myPlayer.playerColor];
            }
        }
        myPlayer.powerup = null;
        Destroy(gameObject);
    }
    public void Magnet()
    {
        foreach(Tile tile in (GameManagerBase.instance as GameManager).listOfTiles)
        {
            if(tile.tileColor==myPlayer.playerColor)
            {
                myPlayer.score++;
                tile.tileColor = ConstsAndEnums.Colors.NotAssigned;
                tile.GetComponent<Renderer>().material.color = GameManagerBase.instance.constsAndEnums.ColorMap[ConstsAndEnums.Colors.NotAssigned];
            }
        }
        myPlayer.scoreText.text = myPlayer.score.ToString();
        myPlayer.powerup = null;
        Destroy(gameObject);
    }
    public void Rocket()
    {
        GetComponent<Rigidbody>().DOMove(transform.position + myPlayer.transform.forward * 15, 3f);
        Destroy(gameObject, 4f);
        myPlayer.powerup = null;
        myPlayer.savedPowerup = null;
    }
    public void Bucket()
    {
        transform.DOMove(transform.position + myPlayer.transform.forward * 15, 3f);
        StartCoroutine(PaintWithBucket());
        myPlayer.powerup = null;
        myPlayer.savedPowerup = null;
        Destroy(gameObject, 4f);
    }
    public IEnumerator PaintWithBucket()
    {
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
        foreach(Tile tile in tilesToPaint)
        {
            tile.tileColor = myPlayer.playerColor;
            tile.GetComponent<Renderer>().material.color = GameManager.instance.constsAndEnums.ColorMap[myPlayer.playerColor];
            yield return new WaitForSeconds(0.05f);
        }
    }
    public void Speed()
    {
        if (myPlayer.currentSpeedCoro != null)
        {
            myPlayer.StopCoroutine(myPlayer.currentSpeedCoro);
        }
        myPlayer.currentSpeedCoro = myPlayer.StartCoroutine(myPlayer.SpeedPowerup());
        myPlayer.powerup = null;
        Destroy(gameObject);
    }
    private void OnTriggerEnter(Collider other)
    {
        if (type == Type.Rocket)
        {
            if (myPlayer != null)
            {
                if (other.GetComponent<Player>() != null && other.GetComponent<Player>() != myPlayer)
                {
                    other.GetComponent<Player>().stunned = true;
                    StopAllCoroutines();
                    Destroy(gameObject);
                }
            }
        }
    }
    
}
