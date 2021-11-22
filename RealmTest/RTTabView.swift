//
//  RTTabView.swift
//  RealmTest
//
//  Created by Matt Gannon on 11/22/21.
//

import SwiftUI

struct RTTabView: View {
    
    @State private var tabSelection = 1
    
    var body: some View {
        TabView {
            Text("Hello, World!")
                .tabItem {
                    Image(systemName: "1.square.fill")
                    Text("Test Tab")
                }
                .tag(1)

            ContentView()
                .tabItem {
                    Image(systemName: "2.square.fill")
                    Text("Content")
                }
                .tag(2)
        }
    }
}

struct RTTabView_Previews: PreviewProvider {
    static var previews: some View {
        RTTabView()
    }
}
