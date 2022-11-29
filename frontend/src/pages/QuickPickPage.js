import React, { useState, useEffect } from 'react';
import '../App.css';
import { ButtonGroup, Card, CircularProgress, Typography } from '@mui/material';
import Stars from "../components/Stars";
import "../assets/style/movieCard.css";
import { useStore } from '../store'
import MyRex from '../components/MyRex'
import axios from 'axios';
import RandoRex from '../components/RandoRex'
import Spinner from '../components/Spinner'
import Flask from '../components/Flask'

const QuickPickPage = () => {
    const user = useStore(state => state.user);
    const [reviewArr, setReview] = useState([])
    const [rating, setRating] = useState(-1)
    const [activeIndex, setIndex] = useState(0);
    const [movieArr, setMovieArr] = useState([]);
    const [hasRecs, setHasRecs] = useState(false);
    const [randoRecs, setRandoRecs] = useState([]);
    const [fetching, setFetching] = useState(false);
    const [calculate, setCalculate] = useState(false);

    function addRatingToArr(movie, rating) {
        setRating(rating);
        let arr = reviewArr;
        if (randoRecs.length > 0) {
            let copy = randoRecs.filter(x => x.tomato_url !== movie.tomato_url)
            setRandoRecs(copy)
        }
        const data = { tomato_url: movie.tomato_url, rating: rating };
        arr.push(data);
        setReview(arr);
        setIndex(activeIndex + 1);
    }
    const getRandomMovies = async () => {
        return await axios({
            method: 'get',
            url: `${process.env.REACT_APP_API_URL}/movie/random/50`,
        })
    }
    const getMoreMovies = () => {
        setFetching(true)
        getRandomMovies()
            .then(res => {
                console.log(res);
                setIndex(0);
                setMovieArr(res.data.movie_list);
                setFetching(false);
            }).catch(err => {
                console.log(err)
                setFetching(false)
            })
    }
    const massSubmit = async () => {
        setCalculate(true)
        const formData = new FormData();
        formData.append('reviews', JSON.stringify(reviewArr));
        await axios({
            method: 'post',
            url: `${process.env.REACT_APP_API_URL}/movie/recs`,
            data: formData,
            headers: {
                'Authorization': localStorage.getItem('rexToken'),
            }
        }).then(res => {
            if (res.data.result === 'success') {
                console.log(res)
                setRandoRecs(res.data.recs)
                setCalculate(false)
            } else {
                console.log(res);
                setCalculate(false);
            }
        })
    }
    useEffect(() => {
        setFetching(true);
        getRandomMovies()
            .then(res => {
                console.log(res.data.movie_list);
                setMovieArr(res.data.movie_list);
                setFetching(false)
            }).catch(err => console.log(err))
    }, [])
    console.log(reviewArr);
    return (
        <div>
            {user.isLoggedIn ? <MyRex /> :
                <div>
                    {calculate ? <Flask message="Hold on, we're brewing up your Movie RX..." /> : fetching ?
                        <Spinner size={300} message={'Fetching movies to rate'} /> :
                        randoRecs.length > 0 ? <RandoRex massSubmit={massSubmit} ratings={reviewArr} setRecs={setRandoRecs} recs={randoRecs} setRating={addRatingToArr} /> :
                            <div>
                                <Typography variant='h4'>Rate Movies</Typography>
                                {activeIndex === 0 ? <p style={{ width: '60%', padding: '2%', margin: '2% auto', background: 'whitesmoke', color: 'black', borderRadius: '.5rem' }}>
                                    Rate at least 5 movies in order to get a recommendation, but the more the better. Remember to rate good AND
                                    bad movies to get the best rating.</p> : null}
                                {movieArr.map((m, i) => (
                                    <div className={i === activeIndex ? "card active" : "card inactive"} key={m.tomato_url}>
                                        <img alt="Movie Poster" className='poster' width='250' src={m.poster_url}></img>
                                        <h4>{m.title}</h4>
                                        {activeIndex !== 0 ?
                                            <span style={{
                                                border: '1px solid #595959',
                                                background: 'white',
                                                color: '#595959',
                                                cursor: 'pointer',
                                                padding: '1.5%', borderRadius: '.5rem'
                                            }} onClick={() => setIndex(activeIndex - 1)}>Go Back</span>
                                            : null
                                        }
                                        <Stars
                                            setRating={addRatingToArr}
                                            movie={m}
                                        /><span style={{
                                            border: '1px solid #595959',
                                            background: 'white',
                                            color: '#595959',
                                            cursor: 'pointer',
                                            padding: '1.5%', borderRadius: '.5rem'
                                        }} onClick={() => setIndex(activeIndex + 1)}>Skip</span>
                                    </div>
                                ))}<br />
                                {reviewArr.length > 4 && !user.isLoggedIn ?
                                    <button className="getMyRexButton" onClick={massSubmit} style={{ marginBottom: "30px" }}>Submit Reviews</button>
                                    : null
                                }
                                {activeIndex > 49 ?
                                    <div style={{ display: 'flex', flexDirection: 'row', justifyContent: 'center', alignItems: 'center' }}>
                                        <button className="getMyRexButton" onClick={() => setIndex(activeIndex - 1)}>Go Back</button>
                                        <button className="getMyRexButton" onClick={getMoreMovies}>Get More Movies to Review</button>
                                    </div> : null}

                            </div>
                    }
                </div>
            }
        </div>
    )
}
export default QuickPickPage;
