app.patch("/users/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { email } = req.body;

    if (!id || !email) {
      return res.status(400).json({ error: "Please enter a name or email" });
    }

    const [updated] = await db("users")
      .where({ id })
      .update({ email })
      .returning("*");

    if (!updated) {
      return res.status(404).json({ error: "User not found" });
    }

    return res.status(200).json({ success: true, user: updated });
  } catch (err) {
    return res.status(500).json({ error: "Internal server error " });
  }
});
