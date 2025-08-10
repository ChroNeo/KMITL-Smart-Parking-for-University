async function testSys(req, res) {
  try {
    return res.status(200).json({ message: "HelloWorld" });
  } catch (err) {
    console.error(err);
  }
}

const testAdmin = (req, res) => {
  if (req.user.role === "admin") {
    res.json({ message: "Welcome, admin!", role: req.user.role });
  } else if (req.user.role === "user") {
    res.json({ message: "Hello, user!", role: req.user.role });
  } else {
    res.status(403).json({ message: "Forbidden", role: req.user.role });
  }
};

module.exports = { testSys, testAdmin };
