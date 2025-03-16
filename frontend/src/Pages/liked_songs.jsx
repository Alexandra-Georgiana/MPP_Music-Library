import React, { useEffect, useRef, useState } from 'react';
import Header from '../Components/header_loged.jsx';
import { ArrowUpDown } from 'lucide-react';
import PlayCd from '../Components/CDPlayer.jsx';
import PlayPickUp from '../Components/VinylPlayer.jsx';
import Draggable from 'react-draggable';

const LikedSongs = () => {
    const [songs, setSongs] = useState(JSON.parse(localStorage.getItem('likedSongs')) || []);
    const [playSongs, setPlaySongs] = useState(false);
    const nodeRef = useRef(null);

    const [playCD, setPlayCD] = useState(false);
    const [playPickUp, setPlayPickUp] = useState(false);

    const [currentSongIndex, setCurrentSongIndex] = useState(0);
    const [sortConfig, setSortConfig] = useState({ key: null, ascending: true });

    const calledFromLiked = 0;

    const renderStars = (rating) => {
        return "★★★★★☆☆☆☆☆".slice(5 - rating, 10 - rating);
    };

    const handleSort = (key) => {
        const isAscending = sortConfig.key === key ? !sortConfig.ascending : true;

        const sortedSongs = [...songs].sort((a, b) => {
            if (a[key] < b[key]) return isAscending ? -1 : 1;
            if (a[key] > b[key]) return isAscending ? 1 : -1;
            return 0;
        });

        setSongs(sortedSongs);
        setSortConfig({ key, ascending: isAscending });
    };

    return (
        <div className="basic-page">
            <Header />
            <div className="liked_title">
                <p className="title-text">Liked</p>
                <span className="username">Songs</span>
            </div>
            <div className="cathegories">
                <div className="cathegory" onClick={() => handleSort('title')}>
                    <b>Title</b> <ArrowUpDown size={20} />
                </div>
                <div className="cathegory" onClick={() => handleSort('artist')}>
                    <b>Artist</b> <ArrowUpDown size={20} />
                </div>
                <div className="cathegory" onClick={() => handleSort('album')}>
                    <b>Album</b> <ArrowUpDown size={20} />
                </div>
                <div className="cathegory" onClick={() => handleSort('genre')}>
                    <b>Genre</b> <ArrowUpDown size={20} />
                </div>
                <div className="cathegory" onClick={() => handleSort('rating')}>
                    <b>Your rating</b> <ArrowUpDown size={20} />
                </div>
            </div>
            <hr className="line5" />
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
                        <b style={{ color: "white", margin: "10px" }}>Which player would you prefer?</b>
                        <button onClick={() => (setPlaySongs(false), setPlayCD(true))}>CD Player</button>
                        <button onClick={() => (setPlaySongs(false), setPlayPickUp(true))}>PickUp Player</button>
                    </div>
                </Draggable>
            )}
            {playCD && (
                <PlayCd
                    songs={songs}
                    currentSongIndex={currentSongIndex}
                    onSongChange={setCurrentSongIndex}
                    setPlayCD={setPlayCD}
                    calledFrom={calledFromLiked}
                />
            )}
            {playPickUp && (
                <PlayPickUp
                    songs={songs}
                    currentSongIndex={currentSongIndex}
                    onSongChange={setCurrentSongIndex}
                    setPlayPickUp={setPlayPickUp}
                    calledFrom={calledFromLiked}
                />
            )}
        </div>
    );
};

export default LikedSongs;
