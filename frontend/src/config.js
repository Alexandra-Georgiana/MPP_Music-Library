const config = {
    // Heroku backend URL for all API calls
    baseUrl: import.meta.env.VITE_API_URL || 'https://mpp-music-library.herokuapp.com',
    
    // API URL is the same as base URL in Heroku deployment
    apiUrl: import.meta.env.VITE_API_URL || 'https://mpp-music-library.herokuapp.com/api'
};

export default config;