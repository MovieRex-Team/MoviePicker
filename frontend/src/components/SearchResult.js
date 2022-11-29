import { borderRadius } from '@mui/system';
import React, { useState } from 'react';
import axios from 'axios'
import { useNavigate } from 'react-router-dom';
import { useStore } from '../store'

const SearchResult = (props) => {
    const [hovered, setHover] = useState(false);
    const setCurrentMovie = useStore(state => state.setCurrentMovie);
    const navigate = useNavigate()
    const movieClick = async () => {
        await axios({
            method: "get",
            url: `${process.env.REACT_APP_API_URL}/movie/${props.movie.tomato_url}/full`,
        }).then((res) => {
            console.log(res.data.movie);
            const obj = { title: res.data.movie.title }
            setCurrentMovie(res.data.movie);
            navigate('/movie');
            props.closeNav(false);
            props.closeDrawer();
            props.setInput('')
            props.setShortList([]);
        })
    }
    return (
        <div onClick={movieClick} onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)} style={hovered ? styles.containerHovered : styles.container} className="searchResult">
            <img style={styles.image} src={props.movie.Poster || props.movie.poster_url} />
            <span style={styles.child}>{props.movie.Title || props.movie.title}</span>
            <span style={styles.child}>({props.movie.Year || props.movie.year})</span>
        </div>
    )
}

const styles = {
    container: {
        display: 'flex',
        flexDirection: 'row',
        justifyContent: "space-evenly",
        alignItems: "center",
        color: 'black',
        margin: "15px",
        padding: "2%",
        borderRadius: ".5rem"
    },
    containerHovered: {
        display: 'flex',
        flexDirection: 'row',
        justifyContent: "space-evenly",
        alignItems: "center",
        color: 'white',
        margin: "15px",
        background: "black",
        transition: ".3s",
        padding: "2%",
        borderRadius: ".5rem"
    },
    image: {
        width: '40px',
        borderRadius: ".5rem"
    },
    child: {
        marginLeft: "20px"
    }
}
export default SearchResult;