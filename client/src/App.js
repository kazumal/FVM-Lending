import React from "react";

const App = () => {
  return (
    <div className="container">
      <header className="header">
        <h1>My Web App</h1>
      </header>
      <nav className="nav">
        <ul>
          <li>
            <a href="#">Home</a>
          </li>
          <li>
            <a href="#">About</a>
          </li>
          <li>
            <a href="#">Contact</a>
          </li>
        </ul>
      </nav>
      <main className="main">
        <p>Welcome to my web app!</p>
      </main>
      <footer className="footer">
        <p>Copyright © 2023 My Web App</p>
      </footer>
    </div>
  );
};

export default App;
