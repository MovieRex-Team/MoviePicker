import '../App.css';
import { Link } from "react-router-dom";

const Movielist = () => {
return (
 <div className='movielist'>
    <h1>Please list 4 of your favoirte movies</h1>
      <div>
        
        <div className='movietwo'>
        <label> Movie 1</label>
        <input type = "text" />
        </div>
        <div className='moviethree'>
        <label> Movie 2</label>
        <input type = "text" />
        </div>
        <div className='moviefour'>
        <label> Movie 3</label>
        <input type = "text" />
        </div>
        <div className='moviefive'>
        <label> Movie 4</label>
        <input type = "text" />
        </div>
        <div className='backDiv'>
                <Link className='linkButton' to={`/questionaire`}>Back</Link>
            </div>
      </div>     
 </div>
)
  
}
export default Movielist;