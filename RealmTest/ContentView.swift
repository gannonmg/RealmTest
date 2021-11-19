//
//  ContentView.swift
//  RealmTest
//
//  Created by Matt Gannon on 11/18/21.
//

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
    
    let queue = DispatchQueue(label: "realm-queue")
    let realm = try! Realm()
    
    func addFacts(_ facts: [DogFact]) {
        queue.async {
            try! realm.write {
                realm.add(facts)
            }
        }
    }
    
    func deleteFact(_ fact: DogFact) {
        queue.async {
            try! realm.write {
                realm.delete(fact)
            }
        }
    }
    
    func deleteMultiple(facts: Results<DogFact>) {
        queue.async {
            try! realm.write {
                realm.delete(facts)
            }
        }
    }
    
    func deleteAllFacts() {
        queue.async {
            let thawedRealm = realm.thaw()
            try! thawedRealm.write {
                thawedRealm.deleteAll()
            }
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

struct ContentView: View {
    
//    @State var facts: [DogFact] = []
    @ObservedResults(DogFact.self) var facts
    
    var body: some View {
        VStack {
            Button("Get Dog Facts", action: buttonPressed)
            Button("Delete Facts", action: deletePressed)
            SwiftUI.List {
                ForEach(facts) { fact in
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
//        RealmManager.shared.deleteMultiple(facts: facts)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
