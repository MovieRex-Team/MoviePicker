import React from 'react'
import '../App.css';
import imdbIcon from "../assets/imdb.jpg"
import rtIcon from "../assets/rtLogo.png"
import metaIcon from "../assets/metaLogo.png"

const MovieCard = props => {
    return (
        <div key={props.movie.imdbID} className="moviePickCard animate">
            <div className='movieFlex'>
                <img alt="Movie Poster" className='moviePickPoster' src={props.movie.Poster} />
                <div className="movieInfoDiv">
                    <div className='moviePickInfo'>
                        <p className='moviePickHeader'><strong>#{props.index + 1} Pick: {props.movie.Title}</strong></p>
                        <div className='quickPickDesc'>
                            <p className="infoText">{props.movie.Plot}</p>
                        </div>
                        <p className='infoHeader'>Cast</p>
                        <p className='infoText'>{props.movie.Actors}</p>
                        <div className='quickInfo'>
                            <div className='quickDiv'>
                                <span className="quickHeader">Director</span>
                                <span className='quickText'>{props.movie.Director}</span>
                            </div>
                            <div className='quickDiv'>
                                <span className="quickHeader">Rating</span>
                                <span className='quickText'>{props.movie.Rated}</span>
                            </div>
                            <div className='quickDiv'>
                                <span className="quickHeader">Run Time</span>
                                <span className='quickText'>{props.movie.Runtime}</span>
                            </div>
                        </div>
                        <hr />
                        <p className='moviePickHeader' style={{ textDecoration: "none" }}><strong>Rate It:</strong></p>
                        <div className="flexRow">
                            <button className="ratingButton loveButton">Loved It</button>
                            <button className="ratingButton skipButton">Skip It</button>
                            <button className="ratingButton hateButton">Hated It</button>
                        </div>
                    </div>
                </div>
                <div className='ratingsDiv'>
                    <div className='rating'>
                        <img alt="imdb logo" src={imdbIcon} width='80' />
                        <p className='ratingValue'>{props.movie.Ratings[0].Value}</p>
                    </div>
                    <div className='rating'>
                        <img alt="rotten tomatoes logo" src={rtIcon} width='80' />
                        <p className='ratingValue'>{props.movie.Ratings[1].Value}</p>
                    </div>
                    <div className='rating'>
                        <img alt="metacritic logo" src={metaIcon} width='100' />
                        <p className='ratingValue'>{props.movie.Ratings[2].Value}</p>
                    </div>
                </div>
            </div>
        </div>
    )
}

export default MovieCard;