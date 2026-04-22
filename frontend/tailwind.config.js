/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        brandTeal: '#0e8c9b', // El color exacto de la barra lateral de tu amigo
      }
    },
  },
  plugins: [],
}