import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';
import { ThemeProvider } from "@mui/material";

import { appTheme } from "./themes/themes";
import { SnackbarProvider } from 'notistack';
import { useSnackbar } from 'notistack';

const root = ReactDOM.createRoot(document.getElementById('root'));

const DismissAction = ({ id }) => {
  const { closeSnackbar } = useSnackbar()
  return (
    <>
      <button style={{ background: 'transparent', cursor: 'pointer', borderRadius: '50%', border: '1px solid white', color: 'white' }} onClick={() => closeSnackbar()}>X</button>
    </>
  )
}
root.render(
  <React.StrictMode>
    <ThemeProvider theme={appTheme} >
      <SnackbarProvider
        action={() => <DismissAction />}
        anchorOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}>
        <App />
      </SnackbarProvider>
    </ThemeProvider>
  </React.StrictMode >
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
