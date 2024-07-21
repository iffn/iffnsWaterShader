using UnityEngine;

public class WaterMeasurement : MonoBehaviour
{
    [Header("Unity assignments")]
    [SerializeField] CustomRenderTexture linkedCRT;
    public int maxRecordSteps;
    public Vector2Int grabCoordinate;

    [Header("Output")]
    public float r;
    public float g;
    public float b;
    public float a;
    public string valueOutput = "";

    // Runtime variables
    int counter;

    void Update()
    {
        Color debugColor = ReadPixel(linkedCRT, grabCoordinate.x, grabCoordinate.y);

        r = debugColor.r;
        g = debugColor.g;
        b = debugColor.b;
        a = debugColor.a;

        if (counter++ < maxRecordSteps)
        {
            valueOutput += $"{debugColor.r}\n";
        }

        if (counter == maxRecordSteps) Debug.Log("Reached");
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
}
