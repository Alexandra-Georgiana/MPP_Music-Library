import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import bcrypt from 'bcryptjs';

const AdminLogin = () => {
    const navigate = useNavigate();
    const [username, setUsername] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');

    const handleSubmit = () => {
        const storedAdmin = JSON.parse(localStorage.getItem('admin'));

        if (!storedAdmin) {
            alert('No admin account found.');
            return;
        }

        const isEmailValid = storedAdmin.email === email;
        const isUsernameValid = storedAdmin.username === username;
        const isPasswordValid = bcrypt.compareSync(password, storedAdmin.password);  // Compare hashed password

        if (!isEmailValid || !isUsernameValid || !isPasswordValid) {
            alert('Invalid credentials');
            return;
        }

        localStorage.setItem('currentUser', JSON.stringify(storedAdmin));
        navigate('/admin');
    };

    return (
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: "100vh", gap: "10px" }}>
            <p style={{ color: "white", fontSize: "40px", fontWeight: "bold" }}>Log in Admin</p>
            <input type="text" placeholder="Username" style={{width: "100%", height: "4%"}} value={username} onChange={(e) => setUsername(e.target.value)} />
            <input type="text" placeholder="Email" style={{width: "100%", height: "4%"}} value={email} onChange={(e) => setEmail(e.target.value)} />
            <input type="password" placeholder="Password" style={{width: "100%", height: "4%"}} value={password} onChange={(e) => setPassword(e.target.value)} />
            <button style={{ marginTop: "20%", width: "100%", backgroundColor: "#a2a4a6" }} onClick={handleSubmit}>Log In</button>
        </div>
    );
};

export default AdminLogin;
