import React, { useRef, useState } from "react";
import Draggable from "react-draggable";
import { X } from "lucide-react";

const AddSong = ({ setAddSong }) => {
  const nodeRef = useRef(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [audioPreview, setAudioPreview] = useState(null);

  const fileToBase64 = (file, callback) => {
    if (!file) return;
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => callback(reader.result);
    reader.onerror = (error) => console.error("Error converting file:", error);
  };

  const handleAddSong = (e) => {
    e.preventDefault();

    const storedSongs = JSON.parse(localStorage.getItem("songs")) || [];

    const newSong = {
      id: storedSongs.length + 2,
      title: e.target.title.value,
      artist: e.target.artist.value,
      album: e.target.album.value,
      genre: e.target.genre.value,
      rating: 0, 
      image: imagePreview, 
      audio: audioPreview, 
    };

    localStorage.setItem("songs", JSON.stringify([...storedSongs, newSong]));
    alert("Song added successfully!");
  };

  return (
    <Draggable nodeRef={nodeRef}>
      <div
        className="song"
        ref={nodeRef}
        style={{
          position: "fixed",
          top: "50px",
          left: "50px",
          width: "400px",
          height: "500px",
          background: "rgb(61, 2, 2)",
          color: "black",
          padding: "20px",
          zIndex: 1000,
          cursor: "grab",
          boxShadow: "0px 15px 10px rgba(0, 0, 0, 0.192)",
          borderRadius: "20px",
        }}
      >
        <div style={{marginLeft:"370px"}}>
            <X size={30} style={{ cursor: "pointer", color: "white" }} onClick={() => setAddSong(false)} />
        </div>
        <b style={{ color: "white", fontSize: "30px" }}>Add Song</b>
        <form onSubmit={handleAddSong}>
          <input type="text" name="title" placeholder="Title" required style={inputStyle} />
          <input type="text" name="artist" placeholder="Artist" required style={inputStyle} />
          <input type="text" name="album" placeholder="Album" required style={inputStyle} />
          <input type="text" name="genre" placeholder="Genre" required style={inputStyle} />
          
          <input type="hidden" name="rating" value="0" />

          <input
            type="file"
            name="image"
            accept="image/*"
            required
            style={inputStyle}
            onChange={(e) => fileToBase64(e.target.files[0], setImagePreview)}
          />
          <input
            type="file"
            name="audio"
            accept="audio/*"
            required
            style={inputStyle}
            onChange={(e) => fileToBase64(e.target.files[0], setAudioPreview)}
          />

          <button type="submit" style={{ width: "300px", height: "50px", marginTop: "20px" }}>
            Add Song
          </button>
        </form>
      </div>
    </Draggable>
  );
};

const inputStyle = {
  width: "300px",
  height: "30px",
  marginTop: "20px",
  background: "transparent",
  border: "none",
  borderBottom: "1px solid black",
};

export default AddSong;
