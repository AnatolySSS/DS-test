// Хранилище в памяти
let newState = {
  selectedItems: new Set(),
  itemOrder: Array.from({ length: 1000000 }, (_, i) => i + 1), // [1, 2, 3, ..., 1000000]
};

let state = {
  selectedItems: new Set(),
  itemOrder: Array.from({ length: 1000000 }, (_, i) => i + 1), // [1, 2, 3, ..., 1000000]
};

export const DataController = {
  async getItems(request, responce) {
    const { searchQuery = "", pageNum = 1, pageSize = 20 } = request.body;
    const offset = (pageNum - 1) * pageSize;

    let items = [...state.itemOrder];

    if (searchQuery) {
      items = items.filter((item) => item.toString().includes(searchQuery));
    }

    const paginatedItems = items.slice(offset, offset + pageSize);
    console.log(paginatedItems);

    responce.json({
      items: paginatedItems,
      total: items.length,
      selectedItems: Array.from(state.selectedItems),
    });
  },

  async orderItems(request, responce) {
    const { newOrder } = request.body;
    state.itemOrder = newOrder;
    responce.json({ success: true });
  },

  async selectItems(request, responce) {
    const { itemId, isSelected } = request.body;
    if (isSelected) {
      state.selectedItems.add(itemId);
    } else {
      state.selectedItems.delete(itemId);
    }

    responce.json({
      success: true,
      selectedItems: Array.from(state.selectedItems),
    });
  },
};
