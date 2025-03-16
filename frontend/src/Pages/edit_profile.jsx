import React, { useState, useEffect } from 'react';
import Header from '../Components/header_loged.jsx';
import User_light from '../assets/user-avatar-light.png';
import { useNavigate } from 'react-router-dom';

const EditProfile = () => {
  const navigate = useNavigate();
  const [favoriteGenre, setFavoriteGenre] = useState('');
  const [favoriteArtist, setFavoriteArtist] = useState('');
  const [bio, setBio] = useState('');
  const [avatar, setAvatar] = useState(User_light);  
  const [selectedImage, setSelectedImage] = useState(null);

  useEffect(() => {
    const currentUser = JSON.parse(localStorage.getItem('currentUser'));
    

    if (currentUser) {
      setFavoriteGenre(currentUser.favoriteGenre || '');
      setFavoriteArtist(currentUser.favoriteArtist || '');
      setBio(currentUser.bio || '');
      setAvatar(currentUser.avatar || User_light); 
    }
  }, []);

  const handleSave = () => {
    const users = JSON.parse(localStorage.getItem('users')) || [];
    const storedUser = JSON.parse(localStorage.getItem('currentUser'));
    const currentUser = Array.isArray(storedUser) ? storedUser[0] : storedUser;

    if (!currentUser) {
        alert("User not found!");
        return;
    }

    const currentUserIndex = users.findIndex((user) => user.email === currentUser.email);

    const updatedUser = {
        ...currentUser,
        ...(favoriteGenre.trim() !== "" && { favoriteGenre }),
        ...(favoriteArtist.trim() !== "" && { favoriteArtist }),
        ...(bio.trim() !== "" && { bio }),
        ...(avatar !== User_light && { avatar }),
    };

    if (currentUserIndex !== -1) {
        users[currentUserIndex] = updatedUser;
    } else {
        users.push(updatedUser); 
    }

    localStorage.setItem('users', JSON.stringify(users));
    localStorage.setItem('currentUser', JSON.stringify(updatedUser)); 

    alert('Profile updated successfully');
    navigate('/account');
  };


  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      const imageUrl = URL.createObjectURL(file);
      setAvatar(imageUrl); 
      setSelectedImage(file); 
    }
  };

  const triggerFileInput = () => {
    document.getElementById('fileInput').click();
  };

  return (
    <div className="background_gradient">
      <Header />
      <div className="edit-info">
        <div className="field">
          <p className="info-class">What is your favorite genre?</p>
          <input
            type="text"
            className="field_input"
            value={favoriteGenre}
            onChange={(e) => setFavoriteGenre(e.target.value)}
          />
        </div>
        <div className="field">
          <p className="info-class">What is your favorite artist?</p>
          <input
            type="text"
            className="field_input"
            value={favoriteArtist}
            onChange={(e) => setFavoriteArtist(e.target.value)}
          />
        </div>
        <div className="field">
          <p className="info-class">Tell us something about yourself:</p>
          <input
            type="text"
            className="field_input"
            value={bio}
            onChange={(e) => setBio(e.target.value)}
          />
        </div>
        <div className="upload_img">
          <p className="info-class" onClick={triggerFileInput}>UPLOAD PICTURE</p>
          
          <input
            type="file"
            accept="image/*"
            id="fileInput"
            style={{ display: 'none' }}
            onChange={handleImageUpload}
          />
        </div>
      </div>
      <div className="avatar">
        <img src={avatar} alt="Avatar" className="avatar-img" />
        <button className="cancel" onClick = {()=>navigate('/account')}>Cancel</button>
        <button className="save" onClick={handleSave}>Save</button>
      </div>
    </div>
  );
};

export default EditProfile;
