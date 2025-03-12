import React from 'react'
import Heather from '../Components/header.jsx'
import Empty from '../assets/empty.png'
import songs from "../assets/mock_songs.js"
import { useNavigate } from 'react-router-dom'

const home1 = () => {
  const navigate = useNavigate();

  const handleSongClick = (id) => {
    navigate(`/song1/${id}`);
  };

  return (
    <div className="basic-page">
        <Heather />
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
    </div>
  )
}

export default home1
