using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.EventSystems;
using static UnityEngine.InputSystem.InputAction;
namespace Game.MiniGames.BombardIsland
{
    public class Player : PlayerBase
    {
        private Vector3 movementInput = Vector3.zero;
        [SerializeField] private float speed;
        [SerializeField] private Rigidbody rb;
        private void Awake()
        {
        }
        protected void Update()
        {
            if (movementInput != Vector3.zero)
            {
                rb.AddForce(movementInput.normalized * (Time.deltaTime * speed), ForceMode.Acceleration);
            }
            transform.LookAt(transform.position + movementInput.normalized);
        }
        public override void OnMove(CallbackContext value)
        {
            movementInput = new Vector3(value.ReadValue<Vector2>().x, 0, value.ReadValue<Vector2>().y);
        }
        public void OnCharge(CallbackContext value)
        {
            rb.AddForce(movementInput.normalized * 15 * (Time.deltaTime * speed), ForceMode.Impulse);
        }
        private void OnCollisionEnter(Collision collision)
        {
            if (collision.gameObject.CompareTag("Player"))
            {
                rb.AddForce((transform.position - collision.transform.position) * 300, ForceMode.Impulse);
            }
        }
    }
}