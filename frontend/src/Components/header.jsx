import {React, useState, useEffect} from 'react'
import { Search } from "lucide-react";
import Logo from "../assets/logo.png"
import {useNavigate} from 'react-router-dom'

const heather = () => {
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
    <header>
        <img src = {Logo} alt="logo" className="logo" onClick = {() => navigate('/home1')}/>
        <div className="search-container">
            <Search className="search-icon" size={16} />
            <input type="text" placeholder="   Search for song" className="search-input"/>
            {filteredSongs.length > 0 && (
              <ul className="dropdown">
                {filteredSongs.map((song, index) => (
                  <li 
                    key={index} 
                    onClick={() => navigate(`/song1/${song.id}`)} 
                    className="dropdown-item"
                  >
                    {song.title} - {song.artist}
                  </li>
                ))}
              </ul>
            )}
        </div>
        <button className = "log" onClick = {() => navigate('/login')}>LogIn</button>
        <button className = "sign" onClick = {() => navigate('/signin')}>Register</button>
    </header>
  )
}

export default heather