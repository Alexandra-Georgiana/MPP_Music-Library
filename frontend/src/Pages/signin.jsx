import React, {useState} from 'react'
import Header from '../Components/header.jsx'
import Left from "../assets/login.jpg"
import { useNavigate } from 'react-router-dom'

const signin = () => {
  const navigate = useNavigate();
  
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [remember, setRemember] = useState(false);
  const bio = '';
  const favoriteGenre = '';
  const favoriteArtist = '';
  const avatar = '';
  const mostPlayed = '';

  const validatePassword = () => {
    const regex = /^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    return regex.test(password);
  }

  const handleSubmit = () => {
    const users = JSON.parse(localStorage.getItem('users')) || [];

    const emailExists = users.find(user => user.email === email);
    if (emailExists) {
      alert('Email already exists');
      return;
    }

    const usernameExists = users.find(user => user.username === username);
    if (usernameExists) {
        alert('Choose another username');
        return;
    }

    if (password !== confirmPassword) {
      alert('Passwords do not match');
      return;
    }

    if (!validatePassword()) {
      alert('Password must contain at least 8 characters, one uppercase letter, one number and one special character');
      return;
    }

    const newUser = {
      username,
      email,
      password,
      bio,
      favoriteGenre,
      favoriteArtist,
      avatar,
    };

    localStorage.setItem('users', JSON.stringify([...users, newUser]));
    localStorage.setItem('currentUser', JSON.stringify(newUser));
    navigate('/account');
  };

  return (
    <div className = "basic-page">
            <div className = "image-gradient">
                <img src={Left} alt="left" className = "left-image"/>
            </div>
            <div className = "login-form">
                <p className = "login-form-title">Sign in</p>
                <input type = "text" placeholder = "Username" className = "form-input" value = {username} onChange ={(e) => setUsername(e.target.value)} />
                <input type = "text" placeholder = "Email" className = "form-input" value = {email} onChange ={(e) => setEmail(e.target.value)}/>
                <input type = "password" placeholder = "Password" className = "form-input" value = {password} onChange ={(e) => setPassword(e.target.value)}/>
                <input type = "password" placeholder = "Confirm Password" className = "form-input" value = {confirmPassword} onChange ={(e) => setConfirmPassword(e.target.value)}/>
                <div className = "remember-me">
                    <input type = "checkbox" className = "checkbox" value = {remember} onChange={() => setRemember(true)}/>
                    <label>Remember me</label>
                </div>
                <hr className="line3"></hr>
                <div className="have-account1">
                    <p style={{color: "black", fontSize: "1.2vw"}}>Already have an account?</p>
                    <b style={{color: "white", fontSize:"1.3vw", cursor: "pointer"}} onClick = {() => navigate('/login')}>Log in</b>
                </div>
                <button className = "login" onClick = {handleSubmit}>Sign In</button>
            </div>
            <Header />
        </div>
  )
}

export default signin