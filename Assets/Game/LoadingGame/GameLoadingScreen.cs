using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Video;

[CreateAssetMenu(fileName = "New Minigame Loading Screen Data", menuName = "Minigame Loading Screen Data", order = 51)]
public class GameLoadingScreen : ScriptableObject
{
    public string gameName;
    public string textDescription;
    public VideoClip videoDescription;
    public Sprite descriptionDetailsImage; // use it to show types of objects in games for example. Like in Tricky Racing we can show different obstacles and how to deal with them.
    public string buttonSouthDescription;
    public string buttonNorthDescription;
    public string buttonEastDescription;
    public string buttonWestDescription;
    public string buttonLeftTrigger1Description;
    public string buttonRightTrigger1Description;
    public string buttonLeftTrigger2Description;
    public string buttonRightTrigger2Description;
    public string buttonLeftStickDescription;
    public string buttonRightStickDescription;
}
