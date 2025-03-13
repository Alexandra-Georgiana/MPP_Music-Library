import React, {useEffect, useRef, useState} from 'react'
import Header from '../Components/header_loged.jsx'
import { ArrowUpDown } from 'lucide-react'
import songs from "../assets/mock_songs.js"
import ReactDOM from 'react-dom';
import Draggable from 'react-draggable';

const liked_songs = () => {

    const [playSongs, setPlaySongs] = useState([]);
    const nodeRef = useRef(null);

    const renderStars = (rating) => {
        return "★★★★★☆☆☆☆☆".slice(5 - rating, 10 - rating);
      };
      

  return (
    <div className = "basic-page">
        <Header />
        <div className = "liked_title">
                <p className = "title-text">Liked</p>
                <span className = "username">Songs</span>
        </div>
        <div className ="cathegories">
            <div className = "cathegory">
                <b>Title</b>
                <ArrowUpDown size = {20}/>
            </div>
            <div className = "cathegory">
                <b>Artist</b>
                <ArrowUpDown size = {20}/>
            </div>
            <div className = "cathegory">
                <b>Album</b>
                <ArrowUpDown size = {20}/>
            </div>
            <div className = "cathegory">
                <b>Genre</b>
                <ArrowUpDown size = {20}/>
            </div>
            <div className = "cathegory">
                <b>Your rating</b>
                <ArrowUpDown size = {20}/>
            </div>
        </div>
        <hr className = "line5"/>
        <div className="fav_song-list">
            <div className="fav_songs">
                {songs.map((song) => (
                    <div key={song.id} className="fav_song-item">
                        <img src={song.image} alt="fav-album_cover" className="fav_album-cover" />
                        <div className="fav_song-details">
                            <b className="fav_song-title">{song.title}</b>
                            <p className="fav_song-artist">{song.artist}</p>
                            <p className="fav_song-album">{song.album}</p>
                            <p className="fav_song-genre">{song.genre}</p>
                            <p className="fav_song-rating">{renderStars(song.rating)}</p>
                        </div>
                    </div>
                ))}
            </div>
        </div>
        <button className="edit-button" onClick={() => setPlaySongs(true)}>Play All</button>
        {playSongs && (
        <Draggable nodeRef={nodeRef}> 
          <div ref={nodeRef} className="music-widget"> 
            <b style = {{color: "white", margin: "10px"}}>Which player would you prefer?
            </b>
            <button onClick={() => setPlaySongs(false)}>CD Player</button>
            <button onClick={() => setPlaySongs(false)}>PickUp Player</button>
          </div>
        </Draggable>
      )}
    </div>
  )
}

export default liked_songs