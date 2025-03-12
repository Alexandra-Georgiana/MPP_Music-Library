import React from 'react'
import Header from '../Components/header_loged.jsx'
import {Heart} from "lucide-react"
import AvatarDrk from '../assets/user-avatar-dark.png'

const account = () => {
  return (
    <div className = "basic-page">
        <Header/>
        <div className = "account-info">
            <div className = "title">
                <p className = "title-text">Wellcome</p>
                <span className = "username">Username</span>
            </div>
            <div className = "user-info">
                <div className = "info">
                    <p className = "info-class">Favourite Song:</p>
                    <p className = "info-text">Song</p>
                </div>
                <div className = "info">
                    <p className = "info-class">Favourite Artist:</p>
                    <p className = "info-text">Song</p>
                </div>
                <div className = "info">
                    <p className = "info-class">Most Played: </p>
                    <p className = "info-text">Song</p>
                </div>
                <div className = "info">
                    <p className = "info-class">Description:</p>
                    <p className = "info-text">Song</p>
                </div>
                <div className = "info">
                    <Heart size = {32}/>
                    <b className = "fav-text">See your favorite songs</b>
                </div>
            </div>
        </div>
        <div className = "avatar">
            <img src = {AvatarDrk} alt = "Avatar" className = "avatar-img"/>
            <button className = "edit">Edit Profile</button>
        </div>
    </div>
  )
}

export default account