import React, {useState} from 'react';
// import {decode} from 'jsonwebtoken'
// import PropTypes from 'prop-types';
import './Login.css';
import {makeStyles} from "@material-ui/core/styles";
import {Button, Modal} from "@material-ui/core";
import {apiTokenValid} from "../../Library";

const apiUrl = process.env.REACT_APP_API_URI

function getModalStyle() {
  const top = 50
  const left = 50
  return {
    top: `${top}%`,
    left: `${left}%`,
    transform: `translate(-${top}%, -${left}%)`,
  };
}

const useStyles = makeStyles((theme) => ({
  paper: {
    position: 'absolute',
    width: 400,
    backgroundColor: theme.palette.background.paper,
    border: '2px solid #000',
    boxShadow: theme.shadows[5],
    padding: theme.spacing(2, 4, 3),
  },
}));

export default function Login() {
  const classes = useStyles();
  // getModalStyle is not a pure function, we roll the style only on the first render
  const [modalStyle] = useState(getModalStyle);
  const [open, setOpen] = useState(false);
  const [errorMessage, setErrorMessage] = useState();

  const handleSubmit = async (event) => {
    event.preventDefault()
    const user = (event.target.elements[0].value)
    const pass = (event.target.elements[1].value)
    const requestOptions = {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({user: user, password: pass})
    };

    await fetch(`${apiUrl}/login`, requestOptions)
      .then((res) => {
        if (res.ok) {
          setErrorMessage('')
          return res.json()
        } else {
          if (res.status === 401) {
            setErrorMessage('Invalid Username or Password')
          }
          throw new Error(res.status)
        }
      })
      .then(
        (data) => {
          localStorage.setItem('apiToken', data.token)
          // localStorage.setItem('time', Date.now().toString().slice(8))
        })
      .catch((err) => {
        // console.log(err.data.message)
      })
    if (apiTokenValid()) {
      setOpen(false)
    }
  }

  const body = (
    <div style={modalStyle} className={classes.paper}>
      {/*<div className="login-wrapper">*/}
      <h1>Please Log In</h1>
      <h3>{errorMessage}</h3>
      <form onSubmit={handleSubmit}>
        <label>
          <p>Username</p>
          <input type="text"/>
          {/*<input type="text" onChange={e => setUserName(e.target.value)} />*/}
        </label>
        <label>
          <p>Password</p>
          <input type="password"/>
        </label>
        <div>
          <button type="submit">Submit</button>
        </div>
      </form>
      <Button onClick={() => setOpen(false)}> Cancel </Button>
    </div>
  );

  if (apiTokenValid()) {
    return (
      <></>
    )
  } else {
    return (
      <div>
        <Button variant={"contained"} color={"default"} onClick={() => setOpen(true)}> Log In </Button>
        <Modal
          open={open}
          onClose={() => setOpen(false)}
        >
          {body}
        </Modal>
      </div>
    )
  }
}
