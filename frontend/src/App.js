import React, { useState, useEffect } from 'react';
import './App.css';
import './assets/style/NavStyle.css';
import './assets/style/LandingStyle.css';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import LandingPage from './pages/LandingPage'
import ProfilePage from './pages/ProfilePage'
import QuickPickPage from './pages/QuickPickPage'
import RegisterPage from './pages/RegisterPage'
import Questionaire from './pages/Questionnaire';
import Movielist from './pages/Movielist';
import MovieFull from './pages/MovieFull'
import MoviePick from './pages/MoviePick';
import Movie from './pages/Movie';
import NavBar from "./components/NavBar";
import axios from 'axios';
import { useStore } from "./store";
import { useSnackbar } from 'notistack';


const App = () => {
  const user = useStore(state => state.user);
  const setUser = useStore(state => state.setUser);
  const { enqueueSnackbar, closeSnackbar } = useSnackbar();
  useEffect(() => {
    const toke = localStorage.getItem('rexToken');
    const user = localStorage.getItem('rexUser');
    const checkToke = async () => {
      return await axios({
        method: "get",
        url: `${process.env.REACT_APP_API_URL}/${user}/validate`,
        headers: {
          'Authorization': localStorage.getItem('rexToken'),
        }
      })
    }
    if (toke && user) {
      checkToke()
        .then(res => {
          console.log(res);
          if (res.data.result === 'success') {
            const u = {
              username: res.data.user.username,
              email: res.data.user.email,
              token: res.data.token,
              isLoggedIn: true,
            }
            setUser(u);
            enqueueSnackbar("Successfully logged in", { variant: "success" })
          } else {
            enqueueSnackbar("Token has expired, please log in", { variant: "error" })
          }
        }).catch(err => console.log(err))
    }
  }, [])
  return (
    <Router>
      <div className="App">
        <NavBar />
        <Routes>
          <Route exact path='/' element={<LandingPage />} />
          <Route exact path='/quickpick' element={<QuickPickPage />} />
          <Route exact path='/profile' element={<ProfilePage />} />
          <Route exact path='/register' element={<RegisterPage />} />
          <Route exact path='/questionaire' element={<Questionaire />} />
          <Route exact path='/movielist' element={<Movielist />} />
          <Route exact path='/moviepick' element={<MoviePick />} />
          <Route exact path='/movie' element={<Movie />} />
          <Route exact path='/moviefull' element={<MovieFull />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
