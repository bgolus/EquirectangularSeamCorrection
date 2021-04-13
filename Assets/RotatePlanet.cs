using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotatePlanet : MonoBehaviour
{
	public float speed = 1f;
	public float mouseSpeed = -5f;
	public Vector3 localAxis = new Vector3(0f, 1f, 0f);

    public UnityEngine.UI.Slider rotation;
    public UnityEngine.UI.Toggle toggleRotation;

    public bool autoRotate = true;

    void Update()
    {    	
    	float angle = rotation.value;

    	if (autoRotate && toggleRotation.isOn)
    	{
	    	angle += speed * Time.deltaTime;
	    	if (angle >= 360f)
	    		angle -= 360f;
			if (angle < 0f)
				angle += 360f;
	    	rotation.value = angle;
	    }

    	transform.localRotation = Quaternion.AngleAxis(angle, localAxis);
    }

    public void SetRotation(float val)
    {
    	// transform.rotation = Quaternion.AngleAxis(val, transform.TransformDirection(localAxis)) * transform.rotation;
    }
}
