import React, { useEffect, useState } from 'react';
import '../App.css';
import '../assets/style/myRex.css'
import { MovieArray, FinalResult } from "../fakeData/MovieData"

const PosterLoading = () => {
    const [index, setIndex] = useState(0);
    const timer = setInterval(() => {
        setIndex(index + 1)
    }, 250)
    useEffect(() => {
        return () => {
            clearInterval(timer)
        }
    },
        [])
    return (
        <div style={{ zIndex: 20 }}>
            <img width='250' src={MovieArray[index % 25].poster_url} />
        </div>
    )
}
export default PosterLoading