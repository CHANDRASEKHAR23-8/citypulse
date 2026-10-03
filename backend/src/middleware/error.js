function errorHandler(err, req, res, next) {
  console.error('[Error Handler]', err);

  if (err.name === 'MulterError') {
    return res.status(400).json({
      success: false,
      error: `File upload error: ${err.message}`
    });
  }

  const statusCode = err.statusCode || 500;
  return res.status(statusCode).json({
    success: false,
    error: err.message || 'Internal server error'
  });
}

module.exports = { errorHandler };
