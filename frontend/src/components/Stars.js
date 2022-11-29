import React, { useState, useRef } from 'react';
import Box from '@mui/material/Box';
import StarIcon from '@mui/icons-material/Star';
import StarBorderIcon from '@mui/icons-material/StarBorder';

const Stars = props => {
    const precision = .5;
    const totalStars = 5;
    const emptyIcon = StarBorderIcon;
    const filledIcon = StarIcon;
    const [activeStar, setActiveStar] = useState(-1);
    const [hoverActiveStar, setHoverActiveStar] = useState(-1);
    const [isHovered, setIsHovered] = useState(false);
    const ratingContainerRef = useRef(null);

    const calculateRating = (e) => {
        const { width, left } = ratingContainerRef.current.getBoundingClientRect();
        let percent = (e.clientX - left) / width;
        const numberInStars = percent * totalStars;
        const nearestNumber = Math.round((numberInStars + precision / 2) / precision) * precision;

        return Number(nearestNumber.toFixed(precision.toString().split('.')[1]?.length || 0));
    };

    const handleClick = (e) => {
        setIsHovered(false);
        const newRating = calculateRating(e)
        setActiveStar(newRating)
        console.log(newRating)
        props.setRating(props.movie, newRating);
    };

    const handleMouseMove = (e) => {
        setIsHovered(true);
        const num = calculateRating(e)
        setHoverActiveStar(num);
       // props.setHoverRating(num);
    };

    const handleMouseLeave = (e) => {
        setHoverActiveStar(-1); // Reset to default state
        setIsHovered(false);
    };
    const EmptyIcon = emptyIcon;
    const FilledIcon = filledIcon;

    return (
        <Box
            sx={{
                display: 'inline-flex',
                position: 'relative',
                cursor: 'pointer',
                textAlign: 'left'
            }}
            onClick={handleClick}
            onMouseMove={handleMouseMove}
            onMouseLeave={handleMouseLeave}
            ref={ratingContainerRef}
        >
            {[...new Array(totalStars)].map((arr, index) => {
                const activeState = isHovered ? hoverActiveStar : activeStar;

                const showEmptyIcon = activeState === -1 || activeState < index + 1;

                const isActiveRating = activeState !== 1;
                const isRatingWithPrecision = activeState % 1 !== 0;
                const isRatingEqualToIndex = Math.ceil(activeState) === index + 1;
                const showRatingWithPrecision =
                    isActiveRating && isRatingWithPrecision && isRatingEqualToIndex;

                return (
                    <Box
                        position={'relative'}
                        sx={{
                            cursor: 'pointer'
                        }}
                        key={index}
                    >
                        <Box
                            sx={{
                                width: showRatingWithPrecision ? `${(activeState % 1) * 100}%` : '0%',
                                overflow: 'hidden',
                                position: 'absolute'
                            }}
                        >
                            <FilledIcon fontSize="large" style={{ color: "#FFD700" }} />
                        </Box>
                        {/*Note here */}
                        <Box
                            sx={{
                                color: showEmptyIcon ? 'gray' : 'inherit'
                            }}
                        >
                            {showEmptyIcon ? <EmptyIcon fontSize="large" style={{ color: "#FFD700" }} /> : <FilledIcon fontSize="large" style={{ color: "#FFD700" }} />}
                        </Box>
                    </Box>
                );
            })}
        </Box>
    );
};

export default Stars;