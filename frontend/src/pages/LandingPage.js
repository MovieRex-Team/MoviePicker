import React, { useEffect } from 'react';
import '../App.css';
import { Link } from "react-router-dom";
import fcImage from "../assets/fcImage2.jpg"
import Typography from '@mui/material/Typography';
import { posters } from "../data/posters"
import { useLocation, useNavigate } from "react-router-dom";
import { useStore } from "../store";
import axios from 'axios'

const LandingPage = () => {
    const navigate = useNavigate();
    const setCurrentMovie = useStore(state => state.setCurrentMovie)
    return (
        <div>
            <div className="topImageDiv">
                <div className="titleDiv">
                    <Typography><h1 className="title">Movie Rex</h1></Typography>
                    <p className="subtitle">When you've seen the Fight Club about 28 times....
                        We've got the RX.</p>
                </div>
            <div className='moviePosters'>
                {posters.map((p) => (
                    // <Link to="/moviefull" state={{ movie: p }}>
                    //     <img alt="MovieImage" width="150" src={p.poster_url} />
                    // </Link>
                    <img style={{cursor:'pointer'}} alt="MovieImage" width="150" src={p.poster_url} onClick={async () => {
                        await axios({
                            method: "get",
                            url: `${process.env.REACT_APP_API_URL}/movie/${p.tomato_url}/full`,
                        }).then((res) => {
                            console.log(res.data.movie);
                            const obj = { title: res.data.movie.title }
                            setCurrentMovie(res.data.movie);
                            navigate('/movie');
                        })
                    }} />
                ))}
            </div>
        </div><div className='bottomDiv'>
                <p className='subtitle'>
                    If you have a fever and the only perscription is a data driven movie recommendation algorithm....<br />
                    Accept no substitutes.
                </p>
            </div>
            </div> 
    )
}

export default LandingPage;