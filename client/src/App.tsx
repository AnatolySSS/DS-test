import React, { useState, useEffect, useCallback, useRef } from "react";
import { FixedSizeList as List, ListOnScrollProps } from "react-window";
import { DndContext, closestCenter, PointerSensor, useSensor, useSensors } from "@dnd-kit/core";
import { SortableContext, verticalListSortingStrategy, arrayMove, useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { DataAPI } from "./api/api";

interface Item {
  id: number;
  selected: boolean;
}

const SortableItem = ({
  id,
  selected,
  toggleSelect,
  style,
}: {
  id: number;
  selected: boolean;
  toggleSelect: (id: number) => void;
  style: React.CSSProperties;
}) => {
  const { attributes, listeners, setNodeRef, transform, transition } = useSortable({ id: id.toString() });

  const itemStyle = {
    ...style,
    transform: CSS.Transform.toString(transform),
    transition,
    display: "flex",
    alignItems: "center",
    padding: "10px",
    borderBottom: "1px solid #eee",
    backgroundColor: selected ? "#e3f2fd" : "white",
  };

  return (
    <div ref={setNodeRef} style={itemStyle} {...attributes} {...listeners}>
      <input type="checkbox" checked={selected} onChange={() => toggleSelect(id)} style={{ marginRight: "10px" }} />
      <span style={{ flex: 1 }}>Item {id}</span>
      <span>≡</span>
    </div>
  );
};

const App: React.FC = () => {
  const [items, setItems] = useState<Item[]>([]);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [initialLoad, setInitialLoad] = useState(true);
  const listRef = useRef<List>(null);

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: {
        distance: 8,
      },
    })
  );

  const fetchItems = useCallback(async (searchQuery = "", pageNum = 1, reset = false) => {
    setLoading(true);
    try {
      const data = await DataAPI.getItems(searchQuery, pageNum);

      if (reset) {
        setItems(
          data.items.map((id: number) => ({
            id,
            selected: data.selectedItems.includes(id),
          }))
        );
      } else {
        setItems((prev) => [
          ...prev,
          ...data.items.map((id: number) => ({
            id,
            selected: data.selectedItems.includes(id),
          })),
        ]);
      }

      setTotal(data.total);
      setHasMore(data.items.length > 0);
    } catch (error) {
      console.error("Error fetching items:", error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchItems("", 1, true).then(() => setInitialLoad(false));
  }, [fetchItems]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setPage(1);
    fetchItems(search, 1, true);
  };

  useEffect(() => {
    if (listRef.current && search) {
      listRef.current.scrollTo(0);
    }
  }, [search]);

  const handleScroll = useCallback(
    ({ scrollOffset, scrollUpdateWasRequested }: ListOnScrollProps) => {
      if (!loading && hasMore && !scrollUpdateWasRequested && !initialLoad && scrollOffset > (items.length - 12) * 50) {
        const nextPage = page + 1;
        setPage(nextPage);
        fetchItems(search, nextPage);
      }
    },
    [loading, hasMore, items.length, page, search, initialLoad, fetchItems]
  );

  const toggleSelect = async (itemId: number) => {
    const isSelected = !items.find((item) => item.id === itemId)?.selected;

    try {
      await DataAPI.selectItems(itemId, isSelected);
      setItems((prev) => prev.map((item) => (item.id === itemId ? { ...item, selected: isSelected } : item)));
    } catch (error) {
      console.error("Error updating selection:", error);
    }
  };

  const handleDragEnd = async (event: any) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;

    const oldIndex = items.findIndex((item) => item.id.toString() === active.id);
    const newIndex = items.findIndex((item) => item.id.toString() === over.id);

    const newItems = arrayMove(items, oldIndex, newIndex);
    setItems(newItems);

    try {
      await DataAPI.orderItems(newItems.map((item) => item.id));
    } catch (error) {
      console.error("Error updating order:", error);
    }
  };

  return (
    <div style={{ padding: "20px", maxWidth: "600px", margin: "0 auto" }}>
      <h1>Item List (1-1,000,000)</h1>

      <form onSubmit={handleSearch} style={{ marginBottom: "20px" }}>
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search items..."
          style={{ padding: "8px", width: "300px" }}
        />
        <button type="submit" style={{ padding: "8px 16px", marginLeft: "8px" }}>
          Search
        </button>
      </form>

      <div style={{ border: "1px solid #ddd", borderRadius: "4px" }}>
        <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
          <SortableContext items={items.map((item) => item.id.toString())} strategy={verticalListSortingStrategy}>
            <List
              ref={listRef}
              height={450}
              itemCount={items.length}
              itemSize={50}
              width="100%"
              onScroll={handleScroll}
              overscanCount={5}
            >
              {({ index, style }) => {
                const item = items[index];
                return (
                  <SortableItem
                    key={item.id}
                    id={item.id}
                    selected={item.selected}
                    toggleSelect={toggleSelect}
                    style={style}
                  />
                );
              }}
            </List>
          </SortableContext>
        </DndContext>

        {loading && <div style={{ padding: "10px", textAlign: "center" }}>Loading...</div>}
        {!hasMore && <div style={{ padding: "10px", textAlign: "center", color: "#666" }}>No more items to load</div>}
      </div>

      <div style={{ marginTop: "10px", color: "#666" }}>
        Showing {items.length} of {total} items
      </div>
    </div>
  );
};

export default App;
