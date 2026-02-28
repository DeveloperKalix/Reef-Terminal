# Login page — default route "/"
# Uses Jac built-in auth (jacLogin / jacSignup).
# On success, redirects to /dashboard.

cl import from "@jac/runtime" { jacLogin, jacSignup, jacIsLoggedIn, useNavigate }

cl {
    import "@styles/login.css";

    def:pub page() -> JsxElement {
        has username:    str  = "";
        has password:    str  = "";
        has loading:     bool = False;
        has error:       str  = "";
        has is_signup:   bool = False;

        navigate = useNavigate();

        can with entry {
            if jacIsLoggedIn() {
                navigate("/dashboard");
            }
        }

        async def handle_submit(e: any) -> None {
            e.preventDefault();
            if loading { return; }

            if not username.trim() or not password {
                error = "Please fill in all fields";
                return;
            }

            loading = True;
            error   = "";

            if is_signup {
                result = await jacSignup(username, password);
                if result["success"] {
                    navigate("/dashboard");
                } else {
                    error   = result["error"] or "Signup failed. Try again.";
                    loading = False;
                }
            } else {
                success = await jacLogin(username, password);
                if success {
                    navigate("/dashboard");
                } else {
                    error   = "Invalid credentials. Please try again.";
                    loading = False;
                }
            }
        }

        return <div className="login-page">
            <div className="login-card">

                <div className="login-brand">
                    <img
                        src="/static/assets/reef_media_svg.png"
                        alt="Reef Media"
                        className="login-logo"
                    />
                    <span className="login-brand-name">Reef Media</span>
                    <span className="login-brand-sub">Trust & Safety Panel</span>
                </div>

                <div className="login-heading">
                    <h1>{is_signup and "Create Account" or "Welcome back"}</h1>
                    <p>{is_signup and "Sign up for access to the dashboard." or "Sign in to access the Trust & Safety Dashboard."}</p>
                </div>

                {error and <div className="login-error">{error}</div>}

                <form onSubmit={handle_submit} style={{"width": "100%", "display": "flex", "flexDirection": "column", "gap": "0.75rem"}}>
                    <input
                        type="text"
                        value={username}
                        onChange={lambda e: any -> None { username = e.target.value; }}
                        placeholder="Username"
                        className="login-input"
                        autoComplete="username"
                    />
                    <input
                        type="password"
                        value={password}
                        onChange={lambda e: any -> None { password = e.target.value; }}
                        placeholder="Password"
                        className="login-input"
                        autoComplete={is_signup and "new-password" or "current-password"}
                    />
                    <button
                        type="submit"
                        className="btn-primary"
                        disabled={loading}
                    >
                        {loading and (
                            <div className="spinner" />
                        )}
                        {loading and (is_signup and "Creating account…" or "Signing in…") or (is_signup and "Sign Up" or "Sign In")}
                    </button>
                </form>

                <div className="login-divider">
                    <span>{is_signup and "Already have an account?" or "Need an account?"}</span>
                </div>

                <button
                    type="button"
                    className="btn-google"
                    onClick={lambda -> None { is_signup = not is_signup; error = ""; }}
                >
                    {is_signup and "Sign in instead" or "Create an account"}
                </button>

                <p className="login-footer">
                    By signing in you agree to Reef Media's{" "}
                    <a href="/terms" target="_blank" rel="noreferrer">Terms of Service</a>
                    {" "}and{" "}
                    <a href="/privacy" target="_blank" rel="noreferrer">Privacy Policy</a>.
                    <br />
                    Access is restricted to authorised personnel only.
                </p>

            </div>
        </div>;
    }
}
