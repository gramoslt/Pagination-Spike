//
//  MovieListViewModel.swift
//  Pagination
//
//  Created by Gerardo Leal on 07/08/23.
//

import Foundation
import Combine

struct Movie: Codable, Identifiable {
    let id: Int
    let title: String
}

struct MovieResults: Codable {
    let page: Int
    let results: [Movie]
    let total_pages: Int
}

final class MovieListViewModel: ObservableObject {
    
    enum BrowsingState: Comparable {
        case good
        case isLoading
        case loadedAll
        case error(String)
    }
    
    @Published var movies: [Movie] = []
    @Published var searchTerm: String = ""
    @Published var state: BrowsingState = .good {
        didSet {
            print("state changed to: \(state)")
        }
    }
    var page = 1
    var total_pages = 1
    
    var subscriptions = Set<AnyCancellable>()
    
    init() {
        $searchTerm
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] term in
                self?.movies = []  // empty the movies array when you change your searchTerm
                self?.total_pages = 1  // reestablish total pages to 1
                self?.page = 1  // return to page 1 of results
                self?.state = .good  // reset state to good
                self?.fetchMovies(for: term) // start a fetchmovies when the searchterm changes
            }.store(in: &subscriptions)
    }
    
    func loadMore() {
        if self.page <= self.total_pages {
            fetchMovies(for: searchTerm)
        }
    }
    
    func fetchMovies(for searchTerm: String) {
        let headers = [
          "accept": "application/json",
          "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI3MzQ2YzJjNzIwMWRjMWI5YWUwZDE4N2IyZTNiYWI0NiIsInN1YiI6IjY0ODlmYjhkZTM3NWMwMDBlMjUxY2VjOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.GZukafCVw0_nLQBE6kBy7FEmTICzLGacuVOYzqtZYzQ"
        ]
        
        // Only load when search term isnt empty
        guard !searchTerm.isEmpty else {
            return
        }
        
        // Only load when you are not already loading
        guard state == .good else {
            return
        }
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.themoviedb.org/3/search/movie?query=\(searchTerm)&page=\(page)")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        
        request.allHTTPHeaderFields = headers
        request.httpMethod = "GET"
        
        state = .isLoading
        
        URLSession.shared.dataTask(with: request as URLRequest) { [ weak self ] data, response, error in
            if let error = error {
                print("urlsession error \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.state = .error("Could not load: \(error.localizedDescription)")
                }
            } else if let data = data {
                do {
                    let result = try JSONDecoder().decode(MovieResults.self, from: data)
                    DispatchQueue.main.async {
                        for movie in result.results {
                            self?.movies.append(movie)
                        }
                        self?.total_pages = result.total_pages
                        
                        self?.state = (result.total_pages == self?.page) ? .loadedAll : .good
                        
                        self?.page += 1
                    }
                } catch {
                    print("decoding error \(error)")
                    DispatchQueue.main.async {
                        self?.state = .error("Could not get data: \(error.localizedDescription)")
                    }
                }
            }
        }.resume()
    }
}
