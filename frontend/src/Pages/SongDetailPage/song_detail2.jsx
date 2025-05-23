import React, { useState, useEffect, useRef } from "react";
import { useParams } from "react-router-dom";
import Heather from '../../Components/Headers/header_loged.jsx';
import PlayCd from '../../Components/Players/CDPlayer.jsx';
import PlayVinyl from '../../Components/Players/VinylPlayer.jsx';
import Review from '../../Components/ReviewWidget/Review.jsx';
import { useNavigate } from "react-router-dom";
import { useAuth } from '../../utils/auth';
import './index.css';
import config from '../../config';

const SongDetails2 = () => {
  const navigate = useNavigate();
  const { isAuthenticated, getToken } = useAuth();
  const [songs, setSongs] = useState([]);
  const [averageRating, setAverageRating] = useState(0);
  const [comments, setComments] = useState([]);
  const [playCD, setPlayCD] = useState(false);
  const [playPickUp, setPlayPickUp] = useState(false);
  const [review, setReview] = useState(false);
  const { id } = useParams();
  const calledFrom = 1; // 0 for CD, 1 for Vinyl

  const [offset, setOffset] = useState(0);
  const limit = 30; // Updated to match the limit in home2.jsx
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [song, setSong] = useState(null); // State to store the fetched song
  const [isLiked, setIsLiked] = useState(false); // State to manage like status


  useEffect(() => {
    getSongs(true);
  }, []);
  const songListRef = useRef(null);

  
    useEffect(() => {
        const handleScroll = () => {
          const list = songListRef.current;
          if (list) {
              const scrollTop = list.scrollTop;
              const scrollHeight = list.scrollHeight;
              const clientHeight = list.clientHeight;

              console.log('ScrollTop:', scrollTop);
              console.log('ClientHeight:', clientHeight);
              console.log('ScrollHeight:', scrollHeight);
              console.log('Loading:', loading);
              console.log('HasMore:', hasMore);

              // Trigger fetching more data when user scrolls near the bottom of the list container
              if (scrollTop + clientHeight >= scrollHeight - 50 && !loading && hasMore) {
                  console.log('Fetching more songs...');
                  fetchMoreSongs();
              } else {
                  console.log('Not fetching: Conditions not met');
              }
          }
      };
  
      const list = songListRef.current;
      if (list) {
          list.addEventListener('scroll', handleScroll);
      }
      return () => {
          if (list) {
              list.removeEventListener('scroll', handleScroll);
          }
      };
  }, [loading, hasMore]);

 const getSongs = async (reset = false) => {
    try {
        setLoading(true);

        // Pass offset and limit as query parameters
        const response = await fetch(`/api/songs?offset=${offset}&limit=${limit}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            console.error('Error fetching songs:', response.status, response.statusText);
            throw new Error(`Failed to fetch songs: ${response.status} ${response.statusText}`);
        }

        const data = await response.json();

        if (reset) {
            setSongs(data);
            setOffset(limit); // Reset offset to the limit
        } else {
            setSongs((prevSongs) => {
                const newSongs = data.filter(song => !prevSongs.some(prev => prev.track_id === song.track_id));
                return [...prevSongs, ...newSongs];
            });
            setOffset((prevOffset) => prevOffset + limit); // Increment offset
        }

        if (data.length < limit) {
            setHasMore(false); // No more songs to fetch
        }
    } catch (error) {
        console.error('Error fetching songs:', error);
    } finally {
        setLoading(false);
    }
};

const fetchMoreSongs = () => {
    getSongs(false);
};

  const getSongDetails = async (trackId) => {
    try {
        const response = await fetch(`/api/songs/${trackId}`); // Use the /songs/{id} endpoint
        if (!response.ok) {
            console.error('Error fetching song details:', response.status, response.statusText);
            throw new Error(`Failed to fetch song details: ${response.status} ${response.statusText}`);
        }
        const data = await response.json();
        setSong(data); // Set the fetched song details
        const response1 = await fetch(`/api/songs/details/${trackId}`);
        if (!response1.ok) {
            console.error('Error fetching song details:', response1.status, response1.statusText);
            throw new Error(`Failed to fetch song details: ${response1.status} ${response1.statusText}`);
        }
        const data1 = await response1.json();
        setAverageRating(data1.average_rating || 0);
        setComments(data1.comments || []); // Ensure comments is an array
    } catch (error) {
        console.error('Error fetching song details:', error);
    }
};

useEffect(() => {
    if (id) {
        getSongDetails(id); // Fetch song details by ID
    }
}, [id]);

if (!song) {
    return <p>Loading song details...</p>; // Show a loading message while fetching
}

  const handleAddToLiked = async () => {
    if (!isAuthenticated()) {
      navigate('/login');
      return;
    }

    try {
      const response = await fetch('/api/songs/like', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${getToken()}`
        },
        body: JSON.stringify({
          songId: song.track_id
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        if (response.status === 401) {
          navigate('/login');
          return;
        }
        throw new Error(error.error || 'Failed to add to liked songs');
      }

      setIsLiked(true);
      alert('Song added to liked list successfully!');
    } catch (err) {
      console.error('Error adding to liked list:', err);
      alert('Something went wrong. Please try again.');
    }
  };

  const handleLike = async () => {
    if (!isAuthenticated()) {
      toast.error('Please log in to like songs');
      return;
    }

    try {
      const response = await fetch('/api/songs/like', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${getToken()}`
        },
        body: JSON.stringify({ songId: song.id })
      });

      if (!response.ok) {
        throw new Error('Failed to update like status');
      }

      setIsLiked(!isLiked);
      toast.success(isLiked ? 'Removed from favorites' : 'Added to favorites');
    } catch (error) {
      console.error('Error updating like status:', error);
      toast.error('Failed to update favorite status');
    }
  };

  const handleSongClick = (id) => {
    const song = songs.find((s) => s.track_id === id);
    if (!song) {
        console.error(`Song with id ${id} not found in the current list.`);
        return;
    }
    navigate(`/song2/${id}`);
  };

  return (
    <div className="basic-page" style={{overflow: 'hidden'}}>
      <div className="song-list">
        <p className="song-list-title">Library</p>
        <hr className="line"></hr>
        <div className="scrolable-song-list" ref={songListRef}>
          <ul className="songs">
          {songs.map((song, index) => (
                  <li key={song.track_id} onClick={() => handleSongClick(song.track_id)} className="song-item">
                    <strong>{index + 1}. {song.track_name}</strong> - {song.artist_name}
                  </li>
                ))}
          </ul>
        </div>
      </div>
      <div className="song-details">
        <img src={song.album_image} style={{width: '10vw', height: '10vw'}} alt="album_cover" className="album-cover" />
        <div className="song-info">
          <b className="song-title">{song.track_name}</b>
          <p className="song-artist" style={{color: "white", fontSize: "4vh"}}>{song.artist_name}</p>
        </div>
        <hr className="line4"></hr>
        <p className="rating">Average Rating: {(averageRating || 0).toFixed(1)} ★</p>
        <ul className="reviews">
          <h3>Last 10 Comments:</h3>
          {comments.map((comment, index) => (
            <li key={index} className="review-item">
              <strong>{comment.username}</strong>: {comment.comment_text}
            </li>
          ))}
        </ul>
      </div>
      <button className="like-button" onClick={handleAddToLiked}>Add to favorites</button>
      <button className="play-CD" onClick={() => setPlayCD(true)}>Play CD</button>
      <button className="play-PickUp" onClick={() => setPlayPickUp(true)}>Play Vinyl</button>

      {playCD && (
        <PlayCd
          songs={[song]}
          currentSongIndex={0}
          onSongChange={() => {}}
          setReview={setReview}
          setPlayCD={setPlayCD}
          calledFrom={calledFrom}
        />
      )}
      {playPickUp && (
        <PlayVinyl
          songs={[song]}
          currentSongIndex={0}
          onSongChange={() => {}}
          setPlayPickUp={setPlayPickUp}
          setReview={setReview}
        calledFrom={calledFrom}
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