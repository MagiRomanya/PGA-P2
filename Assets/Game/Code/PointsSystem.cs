using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointsSystem : MonoBehaviour
{
    private static PointsSystem s_PointsSystem;

    public static PointsSystem I() {
        if (s_PointsSystem == null) {
            s_PointsSystem = FindObjectOfType<PointsSystem>();
        }
        return s_PointsSystem;
    }

    public void AddPoints(int value) {
        m_CurrentPoints += value;
        m_CurrentPoints = Mathf.Max(m_CurrentPoints, 0);
    }

    public int GetPoints() {
        return m_CurrentPoints;
    }

    //----------------------------------------------------------------------------

    private int m_CurrentPoints;
}
