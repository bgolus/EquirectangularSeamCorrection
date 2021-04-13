using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;

public class SettingsManager : MonoBehaviour
{
	public Material mat;
	public UnityEngine.UI.Dropdown accuracyDropdown;
	public UnityEngine.UI.Text mipLevelText;
    public UnityEngine.UI.Text textureSize;

    private Texture2D originalTexture;
    private RenderTexture uncompressedTexture;

    Recorder behaviourUpdateRecorder;

    void Awake()
    {
        originalTexture = mat.GetTexture("_MainTex") as Texture2D;

        SetAccuracy(0);
        SetSeamCorrection(0);
        SetAnisotropicFiltering(true);
        SetMasterTextureLimit(0);
    }

    public void SetAccuracy(int val)
    {
    	mat.DisableKeyword("_ACCURACY_DEFAULT");
    	mat.DisableKeyword("_ACCURACY_COARSE");
    	mat.DisableKeyword("_ACCURACY_FINE");

    	switch(val)
    	{
    		case 2:
    			mat.EnableKeyword("_ACCURACY_FINE");
    			break;
			case 1:
				mat.EnableKeyword("_ACCURACY_COARSE");
				break;
    		case 0:
    		default:
				mat.EnableKeyword("_ACCURACY_DEFAULT");
    			break;
    	}

    	mat.SetFloat("_Accuracy", (float)val);
    }

    public void SetSeamCorrection(int val)
    {
    	accuracyDropdown.interactable = val != 0;

    	mat.DisableKeyword("_SEAMCORRECTION_NONE");
    	mat.DisableKeyword("_SEAMCORRECTION_TARINI");
    	mat.DisableKeyword("_SEAMCORRECTION_EXPLICIT_LOD");
    	mat.DisableKeyword("_SEAMCORRECTION_EXPLICIT_GRADIENTS");
    	mat.DisableKeyword("_SEAMCORRECTION_COARSE_EMULATION");
        mat.DisableKeyword("_SEAMCORRECTION_LEAST_WORST_QUAD_DERIVATIVES");

    	switch(val)
    	{
            case 5:
                mat.EnableKeyword("_SEAMCORRECTION_LEAST_WORST_QUAD_DERIVATIVES");
                break;
    		case 4:
    			mat.EnableKeyword("_SEAMCORRECTION_COARSE_EMULATION");
    			break;
    		case 3:
    			mat.EnableKeyword("_SEAMCORRECTION_EXPLICIT_GRADIENTS");
    			break;
    		case 2:
    			mat.EnableKeyword("_SEAMCORRECTION_EXPLICIT_LOD");
    			break;
			case 1:
				mat.EnableKeyword("_SEAMCORRECTION_TARINI");
				break;
    		case 0:
    		default:
				mat.EnableKeyword("_SEAMCORRECTION_NONE");
    			break;
    	}

    	mat.SetFloat("_SeamCorrection", (float)val);
    }


    public void SetAnisotropicFiltering(bool val)
    {
    	QualitySettings.anisotropicFiltering = val ? AnisotropicFiltering.ForceEnable : AnisotropicFiltering.Disable;
    }

    public void SetMasterTextureLimit(float val)
    {
    	QualitySettings.masterTextureLimit = (int)val;

    	mipLevelText.text = val.ToString();

        int scale = (int)Mathf.Pow(2f, (float)val);

        if (uncompressedTexture != null)
        {
            UpdateRenderTexture();

            scale = 1;
        }

        Texture tex = mat.GetTexture("_MainTex");
        int width = tex.width / scale;
        int height = tex.height / scale;

        textureSize.text = tex.graphicsFormat + " " + width + " x " + height;
    }

    void UpdateRenderTexture()
    {
        if (uncompressedTexture != null)
            RenderTexture.ReleaseTemporary(uncompressedTexture);

        int scale = (int)Mathf.Pow(2f, (float)QualitySettings.masterTextureLimit);

        var rtd = new RenderTextureDescriptor() {
            width = originalTexture.width / scale,
            height = originalTexture.height / scale,
            graphicsFormat = UnityEngine.Experimental.Rendering.GraphicsFormat.R8G8B8A8_SRGB,
            depthBufferBits = 0,
            dimension = UnityEngine.Rendering.TextureDimension.Tex2D,
            volumeDepth = 1,
            msaaSamples = 1,
            autoGenerateMips = true,
            useMipMap = true,
            sRGB = true
        };

        uncompressedTexture = RenderTexture.GetTemporary(rtd);

        uncompressedTexture.wrapMode = originalTexture.wrapMode;
        uncompressedTexture.wrapModeU = originalTexture.wrapModeU;
        uncompressedTexture.wrapModeV = originalTexture.wrapModeV;
        uncompressedTexture.filterMode = originalTexture.filterMode;
        uncompressedTexture.anisoLevel = originalTexture.anisoLevel;

        if (SystemInfo.graphicsDeviceType == UnityEngine.Rendering.GraphicsDeviceType.OpenGLCore || SystemInfo.graphicsDeviceType == UnityEngine.Rendering.GraphicsDeviceType.OpenGLES3)
            Graphics.Blit(originalTexture, uncompressedTexture);
        else
            Graphics.Blit(originalTexture, uncompressedTexture, new Vector2(1f, -1f), new Vector2(0f, 1f));

        mat.SetTexture("_MainTex", uncompressedTexture);
    }

    public void SetTextureUncompressed(bool val)
    {
        if (val)
        {
            UpdateRenderTexture();
        }
        else
        {
            if (uncompressedTexture != null)
            {
                RenderTexture.ReleaseTemporary(uncompressedTexture);
                uncompressedTexture = null;
            }
            mat.SetTexture("_MainTex", originalTexture);
        }
        SetMasterTextureLimit(QualitySettings.masterTextureLimit);
    }

#if UNITY_EDITOR
    void OnApplicationQuit()
    {
        mat.SetTexture("_MainTex", originalTexture);
    }
#endif
}
