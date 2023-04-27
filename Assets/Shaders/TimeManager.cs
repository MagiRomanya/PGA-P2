using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TimeManager : MonoBehaviour
{
    public MeshRenderer ShaderMaterial;
    private int counter = 0;
    private float time = 0.0f;
    void FixedUpdate()
    {
        const float FixedUpdateFPS = 50.0f;
        counter++;
        time = counter * FixedUpdateFPS;

        ShaderMaterial.material.SetFloat("Time", time);
    }
}
