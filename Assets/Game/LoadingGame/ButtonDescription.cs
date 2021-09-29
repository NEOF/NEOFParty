using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class ButtonDescription : MonoBehaviour
{
    public Image buttonImage;
    public TextMeshProUGUI textDescription;
    private void OnValidate()
    {
        buttonImage = GetComponentInChildren<Image>();
        textDescription = GetComponentInChildren<TextMeshProUGUI>();
    }
}
