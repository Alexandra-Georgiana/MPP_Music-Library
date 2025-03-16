import React, {useState, useEffect} from 'react'
import Header from '../Components/header_loged.jsx'
import {Heart} from "lucide-react"
import AvatarDrk from '../assets/user-avatar-dark.png'
import { useNavigate } from 'react-router-dom'

const account = () => {
  const navigate = useNavigate();
  const storedUser = JSON.parse(localStorage.getItem('currentUser')); 
  const currentUser = Array.isArray(storedUser) ? storedUser[0] : storedUser || {}; 

  const [avatar, setAvatar] = useState(currentUser.avatar || AvatarDrk);

  useEffect(() => {
      if (currentUser.avatar ) {
          setAvatar(currentUser.avatar);
      }
  }, [currentUser.avatar]);
  

    const handleLogout = () => {
        localStorage.removeItem('currentUser');
        navigate('/login');
    };

  return (
    <div className = "basic-page">
        <Header/>
        <div className = "account-info">
            <div className = "title">
                <p className = "title-text">Wellcome</p>
                <span className = "username">{currentUser.username}</span>
            </div>
            <div className = "user-info">
                <div className = "info">
                    <p className = "info-class">Favourite Genre:</p>
                    <p className = "info-text">{currentUser.favoriteGenre}</p>
                </div>
                <div className = "info">
                    <p className = "info-class">Favourite Artist:</p>
                    <p className = "info-text">{currentUser.favoriteArtist}</p>
                </div>
                <div className = "info">
                    <p className = "info-class">Description:</p>
                    <p className = "info-text">{currentUser.bio}</p>
                </div>
                <div className = "info" onClick = {() => navigate('/favorites')}>
                    <Heart size = {32}/>
                    <b className = "fav-text">See your favorite songs</b>
                </div>
            </div>
        </div>
        <div className = "avatar">
        <img 
            src={currentUser.avatar || AvatarDrk} 
            alt="Avatar" 
            className="avatar-img"
            onError={(e) => { e.target.src = AvatarDrk; }} 
            />
            <button className = "edit" onClick = {() => navigate('/edit_profile')}>Edit Profile</button>
            <button className = "logout" onClick = {handleLogout}>Logout</button>
        </div>
    </div>
  )
}

export default account