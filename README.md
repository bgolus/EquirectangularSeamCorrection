# EquirectangularSeamCorrection
This is a simple test suite for comparing different ways of handling the seam that occurs when using procedural equirectangular UVs.
https://github.com/bgolus/EquirectangularSeamCorrection/
https://medium.com/@bgolus/distinctive-derivative-differences-cce38d36797b

Seam Correction:
 * None - no correction.
 * Tarini - Marco Tarini's Cylindrical and toroidal parameterizations without vertex seams method. http://vcg.isti.cnr.it/~tarini/no-seams/ cheap, but requires coarse derivatives.
 * Explicit LOD - calculates the best mip level in the shader. cheap, but no anisotropic filtering.
 * Explicit Gradients - calculates the best gradients in the shader, potentially expensive, but works with coarse or fine derivatives and anisotropic filtering.
 * Coarse Emulation - reproduces the equivalent of coarse derivatives regardless of what accuracy is available via in quad communication. cheap, works with coarse and fine derivatives, and anisotropic filtering. does not work on Apple or Mali GPUs.
 * Least Worst Quad Derivatives - gets the worst derivatives from the whole quad via in quad communication. cheap, works with coarse and fine derivatives, and anisotropic filtering. should be used over coarse emulation. may not work on ARM based Windows devices or those with Mali GPUs.

Derivative Accuracy:
 * Default - uses base ddx / ddy / fwidth functions
 * Coarse - uses ddx_coarse / ddy_coarse functions
 * Fine - uses ddx_fine / ddy_fine functions
HAS NO EFFECT ON ANYTHING BUT DIRECT3D DUE TO LACK OF EXPLICIT ACCURACY DERIVATIVE FUNCTION SUPPORT ON THOSE PLATFORMS


Texture Mip Limit:
Slider to clamp the largest mip level (resulting texture size shown in info below)

Anisotropic Filtering:
Change between Trilinear and 16x Anisotropic texture filtering

Uncompressed Tex:
Copy texture to a render texture w/ mip maps to use as the texture instead of the default DXT1 texture. For really killing perf as much as possible to show the difference between the methods.


Defaults to Direct3D 11, but can be forced to OpenGL Core or Vulkan with:
-force-glcore
-force-vulkan

Or you can change the API in the editor by going to Project Settings > Player > Standalone > Other Settings and moving which API you want to the top.
