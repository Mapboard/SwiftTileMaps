//
//  File.swift
//  
//
//  Created by Daven Quinn on 6/22/22.
//

import Foundation
import GEOSwift

private let tileSize = 256
private let initialResolution = 2.0 * Double.pi * 6_378_137.0 / Double(tileSize) // 156543.03392804062 for tileSize 256 pixels
private let originShift = 2.0 * Double.pi * 6_378_137.0 / 2.0

/// Tile bounds in EPSG:3857
public func epsg3857TileBounds(
    x: Int,
    y: Int,
    z: Int)
    -> Envelope
{
    // Flip y, but why?
    let y = (1 << z) - 1 - y

  let southWest = projectPixelToEpsg3857(px: x * tileSize, py: y * tileSize, z: z)
  let northEast = projectPixelToEpsg3857(px: (x + 1) * tileSize, py: (y + 1) * tileSize, z: z)
  
  return try! southWest.union(with: northEast).envelope()

}

// MARK: -

private func projectPixelToEpsg3857(
    px: Int,
    py: Int,
    z: Int)
    -> Point
{
    let resolution: Double = initialResolution / pow(2.0, Double(z))

    let x = Double(px) * resolution - originShift
    let y = Double(py) * resolution - originShift
  
  return Point(x: x, y: y)

}

