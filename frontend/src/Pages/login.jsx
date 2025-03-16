import React, {useState} from 'react'
import Header from '../Components/header.jsx'
import Left from "../assets/login.jpg"
import { useNavigate } from 'react-router-dom'

const login = () => {
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [remember, setRemember] = useState(false);

  const validatePassword = () => {
    const regex = /^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    return regex.test(password);
  }

  const handleSubmit = () => {
    const user = JSON.parse(localStorage.getItem('users')) || [];
    const emailExists = user.find(user => user.email === email);
    const usernameExists = user.find(user => user.username === username);
    const passwordExists = user.find(user => user.password === password);

    if(!emailExists || !usernameExists || !passwordExists){
      alert('Invalid credentials');
      return;
    }

    if(!validatePassword()){
      alert('Password must contain at least 8 characters, one uppercase, one number and one special character');
      return;
    }

    localStorage.setItem('currentUser', JSON.stringify(user));
    navigate('/account');

  };
  return (
    <div className = "basic-page">
        <div className = "image-gradient">
            <img src={Left} alt="left" className = "left-image"/>
        </div>
        <div className = "login-form">
            <p className = "login-form-title">Log in</p>
            <input type = "text" placeholder = "Username" className = "form-input" value = {username} onChange ={(e) => setUsername(e.target.value)}/>
            <input type = "text" placeholder = "Email" className = "form-input" value = {email} onChange ={(e) => setEmail(e.target.value)}/>
            <input type = "password" placeholder = "Password" className = "form-input" value = {password} onChange ={(e) => setPassword(e.target.value)}/>
            <div className="alshimer">
                <div>
                    <input type = "checkbox" className = "checkbox" value = {remember} onChange ={() => setRemember(true)}/>
                    <label>Remember me</label>
                </div>
                <span className = "forgot-pswd">Forgot password?</span>
            </div>
            <hr className="line3"></hr>
            <div className="have-account1">
                <p style={{color: "black", fontSize: "1.3vw"}}>Don't have an account?</p>
                <p style={{color: "white", fontWeight: "bold", fontSize:"1.4vw", cursor: "pointer"}} onClick={() => navigate('/signin')}>Sign in</p>
            </div>
            <button className = "login" onClick = {handleSubmit}>LogIn</button>
        </div>
        <Header />
    </div>

  )
}

export default login