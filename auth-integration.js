// AUTH INTEGRATION - Conecta UI com backend real
class AuthManager {
    constructor() {
        this.baseURL = 'https://aissist.rafante-tec.online';
        this.token = localStorage.getItem('auth_token');
        this.user = null;
        
        if (this.token) {
            this.validateToken();
        }
    }
    
    // Login real
    async login(email, password) {
        try {
            const response = await fetch(`${this.baseURL}/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password })
            });
            
            const data = await response.json();
            
            if (response.ok) {
                this.token = data.token;
                this.user = data.user;
                localStorage.setItem('auth_token', this.token);
                localStorage.setItem('user_data', JSON.stringify(this.user));
                return { success: true, user: this.user };
            } else {
                return { success: false, error: data.error };
            }
        } catch (error) {
            return { success: false, error: 'Erro de conexão' };
        }
    }
    
    // Signup real
    async signup(email, password, tier = 'free') {
        try {
            const response = await fetch(`${this.baseURL}/auth/signup`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ email, password, subscription_tier: tier })
            });
            
            const data = await response.json();
            
            if (response.ok) {
                this.token = data.token;
                this.user = data.user;
                localStorage.setItem('auth_token', this.token);
                localStorage.setItem('user_data', JSON.stringify(this.user));
                return { success: true, user: this.user };
            } else {
                return { success: false, error: data.error };
            }
        } catch (error) {
            return { success: false, error: 'Erro de conexão' };
        }
    }
    
    // Validar token
    async validateToken() {
        if (!this.token) return false;
        
        try {
            const response = await fetch(`${this.baseURL}/auth/me`, {
                headers: {
                    'Authorization': `Bearer ${this.token}`
                }
            });
            
            if (response.ok) {
                const userData = await response.json();
                this.user = userData;
                localStorage.setItem('user_data', JSON.stringify(this.user));
                return true;
            } else {
                this.logout();
                return false;
            }
        } catch (error) {
            this.logout();
            return false;
        }
    }
    
    // Logout
    logout() {
        this.token = null;
        this.user = null;
        localStorage.removeItem('auth_token');
        localStorage.removeItem('user_data');
        window.location.reload();
    }
    
    // Check if user is logged in
    isLoggedIn() {
        return !!(this.token && this.user);
    }
    
    // Get user usage stats
    async getUserUsage() {
        if (!this.token) return null;
        
        try {
            const response = await fetch(`${this.baseURL}/auth/usage`, {
                headers: {
                    'Authorization': `Bearer ${this.token}`
                }
            });
            
            if (response.ok) {
                return await response.json();
            }
            return null;
        } catch (error) {
            console.error('Erro ao buscar usage:', error);
            return null;
        }
    }
    
    // Send AI query with authentication
    async sendAIQuery(query) {
        try {
            const headers = {
                'Content-Type': 'application/json'
            };
            
            if (this.token) {
                headers['Authorization'] = `Bearer ${this.token}`;
            }
            
            const response = await fetch(`${this.baseURL}/ai/chat`, {
                method: 'POST',
                headers,
                body: JSON.stringify({ message: query })
            });
            
            const data = await response.json();
            
            if (response.ok) {
                return { success: true, response: data.response };
            } else {
                return { success: false, error: data.error };
            }
        } catch (error) {
            return { success: false, error: 'Erro de conexão com IA' };
        }
    }
}

// Modal functions
function createLoginModal() {
    const modal = document.createElement('div');
    modal.id = 'loginModal';
    modal.innerHTML = `
        <div class="modal-overlay" onclick="closeModal()">
            <div class="modal-content" onclick="event.stopPropagation()">
                <div class="modal-header">
                    <h2>🔑 Entrar</h2>
                    <button class="modal-close" onclick="closeModal()">×</button>
                </div>
                <form id="loginForm">
                    <div class="form-group">
                        <label>Email:</label>
                        <input type="email" id="loginEmail" required>
                    </div>
                    <div class="form-group">
                        <label>Senha:</label>
                        <input type="password" id="loginPassword" required>
                    </div>
                    <button type="submit" class="modal-btn">Entrar</button>
                </form>
                <p class="modal-footer">
                    Não tem conta? <a href="#" onclick="showSignupModal()">Cadastre-se</a>
                </p>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    return modal;
}

function createSignupModal() {
    const modal = document.createElement('div');
    modal.id = 'signupModal';
    modal.innerHTML = `
        <div class="modal-overlay" onclick="closeModal()">
            <div class="modal-content" onclick="event.stopPropagation()">
                <div class="modal-header">
                    <h2>🚀 Cadastrar</h2>
                    <button class="modal-close" onclick="closeModal()">×</button>
                </div>
                <form id="signupForm">
                    <div class="form-group">
                        <label>Email:</label>
                        <input type="email" id="signupEmail" required>
                    </div>
                    <div class="form-group">
                        <label>Senha:</label>
                        <input type="password" id="signupPassword" required minlength="6">
                    </div>
                    <div class="form-group">
                        <label>Plano:</label>
                        <select id="signupTier">
                            <option value="free">Free - 5 consultas/dia</option>
                            <option value="premium">Premium - R$ 19/mês</option>
                            <option value="pro">Pro - R$ 39/mês</option>
                        </select>
                    </div>
                    <button type="submit" class="modal-btn">Cadastrar</button>
                </form>
                <p class="modal-footer">
                    Já tem conta? <a href="#" onclick="showLoginModal()">Entre aqui</a>
                </p>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    return modal;
}

// Modal styles
const modalStyles = `
<style>
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.8);
    backdrop-filter: blur(10px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 10000;
}

.modal-content {
    background: #111;
    border-radius: 15px;
    padding: 2rem;
    max-width: 400px;
    width: 90%;
    border: 1px solid rgba(255, 255, 255, 0.1);
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 2rem;
}

.modal-header h2 {
    color: #e50914;
    margin: 0;
}

.modal-close {
    background: none;
    border: none;
    color: #fff;
    font-size: 2rem;
    cursor: pointer;
}

.form-group {
    margin-bottom: 1.5rem;
}

.form-group label {
    display: block;
    margin-bottom: 0.5rem;
    color: #fff;
}

.form-group input, .form-group select {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.1);
    color: #fff;
    font-size: 1rem;
}

.modal-btn {
    width: 100%;
    padding: 1rem;
    background: #e50914;
    border: none;
    border-radius: 6px;
    color: #fff;
    font-size: 1.1rem;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.3s;
}

.modal-btn:hover {
    background: #f40612;
}

.modal-footer {
    text-align: center;
    margin-top: 1rem;
    color: #ccc;
}

.modal-footer a {
    color: #e50914;
    text-decoration: none;
}
</style>`;

// Add modal styles to head
document.head.insertAdjacentHTML('beforeend', modalStyles);

// Global auth instance
const auth = new AuthManager();

// Global functions
function showLoginModal() {
    closeModal();
    const modal = createLoginModal();
    
    document.getElementById('loginForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('loginEmail').value;
        const password = document.getElementById('loginPassword').value;
        
        const result = await auth.login(email, password);
        
        if (result.success) {
            closeModal();
            updateUIForLoggedInUser();
            alert(`✅ Bem-vindo, ${result.user.email}!`);
        } else {
            alert(`❌ Erro: ${result.error}`);
        }
    });
}

function showSignupModal() {
    closeModal();
    const modal = createSignupModal();
    
    document.getElementById('signupForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('signupEmail').value;
        const password = document.getElementById('signupPassword').value;
        const tier = document.getElementById('signupTier').value;
        
        const result = await auth.signup(email, password, tier);
        
        if (result.success) {
            closeModal();
            updateUIForLoggedInUser();
            alert(`✅ Conta criada com sucesso! Bem-vindo, ${result.user.email}!`);
        } else {
            alert(`❌ Erro: ${result.error}`);
        }
    });
}

function closeModal() {
    const modals = document.querySelectorAll('#loginModal, #signupModal');
    modals.forEach(modal => modal.remove());
}

function updateUIForLoggedInUser() {
    if (auth.isLoggedIn()) {
        // Update nav buttons
        const authButtons = document.querySelector('.auth-buttons');
        if (authButtons) {
            authButtons.innerHTML = `
                <span style="margin-right: 1rem;">👋 ${auth.user.email}</span>
                <button class="btn-login" onclick="showUserProfile()">Perfil</button>
                <button class="btn-signup" onclick="auth.logout()">Sair</button>
            `;
        }
    }
}

function showUserProfile() {
    alert(`👤 Perfil do Usuário\n\n📧 Email: ${auth.user.email}\n💎 Plano: ${auth.user.subscription_tier.toUpperCase()}\n📊 Uso diário: ${auth.user.daily_usage_count}/day\n📅 Membro desde: ${new Date(auth.user.created_at).toLocaleDateString()}`);
}

// Enhanced AI query function
async function sendEnhancedAIQuery(query) {
    const result = await auth.sendAIQuery(query);
    
    if (result.success) {
        return result.response;
    } else {
        if (result.error.includes('rate limit')) {
            return `⚠️ Limite de consultas atingido!\n\nVocê atingiu o limite do seu plano ${auth.user?.subscription_tier || 'free'}.\n\n💎 Faça upgrade para mais consultas:\n• Premium: 100/dia por R$ 19/mês\n• Pro: 500/dia por R$ 39/mês`;
        } else {
            return `❌ Erro: ${result.error}`;
        }
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    if (auth.isLoggedIn()) {
        updateUIForLoggedInUser();
    }
    console.log('🔐 Auth integration loaded');
});