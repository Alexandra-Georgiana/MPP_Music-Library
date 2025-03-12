import { useState } from 'react'
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

function App() {
  const [count, setCount] = useState(0)

  return (
    <main>
      <div>
        <BrowserRouter>
          <Routes>
            <Route path="/start" element={<Start />} />
            <Route path="/home1" element={<Home1 />} />
            <Route path="/login" element={<Login />} />
            <Route path="/signin" element={<Signin />} />
            <Route path="/account" element={<Account />} />
            <Route path="/edit_profile" element={<EditAcc />} />
            <Route path="/home2" element={<Home2 />} />
            <Route path="/song1/:id" element={<SongDetail1 />} />
            <Route path="/song2/:id" element={<SongDetail2 />} />
          </Routes>
        </BrowserRouter>
      </div>
    </main>
  )
}

export default App
