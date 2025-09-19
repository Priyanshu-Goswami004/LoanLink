// Supply Chain Tracking System Frontend JavaScript
// Web3 integration and user interface management

// Contract Configuration - Replace with your deployed contract details
const CONTRACT_ADDRESS = "0x..."; // Replace with your deployed contract address
const CONTRACT_ABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "anonymous": false,
        "inputs": [
            {"indexed": true, "internalType": "address", "name": "account", "type": "address"},
            {"indexed": false, "internalType": "string", "name": "role", "type": "string"},
            {"indexed": true, "internalType": "address", "name": "grantedBy", "type": "address"}
        ],
        "name": "AuthorityGranted",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {"indexed": true, "internalType": "uint256", "name": "productId", "type": "uint256"},
            {"indexed": false, "internalType": "string", "name": "name", "type": "string"},
            {"indexed": true, "internalType": "address", "name": "manufacturer", "type": "address"},
            {"indexed": false, "internalType": "uint256", "name": "timestamp", "type": "uint256"}
        ],
        "name": "ProductAdded",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {"indexed": true, "internalType": "uint256", "name": "productId", "type": "uint256"},
            {"indexed": false, "internalType": "uint8", "name": "status", "type": "uint8"},
            {"indexed": false, "internalType": "string", "name": "location", "type": "string"},
            {"indexed": true, "internalType": "address", "name": "updatedBy", "type": "address"},
            {"indexed": false, "internalType": "uint256", "name": "timestamp", "type": "uint256"}
        ],
        "name": "StatusUpdated",
        "type": "event"
    },
    {
        "inputs": [
            {"internalType": "string", "name": "_name", "type": "string"},
            {"internalType": "string", "name": "_description", "type": "string"},
            {"internalType": "string", "name": "_manufacturingLocation", "type": "string"},
            {"internalType": "uint256", "name": "_price", "type": "uint256"}
        ],
        "name": "addProduct",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "_productId", "type": "uint256"},
            {"internalType": "uint8", "name": "_newStatus", "type": "uint8"},
            {"internalType": "string", "name": "_location", "type": "string"},
            {"internalType": "string", "name": "_notes", "type": "string"}
        ],
        "name": "updateStatus",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "_productId", "type": "uint256"}
        ],
        "name": "verifyAuthenticity",
        "outputs": [
            {"internalType": "bool", "name": "isAuthentic", "type": "bool"},
            {"internalType": "string", "name": "productName", "type": "string"},
            {"internalType": "address", "name": "manufacturer", "type": "address"},
            {"internalType": "uint256", "name": "manufacturingDate", "type": "uint256"},
            {"internalType": "uint8", "name": "currentStatus", "type": "uint8"},
            {"internalType": "string", "name": "currentLocation", "type": "string"},
            {"internalType": "address", "name": "currentOwner", "type": "address"},
            {"internalType": "uint256", "name": "price", "type": "uint256"},
            {"internalType": "uint256", "name": "totalUpdates", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "address", "name": "_manufacturer", "type": "address"}
        ],
        "name": "authorizeManufacturer",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "address", "name": "_logistics", "type": "address"}
        ],
        "name": "authorizeLogistics",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "_productId", "type": "uint256"}
        ],
        "name": "markAsCounterfeit",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "_productId", "type": "uint256"}
        ],
        "name": "getProductHistory",
        "outputs": [
            {
                "components": [
                    {"internalType": "uint256", "name": "timestamp", "type": "uint256"},
                    {"internalType": "uint8", "name": "status", "type": "uint8"},
                    {"internalType": "string", "name": "location", "type": "string"},
                    {"internalType": "address", "name": "updatedBy", "type": "address"},
                    {"internalType": "string", "name": "notes", "type": "string"}
                ],
                "internalType": "struct Project.StatusUpdate[]",
                "name": "",
                "type": "tuple[]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "owner",
        "outputs": [{"internalType": "address", "name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "productCount",
        "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    }
];

// Global Variables
let provider;
let signer;
let contract;
let userAddress;
let isOwner = false;

// Status mapping
const STATUS_NAMES = {
    0: "Manufactured",
    1: "In Transit", 
    2: "Delivered",
    3: "Sold"
};

const STATUS_CLASSES = {
    0: "status-manufactured",
    1: "status-intransit",
    2: "status-delivered", 
    3: "status-sold"
};

// DOM Elements
const connectWalletBtn = document.getElementById('connectWallet');
const walletInfo = document.getElementById('walletInfo');
const walletAddress = document.getElementById('walletAddress');
const tabBtns = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');
const addProductForm = document.getElementById('addProductForm');
const updateStatusForm = document.getElementById('updateStatusForm');
const verifyBtn = document.getElementById('verifyBtn');
const loadHistoryBtn = document.getElementById('loadHistoryBtn');
const loadingOverlay = document.getElementById('loadingOverlay');
const notification = document.getElementById('notification');
const closeNotification = document.getElementById('closeNotification');

// Initialize Application
document.addEventListener('DOMContentLoaded', function() {
    // Check MetaMask installation
    if (typeof window.ethereum === 'undefined') {
        showNotification('Please install MetaMask to use this application', 'error');
        return;
    }

    setupEventListeners();
    checkConnection();
});

function setupEventListeners() {
    // Wallet connection
    connectWalletBtn.addEventListener('click', connectWallet);
    
    // Tab navigation
    tabBtns.forEach(btn => {
        btn.addEventListener('click', (e) => switchTab(e.target.dataset.tab));
    });
    
    // Form submissions
    addProductForm.addEventListener('submit', addProduct);
    updateStatusForm.addEventListener('submit', updateStatus);
    verifyBtn.addEventListener('click', verifyProduct);
    loadHistoryBtn.addEventListener('click', loadProductHistory);
    
    // Admin functions
    document.getElementById('authorizeManufacturer').addEventListener('click', authorizeManufacturer);
    document.getElementById('authorizeLogistics').addEventListener('click', authorizeLogistics);
    document.getElementById('markCounterfeit').addEventListener('click', markAsCounterfeit);
    
    // Notification close
    closeNotification.addEventListener('click', hideNotification);
