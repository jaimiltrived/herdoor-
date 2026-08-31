const cloudinary = require('cloudinary').v2;
require('dotenv').config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_NAME || 'herdoor',
  api_key: process.env.CLOUDINARY_API_KEY || '762447733112833',
  api_secret: process.env.CLOUDINARY_API_SECRET || '3BD-ry-r2g0IHEUwD_H26ENBTio',
  secure: true,
});

/**
 * Upload an image (file path, remote URL, or base64 data URI) to Cloudinary
 * @param {string} fileSource - Local file path, HTTP URL, or base64 data URI
 * @param {string} folder - Destination folder on Cloudinary (e.g. 'herdoor/stores', 'herdoor/licenses')
 * @returns {Promise<object>} Upload result with secure_url, public_id, etc.
 */
async function uploadToCloudinary(fileSource, folder = 'herdoor/uploads') {
  try {
    const result = await cloudinary.uploader.upload(fileSource, {
      folder,
      resource_type: 'auto',
    });
    return {
      success: true,
      url: result.secure_url,
      publicId: result.public_id,
      format: result.format,
      bytes: result.bytes,
    };
  } catch (error) {
    console.warn('Cloudinary upload error, returning fallback:', error.message);
    return {
      success: false,
      url: fileSource.startsWith('http') ? fileSource : 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      error: error.message,
    };
  }
}

module.exports = {
  cloudinary,
  uploadToCloudinary,
};
