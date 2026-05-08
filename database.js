// We import the better-sqlite3 library
// This gives us a Database class we can use to interact with SQLite
const Database = require('better-sqlite3');

// This creates (or opens if it already exists) a file called budget.db
// Think of this file as your entire database living in one place
const db = new Database('budget.db');

// This function sets up our database table the first time the app runs
// If the table already exists, it does nothing (that's what IF NOT EXISTS does)
function initialiseDatabase() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS transactions (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      type      TEXT    NOT NULL,
      category  TEXT    NOT NULL,
      description TEXT  NOT NULL,
      amount    REAL    NOT NULL,
      date      TEXT    NOT NULL
    )
  `);
  // id          — a unique number for each transaction, auto increments (1, 2, 3...)
  // type        — either "income" or "expense"
  // category    — e.g. "Food", "Salary", "Rent"
  // description — a short note e.g. "Woolworths grocery run"
  // amount      — the dollar value e.g. 45.50
  // date        — stored as text in YYYY-MM-DD format
}

// --- These are our database functions (one per operation) ---

// Get every transaction, newest first
function getAllTransactions() {
  return db.prepare('SELECT * FROM transactions ORDER BY date DESC').all();
}

// Add a new transaction
// The ? marks are placeholders — better-sqlite3 fills them in safely
// This prevents SQL injection attacks
function addTransaction(type, category, description, amount, date) {
  const stmt = db.prepare(
    'INSERT INTO transactions (type, category, description, amount, date) VALUES (?, ?, ?, ?, ?)'
  );
  return stmt.run(type, category, description, amount, date);
}

// Delete a transaction by its id
function deleteTransaction(id) {
  return db.prepare('DELETE FROM transactions WHERE id = ?').run(id);
}

// We export everything so server.js can import and use these functions
module.exports = {
  initialiseDatabase,
  getAllTransactions,
  addTransaction,
  deleteTransaction
};