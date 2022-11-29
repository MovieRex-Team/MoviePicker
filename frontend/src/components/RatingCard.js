import React from 'react'
import '../App.css';
import imdbIcon from "../assets/imdb.jpg"
import rtIcon from "../assets/rtLogo.png"
import metaIcon from "../assets/metaLogo.png"
import Stars from "./Stars"
import StarBorderIcon from '@mui/icons-material/StarBorder';
import StarIcon from '@mui/icons-material/Star';
// import StarHalfIcon from '@mui/icons-material/StarHalf';


/**
 * 
 * To access all the movie info, use props.movie
 * props.length is the length of the move array
 * props.index is current movie being rendered's index with in the movie array
 * Most of the functionality happens in quickpickpage, the buttons in this page call
 * functions that are passed in from quickpickpage and called using props.
 * 
 * @returns 
 */
const RatingCard = props => {
    // Array to reference the stars
    const ratings = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    return (
        <div className='movieCards'>
        <div key={props.movie.imdbID} className="moviePickCard animate">
            <div className='movieFlex'>
                <img alt="moviePoster" className='moviePickPoster' src={props.movie.Poster} />
                <div className="movieInfoDiv">
                    <div className='moviePickInfo'>
                        <p className='moviePickHeader'><strong>Rating {props.index + 1}: {props.movie.Title}</strong></p>
                        <div className='quickPickDesc'>
                            <p className="infoText">{props.movie.Plot}</p>
                        </div>
                        <p className='moviePickHeader' style={{ textDecoration: "none" }}><strong>Rate It:</strong></p>
                        {/**
                         * This is for the stars. Loops throuugh the array ratings.
                         * props.setRating is called here, it is passed in from quickpickpage.
                         */}
                        <div>
                            <Stars setRating={props.setRating} movie={props.movie} />
                            {/* {ratings.map((rating, i) => (
                                props.movie.rexRating !== null && props.movie.rexRating >= ratings[i] ?
                                    <StarIcon
                                        fontSize="large"
                                        className="starButton starOutline"
                                        onClick={() => {
                                            props.setRating(props.movie, ratings[i]);
                                        }} />
                                    :
                                    <StarBorderIcon
                                        fontSize="large"
                                        className="starButton starOutline"
                                        onClick={() => {
                                            props.setRating(props.movie, ratings[i]);
                                        }} />
                            ))} */}
                        </div>
                        <div className="flexRow">
                            {/**
                             * On click these buttons call the prop functions from
                             * quickpickpage. props.skip and props.goBack
                             */}
                            {props.index + 1 < props.length ?
                                <button className="ratingButton skipButton"
                                    onClick={() => props.skip()}
                                >Skip It</button> : null}
                            {props.index !== 0 ?
                                <button
                                    className="ratingButton goBackButton"
                                    onClick={() => props.goBack()}>Go Back</button> : null}
                        </div>
                    </div>
                </div>
            </div>
        </div>
        </div>
       
    )
}

export default RatingCard;
