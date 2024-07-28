using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointMeasurement : MonoBehaviour
{
    [Header("Unity assignments")]
    [SerializeField] WaterMeasurement linkedWaterMeasurement;
    public Vector2Int grabCoordinate;

    [Header("Output")]
    public float r;
    public float g;
    public float b;
    public float a;

    void Update()
    {
        Color debugColor = linkedWaterMeasurement.ReadPixel(grabCoordinate.x, grabCoordinate.y);

        r = debugColor.r;
        g = debugColor.g;
        b = debugColor.b;
        a = debugColor.a;
    }
}
