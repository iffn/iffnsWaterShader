using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using static TMPro.SpriteAssetUtilities.TexturePacker_JsonArray;

public class GersnerWaveSimulator : MonoBehaviour
{
    Mesh mesh;
    MeshCollider meshCollider;

    const int vertexLength = 100;
    int vertexDistance = 1;

    LineRenderer lineRenderer;

    Vector3[] positionOrigins = new Vector3[vertexLength];
    Vector3[] positions = new Vector3[vertexLength];

    public float amplitude = 0.5f; // A
    public float wavelength = 10.0f; // λ
    public float speed = 1.0f; // c
    public float phase = 0.0f; // φ
    public float offsetMultiplier = 1.0f; // Multiplier for wave offset
    public float frequency = 1.0f; // Frequency of the wave
    public float directionAngle = 0.0f; // Direction of the wave in radians

    void CalculateLinePositions()
    {
        float k = 2.0f * Mathf.PI / wavelength; // Wave number
        float omega = k * speed; // Angular frequency

        for (int i = 0; i < positions.Length; i++)
        {
            Vector3 vertex = positionOrigins[i];
            Vector3 offset = Vector3.zero;

            float f = k * vertex.x - omega * Time.time + phase;

            offset.x = amplitude * Mathf.Cos(f);
            offset.y = amplitude * Mathf.Sin(f);

            positions[i] = vertex + offset * offsetMultiplier;
        }
    }

    void CalculateMeshPositions()
    {
        Vector3[] vertices = mesh.vertices;

        float k = 2.0f * Mathf.PI / wavelength; // Wave number
        float omega = k * speed; // Angular frequency

        for (int i = 0; i < positionOrigins.Length; i++)
        {
            Vector3 offset = Vector3.zero;

            float f = k * positionOrigins[i].y - omega * Time.time + phase;

            offset.y = amplitude * Mathf.Cos(f);
            offset.z = amplitude * Mathf.Sin(f);

            vertices[i] = positionOrigins[i] + offset * offsetMultiplier;
        }

        mesh.vertices = vertices;

        mesh.RecalculateBounds();
        mesh.RecalculateNormals();
        mesh.RecalculateTangents();

        //Refresh mesh collider
        meshCollider.sharedMesh = null;
        meshCollider.sharedMesh = mesh;
    }

    public string returnString;

    void GetPositions()
    {
        int samples = 200;
        float offset = 10f / samples;

        returnString = "";

        for(int i = 0; i<samples; i++)
        {
            Ray ray = new Ray(3 * Vector3.up + offset * i *Vector3.forward, Vector3.down);
            RaycastHit hit;
            if (Physics.Raycast(ray, out hit, Mathf.Infinity))
            {
                returnString += hit.point.y + System.Environment.NewLine;
            }
        }
    }

    void SetLinePositions()
    {
        lineRenderer.positionCount = positions.Length;
        lineRenderer.SetPositions(positions);
    }

    // Start is called before the first frame update
    void Start()
    {
        //lineRenderer = GetComponent<LineRenderer>();

        mesh = GetComponent<MeshFilter>().mesh;
        positionOrigins = mesh.vertices;
        meshCollider = GetComponent<MeshCollider>();

        /*
        List<int> triangles = new List<int>();

        for(int i = 0; i < positions.Length; i++)
        {
            positionOrigins[i] = Vector3.right * i;
        }
        */

        CalculateMeshPositions();
        GetPositions();

    }

    // Update is called once per frame
    void Update()
    {
        /*
        CalculateLinePositions();

        SetLinePositions();
        */
        
    }
}
