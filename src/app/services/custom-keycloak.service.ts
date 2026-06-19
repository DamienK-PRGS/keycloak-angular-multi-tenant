import { Injectable } from '@angular/core';
import { KeycloakService } from 'keycloak-angular';
import { KeycloakProfile } from 'keycloak-js';
import { Realm } from "../custom-components/auth/auth.component";
//import { environment } from 'src/environments/environment';

@Injectable({
    providedIn: 'root'
})
export class CustomKeycloakService {

    DELAY_MS = 500

    private _keycloakInstance: KeycloakService
    private _currentRealm: Realm

    constructor() {
        this._keycloakInstance = new KeycloakService()
        this._currentRealm = {
            name: "",
            displayName: "",
            clientId: ""
        }
    }

    get keycloakInstance(): KeycloakService {
        return this._keycloakInstance;
    }

    get currentRealm(): Realm {
        return this._currentRealm;
    }

    set currentRealm(value: Realm) {
        this._currentRealm = value;
    }

    public initializeKeycloak(realm: Realm): Promise<boolean> {
        return this._keycloakInstance.init({
            config: {
                url: 'http://localhost:8080/auth',
                realm: realm.name,
                clientId: realm.clientId,
                
            },
            initOptions: {
                onLoad: 'check-sso',
                silentCheckSsoRedirectUri: window.location.origin + '/assets/silent-check-sso.html',
                //redirectUri: environment.keycloak.redirectUri
            },
            enableBearerInterceptor: true, // attach ACCESS_TOKEN on each request
            bearerPrefix: 'Bearer', // prefix "bearer <TOKEN> on each request
            bearerExcludedUrls: []            
        });
    }

    public isLoggedInWithDelay(): Promise<boolean> {
        return new Promise((resolve, reject) => {
            setTimeout(() => {
                this._keycloakInstance.isLoggedIn().then(resolve, reject);
            }, this.DELAY_MS)
        });
    }
}
