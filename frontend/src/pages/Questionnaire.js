import { Link } from 'react-router-dom';
import '../App.css';


function Card(props) {
  return (
    <div className="card -horizontal" >
      <div className='cardBody'>
        <h2 className='cardTitle'>
          {props.title}
        </h2>
        <div className='listLink'>
        {props.link ? <Link to="/movielist" className="listBtn" ><span></span></Link>  : null} 
        </div>
        <div className='pickLink'>
          {props.links ? <Link to="/quickpick" className="pickBtn" ><span></span></Link>  : null} 
        </div>
      </div>
    </div>
    
  )
}
const Questionaire = () => {
return  ( 
  <>
  <Card 
   title='List Movies'
   link={true}
   links={false}/>
   <Card 
   title='Pick Movies'
   link={false}
   links={true} />
  </> 

)
}
export default Questionaire;