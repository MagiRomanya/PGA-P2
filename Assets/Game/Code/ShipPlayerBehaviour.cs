using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShipPlayerBehaviour : MonoBehaviour {

    public float m_CurrPosX = 0.0f;
    public float m_MovSpeed = 5.0f;
    public float m_PosClampX = 3.0f;

    private void Update() {
        float targetVel = 0.0f;

        float deltaPos = m_MovSpeed * Time.deltaTime;
        if (Input.GetKey(KeyCode.A)) {
            targetVel -= deltaPos;
        }
        if (Input.GetKey(KeyCode.D)) {
            targetVel += deltaPos;
        }

        m_CurrPosX += targetVel;
        m_CurrPosX = Mathf.Clamp(m_CurrPosX, -m_PosClampX, m_PosClampX);

        Vector3 cPos = transform.localPosition;
        cPos.x = m_CurrPosX;
        transform.localPosition = cPos;
    }
}
