import React, { useState, useEffect } from "react";
import { ArrowUpDown, Search } from "lucide-react";
import { useNavigate } from "react-router-dom";
import SongDetails from "../Components/SongDetails_admin.jsx";
import AddSong from "../Components/AddSong.jsx";

const AdminPage = () => {
  const navigate = useNavigate();

  const [songs, setSongs] = useState(JSON.parse(localStorage.getItem("songs")) || []);
  const [sortConfig, setSortConfig] = useState({ key: null, ascending: true });

  const [showSong, setShowSong] = useState();
  const [isOpened, setIsOpened] = useState(false);
  const [addSong, setAddSong] = useState(false);

  const [searchTerm, setSearchTerm] = useState("");
  const [filteredSongs, setFilteredSongs] = useState([]);

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

  useEffect(() => {
    if (searchTerm.trim() === "") {
      setFilteredSongs([]);
      return;
    }
    const filtered = songs.filter(
      (song) =>
        song.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        song.artist.toLowerCase().includes(searchTerm.toLowerCase()) ||
        song.album.toLowerCase().includes(searchTerm.toLowerCase()) ||
        song.genre.toLowerCase().includes(searchTerm.toLowerCase())
    );
    setFilteredSongs(filtered);
  }, [searchTerm, songs]);

  return (
    <div
      style={{
        backgroundColor: "#561B21",
        width: "100%",
        height: "100vh",
        position: "absolute",
        top: 0,
        left: 0,
        overflow: "hidden",
      }}
    >
      <b style={{ color: "white", fontSize: "40px" }}> Admin Manager</b>
      <div className="search-container" style={{ marginLeft: "120px", position: "relative" }}>
        <Search className="search-icon" size={16} />
        <input
          type="text"
          placeholder="   Search for song"
          className="search-input"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
        {filteredSongs.length > 0 && (
          <ul
            className="dropdown"
            style={{
              position: "absolute",
              top: "40px",
              left: "0",
              width: "250px",
              background: "white",
              color: "black",
              listStyle: "none",
              padding: "10px",
              borderRadius: "5px",
              zIndex: 1000,
              boxShadow: "0px 4px 8px rgba(0, 0, 0, 0.2)",
            }}
          >
            {filteredSongs.map((song, index) => (
              <li
                key={index}
                onClick={() => {
                  setShowSong(song);
                  setIsOpened(true);
                  setSearchTerm(""); 
                }}
                className="dropdown-item"
                style={{ padding: "5px", cursor: "pointer", borderBottom: "1px solid #ddd" }}
              >
                {song.title} - {song.artist}
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="cathegories" style={{ marginTop: "20px", marginLeft: "19%" }}>
        <div className="cathegory" onClick={() => handleSort("title")}>
          <b style={{ color: "white" }}>Title</b> <ArrowUpDown size={20} style={{ color: "white" }} />
        </div>
        <div className="cathegory" onClick={() => handleSort("artist")}>
          <b style={{ color: "white" }}>Artist</b> <ArrowUpDown size={20} style={{ color: "white" }} />
        </div>
        <div className="cathegory" onClick={() => handleSort("album")}>
          <b style={{ color: "white" }}>Album</b> <ArrowUpDown size={20} style={{ color: "white" }} />
        </div>
        <div className="cathegory" onClick={() => handleSort("genre")}>
          <b style={{ color: "white" }}>Genre</b> <ArrowUpDown size={20} style={{ color: "white" }} />
        </div>
        <div className="cathegory" onClick={() => handleSort("rating")}>
          <b style={{ color: "white" }}>Rating</b> <ArrowUpDown size={20} style={{ color: "white" }} />
        </div>
      </div>

      <hr className="line5" style={{ marginTop: "-7%", marginLeft: "8%" }} />
      <div
        className="fav_song-list"
        style={{
          marginTop: "-85%",
          marginLeft: "70px",
          maxHeight: "50vh",
          overflowY: "auto",
          overflowX: "hidden",
        }}
      >
        <div className="fav_songs">
          {songs.map((song) => (
            <div
              key={song.id}
              className="fav_song-item"
              style={{
                background:
                  "radial-gradient(ellipse 50% 60% at 50% 100%, rgba(36, 19, 19, 0.5),hsl(354, 52.20%, 22.20%)",
                backgroundSize: "cover",
                cursor: "pointer",
              }}
              onClick={() => {
                setShowSong(song);
                setIsOpened(true);
              }}
            >
              <img src={song.image} alt="fav-album_cover" className="fav_album-cover" />
              <div className="fav_song-details">
                <b className="fav_song-title" style={{ color: "white" }}>
                  {song.title}
                </b>
                <p className="fav_song-artist" style={{ color: "white" }}>
                  {song.artist}
                </p>
                <p className="fav_song-album" style={{ color: "white" }}>
                  {song.album}
                </p>
                <p className="fav_song-genre" style={{ color: "white" }}>
                  {song.genre}
                </p>
                <p className="fav_song-rating" style={{ color: "white" }}>{renderStars(song.rating)}</p>
              </div>
            </div>
          ))}
        </div>
        {isOpened && <SongDetails song={showSong} setIsOpened={setIsOpened} />}
      </div>

      <button style={{ fontSize: "20px", fontWeight: "bold", borderRadius: "40px", marginRight: "3%" }} onClick={() => setAddSong(true)}>
        Add Song
      </button>
      <button
        style={{ backgroundColor: "white", color: "black", fontSize: "20px", fontWeight: "bold", borderRadius: "40px", marginRight: "-60%" }}
        onClick={() => navigate("/login")}
      >
        Exit Admin Mode
      </button>

      {addSong && <AddSong setAddSong={setAddSong} />}
    </div>
  );
};

export default AdminPage;
