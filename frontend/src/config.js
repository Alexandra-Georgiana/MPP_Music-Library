const config = {
    apiUrl: process.env.NODE_ENV === 'production' 
        ? 'https://mppmusic-library-production.up.railway.app/api'
        : 'http://localhost:3000/api',
    baseUrl: process.env.NODE_ENV === 'production'
        ? 'https://mppmusic-library-production.up.railway.app'
        : 'http://localhost:3000'
};

export default config;
