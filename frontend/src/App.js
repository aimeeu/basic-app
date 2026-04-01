import React, { useState, useEffect } from 'react';
import './App.css';

// Read the backend API URL injected at container startup via env-config.js.
// Falls back to the REACT_APP_BACKEND_API_URL build-time variable or localhost.
function getBackendUrl() {
  if (window.__ENV && window.__ENV.BACKEND_API_URL) {
    return window.__ENV.BACKEND_API_URL;
  }
  return process.env.REACT_APP_BACKEND_API_URL || 'http://localhost:8080';
}

function App() {
  const [items, setItems] = useState([]);
  const [health, setHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const backendUrl = getBackendUrl();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [itemsRes, healthRes] = await Promise.all([
          fetch(`${backendUrl}/api/items`),
          fetch(`${backendUrl}/health`),
        ]);

        if (!itemsRes.ok) throw new Error(`Items request failed: ${itemsRes.status}`);
        if (!healthRes.ok) throw new Error(`Health request failed: ${healthRes.status}`);

        const itemsData = await itemsRes.json();
        const healthData = await healthRes.json();

        setItems(itemsData);
        setHealth(healthData);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [backendUrl]);

  return (
    <div className="app">
      <header className="app-header">
        <h1>Basic App</h1>
        <p className="api-url">Backend API: <code>{backendUrl}</code></p>
      </header>

      <main className="app-main">
        <section className="health-section">
          <h2>API Health</h2>
          {loading && <p className="loading">Loading…</p>}
          {error && <p className="error">Error: {error}</p>}
          {health && (
            <div className="health-card">
              <span className={`status status--${health.status}`}>{health.status}</span>
              <span className="timestamp">{health.timestamp}</span>
              <span className="version">v{health.version}</span>
            </div>
          )}
        </section>

        <section className="items-section">
          <h2>Items</h2>
          {loading && <p className="loading">Loading…</p>}
          {error && <p className="error">Error: {error}</p>}
          {!loading && !error && (
            <ul className="items-list">
              {items.map((item) => (
                <li key={item.id} className="item-card">
                  <h3>{item.name}</h3>
                  <p>{item.description}</p>
                </li>
              ))}
            </ul>
          )}
        </section>
      </main>
    </div>
  );
}

export default App;
