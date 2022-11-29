import React, { useState, useEffect } from 'react';
import '../App.css';
import { Typography } from '@mui/material';
import Stars from "../components/Stars";
import "../assets/style/movieCard.css";
import { useStore } from '../store'
import MyRex from '../components/MyRex'
import axios from 'axios';
import RandoRex from '../components/RandoRex'
import { useSnackbar } from 'notistack';
import Flask from './Flask';
import Spinner from './Spinner'
import '../assets/style/myRex.css'


const RateMore = props => {
    const user = useStore(state => state.user);
    const incRatings = useStore(state => state.incRatings);
    const [rating, setRating] = useState(-1);
    const [fetching, setFetching] = useState(false);
    const [posting, setPosting] = useState(false);
    const [activeIndex, setIndex] = useState(0);
    const [currentRating, setCurrentRating] = useState({});
    const [movieArr, setMovieArr] = useState([]);
    const { enqueueSnackbar, closeSnackbar } = useSnackbar();
    const getRandomMovies = async () => {
        return await axios({
            method: 'get',
            url: `${process.env.REACT_APP_API_URL}/movie/random/50`,
        })
    }
    const getMoreMovies = () => {
        setFetching(true);
        getRandomMovies()
            .then(res => {
                console.log(res);
                setFetching(false);
                setIndex(0);
                setMovieArr(res.data.movie_list)
            }).catch(err => {
                console.log(err)
                setFetching(false)
            })
    }
    const updateCurrentRating = (movie, rating) => {
        console.log(rating);
        const data = {
            tomato_url: movie.tomato_url,
            rating: rating
        }
        setCurrentRating(data)
    }
    const submitCurrentRating = async () => {
        setPosting(true);
        const id = currentRating.movie_id
        var bodyFormData = new FormData();
        bodyFormData.append('tomato_url', currentRating.tomato_url)
        bodyFormData.append('rating', currentRating.rating * 2);
        await axios({
            method: 'post',
            url: `${process.env.REACT_APP_API_URL}/${user.username}/review/add`,
            data: bodyFormData,
            headers: {
                'Authorization': localStorage.getItem('rexToken'),
            }
        }).then(res => {
            setCurrentRating({});
            console.log('in em')
            enqueueSnackbar('Review Submitted!', { variant: 'success' });
            incRatings();
            setPosting(false);
            setIndex(activeIndex + 1);
        }).catch(err => {
            setPosting(false);
            console.log(err)
        })
    }
    useEffect(() => {
        setFetching(true)
        getRandomMovies()
            .then(res => {
                console.log(res.data.movie_list);
                setMovieArr(res.data.movie_list);
                setFetching(false);
            }).catch(err => {
                console.log(err)
                setFetching(false)
            })
    }, [])

    return (
        <div>
            <button className="getMyRexButton" onClick={() => props.setRateMore(false)}>Back To My Rex</button>
            {movieArr.map((m, i) => (
                <div className={i === activeIndex ? "card active" : "card inactive"} key={m.tomato_url}>
                    {fetching ? <Spinner message='Fetching Movies to rate.' size={300} /> :
                        <div>
                            <img alt='Movie Poster' className='poster' width='250' src={m.poster_url}></img>
                            <h4>{m.title}</h4>
                            {posting ? <Spinner message="Submitting Review" size={200} /> :
                                <div>
                                    {activeIndex !== 0 ?
                                        <span style={{ position: 'relative', top: '-10px', fontSize: '1.1rem', marginRight: '25px', paddingBottom: '20px', cursor: 'pointer', textDecoration: 'underline' }} onClick={() => setIndex(activeIndex - 1)}>Go Back</span>
                                        : null
                                    }
                                    <Stars
                                        setRating={updateCurrentRating}
                                        movie={m}
                                    /><span style={{ position: 'relative', top: '-10px', fontSize: '1.1rem', marginLeft: '25px', paddingBottom: '20px', cursor: 'pointer', textDecoration: 'underline' }} onClick={() => setIndex(activeIndex + 1)}>Skip</span>
                                    <br /><button className='getMyRexButton' onClick={submitCurrentRating}>Submit {currentRating.rating} Stars</button>
                                </div>
                            }
                        </div>
                    }
                </div>
            ))}<br />
            {activeIndex > 49 ?
                <div style={{ display: 'flex', flexDirection: 'row', justifyContent: 'center', alignItems: 'center' }}>
                    <button className="getMyRexButton" onClick={() => setIndex(activeIndex - 1)}>Go Back</button>
                    <button className="getMyRexButton" onClick={getMoreMovies}>Get More Movies to Review</button>
                </div> : null}

        </div>
    )
}

export default RateMore;
