using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoatMover : MonoBehaviour
{
    public float minValue;
    public float speed;
    public Transform element;
    public Vector3 movementVector;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        float pos = (Time.time * speed % (minValue * 2) - minValue);

        element.position = movementVector * pos;
    }
}
