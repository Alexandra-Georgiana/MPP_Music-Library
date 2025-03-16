import React, {useState} from "react";
import { useParams } from "react-router-dom";
import {FaStar} from "react-icons/fa";
import Heather from '../Components/header.jsx'
import { useNavigate } from 'react-router-dom'
import { FastForward } from "lucide-react";

const SongDetails = () => {
  const songs = JSON.parse(localStorage.getItem('songs')) || [];
  const { id } = useParams();
  const song = songs.find((s) => s.id === parseInt(id)); 

    
  const reviews = JSON.parse(localStorage.getItem('reviews')) || [];
  const displayReviews = reviews.filter((review) => review.song === song.title);

  const navigate = useNavigate();

  const handleSongClick = (id) => {
    navigate(`/song1/${id}`);
  };

  if (!song) {
    return <p>Song not found</p>;
  }
  const renderStars = (rating) => {
    return "★★★★★☆☆☆☆☆".slice(5 - rating, 10 - rating);
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
            <img src = {song.image} alt="album_cover" className = "album-cover" />
            <div className = "song-info">
            <b className = "song-title">{song.title}</b>
            <p className = "song-artist">{song.artist}</p>
            <p className = "song-description">{song.description}</p>
            </div>
            <hr className="line4"></hr>
            <p className="rating">{renderStars(song.rating)}</p>
            <ul className="reviews">
              {displayReviews.map((review) => (
                <li key={review.id} className="review-item">
                  <p className="review-user">{review.user}: {review.impression}</p>
                </li>
              ))}
            </ul>
        </div>
        <button className="like-button" onClick = {() => navigate('/signin')}>Add to favorites</button>
        <button className="play-CD" onClick ={() => navigate('/signin')}>Play CD</button>
        <button className="play-PickUp" onClick={() => navigate('/signin')}>Play Vinyl</button>
        <Heather />
    </div>
  );
};

export default SongDetails;
