using Sirenix.OdinInspector;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LoadingScreenManager : SerializedMonoBehaviour
{
    public Dictionary<ConstsAndEnums.Games, GameLoadingScreen> gameToDataMap;
}
