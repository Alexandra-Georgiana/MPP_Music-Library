import { useState } from 'react'
import {useEffect} from 'react'
import reactLogo from './assets/react.svg'
import viteLogo from '/vite.svg'
import './App.css'
import { BrowserRouter, Routes, Route } from 'react-router-dom'
import Start from './Pages/start.jsx'
import Home1 from './Pages/home1.jsx'
import Login from './Pages/login.jsx'
import Signin from './Pages/signin.jsx'
import Account from './Pages/account.jsx'
import EditAcc from './Pages/edit_profile.jsx'
import Home2 from './Pages/home2.jsx'
import SongDetail1 from './Pages/song_detail1.jsx'
import SongDetail2 from './Pages/song_detail2.jsx'
import Favorites from './Pages/liked_songs.jsx'
import songs from './assets/mock_songs.js'
import Admin from './Pages/adminPage.jsx'
import AdimnSC from './Components/AdminShortCut.jsx'
import AdminLog from './Pages/admin_login.jsx'
import createAdminAcc from './adminAcc.js'

function App() {
  const [count, setCount] = useState(0)
  useEffect(() => {
    const storedSongs = localStorage.getItem('songs'); 
    if (!storedSongs) {
      console.log('adding songs to local storage');
      localStorage.setItem('songs', JSON.stringify(songs));
    }
  },[]);

  createAdminAcc();

  return (
    <main>
      <div>
        <BrowserRouter>
        <AdimnSC/>
          <Routes>
            <Route path="/" element={<Start />} />
            <Route path="/home1" element={<Home1 />} />
            <Route path="/login" element={<Login />} />
            <Route path="/signin" element={<Signin />} />
            <Route path="/account" element={<Account />} />
            <Route path="/edit_profile" element={<EditAcc />} />
            <Route path="/home2" element={<Home2 />} />
            <Route path="/song1/:id" element={<SongDetail1 />} />
            <Route path="/song2/:id" element={<SongDetail2 />} />
            <Route path= "/favorites" element={<Favorites />} />
            <Route path = "/admin" element = {<Admin />} />
            <Route path = "/admin_login" element = {<AdminLog />} />
          </Routes>
        </BrowserRouter>
      </div>
    </main>
  )
}

export default App
