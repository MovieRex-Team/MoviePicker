import React from "react"
import spinner from "../assets/spinner.svg"

const FetchingData = () => {
    return (
        <div style={{ width: '200px', display: 'flex', flexDirection: "row", justifyContent: "flex-start", alignItems: "center", color: 'black' }}>
            <img src={spinner} width="45px" />
            <span>Fetching Data</span>
        </div>
    )
}

export default FetchingData;