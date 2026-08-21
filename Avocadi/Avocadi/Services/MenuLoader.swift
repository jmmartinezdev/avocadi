//
//  MenuLoader.swift
//  Avocadi
//
//  Created by Chema Martinez on 21/8/26.
//

import Foundation

/// Reads and decodes the bundled menu JSON into a `Menu`.
///
/// This is purely an I/O boundary — it knows how to find and decode the
/// JSON resource, nothing about how that data gets turned into view-ready
/// models (see `DayViewModel`/`WeekViewModel` for that).
enum MenuLoader {
    enum LoaderError: Error {
        case resourceNotFound(String)
    }

    static func load(resource: String = "Menu", bundle: Bundle = .main) throws -> Menu {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw LoaderError.resourceNotFound(resource)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Menu.self, from: data)
    }
}
