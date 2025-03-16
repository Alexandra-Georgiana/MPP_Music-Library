import React, { useState, useEffect } from 'react';
import { Search, User, Heart } from "lucide-react";
import { useNavigate } from 'react-router-dom';
import Logo from "../assets/logo.png";

const Header = () => {
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');
  const [songs, setSongs] = useState([]);
  const [filteredSongs, setFilteredSongs] = useState([]);

  useEffect(() => {
    const storedSongs = JSON.parse(localStorage.getItem("songs")) || [];
    setSongs(storedSongs);
  }, []);

  useEffect(() => {
    if (searchTerm.trim() === "") {
      setFilteredSongs([]);
      return;
    }
    const filtered = songs.filter(song =>
      song.title.toLowerCase().includes(searchTerm.toLowerCase())||song.artist.toLowerCase().includes(searchTerm.toLowerCase())
    );
    setFilteredSongs(filtered);
  }, [searchTerm, songs]);

  return (
    <header className="header">
      <img 
        src={Logo} 
        alt="logo" 
        className="logo" 
        onClick={() => navigate('/home2')} 
      />

      <div className="search-container">
        <Search className="search-icon" size={16} />
        <input 
          type="text" 
          placeholder="Search for a song" 
          className="search-input" 
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />

        {filteredSongs.length > 0 && (
          <ul className="dropdown">
            {filteredSongs.map((song, index) => (
              <li 
                key={index} 
                onClick={() => navigate(`/song2/${song.id}`)} 
                className="dropdown-item"
              >
                {song.title} - {song.artist}
              </li>
            ))}
          </ul>
        )}
      </div>

      <Heart 
        size={40} 
        className="heart" 
        onClick={() => navigate('/favorites')} 
      />
      <User 
        size={40} 
        className="user" 
        onClick={() => navigate('/account')} 
      />
    </header>
  );
}

export default Header;
