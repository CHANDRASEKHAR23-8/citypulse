function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required.'
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: `Forbidden: Access restricted to roles [${allowedRoles.join(', ')}]. Current role: '${req.user.role}'.`
      });
    }

    next();
  };
}

module.exports = { requireRole };
