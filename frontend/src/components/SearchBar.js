
import React, { useEffect, useState, useRef } from 'react';
import { shortTitles } from '../data/1lettertitle';
import SearchResult from './SearchResult';
import FetchingData from './FetchingData'
import axios from 'axios'
import { DebounceInput } from 'react-debounce-input';
import { useSnackbar } from 'notistack';

const SearchBar = props => {
    const ref = useRef(null);
    const [input, setInput] = useState('');
    const [exact, setExact] = useState(false);
    const [limit, setLimit] = useState(10);
    const [shortList, setShortList] = useState([]);
    const [fullResults, setFullResults] = useState([])
    const [loading, setLoading] = useState(false);
    const [apiData, setApiData] = useState([]);
    const [movie, setMovie] = useState({});
    const [notFound, setNotFound] = useState(false);
    const handleInput = async e => {
        setFullResults([])
        setExact(false)
        console.log(e.target.value.length)
        if (e.target.value.length === 0) {
            setInput(e.target.value)
            setShortList([])
            return;
        } else if (e.target.value.length === 1) {
            setInput(e.target.value)
            const titles = shortTitles.filter(x => x.title.toLowerCase().includes(e.target.value.toLowerCase()))
            setShortList(titles)
            return
        } else {
            setLimit(10)
            if (e.target.value.length > 0) {
                setLoading(true);
                setInput(e.target.value)
                var bodyFormData = new FormData();
                bodyFormData.append('search', e.target.value);
                await axios({
                    method: "post",
                    url: `${process.env.REACT_APP_API_URL}/movie/search/all`,
                    data: bodyFormData,
                    headers: { "Content-Type": "multipart/form-data" },
                }).then(res => {
                    console.log(res);
                    if (res.data.movie_list !== undefined) {
                        setShortList(res.data.movie_list)
                    } else {
                        console.log('in else')
                        setShortList([]);
                    }
                    setLoading(false)
                }).catch(err => console.log(err))
            } else console.log('caught')
        }
    }
    useEffect(() => {
        /**
         * Clear input and shortList if clicked outside of component.
         */
        function handleClickOutside(event) {
            if (ref.current && !ref.current.contains(event.target)) {
                setInput('');
                setShortList([]);
                setLimit(10)
            }
        }
        // Bind the event listener
        document.addEventListener("mousedown", handleClickOutside);
        return () => {
            // Unbind the event listener on clean up
            document.removeEventListener("mousedown", handleClickOutside);
        };
    }, [ref]);
    const getAll = async () => {
        setExact(false);
        setShortList(fullResults);
        setFullResults([])
    }
    if (apiData.length > 0) console.log(apiData[0].Title);
    const getExact = () => {
        setExact(true)
        setFullResults(shortList);
        const list = shortList.filter(x => x.title.toLowerCase() === input.toLowerCase())
        setShortList(list)
    }
    console.log(shortList, limit)
    const searchType = exact ? 'Exact Matches' : "Search Results"
    return (
        <div ref={ref} style={input.length > 0 ? styles.searchDropdown : null}>
            <DebounceInput
                type="search"
                value={input}
                onChange={e => handleInput(e)}
                placeholder="Movie"
                debounceTimeout={500}
                width="100px" />
            {input.length > 0 ?
                <div style={{ textAlign: 'center', marginTop: '15px' }}>
                    {input.length === 1 ? <p style={styles.topMessage}>Only showing 1 letter titles, for more results expand your search to at least 2 chararacters</p> : null}
                    <p className='bold' style={styles.topMessage}>{shortList.length} {searchType} for <strong>"{input.replace(/ /g, "\u00A0")}"</strong></p>
                    {shortList.length > 50 && exact === false ? <button className='getMoreButton' onClick={getExact}>Show Exact Matches</button> : null}
                    {exact === true && input.length > 1 ? <button className='getMoreButton' onClick={getAll}>Show All Results</button> : null}
                    <hr />
                </div>
                : null}
            {input.length === 0 ? null :
                loading ?
                    <FetchingData /> :
                    <div>
                        {shortList.length > 0 ?
                            shortList.map((m, i) => (
                                <div key={m.tomato_url}>
                                    {i + 1 <= limit ?
                                        <div style={styles.searchResultDiv} className='searchDropdown'>
                                            <SearchResult closeNav={props.closeNav} movie={m} setInput={setInput} setShortList={setShortList} closeDrawer={props.closeDrawer} />
                                            <hr />
                                        </div>
                                        : null}
                                </div>
                            )) : <p style={styles.topMessage}>No Movies Found For "{input.replace(/ /g, "\u00A0")}"</p>}
                        {shortList.length > 0 && shortList.length + 1 > limit ?
                            <div style={{ textAlign: 'center' }}>
                                <p className="bold" style={{ color: 'black', width: '80%', margin: 'auto' }}>Showing {limit} movies out of {shortList.length} results </p>
                                <button className='getMoreButton' onClick={() => setLimit(limit + 10)}>Show more</button>
                            </div> : <p className="bold" style={{ width: "80%", color: 'black', margin: 'auto', marginTop: '25px' }}>Showing all {shortList.length} results for {input}</p>}
                    </div>
            }
        </div >
    )
}
const styles = {
    searchDropdown: {
        position: 'relative',
        zIndex: 10,
        maxHeight: '400px',
        overflow: "scroll",
        background: "white",
        paddingBottom: '30px'

    },
    searchResultDiv: {
        width: '300px',
        cursor: 'pointer'
    },
    titleText: {
        color: 'black'
    },
    topMessage: {
        maxWidth: '250px',
        width: '80%',
        margin: 'auto',
        color: 'black'
    }
}

export default SearchBar;