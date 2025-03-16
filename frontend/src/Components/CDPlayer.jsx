import React, { useEffect, useRef, useState } from 'react';
import Draggable from 'react-draggable';
import AstroPlayer from "../assets/AstroPlayer.svg";
import CD from "../assets/CD.svg"; 
import { X } from 'lucide-react';
import Review from './Review.jsx';

const CDPlayer = ({ songs, currentSongIndex, onSongChange, setReview, setPlayCD, calledFrom }) => {
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
    }
  };
  const handleSongEnd = () => {
    if (calledFrom === 1) {
      setReview(true);  
      setPlayCD(false);
    } else { 
      handleNext();
    }
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

  if (!setPlayCD) {
    return null;
  }

  return (
    <>
      <Draggable nodeRef={nodeRef}>
        <div ref={nodeRef} className="music-widget">
          <div className="cd-widget-content">
            <button 
              className="close-button" 
              onClick={() => setPlayCD(false)} 
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
            <div className="play-bar">
              <img src={CD} alt="CD" style={{width: "60%", height: "60%", marginTop:"-130px", position: "absolute", animation: "rotate 6s linear infinite"}}/>
              <img src={AstroPlayer} alt="AstroPlayer" style={{width: "70%", height: "70%", marginTop:"15px"}}/>
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
              <p>{currentSong.title} - {currentSong.artist}</p> 
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
    </>
  );
};

export default CDPlayer;
