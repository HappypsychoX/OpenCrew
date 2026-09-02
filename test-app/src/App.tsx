import { useEffect, useMemo, useState } from 'react'
import type { FormEvent } from 'react'
import type { InventoryItem } from './types'
import { loadItems, saveItems } from './storage'
import './App.css'

interface Draft {
  name: string
  category: string
  location: string
  quantity: string
  minQuantity: string
}

const emptyDraft: Draft = {
  name: '',
  category: '',
  location: '',
  quantity: '',
  minQuantity: '',
}

function isLowStock(item: InventoryItem): boolean {
  return item.quantity <= item.minQuantity
}

function App() {
  const [items, setItems] = useState<InventoryItem[]>(() => loadItems())
  const [search, setSearch] = useState('')
  const [categoryFilter, setCategoryFilter] = useState('')
  const [locationFilter, setLocationFilter] = useState('')
  const [lowStockOnly, setLowStockOnly] = useState(false)
  const [draft, setDraft] = useState<Draft>(emptyDraft)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    saveItems(items)
  }, [items])

  const categories = useMemo(
    () =>
      Array.from(new Set(items.map((item) => item.category.trim()).filter(Boolean))).sort(),
    [items],
  )

  const locations = useMemo(
    () =>
      Array.from(new Set(items.map((item) => item.location.trim()).filter(Boolean))).sort(),
    [items],
  )

  const filteredItems = useMemo(() => {
    const query = search.trim().toLowerCase()
    return items.filter((item) => {
      if (lowStockOnly && !isLowStock(item)) return false
      if (categoryFilter && item.category !== categoryFilter) return false
      if (locationFilter && item.location !== locationFilter) return false
      if (query) {
        const haystack = `${item.name} ${item.category} ${item.location}`.toLowerCase()
        if (!haystack.includes(query)) return false
      }
      return true
    })
  }, [items, search, categoryFilter, locationFilter, lowStockOnly])

  const lowStockCount = items.filter(isLowStock).length

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    const name = draft.name.trim()
    const category = draft.category.trim()
    const location = draft.location.trim()
    const quantity = Number(draft.quantity)
    const minQuantity = Number(draft.minQuantity)

    if (!name || !category || !location) {
      setError('Name, category, and location are required.')
      return
    }
    if (draft.quantity === '' || !Number.isInteger(quantity) || quantity < 0) {
      setError('Quantity must be a whole number of 0 or more.')
      return
    }
    if (
      draft.minQuantity === '' ||
      !Number.isInteger(minQuantity) ||
      minQuantity < 0
    ) {
      setError('Minimum quantity must be a whole number of 0 or more.')
      return
    }

    if (editingId) {
      setItems((prev) =>
        prev.map((item) =>
          item.id === editingId
            ? { ...item, name, category, location, quantity, minQuantity }
            : item,
        ),
      )
    } else {
      const newItem: InventoryItem = {
        id: crypto.randomUUID(),
        name,
        category,
        location,
        quantity,
        minQuantity,
      }
      setItems((prev) => [...prev, newItem])
    }

    setDraft(emptyDraft)
    setEditingId(null)
    setError('')
  }

  function startEdit(item: InventoryItem) {
    setEditingId(item.id)
    setDraft({
      name: item.name,
      category: item.category,
      location: item.location,
      quantity: String(item.quantity),
      minQuantity: String(item.minQuantity),
    })
    setError('')
  }

  function cancelEdit() {
    setEditingId(null)
    setDraft(emptyDraft)
    setError('')
  }

  function removeItem(id: string) {
    setItems((prev) => prev.filter((item) => item.id !== id))
    if (editingId === id) cancelEdit()
  }

  function updateDraft(field: keyof Draft, value: string) {
    setDraft((prev) => ({ ...prev, [field]: value }))
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>Parts Bin</h1>
        <p className="subtitle">
          {items.length} {items.length === 1 ? 'item' : 'items'}
          {lowStockCount > 0 && (
            <span className="badge badge-warn"> · {lowStockCount} low stock</span>
          )}
        </p>
      </header>

      <section className="panel">
        <h2>{editingId ? 'Edit Item' : 'Add Item'}</h2>
        <form className="item-form" onSubmit={handleSubmit}>
          <label>
            <span>Name</span>
            <input
              type="text"
              value={draft.name}
              onChange={(e) => updateDraft('name', e.target.value)}
              placeholder="e.g. M3 x 20mm bolt"
            />
          </label>
          <label>
            <span>Category</span>
            <input
              type="text"
              list="category-options"
              value={draft.category}
              onChange={(e) => updateDraft('category', e.target.value)}
              placeholder="e.g. Fasteners"
            />
          </label>
          <label>
            <span>Location</span>
            <input
              type="text"
              list="location-options"
              value={draft.location}
              onChange={(e) => updateDraft('location', e.target.value)}
              placeholder="e.g. Shelf A-3"
            />
          </label>
          <label>
            <span>Quantity</span>
            <input
              type="number"
              min="0"
              step="1"
              value={draft.quantity}
              onChange={(e) => updateDraft('quantity', e.target.value)}
              placeholder="0"
            />
          </label>
          <label>
            <span>Minimum</span>
            <input
              type="number"
              min="0"
              step="1"
              value={draft.minQuantity}
              onChange={(e) => updateDraft('minQuantity', e.target.value)}
              placeholder="0"
            />
          </label>
          <div className="form-actions">
            <button type="submit" className="btn btn-primary">
              {editingId ? 'Save Changes' : 'Add Item'}
            </button>
            {editingId && (
              <button type="button" className="btn" onClick={cancelEdit}>
                Cancel
              </button>
            )}
          </div>
        </form>
        {error && <p className="form-error">{error}</p>}
        <datalist id="category-options">
          {categories.map((c) => (
            <option key={c} value={c} />
          ))}
        </datalist>
        <datalist id="location-options">
          {locations.map((l) => (
            <option key={l} value={l} />
          ))}
        </datalist>
      </section>

      <section className="panel">
        <div className="toolbar">
          <input
            type="search"
            className="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search name, category, or location"
          />
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
          >
            <option value="">All categories</option>
            {categories.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
          <select
            value={locationFilter}
            onChange={(e) => setLocationFilter(e.target.value)}
          >
            <option value="">All locations</option>
            {locations.map((l) => (
              <option key={l} value={l}>
                {l}
              </option>
            ))}
          </select>
          <label className="checkbox">
            <input
              type="checkbox"
              checked={lowStockOnly}
              onChange={(e) => setLowStockOnly(e.target.checked)}
            />
            Low stock only
          </label>
        </div>

        {filteredItems.length === 0 ? (
          <p className="empty">
            {items.length === 0
              ? 'No items yet. Add your first item above.'
              : 'No items match your search or filters.'}
          </p>
        ) : (
          <table className="items-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Category</th>
                <th>Location</th>
                <th className="num">Quantity</th>
                <th className="num">Min</th>
                <th>Status</th>
                <th className="actions-col">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.map((item) => (
                <tr key={item.id}>
                  <td className="name-cell">{item.name}</td>
                  <td>{item.category}</td>
                  <td>{item.location}</td>
                  <td className="num">{item.quantity}</td>
                  <td className="num">{item.minQuantity}</td>
                  <td>
                    {isLowStock(item) ? (
                      <span className="badge badge-warn">Low Stock</span>
                    ) : (
                      <span className="badge badge-ok">In Stock</span>
                    )}
                  </td>
                  <td className="actions-col">
                    <button
                      type="button"
                      className="btn btn-small"
                      onClick={() => startEdit(item)}
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      className="btn btn-small btn-danger"
                      onClick={() => removeItem(item.id)}
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  )
}

export default App
