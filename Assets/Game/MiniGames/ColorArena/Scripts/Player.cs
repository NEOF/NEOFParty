using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.InputSystem.InputAction;
using DG.Tweening;
using TMPro;

namespace Game.MiniGames.ColorArena
{
    public class Player : PlayerBase
    {
        private ConstsAndEnums.Side movementDirection=ConstsAndEnums.Side.NotAssigned;
        public ConstsAndEnums.Side lastDirection = ConstsAndEnums.Side.NotAssigned;
        public Tile currentTile;
        public Vector3 shift;
        public Renderer coloredPartOnTheCharacter;
        public ConstsAndEnums.Colors playerColor;
        public PowerUp powerup=null;
        public PowerUp savedPowerup = null;
        public TextMeshProUGUI scoreText;
        public float delay=0.6f;
        public float delayMultiplier=1f;
        public int score;
        public Coroutine currentSpeedCoro;
        public bool stunned;
        public void SetPowerup( PowerUp newPowerup)
        {
            newPowerup.myPlayer = this;
            currentTile.powerUpOnTile = null;
            switch (newPowerup.type)
            {
                case PowerUp.Type.Bomb:
                case PowerUp.Type.Magnet:
                case PowerUp.Type.Speed:
                    newPowerup.Activate(); break;
                case PowerUp.Type.Bucket:
                case PowerUp.Type.Rocket:
                    if(savedPowerup!=null)
                    {
                        Destroy(savedPowerup.gameObject);
                    }
                    powerup = newPowerup;
                    powerup.transform.parent = this.transform;
                    powerup.transform.localPosition = Vector3.up;
                    savedPowerup = newPowerup;
                    break;
                default: break;
            }
        }
        
        
        public override void OnMove(CallbackContext value)
        {
            if (input == Vector2.zero || input.sqrMagnitude<0.2f)
            {
                movementDirection = ConstsAndEnums.Side.NotAssigned;
                return;
            }

            List<float> distances = new List<float>
            {
                Vector2.Distance(input, Vector2.up),
                Vector2.Distance(input, Vector2.right),
                Vector2.Distance(input, Vector2.down),
                Vector2.Distance(input, Vector2.left)
            };
            SetMovement((ConstsAndEnums.Side)distances.IndexOf(Mathf.Min(distances.ToArray())));
        }
        public void OnPowerup()
        {
            if (savedPowerup!=null)
            {
                switch (savedPowerup.type)
                {
                    case PowerUp.Type.Bucket:
                    case PowerUp.Type.Rocket:
                        savedPowerup.Activate(); break;

                    default: break;
                }
            }
        }
        public void SetMovement(ConstsAndEnums.Side nextDirection)
        {
            movementDirection = nextDirection;
            lastDirection = movementDirection;
            
        }
        public void MoveToTheNextTile()
        {
            if(movementDirection!= ConstsAndEnums.Side.NotAssigned && currentTile.neighbors.ContainsKey(movementDirection) && currentTile.neighbors[movementDirection].playerOnTile==null)
            {
                currentTile.playerOnTile = null;
                currentTile.neighbors[movementDirection].playerOnTile = this;               
                transform.DOJump(currentTile.neighbors[movementDirection].transform.position + shift,0.5f,1, delay * delayMultiplier).OnComplete(() => { FinishJumping();  });
                currentTile = currentTile.neighbors[movementDirection];
                transform.eulerAngles = new Vector3(0, 90, 0) * (int)movementDirection;
            }
        }
        public void FinishJumping()
        {
            currentTile.GetComponent<Renderer>().material.color = GameManager.instance.constsAndEnums.ColorMap[playerColor];
            currentTile.tileColor = playerColor;
            if(currentTile.powerUpOnTile!=null)
            {
                SetPowerup(currentTile.powerUpOnTile);
                
            }
        }
        public IEnumerator MovePlayer()
        {
            while (GameManager.instance.gameIsInProgress && GameManager.instance.gameHasStarted)
            {
                MoveToTheNextTile();
                yield return new WaitForSeconds(delay * delayMultiplier);
                if (stunned)
                { 
                    yield return new WaitForSeconds(4f);
                    stunned = false;
                }
            }
        }
        public IEnumerator SpeedPowerup()
        {
            delayMultiplier = 0.5f;
            yield return new WaitForSeconds(4f);
            delayMultiplier = 1f;
        }
    }
}
