# Copilot Instructions

## Commands

```bash
# Install dependencies (use yarn, not npm)
yarn install

# Start dev server at http://localhost:4200
yarn start

# Build
yarn build

# Run all tests
yarn test

# Run a single test file
yarn test --include="**/auth.component.spec.ts"

# Lint
yarn lint

# Start Keycloak + Postgres (required for auth to work)
docker-compose up
```

## Architecture

This is an **Angular 12** app demonstrating multi-tenant Keycloak authentication. Three Keycloak realms (`riri`, `fifi`, `loulou`) are pre-configured via Docker.

### Authentication Flow

Keycloak is **not initialized at app startup** (no `APP_INITIALIZER`). It is initialized lazily when a user picks a realm:

1. **`/home`** (`HomeComponent`) — user selects a realm and action (login/register) from `AuthComponent`
2. Navigation to `/gateway?action=login&realm=<name>&clientid=<id>` — routed to `AppComponent`
3. **`AppComponent`** reads query params manually via regex (`getParameterFromUrl`), then calls `CustomKeycloakService.initializeKeycloak()` for the selected realm, then calls `keycloak.login()`
4. Keycloak redirects back to `/gateway?action=return&realm=<name>&clientid=<id>`
5. `AppComponent` re-initializes Keycloak, sets `CustomKeycloakService.currentRealm`, calls `TotoService` to hit the backend, then navigates to `home`

### Key Services

- **`CustomKeycloakService`** (`src/app/services/custom-keycloak.service.ts`) — owns a manually-created `KeycloakService` instance (not via Angular DI). Exposes `initializeKeycloak(realm)` and `isLoggedInWithDelay()` (500 ms delay workaround for dev server refresh bug).
- **`AuthInterceptor`** (`src/app/auth.interceptor.ts`) — attaches `Bearer <token>` to all HTTP requests. Replaces the commented-out `KeycloakBearerInterceptor`.
- **`TotoService`** (`src/app/services/toto.service.ts`) — calls the OpenEdge backend at `http://localhost:8092/oeabl/web/webhandler`.

### Realm Configuration

Realms are hardcoded in `AuthComponent.realmList` (`src/app/custom-components/auth/auth.component.ts`). Each realm maps a display name, a Keycloak realm name, and an Angular client ID:

```ts
{ clientId: "angular-client-riri",   name: "riri",   displayName: "Riri's realm" }
{ clientId: "angular-client-fifi",   name: "fifi",   displayName: "Fifi's realm" }
{ clientId: "angular-client-loulou", name: "loulou", displayName: "Loulou's realm" }
```

Keycloak server runs at `http://localhost:8080/auth` (admin: `admin`/`admin`).

## Key Conventions

- **`Realm` interface is defined in `auth.component.ts`** and imported from there by other files — keep it there as the source of truth.
- **URL params are read via regex**, not Angular's `ActivatedRoute`, in `AppComponent`. This is intentional for the gateway pattern.
- **UI components** use `ng-zorro-antd` (Ant Design for Angular) — import individual NZ modules (`NzSpinModule`, `NzButtonModule`, etc.), not the full `NgZorroAntdModule`.
- The `KeycloakBearerInterceptor` from `keycloak-angular` is disabled; use `AuthInterceptor` instead.
- The `/gateway` route is handled by `AppComponent` itself; all other routes fall under `PagesModule`.
