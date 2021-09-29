using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
[CreateAssetMenu(fileName = "ConstsAndEnums", menuName = "Consts And Enums Scriptable Object", order = 52)]
public class ConstsAndEnums : SerializedScriptableObject
{
    public enum GameMode { BoardGame, MiniGames, StoryMode };
    public enum Games { BombardIsland, ColorArena, CrazyKitchen, HorseRace, PickBiggestSize, Shepherd, Simon, Snake, TrickyRacing, ZigZag };
    public enum Colors { Red, Green, Blue, Yellow, NotAssigned };
    public enum Side { North, East, South, West, NotAssigned };
    public Dictionary<Colors, Color> ColorMap;
}
