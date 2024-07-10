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
    public Vector4 currentColor;

    // Update is called once per frame
    void Update()
    {
        if(initialTimeCounter == Time.frameCount + 1)
        {
            linkedCRT.material = WaterCalculationMaterial;
        }

        Color debugColor = ReadPixel(linkedCRT, 50, 50);

        debugColor = new Vector4(debugColor.r, debugColor.g, debugColor.b, debugColor.a);

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
