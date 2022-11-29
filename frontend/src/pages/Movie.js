import axios from 'axios';
import React, { useEffect, useState } from 'react';
import { useStore } from "../store";
import Stars from "../components/Stars";
import { Navigate } from "react-router-dom"
import Flask from '../components/Flask';
import Spinner from '../components/Spinner'
const Movie = () => {
    const movie = useStore(state => state.currentMovie);
    const user = useStore(state => state.user);
    const incRatings = useStore(state => state.incRatings);
    const [stars, setStars] = useState(0);
    const [rated, setRated] = useState(true);
    const [hoverRating, setHoverRating] = useState(0)
    const [storedRating, setStoredRating] = useState(0)
    const [fetching, setFetching] = useState(false)
    const setRating = (movie, rating) => {
        setStars(rating * 2);
    }
    const handleSubmit = async () => {
        console.log(stars);
        setFetching(true);
        var bodyFormData = new FormData();
        bodyFormData.append('tomato_url', movie.tomato_url)
        bodyFormData.append('rating', stars);
        await axios({
            method: 'post',
            url: `${process.env.REACT_APP_API_URL}/${user.username}/review/add`,
            data: bodyFormData,
            headers: {
                'Authorization': localStorage.getItem('rexToken'),
            }
        }).then(res => {
            console.log(res);
            setRating(0);
            setRated(true);
            setFetching(false)
            incRatings();
            getRating()
                .then(res => {
                    console.log(res);
                    setRated(true);
                    setStoredRating(res.data.review.rating);
                }).catch(err => {
                    console.log('hihih')
                    setRated(false);
                })
        }).catch(err => {
            setFetching(false)
        })
    }
    const getRating = async () => {
        return await axios({
            method: 'get',
            url: `${process.env.REACT_APP_API_URL}/${user.username}/review/get/${movie.tomato_url}`,
            headers: {
                'Authorization': localStorage.getItem('rexToken'),
            }
        })

    }
    useEffect(() => {
        if (user.isLoggedIn) {
            getRating()
                .then(res => {
                    if (res.data.result === 'success') {
                        console.log(res);
                        setRated(true);
                        setStoredRating(res.data.review.rating);
                    } else setRated(false)
                }).catch(err => {
                    console.log('hihih')
                    setRated(false);
                })
        }
    }, [movie, user])
    console.log(Object.keys(movie).length)
    return (
        <div>
            {Object.keys(movie).length === 0 ?
                <Navigate
                    to={{
                        pathname: "/",
                    }}
                /> :
                <div>
                    <h1>{movie.title} ({movie.year})</h1>
                    {fetching ? <Spinner size={275} message='Submitting Rating' /> :
                        <img src={movie.poster_url} />}
                    <br />

                    {user.isLoggedIn ?
                        <div>
                            {rated ?
                                <div>
                                    {storedRating === 0 ? <p>You skipped rating this movie</p> : <p style={{ color: 'gold', fontSize: '1.1rem' }}><strong>You rated this movie {storedRating / 2} Stars.</strong></p>}
                                    <p>Click To Set Rating</p>
                                    <Stars setRating={setRating} movie={movie} setHoverRating={setHoverRating} /><br />
                                    {stars > 0 && stars !== storedRating ?
                                        <button onClick={handleSubmit}>Submit {stars / 2} Star Rating</button> : null}
                                </div>
                                :
                                <div>
                                    <p>Click To Set Rating</p>
                                    <Stars setRating={setRating} movie={movie} setHoverRating={setHoverRating} /><br />
                                    {stars > 0 ?
                                        <button className="getMyRexButton" onClick={handleSubmit}>Submit {stars / 2} Star Rating</button> : null}
                                </div>}
                        </div> : <p style={{ color: 'gold', fontSize: '1.1rem' }}>Login to rate this movie</p>
                    }
                    <div style={{ marginTop: "5%" }}>
                        <p style={{ width: '80%', margin: "auto" }}>{movie.plot}</p>
                        <p>Starring: {movie.actors.join(',')}</p>
                    </div>
                </div >
            }
        </div>
    )
}

const styles = {
    tooltip: {

    }
}

export default Movie;