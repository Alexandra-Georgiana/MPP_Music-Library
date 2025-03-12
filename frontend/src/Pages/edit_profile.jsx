import React from 'react'
import Header from '../Components/header_loged.jsx'
import User_light from '../assets/user-avatar-light.png'

const edit_profile = () => {
  return (
    <div className = "background_gradient">
        <Header/>
        <div className = "edit-info">
            <div className = "field">
                <p className = "info-class">What is your favorite ganra?</p>
                <input type="text" className = "field_input"/>
            </div>
            <div className = "field">
                <p className = "info-class">What is your favorite artist?</p>
                <input type="text" className = "field_input"/>
            </div>
            <div className = "field">
                <p className = "info-class">Tell us something about yourself: </p>
                <input type="text" className = "field_input"/>
            </div>
            <div className = "upload_img">
                <p className = "info-class">UPLOAD PICTURE</p>
            </div>
        </div>
        <div className = "avatar">
            <img src = {User_light} alt = "Avatar" className = "avatar-img"/>
            <button className = "cancel">Cancel</button>
            <button className = "save">Save </button>
        </div>
    </div>
  )
}

export default edit_profile