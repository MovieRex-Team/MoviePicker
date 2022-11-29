import React, { useEffect, useState } from 'react';
import '../App.css';
import {Link} from 'react-router-dom'
import '../assets/style/myRex.css'
import Typography from '@mui/material/Typography';
import { useStore } from '../store';
import axios from 'axios'
import Stars from './Stars'
import { useSnackbar } from 'notistack';
import Flask from './Flask';
import Spinner from './Spinner'
import RateMore from './RateMore';

const MyRex = props => {
    const user = useStore(state => state.user);
    const myRex = useStore(state => state.myRex);
    const setMyRex = useStore(state => state.setMyRex);
    const ratings = useStore(state => state.ratings);
    const incRatings = useStore(state => state.incRatings);
    const resetRatings = useStore(state =>state.resetRatings);
    const [calculate, setCalculate] = useState(false);
    const [fetching, setFetching] = useState(false);
    const [rexes, setRexes] = useState(0);
    const [recs, setRex] = useState([]);
    const [currentRating, setCurrentRating] = useState({});
    const { enqueueSnackbar, closeSnackbar } = useSnackbar();
    const [rateMore, setRateMore] = useState(false);
    useEffect(() => {
        const getReviews = async () => {
            const url = `${process.env.REACT_APP_API_URL}/${user.username}/review/getpage/info`
            return await axios({
                method: 'get',
                url: url,
                headers: {
                    'Authorization': localStorage.getItem('rexToken'),
                }
            })
        }
        getReviews()
            .then(res => {
                console.log(res, res.data.reviews.length);
                if (res.data.reviews.length > 0) {
                    setRexes(res.data.reviews.length);
                }
            })
    }, [])
    const getRex = (async () => {
        setCalculate(true)
        await axios({
            method: 'get',
            url: `${process.env.REACT_APP_API_URL}/movie/recs/${user.username}`,
            headers: {
                'Authorization': localStorage.getItem('rexToken'),
            }
        }).then(res => {
            if (res.data.result === 'success') {
                console.log(res)
                setMyRex(res.data.recs)
                setCalculate(false);
                resetRatings();
            } else {
                console.log(res)
                enqueueSnackbar('Could not get rex. Reason: ' + res.data.err , {variant: 'error'})
                setCalculate(false)
            }
        }).catch(err => {
            setCalculate(false);
            console.log(err)
        })
    })
    const updateCurrentRating = (movie, rating) => {
        console.log(rating);
        const data = {
            tomato_url: movie.tomato_url,
            rating: rating
        }
        setCurrentRating(data)
    }
    const submitCurrentRating = async () => {
        setFetching(true);
        const id = currentRating.tomato_url
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
            enqueueSnackbar('Review Submitted!', { variant: 'success' });
            incRatings();
            const copy = myRex.filter((x) => x.tomato_url !== id)
            console.log(copy)
            setMyRex(copy);
            setFetching(false);
        }).catch(err => {
            setFetching(false);
            console.log(err)
        })
    }
    console.log(currentRating)
    return (
        <div>
            {calculate ? <Flask message="Hold on, we're brewing up your Movie RX..." /> :
                <div>
                    {/* <Typography variant='h4'>Hi, {user.username}</Typography> */}
                    <div className="rexDiv">
                        <Typography variant='h5'>{!rateMore ? 'Current Recommendation' : 'Rate Movies'}</Typography>
                        {Object.keys(myRex).length > 0 ? <p style={{ color: '#40826D', width: '60%', padding: '2%', margin: '2% auto', background: 'whitesmoke', fontWeight: '650', borderRadius: '.5rem' }}>
                            {rateMore ? 'Rate as many movies as you want here, but the more the better.. Then return to My Rex and Recalculate your Rex!!' :
                                "MovieRex is an interactive platform, rate the movies you've seen, skip the ones you're not interested in, and watch the rest!."}</p>
                            : null}
                    </div>
                    {rateMore ? <RateMore setRateMore={setRateMore} rateMore={rateMore}  /> : <div>
                        {myRex.length > 0 ?
                            <div className='rexContainer'>
                                {myRex.map((r, i) => (
                                    fetching && r.tomato_url === currentRating.tomato_url ?
                                        <Spinner message="Sending Review" size={200} /> :
                                        <div className='rexDiv'>
                                            {/* <img style={{cursor: 'pointer'}} width='200' src={r.poster_url} onClick={() => { */}
                                                <Link to="/moviefull" state={{ movie: r }}>
                                                    <img alt="MovieImage" width="150" src={r.poster_url} />
                                                </Link>
                                            {/* }}  /> */}
                                            <p>{i + 1}. {r.title}</p>
                                            <Stars
                                                setRating={updateCurrentRating}
                                                movie={r} />
                                            {r.tomato_url === currentRating.tomato_url ?
                                                <button className="getMyRexButton" onClick={submitCurrentRating}>Submit {currentRating.rating} Stars</button> :
                                                <button className="getMyRexButton" onClick={async () => {
                                                    setCurrentRating(r)
                                                    var bodyFormData = new FormData();
                                                    setFetching(true)
                                                    bodyFormData.append('tomato_url', r.tomato_url)
                                                    bodyFormData.append('rating', 0);
                                                    await axios({
                                                        method: 'post',
                                                        url: `${process.env.REACT_APP_API_URL}/${user.username}/review/add`,
                                                        data: bodyFormData,
                                                        headers: {
                                                            'Authorization': localStorage.getItem('rexToken'),
                                                        }
                                                    }).then(res => {
                                                        setCurrentRating({});
                                                        enqueueSnackbar('Review Submitted!', { variant: 'success' });
                                                        incRatings();
                                                        const copy = myRex.filter((x) => x.tomato_url !== r.tomato_url)
                                                        console.log(copy)
                                                        setMyRex(copy);
                                                        setFetching(false);
                                                    }).catch(err => {
                                                        setFetching(false);
                                                        console.log(err)
                                                    })
                                                }}>Skip This Rec</button>
                                            }
                                        </div>
                                ))}
                            </div> : <button className="getMyRexButton" onClick={() => getRex()}>Get My Rex</button>}
                        <div>
                            {ratings > 0 ? <p className="sentRatingP">You have rated {ratings} movies this session.</p> : null}
                            <button className="getMyRexButton" onClick={() => setRateMore(true)}>Rate Random Movies</button> 
                            {ratings > 0 ? <button className="getMyRexButton" onClick={() => getRex()}>Recalculate Rex</button> : null}
                        </div>
                    </div>
                    }
                </div>}
        </div >

    )
}
export default MyRex;