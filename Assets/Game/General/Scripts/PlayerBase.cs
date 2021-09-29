using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.InputSystem.InputAction;

public class PlayerBase : MonoBehaviour
{
    protected Vector2 input;
    public virtual void OnMove(CallbackContext value)
    {
        input = value.ReadValue<Vector2>();

    }
}
