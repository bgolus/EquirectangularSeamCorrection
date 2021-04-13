using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using UnityEngine.EventSystems;// Required when using Event data.

public class RotationSliderHandler : MonoBehaviour, IPointerUpHandler, IPointerDownHandler
{
	public RotatePlanet rotatePlanet;

    public void OnPointerDown(PointerEventData eventData)
    {
        rotatePlanet.autoRotate = false;
    }
    public void OnPointerUp(PointerEventData eventData)
    {
        rotatePlanet.autoRotate = true;
    }
}