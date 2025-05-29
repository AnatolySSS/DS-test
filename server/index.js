// server.js
import express from "express";
import cors from "cors";
import router from "./router.js";

const app = express();

app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: "50mb" }));

app.use("/api", router);

app.listen(3010, () => {
  console.log("Server running on http://localhost:3010");
});
