import React, {useState,useRef} from 'react'
import Draggable from 'react-draggable';
import {X} from 'lucide-react'
import Update from './UpdateSong.jsx'

const SongDetails_admin = ({song, setIsOpened}) => {
  const nodeRef = useRef(null);

  const[isUpdate, setIsUpdate] = useState(false);

  const renderStars = (rating) => {
    return "★★★★★☆☆☆☆☆".slice(5 - rating, 10 - rating);
  };

  const handleDelete = () => {
    const storedSongs = JSON.parse(localStorage.getItem('songs'));
    const storedLikedSongs = JSON.parse(localStorage.getItem('likedSongs')) || [];
    const updatedSongs = storedSongs.filter((s) => s.id !== song.id);
    const updatedLikedSongs = storedLikedSongs.filter((s) => s.id !== song.id);
    const confirmDelete = window.confirm(`Are you sure you want to delete ${song.title}?`);
    if (confirmDelete) {
        localStorage.setItem('songs', JSON.stringify(updatedSongs));
        localStorage.setItem('likedSongs', JSON.stringify(updatedLikedSongs));
        setIsOpened(false);
        alert("Song deleted successfully!");
        }
    else{
        alert("Song was not deleted!");
    }    
  }

  return (
    <Draggable nodeRef={nodeRef}>
      <div
        className="song"
        ref={nodeRef}
        style={{
          position: "fixed", 
          top: "50px", 
          left: "50px", 
          width: "700px",
          height: "500px",
          background: "#531B21",
          color: "black",
          padding: "20px",
          zIndex: 1000,
          cursor: "grab",
          boxShadow: "0px 15px 10px rgba(0, 0, 0, 0.192)",
          borderRadius: "20px"
        }}
      >
        <div style ={{background:"linear-gradient(to bottom,rgb(61, 2, 2) 0%, transparent 100%)", borderRadius: "20px", height: "100%"}}>
            <div style = {{marginLeft: "650px"}}>
                <X size={30} style={{cursor: "pointer", color: "white", marginTop: "10px"}} onClick={() => setIsOpened(false)}/>
            </div>
            <div>
                <img src={song.image} alt="Song" style={{width: "140px", height: "140px", marginTop: "20px", marginLeft: "-500px"}}/>
            </div>
            <div style = {{marginTop: "-130px", marginLeft: "-150px"}}>
                <div style={{fontFamily:"Economica", fontSize: "50px", color: "white", marginRight:"-300px"}}>
                    <b>{song.title}</b>
                </div>
                <div style = {{marginTop: "-20px", marginLeft: "500px", fontFamily:"Economica", fontSize: "30px", color: "white"}}>
                    <b>{song.artist}</b>
                </div>
            </div>
            <div>
                <p style = {{fontFamily:"Albert Sans", fontSize: "20px", fontWeight:"100", color: "white", marginTop: "7%", marginLeft:"-30%" }}>{song.description}</p>
            </div>
            <hr style={{border: "1px solid rgba(26, 12, 7, 0.34)", width: "90%"}}/>
            <div style = {{ marginLeft: "-470px"}}>
                <b style = {{color:"white", fontSize:"33px"}}>{renderStars(song.rating)}</b>
            </div>
            <div className="song-genre">
                <p style = {{color:"white",fontFamily:"Albert Sans", fontSize: "20px", fontWeight:"100", marginLeft: "-450px"}}>Genre: {song.genre}</p>
            </div>
            <button style = {{borderRadius: "20px", marginTop: "50px", marginRight: "10px", width:"120px"}} onClick={()=>handleDelete()} >Remove </button>
            <button style = {{borderRadius: "20px", marginTop: "50px", marginRight: "-400px", width:"120px"}} onClick={()=>setIsUpdate(true)}>Update </button>
            {isUpdate && <Update song={song} setIsUpdate={setIsUpdate}/>}
        </div>
      </div>
    </Draggable>
  )
}

export default SongDetails_admin