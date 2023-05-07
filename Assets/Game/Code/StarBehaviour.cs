using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StarBehaviour : MonoBehaviour
{
    Material material;
    int Counter = 0;
    void Start()
    {
        Renderer renderer = GetComponent<Renderer>();      
        material = renderer.material;
    }

    // Update is called once per frame
    void Update()
    {
        const float FixedUpdateFPS = 50.0f;
        float Time = Counter / FixedUpdateFPS;
        Time = Time / 10.0f;
        material.SetTextureOffset("_HeightMap", new Vector2(Mathf.Sin(Time), Mathf.Cos(Time)));
        //material.SetColor("Color", Color.black);
    }

    void FixedUpdate()
    {
        Counter++;
    }
}
