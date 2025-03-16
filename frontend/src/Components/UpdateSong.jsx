import React, { useRef, useState } from "react";
import Draggable from "react-draggable";
import { X } from "lucide-react";

const UpdateSong = ({ song, setIsUpdate }) => {
  const nodeRef = useRef(null);
  const [updatedSong, setUpdatedSong] = useState({ ...song });

  const handleChange = (e) => {
    setUpdatedSong({ ...updatedSong, [e.target.name]: e.target.value });
  };

  const fileToBase64 = (file, callback) => {
    if (!file) return;
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => callback(reader.result);
    reader.onerror = (error) => console.error("Error converting file:", error);
  };

  const handleUpdateSong = (e) => {
    e.preventDefault();

    let storedSongs = JSON.parse(localStorage.getItem("songs")) || [];

    storedSongs = storedSongs.map((s) => (s.id === song.id ? updatedSong : s));

    localStorage.setItem("songs", JSON.stringify(storedSongs));
    alert("Song updated successfully!");
    setIsUpdate(false);
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
        <div style={{ marginLeft: "370px" }}>
          <X size={30} style={{ cursor: "pointer", color: "white" }} onClick={() => setIsUpdate(false)} />
        </div>
        <b style={{ color: "white", fontSize: "30px" }}>Update Song</b>
        <form onSubmit={handleUpdateSong}>
          <input type="text" name="title" value={updatedSong.title} onChange={handleChange} required style={inputStyle} />
          <input type="text" name="artist" value={updatedSong.artist} onChange={handleChange} required style={inputStyle} />
          <input type="text" name="album" value={updatedSong.album} onChange={handleChange} required style={inputStyle} />
          <input type="text" name="genre" value={updatedSong.genre} onChange={handleChange} required style={inputStyle} />

          <input type="hidden" name="rating" value={updatedSong.rating} />

          <input
            type="file"
            name="image"
            accept="image/*"
            style={inputStyle}
            onChange={(e) => fileToBase64(e.target.files[0], (base64) => setUpdatedSong({ ...updatedSong, image: base64 }))}
          />
          <input
            type="file"
            name="audio"
            accept="audio/*"
            style={inputStyle}
            onChange={(e) => fileToBase64(e.target.files[0], (base64) => setUpdatedSong({ ...updatedSong, audio: base64 }))}
          />

          <button type="submit" style={{ width: "300px", height: "50px", marginTop: "20px" }}>
            Update Song
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

export default UpdateSong;
