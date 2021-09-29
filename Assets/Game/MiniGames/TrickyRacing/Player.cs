using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.InputSystem.InputAction;

namespace Game.MiniGames.TrickyRacing
{
    public class Player : PlayerBase
    {

        public Vector4 levelBorder;
        public override void OnMove(CallbackContext value)
        {
            input = value.ReadValue<Vector2>();

        }
        public IEnumerator MovePlayer()
        {

            yield return null;
        }
    }
}
