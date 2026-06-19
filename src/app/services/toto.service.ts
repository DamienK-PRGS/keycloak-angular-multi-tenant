import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from 'src/environments/environment';

@Injectable({
  providedIn: 'root',
})
export class TotoService {

  private apiUrl = 'http://localhost:8092/oeabl/web/webhandler';  // URL de votre API
  //private apiUrl = 'http://localhost:8092/web/webhandler';  // URL de votre API
  

  constructor(private http: HttpClient) {}

  // Méthode pour effectuer un appel GET
  getTotoData(): Observable<any> {
    return this.http.get<any>(this.apiUrl);
  }

  // Méthode pour effectuer un appel POST (si nécessaire)
  postTotoData(data: any): Observable<any> {
    return this.http.post<any>(this.apiUrl, data, {
      headers: new HttpHeaders().set('Content-Type', 'application/json')
    });
  }
}
