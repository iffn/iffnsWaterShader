using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InitializeCRT : MonoBehaviour
{
    [SerializeField] CustomRenderTexture linkedCRT;


    // Start is called before the first frame update
    void Start()
    {
        linkedCRT.Initialize();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void InitializeLinkedCRT()
    {
        linkedCRT.Initialize();
    }
}
