using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GroundMovement : MonoBehaviour
{
    private MeshRenderer m_Renderer;

    void Start() {
        m_Renderer = GetComponent<MeshRenderer>();
    }

    void Update() {
        m_Renderer.sharedMaterial.SetTextureOffset("_HeightMap", new Vector2(1.0f, Time.time * 0.1f));
    }
}
