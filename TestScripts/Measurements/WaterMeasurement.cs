using UnityEngine;

public class WaterMeasurement : MonoBehaviour
{
    [Header("Unity assignments")]
    [SerializeField] CustomRenderTexture linkedCRT;

    public Color ReadPixel(int x, int y)
    {
        // Set the active RenderTexture to the CRT
        RenderTexture currentRT = RenderTexture.active;
        RenderTexture.active = linkedCRT;

        // Create a new Texture2D with the same dimensions as the CustomRenderTexture
        Texture2D texture2D = new Texture2D(linkedCRT.width, linkedCRT.height, TextureFormat.RGBA32, false);

        // Read the CustomRenderTexture contents into the Texture2D
        texture2D.ReadPixels(new Rect(0, 0, linkedCRT.width, linkedCRT.height), 0, 0);
        texture2D.Apply();

        // Get the pixel color at the specified coordinates
        Color pixelColor = texture2D.GetPixel(x, y);

        // Clean up
        RenderTexture.active = currentRT;
        Destroy(texture2D);

        return pixelColor;
    }
}
