import React, { useState } from 'react';

import { Link } from 'react-router-dom';
import Button from '@mui/material/Button';
import Dialog from '@mui/material/Dialog';
import DialogActions from '@mui/material/DialogActions';
import DialogContent from '@mui/material/DialogContent';
import DialogContentText from '@mui/material/DialogContentText';
import DialogTitle from '@mui/material/DialogTitle';
import RegisterPage from '../pages/RegisterPage';
import { useStore } from "../store"
import SearchBar from "./SearchBar"
import axios from 'axios';
import { useSnackbar } from 'notistack';


const NavBar = props => {
    const [loginToggle, toggleLogin] = useState(false);
    const [open, setOpen] = React.useState(false);
    const user = useStore(state => state.user);
    const setMyRex = useStore(state => state.setMyRex);
    const { enqueueSnackbar } = useSnackbar();
    const setUser = useStore(state => state.setUser);
    const [username, setUsername] = useState('');
    const [pass, setPass] = useState('');
    const [isNavExpanded, setIsNavExpanded] = useState(false)
    const handleClickOpen = () => {
        setOpen(true);
    };

    const handleClose = () => {
        setOpen(false);
    };
    const onLoginClick = async () => {
        if (username.length === 0 || pass.length === 0) {
            enqueueSnackbar('Please fill out all fields', { variant: 'error' })
            return;
        }
        var bodyFormData = new FormData();
        bodyFormData.append('username', username);
        bodyFormData.append('password', pass);
        await axios({
            method: "post",
            url: `${process.env.REACT_APP_API_URL}/login`,
            data: bodyFormData,
        }).then(res => {
            console.log(res);
            if (res.data.result === 'success') {
                const u = {
                    username: res.data.user.username,
                    email: res.data.user.email,
                    token: res.data.token,
                    isLoggedIn: true,
                }
                setUser(u);
                enqueueSnackbar('Successfully logged in', { variant: 'success' })
                localStorage.setItem("rexToken", res.data.token);
                localStorage.setItem("rexUser", res.data.user.username)
                toggleLogin(false);
                setUsername('');
                setPass('');
                setIsNavExpanded(false);
            } else {
                enqueueSnackbar('Improper credentials or user', { variant: 'error' })
            }
        }).catch(err => console.log(err))

    }
    const logOut = () => {
        const emptyUser = {
            email: '',
            username: '',
            token: '',
            isLoggedIn: false,
        };
        setUser(emptyUser);
        toggleLogin(false);
        setIsNavExpanded(false);
        setMyRex([]);
        localStorage.removeItem("rexToken");
        localStorage.removeItem("rexUser")
    }
    const cancel = () => {
        toggleLogin(false);
        setUsername('');
        setPass('');
    }
    console.log(isNavExpanded)
    return (
        <nav className="navigation">
            <div className='navSection'>
                <Link className='navLink' to='/'>
                    <span className='brand-name'> MovieRex</span>
                </Link>
            </div>
            <button className="hamburger"
                onClick={() => {
                    setIsNavExpanded(!isNavExpanded)
                }}>
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-5 w-5"
                    viewBox="0 0 20 20"
                    fill="white"
                >
                    <path
                        fillRule="evenodd"
                        d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM9 15a1 1 0 011-1h6a1 1 0 110 2h-6a1 1 0 01-1-1z"
                        clipRule="evenodd"
                    />
                </svg>
            </button>
            <div className={isNavExpanded ? "navigation-menu expanded" : "navigation-menu"}>
                <div onClick={() => {
                    setIsNavExpanded(false)
                }} className='navSection'>
                    <Link className='navLink' to='/quickpick'>
                        <span className='navText'>{user.isLoggedIn ? 'My Rex' : 'Get Rex'}</span>
                    </Link>
                </div>
                {user.isLoggedIn ?
                    <div className='navSection'>
                        <Link onClick={() => {
                            setIsNavExpanded(false)
                        }} className="navLink" to="/profile"><span className="navText">{user.username}</span></Link>
                    </div> :
                    <div>
                        {!loginToggle ?
                            <div className='navSection'>
                                <span onClick={() => toggleLogin(true)} className='navText'>Login</span>
                            </div> :
                            <div className="loginInputDiv">
                                <input onChange={e => setUsername(e.target.value)} value={username} className="navInput" type="text" placeholder="Username" />
                                <input value={pass} onChange={e => setPass(e.target.value)} className="navInput" type="password" placeholder="Password" />
                                <button className="navButton navLoginButton" onClick={onLoginClick}>Login</button>
                                <button className="navButton navCancelButton" onClick={cancel}>Cancel</button>
                            </div>
                        }
                    </div>
                }
                <div className='navSection'>
                    {user.isLoggedIn ?
                        <span onClick={logOut} className="navText">Logout</span> :
                        <div>
                            {!loginToggle ?
                                <span onClick={() => {
                                    setIsNavExpanded(false)
                                    handleClickOpen()
                                }} className='navText'>Register</span> : null}
                        </div>
                    }
                </div>
                <div className="navSection searchDiv">
                    <SearchBar closeNav={setIsNavExpanded} closeDrawer={() => setIsNavExpanded(false)} />
                </div>
            </div>
            <Dialog open={open} onClose={handleClose}>
                <DialogTitle>Registration</DialogTitle>
                <DialogContent>
                    <DialogContentText>
                        Please supply some personal information.
                    </DialogContentText>
                    <RegisterPage toggleOff={handleClose} />
                </DialogContent>
                <DialogActions>
                    <Button onClick={handleClose}>Cancel</Button>
                </DialogActions>
            </Dialog>

        </nav>
    )
}

export default NavBar;


