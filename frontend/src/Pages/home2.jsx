import React from 'react'
import Heather from '../Components/header_loged.jsx'
import Empty from '../assets/empty.png'
import { useNavigate } from 'react-router-dom'

const home2 = () => {
  const navigate = useNavigate();
  const songs = JSON.parse(localStorage.getItem('songs')) || [];

  const handleSongClick = (id) => {
    navigate(`/song2/${id}`);
  };

  return (
    <div className="basic-page">
        <div className = "song-list">
            <p className = "song-list-title">Library</p>
            <hr className="line"></hr>
            <div className = "scrolable-song-list">
                <ul className = "songs">
                {songs.map((song, index) => (
                  <li key={song.id} onClick={() => handleSongClick(song.id)} className="song-item">
                    <strong>{index + 1}. {song.title}</strong> - {song.artist}
                  </li>
                ))}
                </ul>
            </div>
        </div>
        <div className = "song-details">
            <img src = {Empty} alt="empty" className = "empty-image" />
            <b className = "discover-text">Discover Your Next Favorite Song</b>
            <p className = "discover-description">Browse our extensive library, <br/> choose a track, and uncover details about the music you love.</p>
            <hr className="line2"></hr>
        </div>
        <Heather />
    </div>
  )
}

export default home2
