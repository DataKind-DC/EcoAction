import {decode} from "jsonwebtoken";

function apiTokenValid() {
  const token = localStorage.getItem('apiToken')
  if (token) {
    var decodedToken=decode(token, {complete: true});
    var dateNow = new Date();
    // console.log(decodedToken)
    return (decodedToken.payload.exp * 1e3 > dateNow.getTime())
  } else {
    return false
  }
}

export {apiTokenValid}