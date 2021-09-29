using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.Events;
using DG.Tweening;

public class GameStartCountdown : MonoBehaviour
{
    public UnityEvent CountdownStarted;
    public UnityEvent CountdownFinished;
    public TextMeshProUGUI text;
    public void Start()
    {
        StartCoroutine(Countdown());
    }
    public IEnumerator Countdown()
    {
        CountdownStarted.Invoke();
        text.text = "3";
        text.transform.localScale = Vector3.zero;
        text.transform.DOScale(Vector3.one, 1f);
        yield return new WaitForSeconds(1f);
        text.text = "2";
        text.transform.localScale = Vector3.zero;
        text.transform.DOScale(Vector3.one, 1f);
        yield return new WaitForSeconds(1f);
        text.text = "1";
        text.transform.localScale = Vector3.zero;
        text.transform.DOScale(Vector3.one, 1f);
        yield return new WaitForSeconds(1f);
        text.text = "START!";
        text.transform.localScale = Vector3.zero;
        text.transform.DOScale(Vector3.one, 1f);
        CountdownFinished.Invoke();
        yield return new WaitForSeconds(1f);
        text.transform.localScale = Vector3.zero;
    }
    
}
