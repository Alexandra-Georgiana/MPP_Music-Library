import React from 'react'
import Header from '../Components/header.jsx'
import Left from "../assets/login.jpg"

const signin = () => {
  return (
    <div className = "basic-page">
            <div className = "image-gradient">
                <img src={Left} alt="left" className = "left-image"/>
            </div>
            <div className = "login-form">
                <p className = "login-form-title">Sign in</p>
                <input type = "text" placeholder = "Username" className = "form-input"/>
                <input type = "text" placeholder = "Email" className = "form-input"/>
                <input type = "password" placeholder = "Password" className = "form-input"/>
                <input type = "password" placeholder = "Confirm Password" className = "form-input"/>
                <div className = "remember-me">
                    <input type = "checkbox" className = "checkbox"/>
                    <label>Remember me</label>
                </div>
                <hr className="line3"></hr>
                <div className="have-account1">
                    <p style={{color: "black", fontSize: "17px"}}>Already have an account?</p>
                    <p style={{color: "white", fontWeight: "bold", fontSize:"20px"}}>Log in</p>
                </div>
                <button className = "login">Sign In</button>
            </div>
            <Header />
        </div>
  )
}

export default signin