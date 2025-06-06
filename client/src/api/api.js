import axios from "axios";

// const URL_HOME = "http://localhost:3010";
const URL_SITE = "http://5.129.195.79:3010";

const instance = axios.create({
  withCredentials: true,
  baseURL: `${URL_SITE}/api`,
});

export const DataAPI = {
  async getItems(searchQuery, pageNum) {
    const responce = await instance.post(`items`, { searchQuery, pageNum });
    return responce.data;
  },
  async orderItems(newOrder) {
    const responce = await instance.post(`items/order`, { newOrder });
    return responce.data;
  },
  async selectItems(itemId, isSelected) {
    const responce = await instance.post(`items/select`, { itemId, isSelected });
    return responce.data;
  },
};
