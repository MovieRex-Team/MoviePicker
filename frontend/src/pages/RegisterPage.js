import axios from 'axios';
import React, { useState } from 'react';

import '../App.css';
import "../assets/style/AuthStyle.css"
import { useStore } from "../store"
import { useSnackbar } from 'notistack';



const RegisterPage = props => {
    const setUser = useStore(state => state.setUser);
    const [email, setEmail] = useState('');
    const [username, setUsername] = useState('');
    const { enqueueSnackbar, closeSnackbar } = useSnackbar();
    const [pass, setPass] = useState('');
    const [confirm, setConfirm] = useState('');
    const handleSubmit = async () => {
        if (email.length === 0 || pass.length === 0 || username.length === 0) {
            enqueueSnackbar("Please fill out all fields", { variant: 'error' })
            return;
        }
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        if (!re.exec(email)) {
            enqueueSnackbar("Email not in proper format", { variant: 'error' })
            return;
        }
        if (username.length <= 3) {
            enqueueSnackbar("username must be at least 4 characters", { variant: 'error' })
            return
        }
        if (pass.length < 8) {
            enqueueSnackbar("Password must be at least 8 characters", { variant: 'error' })
            return;
        }
        if (pass !== confirm) {
            enqueueSnackbar("Passwords must match", { variant: 'error' })
            return
        }
        var bodyFormData = new FormData();
        bodyFormData.append('username', username);
        bodyFormData.append('email', email);
        bodyFormData.append('password', pass);
        await axios({
            method: "post",
            url: `${process.env.REACT_APP_API_URL}/signup`,
            data: bodyFormData,
        }).then(res => {
            console.log(res)
            if (res.data.result === 'success') {
                enqueueSnackbar("Succcessfully registered! Please log in.", { variant: 'success' })
                props.toggleOff();
            } else {
                enqueueSnackbar("Error signing up, please try again", { variant: "error" })
            }
        }).catch(err => console.log('could not register'))
    }
    return (
        <div>
            <input className='input' placeholder='Email' type='email' onChange={e => setEmail(e.target.value)} value={email} />
            <input className='input' placeholder='Username' type='text' onChange={e => setUsername(e.target.value)} value={username} />
            <input className='input' placeholder='Password' type='password' onChange={e => setPass(e.target.value)} value={pass} />
            <input className='input' placeholder='Confirm Password' type='password' onChange={e => setConfirm(e.target.value)} value={confirm} />
            <br />
            <div className="submitButtonDiv">
                <button onClick={handleSubmit} className='submitButton'>Submit</button>
            </div>
        </div>
    )
}

export default RegisterPage;