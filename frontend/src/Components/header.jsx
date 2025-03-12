import {React, useState} from 'react'
import { Search } from "lucide-react";
import Logo from "../assets/logo.png"

const heather = () => {
  return (
    <header>
        <img src = {Logo} alt="logo" className="logo"/>
        <div className="search-container">
            <Search className="search-icon" size={16} />
            <input type="text" placeholder="   Search for song" className="search-input"/>
        </div>
        <button className = "log">LogIn</button>
        <button className = "sign">Register</button>
    </header>
  )
}

export default heather