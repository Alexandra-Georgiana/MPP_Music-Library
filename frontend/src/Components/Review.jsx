import React, {useRef,useState} from 'react'
import { useEffect } from 'react';
import Draggable from 'react-draggable';
import { X } from 'lucide-react';

const Review = ({songs, currentSongIndex, setReview}) => {
    
  const reviewRef = useRef(null);
  const [rating, setRating] = useState(0);
  const [impression, setImpression] = useState("");
  const currentSong = songs[currentSongIndex];


  const handleSubmit = () => {
    const currentUser = JSON.parse(localStorage.getItem('currentUser'));
    const user = currentUser.username;
    const likedSongs = JSON.parse(localStorage.getItem('likedSongs')) || [];
    const song = currentSong.title;
    const songRating = currentSong.rating;
    const reviews = JSON.parse(localStorage.getItem('reviews')) || [];
    const allSongs = JSON.parse(localStorage.getItem('songs')) || [];
    const songIndex = allSongs.findIndex((s) => s.title === song);
    const newReview = songRating === 0 ? rating : (rating + songRating) / 2;
  
    const updatedReview = {
      user,
      song,
      impression,
    };
  
    const updatedLikedSongs = {
      user,
      ...currentSong,
      rating,
    };

    allSongs[songIndex].rating = newReview;
    localStorage.setItem('songs', JSON.stringify(allSongs));
  
    localStorage.setItem('reviews', JSON.stringify([...reviews, updatedReview])); // Store as an array
    localStorage.setItem('likedSongs', JSON.stringify([...likedSongs, updatedLikedSongs])); // Store as an array
  
    alert('Review submitted successfully'); 
    setReview(false); 
  };
  

  return (
    <Draggable nodeRef={reviewRef}>
          <div ref={reviewRef} className="review-widget" style={{
              position: "fixed",
              top: "50%",
              left: "50%",
              transform: "translate(-50%, -50%)",
              background: "linear-gradient(135deg,rgb(99, 5, 5),rgb(10, 7, 7))",
              padding: "20px",
              borderRadius: "10px",
              zIndex: 1000,
              color: "white",
              width: "37%"
          }}>
            <div className="review-header" style={{
                display: "flex",
                marginTop: "-50px",
                justifyContent: "space-between",
                alignItems: "center"
            }}>
              <p style={{ fontSize: "18px", fontWeight: "bold", fontFamily: "Economica", fontSize:"42px" }}>Share Your Thoughts</p>
              <button onClick={() => setReview(false)} style={{
                  background: "transparent",
                  border: "none",
                  color: "white",
                  cursor: "pointer"
              }}>
                <X size={20} />
              </button>
            </div>

           <div style = {{display: "flex", marginTop: "-20px", marginBottom: "50px" }}>
                <div style={{ textAlign: "start"}}>
                    <img src={currentSong.image} alt="Album Cover" style={{ width: "150px", height: "150px", borderRadius: "10px"}} />
                </div>

                <div style={{display: "flex", flexDirection: "column", justifyContent: "space-between", marginLeft: "30px"}}>   
                    <div style={{ display: "flex", justifyContent: "start", gap: "5px", marginBottom: "10px" }}>
                    {Array.from({ length: 5 }).map((_, index) => (
                        <span 
                        key={index} 
                        onClick={() => setRating(index + 1)}
                        onChange={(e) => setRating(e.target.value)}
                        style={{ cursor: "pointer", fontSize: "20px", color: index < rating ? "#FFD700" : "gray" }}
                        >
                        ★
                        </span>
                    ))}
                    </div>

                    <textarea 
                    placeholder="Write a review..." 
                    value={impression} 
                    onChange={(e) => setImpression(e.target.value)}
                    style={{
                        width: "200%",
                        height: "80px",
                        background: "transparent",
                        color: "white",
                        border: "none",
                        padding: "10px",
                        borderRadius: "5px",
                        marginBottom: "10px"
                    }}
                    />
                </div>
           </div>

            <div style={{ display: "flex", justifyContent: "end", gap: "20px" }}>
              <button 
                onClick={() => 
                  setReview(false)} 
                style={{ width: "30%", background: "white", padding: "8px", borderRadius: "40px", color: "black" }}
              >
                Cancel
              </button>
              <button 
                onClick={() => { 
                  handleSubmit();
                  setReview(false);
                }} 
                style={{ width: "30%", background: "white", padding: "8px", borderRadius: "40px", color: "black"}}
              >
                Add
              </button>
            </div>
          </div>
        </Draggable>
  )
}

export default Review