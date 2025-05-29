import { Router } from "express";
import { DataController } from "./controllers/data.controller.ts";

const router = new Router();

router.post("/items", DataController.getItems);
router.post("/items/order", DataController.orderItems);
router.post("/items/select", DataController.selectItems);

export default router;
