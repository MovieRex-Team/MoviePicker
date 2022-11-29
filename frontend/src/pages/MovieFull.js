import axios from 'axios';
import React, { useEffect, useState } from 'react';
import { useStore } from "../store";
import { Navigate } from "react-router-dom"
import { useLocation } from "react-router-dom";
import "../assets/style/MovieFull.css"
import Spinner from '../components/Spinner'

const MovieFull = props => {
    let data = useLocation();
    const [movie, setMovie] = useState(null)
    console.log(movie);
    const [fetching, setFetching] = useState(false);
    useEffect(() => {
        setFetching(true)
        const getMovie = async () => {
            return await axios({
                method: "get",
                url: `${process.env.REACT_APP_API_URL}/movie/${data.state.movie.tomato_url}/full`,
            })
        }
        getMovie()
            .then((res) => {
                console.log(res.data.movie);
                const obj = { title: res.data.movie.title }
                setMovie(res.data.movie);
                setFetching(false)
            }).catch(err => setFetching(false))
    }, [])
    console.log(movie)
    return (
        <div>
            {fetching ? <Spinner size={300} message={"Fetching Movie Data"} /> :
                <div>
                    {movie !== null ?
                        <div>
                            <h1>{movie.title} ({movie.year})</h1>
                            <img src={movie.poster_url} />
                            <br />
                            <p className="description">{movie.plot}</p>
                            <p>Starring: {movie.actors.join(',')}</p>
                        </div> : <p>Could not fetch movie, please check internet connection and refresh page</p>
                    }
                </div>
            }
        </div>
    )
}

export default MovieFull;