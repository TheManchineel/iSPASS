//
//  SpassImplementation.swift
//  iSPASS
//

import Foundation

protocol SpassImplementation {
    var outputText: String { get }
    func run(args: [String], url: URL)
}
