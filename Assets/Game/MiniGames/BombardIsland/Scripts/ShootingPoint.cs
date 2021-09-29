using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;
namespace Game.MiniGames.BombardIsland
{
    public class ShootingPoint : MonoBehaviour
    {
        [SerializeField] private GameObject projectilePrefab;
        [SerializeField] private GameObject spawnPoint;
        [SerializeField] private Animator animator;
        // Start is called before the first frame update
        IEnumerator Start()
        {
            while (!GameManager.instance.gameIsInProgress)
            {
                animator.SetBool("Throw", false);
                yield return null;
            }
            while (GameManager.instance.gameIsInProgress)
            {
                animator.SetBool("Throw", true);

                yield return null;
            }

        }
        public void Throw()
        {
            GameObject projectile = Instantiate(projectilePrefab, spawnPoint.transform.position, Quaternion.identity);
            projectile.GetComponent<Rigidbody>().DOJump(GetTargetPoint(), 30f, 0, 2f).SetEase(Ease.OutQuad);
        }

        private Vector3 GetTargetPoint()
        {
            return new Vector3(Random.Range(-8, 8), -2f, Random.Range(-8, 8));
        }


    }
}