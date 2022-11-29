import React, { useEffect, useState } from 'react';
import '../App.css';
import '../assets/style/profileStyle.css'
import { useStore } from "../store";
import { Link, Navigate, useNavigate } from "react-router-dom"
import axios from 'axios'
import TextField from '@mui/material/TextField'
import Typography from '@mui/material/Typography';
import { useSnackbar } from 'notistack';
import Flask from '../components/Flask';
import Spinner from '../components/Spinner'


const ProfilePage = props => {
    const user = useStore(state => state.user);
    const [calculate, setCalculate] = useState(false);
    const [rexIndex, setRexIndex] = useState(0);
    const myRex = useStore(state => state.myRex);
    const setMyRex = useStore(state => state.setMyRex);
    const ratings = useStore(state => state.ratings);
    const incRatings = useStore(state => state.incRatings);
    const resetRatings = useStore(state => state);
    const [reviews, setReviews] = useState([]);
    const [loading, setLoading] = useState(false);
    const [editEmail, setEditEmail] = useState(false);
    const { enqueueSnackbar, closeSnackbar } = useSnackbar();
    const [email, setEmail] = useState(user.email)
    const [pass, setPass] = useState('');
    const setCurrentMovie = useStore(state => state.setCurrentMovie);
    const navigate = useNavigate();
    const [page, setPage] = useState(1);
    const getReviews = async (page) => {
        const url = `${process.env.REACT_APP_API_URL}/${user.username}/review/getpage/${page}/info`
        return await axios({
            method: 'get',
            url: url,
            headers: {
                'Authorization': localStorage.getItem('rexToken'),
            }
        })
    }
    useEffect(() => {
        setLoading(true)
        getReviews(1)
            .then(res => {
                if (res.data.result === 'success') {
                    console.log(res)
                    setReviews(res.data.reviews);
                    setLoading(false);
                    enqueueSnackbar('Reviews Fetched', {variant: 'success'})
                } else {
                    console.log('no reviews yet.')
                    setLoading(false);
                }
            }).catch(err => console.log(err))
    }, [])
    const getNextPage = () => {
        setPage(page + 1)
        setLoading(true)
        getReviews(page + 1)
            .then(res => {
                if (res.data.result === 'success') {
                    console.log(res);
                    let arr = reviews;
                    arr.concat(res.data.reviews);
                    setLoading(false);
                    setReviews(res.data.reviews);
                } else console.log('no moe reviews')
            }).catch(err => {

            })
    }
    const goBack = () => {
        setPage(page - 1)
        setLoading(true)
        getReviews(page - 1)
            .then(res => {
                if (res.data.result === 'success') {
                    console.log(res);
                    let arr = reviews;

                    setLoading(false);
                    setReviews(res.data.reviews);
                } else console.log('no moe reviews')
            }).catch(err => {
                console.log(err)
                setLoading(false);
            })
    }
    const updateEmail = async () => {
        var bodyFormData = new FormData();
        bodyFormData.append('new_email', email);
        bodyFormData.append('password', pass)
        await axios({
            method: "post",
            url: `${process.env.REACT_APP_API_URL}/${user.username}/change/email`,
            data: bodyFormData,
            headers: {
                'Authorization': localStorage.getItem('rexToken'),
            }
        }).then((res) => {
            console.log(res)
            enqueueSnackbar('Could not update', { variant: 'success' });
        })
    }
    const updatePass = () => {

    }
    const goToMovie = async id => {
        await axios({
            method: "get",
            url: `${process.env.REACT_APP_API_URL}/movie/${id}/full`,
        }).then((res) => {
            setCurrentMovie(res.data.movie);
            navigate('/movie');
        })
    }
    const getRex = (async () => {
        setCalculate(true);
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
            } else {
                console.log(res)
                enqueueSnackbar('Could not get rex. Reason: ' + res.data.err, { variant: 'error' })
                setCalculate(false)
            }
        })
            .catch(err => {
                console.log(err);
                setCalculate(false)
            })
    })
    const delButton = rev => {
        console.log(rev)
    }
    return (
        <div>
            {user.isLoggedIn ? null :
                <Navigate
                    to={{
                        pathname: "/",
                    }}
                />
            }
            {calculate ? <Flask message="Hold on, we're brewing up your Movie RX" /> :
                <div>
                    <Typography><h1>Hi, {user.username || user.email}</h1></Typography>
                    <div className="profileContainer">
                        <div style={styles.infoDiv}>
                            <div>
                                <Typography><h3>Current Recommendations</h3></Typography>
                                {myRex.length > 0 ?
                                    <div>
                                        <img width='200' src={myRex[rexIndex].poster_url} />
                                        <p>{rexIndex + 1}. {myRex[rexIndex].title}</p>
                                        {rexIndex > 0 ? <button className='profileButtons' onClick={() => setRexIndex(rexIndex - 1)}>Back</button> : null}
                                        {rexIndex + 1 < (myRex.length) ? <button className='profileButtons' onClick={() => setRexIndex(rexIndex + 1)}>Next</button> : null}
                                        {ratings > 0 ? <p className='sentRatingP'>You have rated {ratings} movies this session.</p> : null}
                                        <p>To interact with your recs, go to &nbsp;
                                            <Link className='navLink' to='/quickpick'>
                                                <span style={{color:"#40826D", textDecoration: 'underline'}}>My Rex</span>
                                            </Link></p>
                                    </div> : <button className='profileButtons' style={{ padding: '3%' }} onClick={() => getRex()}>Calculate My Rex</button>}
                            </div>
                            <div>
                                <Typography><h3>My Info</h3></Typography>
                                <TextField style={{ width: '240px' }} id="outlined-basic" label="Username" disabled variant="outlined" value={user.username} />
                                <br />
                                <TextField
                                    style={{ width: '240px', marginTop: '25px' }}
                                    onChange={e => setEmail(e.target.value)}
                                    id="outlined-basic" label="Email"
                                    disabled={!editEmail} variant="outlined"
                                    value={email} />
                                <br />
                                {!editEmail ? null :
                                    < TextField
                                        style={{ width: '240px', marginTop: '25px' }}
                                        onChange={e => setPass(e.target.value)}
                                        id="outlined-basic" label="Password" type="password" variant="outlined" value={pass} />
                                }
                                <div className="buttonDiv">
                                    <button onClick={() => setEditEmail(!editEmail)} className='profileButtons'>{!editEmail ? 'Edit Email' : 'Cancel Edit'}</button>
                                    {editEmail ?
                                        <button onClick={updateEmail} className='profileButtons'>Submit Email</button> : null
                                    }
                                </div>
                            </div>
                        </div>
                        <div>
                            <Typography><h3>My Reviews</h3></Typography>
                            {!loading ?
                                <div style={styles.reviewList}>
                                    {reviews.length > 0 ?
                                        <div>
                                            {reviews.map((r, i) => (
                                                <div className='reviewDiv'>
                                                    <img onClick={() => goToMovie(r.movie_info.tomato_url)} style={styles.image} src={r.movie_info.poster_url} />
                                                    <div style={styles.miniFlex}>
                                                        <span style={styles.title}><strong>{r.movie_info.title}</strong></span>
                                                        {r.rating > 0 ? <span style={styles.review}>{r.rating / 2} Stars</span> : <p style={styles.review}>Skipped</p>}
                                                        <span onClick={async () => {
                                                            console.log(r);
                                                            setLoading(true);
                                                            await axios({
                                                                method: "post",
                                                                url: `${process.env.REACT_APP_API_URL}/${user.username}/review/delete/${r.movie_info.tomato_url}`,
                                                                headers: {
                                                                    'Authorization': localStorage.getItem('rexToken'),
                                                                }
                                                            }).then((res) => {
                                                                console.log(res)
                                                                if (res.data.result === 'success') {
                                                                    setLoading(false);
                                                                    enqueueSnackbar("Review Successfully Deleted", { variant: 'success' })
                                                                    getReviews(page);
                                                                }
                                                            }).catch(err => {
                                                                console.log(err)
                                                                setLoading(false);
                                                                enqueueSnackbar('Could not delete', { variant: 'error' })
                                                            })
                                                        }} style={styles.delButton}>Delete</span>
                                                    </div>
                                                </div>
                                            ))}
                                        </div> : <p>You do not have any reviews yet..</p>
                                    }
                                </div> :
                                <div style={styles.reviewList}>
                                    <Spinner size={200} message={"Fetching Reviews"} />
                                </div>
                            }
                            <p style={{ color: 'gold' }}>Page {page}</p>
                            <div style={styles.buttonDiv}>
                                {page > 1 ?
                                    <button className='profileButtons' onClick={goBack}>Go Back</button> : null}
                                <button className='profileButtons' onClick={getNextPage}>Get More</button>
                            </div>
                        </div>
                    </div>
                </div>}
        </div>
    )
}

const styles = {
    reviewContainer: {
        display: 'flex',
        flexDirection: 'center',
        justifyContent: "space-between",
        alignItems: "center",
        margin: '1%'
    },
    reviewList: {
        background: 'lightgray',
        color: 'black',
        borderRadius: '.5rem',
        height: '500px',
        overflowY: 'scroll',
        padding: '1%',
        width: '280px',
        margin: 'auto'
    },
    image: {
        width: '80px',
        borderRadius: ".5rem"
    },
    buttonDiv: {
        display: "flex",
        flexDirection: 'row',
        justifyContent: 'center'
    },
    infoButtonDiv: {
        marginTop: '20px'
    },
    title: {
        width: '200px'
    },
    review: {
        color: 'blue',
        marginTop: '20px'
    },
    delButton: {
        color: 'red',
        textDecoration: 'underline',
        cursor: 'pointer'
    },
    miniFlex: {
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-evenly',
        alignItems: 'center'
    },
}

export default ProfilePage;