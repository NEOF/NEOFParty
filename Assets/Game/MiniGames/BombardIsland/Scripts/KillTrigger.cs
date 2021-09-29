using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace  Game.MiniGames.BombardIsland
{
    public class KillTrigger : MonoBehaviour
    {
        int count = 0;
        private void OnTriggerEnter(Collider other)
        {
            if (other.CompareTag("Player"))
            {
                count++;
            }
            if (count == 3)
            {
                GameManager.instance.gameIsInProgress = false;
                GameManager.instance.gameHasEnded.Invoke();
            }
        }
    }
}
