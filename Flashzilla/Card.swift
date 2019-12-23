//
//  Card.swift
//  Flashzilla
//
//  Created by NICK POLYCHRONAKIS on 20/12/19.
//  Copyright © 2019 NICK POLYCHRONAKIS. All rights reserved.
//

import Foundation

struct Card: Codable {
    let prompt: String
    let answer: String
    
    static var example: Card {
        return Card(prompt: "Who played the 13th Doctor in Doctor Who?", answer: "Jodie Whittaker")
    }
}
