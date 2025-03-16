import React, {useState} from "react";
import { useParams } from "react-router-dom";
import {FaStar} from "react-icons/fa";
import Heather from '../Components/header_loged.jsx'
import { useNavigate } from 'react-router-dom'
import { FastForward } from "lucide-react";
import PlayCd from '../Components/CDPlayer.jsx';
import PlayVinyl from '../Components/VinylPlayer.jsx';
import Review from '../Components/Review.jsx';

const SongDetails2 = () => {
  const songs = JSON.parse(localStorage.getItem('songs')) || [];
  const { id } = useParams();
  const song = songs.find((s) => s.id === parseInt(id)); 
  const [playCD, setPlayCD] = useState(false);
  const[playPickUp, setPlayPickUp] = useState(false);
  const [review, setReview] = useState(false);
  const calledFromHome = 1;

  
  const reviews = JSON.parse(localStorage.getItem('reviews')) || [];
  const displayReviews = reviews.filter((review) => review.song === song.title);


  const navigate = useNavigate();

  const handleSongClick = (id) => {
    navigate(`/song2/${id}`);
  };

  const handleLiked = () => {
    setReview(true);
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
        <button className="like-button" onClick = {handleLiked}>Add to favorites</button>
        <button className="play-CD" onClick ={() => setPlayCD(true)}>Play CD</button>
        {playCD && (
          <PlayCd 
            songs={[song]}  
            currentSongIndex={0}  
            onSongChange={() => {}} 
            setReview={setReview}
            setPlayCD={setPlayCD}
            calledFrom = {calledFromHome}
          />
        )}
        <button className="play-PickUp" onClick={() => setPlayPickUp(true)}>Play Vinyl</button>
        {playPickUp && (
          <PlayVinyl 
            songs={[song]}  
            currentSongIndex={0}  
            onSongChange={() => {}} 
            setPlayPickUp={setPlayPickUp}
            setReview={setReview}
            calledFrom = {calledFromHome}	
          />
        )}
        {review && (
          <Review 
            songs={[song]} 
            currentSongIndex={0} 
            setReview={setReview} 
          />
        )}
        <Heather />
    </div>
  );
};

export default SongDetails2;
