import create from 'zustand'

export const useStore = create(set => ({
    // Current User Data
    user: {
        name: '',
        username: '',
        email: '',
        isLoggedIn: false,
        role: '',
        token: '',
    },
    setUser: info => set(state => ({ user: info })),
    currentMovie: {},
    setCurrentMovie: movie => set(state => ({ currentMovie: movie })),
    myRex: [],
    setMyRex: list => set(state => ({ myRex: list })),
    ratings: 0,
    incRatings: () => set((state) => ({ ratings: state.ratings + 1 })),
    resetRatings: () => set({ ratings: 0 }),
}));
