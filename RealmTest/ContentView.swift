//
//  ContentView.swift
//  RealmTest
//
//  Created by Matt Gannon on 11/18/21.
//

import Combine
import RealmSwift
import SwiftUI

class DogFact: Object, ObjectKeyIdentifiable, Codable {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var fact: String
    
    enum CodingKeys: String, CodingKey {
        case fact
    }
    
}

struct RealmManager {
    
    static let shared = RealmManager()
    private init() {}
    
    func addFacts(_ facts: [DogFact]) {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(facts)
            }
        } catch {
            print("Failed to add facts")
        }
    }
    
    func deleteAllFacts() {
        do {
            let realm = try Realm()
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print("Failed to deleteAll()")
        }
    }
    
}

struct APIManager {
    
    static let shared = APIManager()
    
    func getDogFacts(completion: @escaping (([DogFact]) -> Void)) {
        let url = URL(string: "https://dog-facts-api.herokuapp.com/api/v1/resources/dogs?number=25")!
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error with fetching films: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                      print("Error with the response, unexpected status code: \(String(describing: response))")
                      return
                  }
            
            if let data = data,
               let facts = try? JSONDecoder().decode([DogFact].self, from: data) {
                completion(facts)
            }
        }
        
        task.resume()
    }
    
}

class ContentViewModel: ObservableObject {
    
    @ObservedResults(DogFact.self) private var factsResults
    @Published private(set) var facts:[DogFact] = []
    var factsCancellable: AnyCancellable?
    
    init() {

        factsCancellable = factsResults.collectionPublisher
            .subscribe(on: DispatchQueue.main)
            .sink { errors in
                print("Errors are \(errors)")
            } receiveValue: { results in
                let indexSet = IndexSet(integersIn: 0..<results.endIndex)
                self.facts = results.objects(at: indexSet)
            }
    }
    
    deinit {
        factsCancellable?.cancel()
        factsCancellable = nil
    }
    
}

struct ContentView: View {
    
    @StateObject var viewModel: ContentViewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            Button("Get Dog Facts", action: buttonPressed)
            Button("Delete Facts", action: deletePressed)
            SwiftUI.List {
                ForEach(viewModel.facts) { fact in
                    Text(fact.fact)
                }
            }
            
        }
    }
    
    func buttonPressed() {
        APIManager.shared.getDogFacts() {
            RealmManager.shared.addFacts($0)
        }
    }
    
    func deletePressed() {
        RealmManager.shared.deleteAllFacts()
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
