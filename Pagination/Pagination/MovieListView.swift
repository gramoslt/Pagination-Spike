//
//  ContentView.swift
//  Pagination
//
//  Created by Gerardo Leal on 07/08/23.
//

import SwiftUI

struct MovieListView: View {
    @StateObject var movieVM = MovieListViewModel()
    
    var body: some View {
        NavigationStack {
                List {
                    ForEach (movieVM.movies) { movie in
                        Text(movie.title)
                    }
                    switch movieVM.state {
                    case .good :
                        Color.clear
                            .onAppear {
                                movieVM.loadMore()
                            }
                    case .isLoading :
                        ProgressView()
                    case .loadedAll:
                        Text("No more results")
                            .foregroundColor(.red)
                    case .error(let message):
                        Text(message)
                    }
                }
            .navigationTitle("Movies")
        }
        .searchable(text: $movieVM.searchTerm)
    }
}

struct MovieListView_Previews: PreviewProvider {
    static var previews: some View {
        MovieListView()
    }
}
