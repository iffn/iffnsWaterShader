using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InitializeCRT : MonoBehaviour
{
    [SerializeField] CustomRenderTexture linkedCRT;
    [SerializeField] Material WaterInitializationMaterial;
    [SerializeField] Material WaterCalculationMaterial;

    int initialTimeCounter;

    void InitializeMaterial()
    {
        initialTimeCounter = Time.frameCount;
        linkedCRT.material = WaterInitializationMaterial;

        //linkedCRT.Initialize();
        //GL.Clear(true, true, new Color(0.5f, 0.5f, 0.5f));
    }

    // Start is called before the first frame update
    void Start()
    {
        InitializeMaterial();
    }

    public Material debugMaterial;

    public Vector2Int grabCoordinate;
    public float r;
    public float g;
    public float b;
    public float a;


    // Update is called once per frame
    void Update()
    {
        if(Time.frameCount == initialTimeCounter + 60)
        {
            linkedCRT.material = WaterCalculationMaterial;
        }

        Color debugColor = ReadPixel(linkedCRT, grabCoordinate.x, grabCoordinate.y);

        r = debugColor.r;
        g = debugColor.g;
        b = debugColor.b;
        a = debugColor.a;

        debugMaterial = linkedCRT.material;
    }

    Color ReadPixel(CustomRenderTexture customRenderTexture, int x, int y)
    {
        // Set the active RenderTexture to the CRT
        RenderTexture currentRT = RenderTexture.active;
        RenderTexture.active = customRenderTexture;

        // Create a new Texture2D with the same dimensions as the CustomRenderTexture
        Texture2D texture2D = new Texture2D(customRenderTexture.width, customRenderTexture.height, TextureFormat.RGBA32, false);

        // Read the CustomRenderTexture contents into the Texture2D
        texture2D.ReadPixels(new Rect(0, 0, customRenderTexture.width, customRenderTexture.height), 0, 0);
        texture2D.Apply();

        // Get the pixel color at the specified coordinates
        Color pixelColor = texture2D.GetPixel(x, y);

        // Clean up
        RenderTexture.active = currentRT;
        Destroy(texture2D);

        return pixelColor;
    }

    public void InitializeLinkedCRT()
    {
        linkedCRT.Initialize();
    }
}
