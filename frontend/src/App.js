import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Get API endpoint from environment or use a default
const API_ENDPOINT = process.env.REACT_APP_API_ENDPOINT || 'http://localhost:8000';

function App() {
  const [todos, setTodos] = useState([]);
  const [newTodo, setNewTodo] = useState({ title: '', description: '' });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchTodos();
  }, []);

  const fetchTodos = async () => {
    setLoading(true);
    try {
      const response = await axios.get(`${API_ENDPOINT}/todos`);
      setTodos(response.data);
      setError(null);
    } catch (err) {
      setError('Error fetching todos. Make sure the API is running.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewTodo({ ...newTodo, [name]: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!newTodo.title.trim()) return;

    try {
      const response = await axios.post(`${API_ENDPOINT}/todos`, newTodo);
      setTodos([...todos, response.data]);
      setNewTodo({ title: '', description: '' });
      setError(null);
    } catch (err) {
      setError('Error creating todo.');
      console.error(err);
    }
  };

  const handleToggleComplete = async (id, todo) => {
    try {
      const updated = { ...todo, completed: !todo.completed };
      const response = await axios.put(`${API_ENDPOINT}/todos/${id}`, updated);
      setTodos(todos.map(t => t.id === id ? response.data : t));
      setError(null);
    } catch (err) {
      setError('Error updating todo.');
      console.error(err);
    }
  };

  const handleDelete = async (id) => {
    try {
      await axios.delete(`${API_ENDPOINT}/todos/${id}`);
      setTodos(todos.filter(t => t.id !== id));
      setError(null);
    } catch (err) {
      setError('Error deleting todo.');
      console.error(err);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Todo App</h1>
        <p>Powered by FastAPI, React, and PostgreSQL, deployed with Terraform</p>
      </header>

      <main>
        {error && <div className="error">{error}</div>}
        
        <form onSubmit={handleSubmit} className="todo-form">
          <h2>Add New Todo</h2>
          <div>
            <input
              type="text"
              name="title"
              placeholder="Title"
              value={newTodo.title}
              onChange={handleInputChange}
              required
            />
          </div>
          <div>
            <textarea
              name="description"
              placeholder="Description"
              value={newTodo.description}
              onChange={handleInputChange}
            />
          </div>
          <button type="submit">Add Todo</button>
        </form>

        <div className="todos-container">
          <h2>Your Todos</h2>
          {loading ? (
            <p>Loading todos...</p>
          ) : todos.length === 0 ? (
            <p>No todos yet. Add one above!</p>
          ) : (
            <ul className="todos-list">
              {todos.map((todo) => (
                <li key={todo.id} className={`todo-item ${todo.completed ? 'completed' : ''}`}>
                  <div className="todo-content">
                    <h3>{todo.title}</h3>
                    <p>{todo.description}</p>
                  </div>
                  <div className="todo-actions">
                    <button
                      onClick={() => handleToggleComplete(todo.id, todo)}
                      className="toggle-btn"
                    >
                      {todo.completed ? 'Mark Incomplete' : 'Mark Complete'}
                    </button>
                    <button
                      onClick={() => handleDelete(todo.id)}
                      className="delete-btn"
                    >
                      Delete
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      </main>
    </div>
  );
}

export default App; 