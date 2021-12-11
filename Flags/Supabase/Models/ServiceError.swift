//
//  ServiceError.swift
//  Flags
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation

struct ServiceError: Decodable, Error {
    let message: String
}
