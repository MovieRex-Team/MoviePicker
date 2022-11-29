import React, { useState } from 'react';
import '../App.css';
import "../assets/style/AuthStyle.css"
import axios from 'axios';
import { useSnackbar } from 'notistack';


const LoginComponent = () => {
    const [username, setUsername] = useState('');
    const [pass, setPass] = useState('');
    const { enqueueSnackbar, closeSnackbar } = useSnackbar();
    const handleSubmit = () => {
        console.log(email.length, pass.length);
        if (username.length === 0 || pass.length === 0) {
            // setMessageInDOM("Please fill out all fields", "messageError")
            enqueueSnackbar('Please fill out all fields', { variant: 'error' })
            return;
        }
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        // if (!re.exec(email)) {
        //     setMessageInDOM("Email not in proper format", "messageError")
        //     return;
        // }
        var bodyFormData = new FormData();
        bodyFormData.append('username', username);
        bodyFormData.append('password', pass);
        await axios({
            method: "post",
            url: "http://localhost:8000/movie/search",
            data: bodyFormData,
            url: `http://localhost:8000/movie/${props.movie.tomato_url}/full`,
        }).then(res => {
            console.log(res);
        }).catch(err => console.log(err))

    }
    const setMessageInDOM = (message, type, duration = 5000) => {
        setMessage(message);
        setMessageType("messageError")
        setTimeout(() => {
            setMessage('')
            setMessageType("")
        }, duration)
    }
    const [message, setMessage] = useState('');
    const [messageType, setMessageType] = useState('');
    return (
        <div>
            {message.length > 0 ? <div className={messageType}><p>{message}</p></div> : null}
            <input className='input' placeholder='Username' type='email' onChange={e => setUsername(e.target.value)} value={username} />
            <input className='input' placeholder='Password' type='password' onChange={e => setPass(e.target.value)} value={pass} />
            <br />
            <div className="submitButtonDiv">
                <button onClick={handleSubmit} className='submitButton'>Submit</button>
            </div>
        </div>
    )
}

export default LoginComponent;