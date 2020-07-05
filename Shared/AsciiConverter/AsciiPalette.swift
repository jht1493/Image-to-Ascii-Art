//
//  AsciiPalette.swift
//  ImageToAsciiArt
//
//  Created by Liam Rosenfeld on 11/1/17.
//  Copyright © 2017 liamrosenfeld. All rights reserved.
//

import Foundation
import UIKit

// Provides a list of ASCII symbols sorted from darkest to brightest.
class AsciiPalette {
    private let font: UIFont

    init(font: UIFont) {
        self.font = font
    }

    lazy var symbols: [String] = self.loadSymbols()

    private func loadSymbols() -> [String] {
        return symbolsSortedByIntensityForAsciiCodes(32...126) // from ' ' to '~'
    }

    private func symbolsSortedByIntensityForAsciiCodes(_ codes: CountableClosedRange<Int>) -> [String] {
        let symbols          = codes.map { self.symbolFromAsciiCode($0) }
        let symbolImages     = symbols.map { $0.toImage(withFont: self.font) }
        let whitePixelCounts = symbolImages.map { self.countWhitePixelsInImage($0) }
        let sortedSymbols    = sortByIntensity(symbols, whitePixelCounts)
        return sortedSymbols
    }

    private func symbolFromAsciiCode(_ code: Int) -> String {
        return String(Character(UnicodeScalar(code)!))
    }

    private func countWhitePixelsInImage(_ image: UIImage) -> Int {
        let
            dataProvider = image.cgImage?.dataProvider,
            pixelData    = dataProvider?.data,
            pixelPointer = CFDataGetBytePtr(pixelData),
            byteCount    = CFDataGetLength(pixelData),
            pixelOffsets = stride(from: 0, to: byteCount, by: Pixel.bytesPerPixel)
        return pixelOffsets.reduce(0) { (count, offset) -> Int in
            let
                r = pixelPointer?[offset + 0],
                g = pixelPointer?[offset + 1],
                b = pixelPointer?[offset + 2],
                isWhite = (r == 255) && (g == 255) && (b == 255)
            return isWhite ? count + 1 : count
        }
    }

    private func sortByIntensity(_ symbols: [String], _ whitePixelCounts: [Int]) -> [String] {
        let mappings = Array(zip(whitePixelCounts, symbols))
        let unique   = mappings.removingDuplicates()
        let sorted   = unique.sorted { $0.0 < $1.0 }
        let sortedSymbols = sorted.map { $0.1 }

        return sortedSymbols
    }

}

extension Array where Element == (Int, String) {
    func removingDuplicates() -> [Element] {
        var addedDict = [Int: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0.0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
