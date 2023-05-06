using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StarSpawner : MonoBehaviour
{
    public GameObject StarPrefab;
    public int StarNumber = 10;
    public float SpawnRadius = 10.0f;
    
    void Start()
    {
        for (int i = 0; i < StarNumber; i++)
        {
            SpawnStar();
        }
    }

    private void SpawnStar()
    {
        float x = Random.Range(-SpawnRadius, SpawnRadius);
        float y = Random.Range(-SpawnRadius, SpawnRadius);
        float z = Random.Range(-SpawnRadius, SpawnRadius);
        
        Instantiate(StarPrefab, new Vector3(x,y,z), Quaternion.identity);

    }

    void Update()
    {
        
    }
}
