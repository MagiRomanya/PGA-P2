using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class UI_PointsCounter : MonoBehaviour
{
    [SerializeField] private TextMeshProUGUI m_Text;
    private int m_CurrValue = 0;

    private void Update() {
        if(m_CurrValue != PointsSystem.I().GetPoints()) {
            m_CurrValue = PointsSystem.I().GetPoints();
            m_Text.text = m_CurrValue.ToString();
        }
    }
}
