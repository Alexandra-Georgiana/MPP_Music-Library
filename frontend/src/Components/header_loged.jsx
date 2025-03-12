import {React, useState} from 'react'
import { Search } from "lucide-react";
import Logo from "../assets/logo.png"
import {User} from "lucide-react"
import { Heart } from 'lucide-react';

const heather = () => {
  return (
    <header>
        <img src = {Logo} alt="logo" className="logo"/>
        <div className="search-container">
            <Search className="search-icon" size={16} />
            <input type="text" placeholder="   Search for song" className="search-input"/>
        </div>
        <Heart size = {40} className = "heart"/>
        <User size = {40} className = "user"/>
    </header>
  )
}

export default heather