using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointPeakToPeak : MonoBehaviour
{
    [Header("Unity assignments")]
    [SerializeField] WaterMeasurement linkedWaterMeasurement;
    public Vector2Int grabCoordinate;

    //Runtime variables
    bool onAscend = true;
    float prevValue = -Mathf.Infinity;
    int prevPeak = 0;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Color debugColor = linkedWaterMeasurement.ReadPixel(grabCoordinate.x, grabCoordinate.y);
        float newValue = debugColor.r;

        bool nowOnAscend = newValue > prevValue;

        if(!onAscend && nowOnAscend)
        {
            Debug.Log($"{gameObject.name}: Peak after {Time.frameCount - prevPeak} at {Time.frameCount}");

            prevPeak = Time.frameCount;
        }

        prevValue = newValue;
        onAscend = nowOnAscend;
    }
}
