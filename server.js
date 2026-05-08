// Express is the web framework — it handles incoming HTTP requests
const express = require('express');

// We import our database functions from the file we just created
const {
  initialiseDatabase,
  getAllTransactions,
  addTransaction,
  deleteTransaction
} = require('./database');

// Create an Express application
const app = express();

// This tells Express to automatically parse incoming JSON request bodies
// Without this, req.body would be undefined when someone POSTs JSON data
app.use(express.json());

// This tells Express to serve any files inside the /public folder automatically
// So when someone visits http://localhost:3000 they get public/index.html
app.use(express.static('public'));

// Set up the database (creates the table if it doesn't exist)
initialiseDatabase();

// --- Routes ---
// A route is just: "when someone sends THIS type of request to THIS URL, do THIS"

// GET /api/transactions
// Returns all transactions as a JSON array
app.get('/api/transactions', (req, res) => {
  const transactions = getAllTransactions();
  res.json(transactions);
});

// POST /api/transactions
// Adds a new transaction
// req.body contains the data sent from the frontend
app.post('/api/transactions', (req, res) => {
  const { type, category, description, amount, date } = req.body;

  // Basic validation — make sure nothing is missing
  if (!type || !category || !description || !amount || !date) {
    // 400 means "Bad Request" — the client sent incomplete data
    return res.status(400).json({ error: 'All fields are required' });
  }

  const result = addTransaction(type, category, description, amount, date);

  // 201 means "Created" — a new resource was successfully created
  res.status(201).json({ id: result.lastInsertRowid });
});

// DELETE /api/transactions/:id
// The :id is a URL parameter — e.g. DELETE /api/transactions/5 deletes transaction with id 5
app.delete('/api/transactions/:id', (req, res) => {
  const { id } = req.params;
  deleteTransaction(id);

  // 200 means "OK"
  res.json({ message: 'Transaction deleted' });
});

// Start the server and listen on port 3000
// process.env.PORT means "use the PORT environment variable if it exists"
// This is important later when we deploy to AWS — it sets the port for us
// If no environment variable is set, fall back to 3000 locally
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Budget tracker running on http://localhost:${PORT}`);
});