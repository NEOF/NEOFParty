
using UnityEngine;

[System.Serializable]
public class ClayxelsPrefs {
    public int[] boundsColor = new int[]{100, 100, 100, 50};
    public string pickingKey = "p";
    public string mirrorDuplicateKey = "m";
    public int maxPointCount = 2;
    public int maxSolidsCount = 0;
    public int maxSolidsPerVoxel = 0;
    public int frameSkip = 0;
    public int maxBounds = 3;
    public bool vramLimitEnabled = true;
    public float lodNear = 0.0f;
    public float lodFar = 0.0f;
    public string defaultAssetsPath = "clayxelsFrozen";
}
