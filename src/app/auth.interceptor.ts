import { Injectable } from '@angular/core';
import {
  HttpRequest,
  HttpHandler,
  HttpEvent,
  HttpInterceptor,
} from '@angular/common/http';
import { Observable, from } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { CustomKeycloakService } from './services/custom-keycloak.service';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private customKeycloakService: CustomKeycloakService) {}

  intercept(
    request: HttpRequest<unknown>,
    next: HttpHandler
  ): Observable<HttpEvent<unknown>> {
    return from(this.customKeycloakService.keycloakInstance.getToken()).pipe(
      switchMap((token) => {
        //console.log("Token reçu:", token);
        
        const clonedRequest = request.clone({
          setHeaders: { Authorization: `Bearer ${token}` },
        });

        console.log("Requête modifiée:", clonedRequest.headers.get('Authorization'));

        return next.handle(clonedRequest);
      })
    );
  }
}
