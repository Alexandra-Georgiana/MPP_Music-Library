import React, { useEffect, useRef, useState } from 'react';
import Draggable from 'react-draggable';
import PickUp from "../assets/PickUpBase.svg";
import Stylus from "../assets/PickUpStylus.svg";
import Vinyl from "../assets/Vinyl.svg"; 
import {X} from 'lucide-react';


const VinylPlayer = ({ songs, currentSongIndex, onSongChange, setPlayPickUp, calledFrom, setReview}) => {
  const audioRef = useRef(null);
  const nodeRef = useRef(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);

  const currentSong = songs[currentSongIndex];

  const togglePlayPause = () => {
    if (isPlaying) {
      audioRef.current.pause();
    } else {
      audioRef.current.play();
    }
    setIsPlaying(!isPlaying);
  };

  const handleNext = () => {
    const nextIndex = (currentSongIndex + 1) % songs.length;
    onSongChange(nextIndex);
  };

  const handlePrev = () => {
    const prevIndex = (currentSongIndex - 1 + songs.length) % songs.length;
    onSongChange(prevIndex);
  };

  const handleTimeUpdate = () => {
    const currentTime = audioRef.current.currentTime;
    const duration = audioRef.current.duration || 1;
    setProgress((currentTime / duration) * 100);
  };

  const handleSeek = (e) => {
    const duration = audioRef.current.duration;
    if (duration && isFinite(duration)) {
      const seekTime = (e.target.value / 100) * duration;
      audioRef.current.currentTime = seekTime;
    } else {
      console.warn("Invalid audio duration", duration);
    }
  };

  const handleSongEnd = () => {
    if (calledFrom === 1) {
      setReview(true);
      setPlayPickUp(false);
    }else{ 
      handleNext();}
  };



  useEffect(() => {
    setProgress(0);
    if (audioRef.current) {
      audioRef.current.pause();  
      audioRef.current.currentTime = 0;  
      audioRef.current.play().catch((err) => {
        console.error("Audio play error:", err);
      });
    }
    setIsPlaying(true); 
  }, [currentSongIndex]);  

  if (!setPlayPickUp) {
    return null;
  }

  return (
    <Draggable nodeRef={nodeRef}>
      <div ref={nodeRef} className="music-widget">
        <div className="cd-widget-content">
        <button 
          className="close-button" 
          onClick={() => setPlayPickUp(false)} 
          style={{
            position: 'absolute',
            top: '10px',
            right: '10px',
            background: 'transparent',
            border: 'none',
            color: 'white',
            cursor: 'pointer',
            zIndex: '10',
          }} 
        >
          <X size={20} />
        </button>
          <div className = "play-bar">
              <img src={Stylus} alt="Stylus" style={{width: "60%", height: "60%", marginTop:"-170px", marginLeft:"-90px", position: "absolute", zIndex: "9999"}}/>
              <img src={Vinyl} alt="Vinyl" style={{width: "55%", height: "55%", marginTop:"-100px", marginLeft:"40px", position: "absolute", animation: "rotate 6s linear infinite"}}/>
              <img src={PickUp} alt="PickUp" style={{width: "80%", height: "80%", marginTop:"15px"}}/>
            <input type="range" value={progress} onChange={handleSeek} />
              <div className="buttons">
                <button onClick={handlePrev}>⏮</button>
                <button onClick={togglePlayPause}>
                  {isPlaying ? '⏸' : '▶'}
                </button>
                <button onClick={handleNext}>⏭</button>
              </div>
          </div>
          <div className="controls">
            <div className="cd-image">
              <img src={currentSong.image} alt="album cover" style={{color: "white"}}/>
            </div>
            <p>{currentSong.title}-{currentSong.artist}</p> 
          </div>
        </div>
        <audio
          ref={audioRef}
          src={currentSong.audio}
          onTimeUpdate={handleTimeUpdate}
          onEnded={handleSongEnd}
        />
      </div>
    </Draggable>
  );
};

export default VinylPlayer;
