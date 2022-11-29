import React from 'react';
import '../App.css';
import '../assets/style/myRex.css'
import Stars from './Stars'

import Typography from '@mui/material/Typography';

import { useSnackbar } from 'notistack';


const RandoRex = props => {
    const newRating = () => {
        props.setRating()
    }
    const startOver = () => {
        props.setRecs([]);
        props.setRatings([]);
    }
    console.log(props.ratings)
    return (
        <div>
            <p style={{ color: '#40826D', width: '60%', padding: '2%', margin: '2% auto', background: 'whitesmoke', fontWeight: '650', borderRadius: '.5rem' }}>
                Rate the recs you have seen, then recalculate your recs. Go back and add ratings to your current ratings list or start completely over. But to get the best recs you should sign up for an account and we will save all your ratings.
            </p>
            <div className='rexContainer'>
                {props.recs.map((r, i) => (
                    <div key={r.tomato_url} className='rexDiv'>
                        <img alt="Movie Poster" width='200' src={r.poster_url} />
                        <p>{i + 1}. {r.title}</p>
                        <Stars
                            setRating={props.setRating}
                            movie={r} />
                    </div>
                ))}
            </div>
            <button className="getMyRexButton" onClick={props.massSubmit} style={{ marginBottom: "30px" }}>Recalculate Recs</button>
            <p>Click below to add ratings to your current list of ratings.</p>
            <button className="getMyRexButton" onClick={() => props.setRecs([])}>Add Reviews</button>
            <p>Click below to start completely over, current Rex will be lost.</p>
            <button className="getMyRexButton" onClick={startOver}>Start Over</button>
        </div>
    )
}
export default RandoRex