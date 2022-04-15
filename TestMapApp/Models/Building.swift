//
//  Building.swift
//  TestMapApp
//
//  Created by Batbold Bilguun on 21/11/20.
//

import Foundation

struct BuildingListResponse: Decodable {
    let buildingList: Array<Building>
    
    private enum CodingKeys: String, CodingKey {
        case buildingList = "buiding_list"
    }

}


struct Building: Decodable {
    let id: Int
    let name: String
}

// MARK: - BuildingInfo
struct BuildingInfo: Codable {
    let id: Int
    let name: String
    let floors: [Floor]
}

// MARK: - Floor
struct Floor: Codable {
    let id: Int
    let name: String
    let markers: [Marker]
    let links: [Link]
    let url: String?
    let corners: [Center]?
    let angle: Int?
    let center: Center?
    let width, height, bearing: Double?
}

// MARK: - Center
struct Center: Codable {
    let lat, lng: Double
}

// MARK: - Link
struct Link: Codable {
    let id, fromID, toID: Int

    enum CodingKeys: String, CodingKey {
        case id
        case fromID = "fromId"
        case toID = "toId"
    }
}

// MARK: - Marker
struct Marker: Codable {
    let position: Center
    let id: Int
    let name: String
}
