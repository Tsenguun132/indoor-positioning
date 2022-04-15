//
//  API.swift
//  TestMapApp
//
//  Created by Batbold Bilguun on 14/11/20.
//

import Foundation

class APIService {
    
    let decoder: JSONDecoder
    
    static let shared = APIService()
    
    init() {
        decoder = JSONDecoder()
    }
    
    func postRequest<T: Decodable>(request: URLRequest, completion: @escaping (_ result: T?) -> Void) {
        URLSession.shared.dataTask(with: request) {data, response, error in
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(T.self, from: data)
                    completion(result)
                }
                
                catch let error {
                    print(error)
                    completion(nil)
                }
            }
            else {
                completion(nil)
            }
        }.resume()
    }
    
    func getRequest<T: Decodable>(url: URL, completion: @escaping(_ result: T?) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                let result = try self.decoder.decode(T.self, from: data)
                completion(result)
            }
            
            catch let error {
                print(error)
                completion(nil)
            }
        }.resume()
    }
    
    func fetchBuildingList(completion: @escaping(_ result: BuildingListResponse?) -> Void) {
        guard let url = URL(string: "http://137.132.165.14:8100/buildinglist") else {
            completion(nil)
            return
        }
        
        getRequest(url: url, completion: completion)
        
    }
    
    func fetchBuildingInfo(id: Int, completion: @escaping(_ result: BuildingInfo?) -> Void) {
        //Make JSON to send to send to server
        
        guard let url = URL(string: "http://137.132.165.14:8100/getbuildding") else {
            completion(nil)
            return
        }
        var json = [String:Any]()
        json["id"] = id
        var request = URLRequest(url: url)
        let data = try? JSONSerialization.data(withJSONObject: json, options: [])
        
        request.httpMethod = "POST"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        postRequest(request: request, completion: completion)
    }
    
    func fetchUUIDList(region: String, completion: @escaping (_ result: BeaconUUIDResponse) -> Void) {
        if let url = URL(string: "http://137.132.165.14:8100/uuidget") {
            do {
                //Make JSON to send to send to server
                var json = [String:Any]()
                json["region"] = region
                var request = URLRequest(url: url)
                
                let data = try JSONSerialization.data(withJSONObject: json, options: [])
                
                request.httpMethod = "POST"
                request.httpBody = data
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let data = data {
                        do {
                            let result = try JSONDecoder().decode(BeaconUUIDResponse.self, from: data)
                            
                            print(result)
                            
                            completion(result)
                        }
                        catch let error {
                            print(error)
                        }
                    }
                }.resume()
            }catch{
                
            }
        }
    }
    
    func triggerLearning(region: String, completion: @escaping (_ result: Bool) -> Void) {
        
        if let url = URL(string: "http://137.132.165.14:8100/learning") {
            do {
                //Make JSON to send to send to server
                var json = [String:Any]()
                json["region"] = region
                var request = URLRequest(url: url)
                
                let data = try JSONSerialization.data(withJSONObject: json, options: [])
                
                request.httpMethod = "POST"
                request.httpBody = data
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let data = data {
                        do {
                            let result = try JSONDecoder().decode([String: String].self, from: data)
                            
                            if result["errmsg"] == "ok" {
                                completion(true)
                            }
                            else {
                                completion(false)
                            }
                        }
                        catch let error {
                            print(error)
                        }
                    }
                }.resume()
            }catch{
                
            }
        }
    }
    
}
