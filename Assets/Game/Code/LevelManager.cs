using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LevelManager : MonoBehaviour
{
    [System.Serializable]
    class PointsObject {
        public GameObject m_Prefab;
        public int m_Rarity;
        private float m_Chance;
    }

    private void Start() {
        m_PointsObject.Sort((x, y) => { return x.m_Rarity - y.m_Rarity; });
    }

    private void Update() {
        if (m_CurrTime > m_SpawnCD) {
            m_CurrTime = 0;
            Vector3 spawnPos = m_SpawnPos.position + Vector3.right * Random.Range(-1.0f, 1.0f) * m_ObjectOffset;
            m_SpawnedObjects.Add(Instantiate(m_PointsObject[0].m_Prefab, spawnPos, Quaternion.identity));
        }

        for (int i = m_SpawnedObjects.Count - 1; i >= 0 ; i--) {
            Vector3 cPos = m_SpawnedObjects[i].transform.position;
            cPos.z -= m_ObjectSpeed * Time.deltaTime;
            m_SpawnedObjects[i].transform.position = cPos;

            if (cPos.z <= -10.0f) {
                GameObject obj = m_SpawnedObjects[i];
                m_SpawnedObjects.RemoveAt(i);
                Destroy(obj);
            }
        }

        m_CurrTime += Time.deltaTime;
    }
    
    [SerializeField] private List<PointsObject> m_PointsObject;
    [SerializeField ]private Transform m_SpawnPos;
    [SerializeField] private float m_ObjectSpeed = 5.0f;
    [SerializeField] private float m_ObjectOffset = 5.0f;
    private List<GameObject> m_SpawnedObjects = new List<GameObject>();
    private float m_CurrTime = 0.0f;
    private float m_SpawnCD = 1.0f;
}