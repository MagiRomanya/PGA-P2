using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointsCollectable : MonoBehaviour
{
    [SerializeField] private int m_PointsValue = 10;

    private void OnTriggerEnter(Collider other) {
            PointsSystem.I().AddPoints(m_PointsValue);
        transform.position = transform.position + Vector3.down * 100;
    }
}
