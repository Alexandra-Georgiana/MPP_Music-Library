import React from "react";
import { useParams } from "react-router-dom";
import {FaStar} from "react-icons/fa";
 import songs from "../assets/mock_songs.js";
import Heather from '../Components/header_loged.jsx'
import { useNavigate } from 'react-router-dom'
import { FastForward } from "lucide-react";

const SongDetails2 = () => {
  const { id } = useParams();
  const song = songs.find((s) => s.id === parseInt(id)); 


  const navigate = useNavigate();

  const handleSongClick = (id) => {
    navigate(`/song2/${id}`);
  };

  if (!song) {
    return <p>Song not found</p>;
  }
  const renderStars = (rating) => {
    return "★★★★★☆☆☆☆☆".slice(5 - rating, 10 - rating);
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
            <img src = {song.image} alt="album_cover" className = "album-cover" />
            <div className = "song-info">
            <b className = "song-title">{song.title}</b>
            <p className = "song-artist">{song.artist}</p>
            <p className = "song-description">{song.description}</p>
            </div>
            <hr className="line4"></hr>
            <p className="rating">{renderStars(song.rating)}</p>
        </div>
    </div>
  );
};

export default SongDetails2;
