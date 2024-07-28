using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static UnityEditor.Experimental.AssetDatabaseExperimental.AssetDatabaseCounters;

public class PointLogger : MonoBehaviour
{
    [Header("Unity assignments")]
    [SerializeField] WaterMeasurement linkedWaterMeasurement;
    public Vector2Int grabCoordinate;
    public int maxRecordSteps;

    [Header("Output")]
    public int frame;
    public string valueOutput = "";

    // Runtime variables
    int counter;

    void Update()
    {
        Color debugColor = linkedWaterMeasurement.ReadPixel(grabCoordinate.x, grabCoordinate.y);

        frame = Time.frameCount;

        if (counter++ < maxRecordSteps)
        {
            valueOutput += $"{debugColor.r}\n";
        }

        if (counter == maxRecordSteps) Debug.Log("Reached");
    }
}
