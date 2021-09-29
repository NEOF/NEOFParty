using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AddExplosiveForceOnCollision : MonoBehaviour
{
    [SerializeField] private float force;
    private void OnCollisionEnter(Collision collision)
    {
        Collider[] objects = Physics.OverlapSphere(transform.position, 5);
        foreach (Collider h in objects)
        {
            Rigidbody r = h.GetComponent<Rigidbody>();
            if (r != null)
            {
                if (r.CompareTag("Player"))
                {
                    r.AddExplosionForce(force, transform.position, 5);
                }
            }
        }
    }
}
