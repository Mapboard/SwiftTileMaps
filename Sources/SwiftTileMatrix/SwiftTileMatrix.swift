import Foundation
import CoreLocation
import GEOSwift

private let latMax = 2*atan(exp(Double.pi))-Double.pi/2

public let earthRadius: Double = 6378137
let gridSize = 2*Double.pi*earthRadius

enum GeographyError: Error {
  case invalidTileIndex(_ x: Int, _ y: Int, _ z: Int)
}

public func webMercatorScale(zoom: Double, latitude: Double, tileSize: Double = 512)->Double {
  //meters per pixel
  let nTiles = pow(2,zoom)
  let pixelsPerTile = tileSize
  let metersPerTile = abs(cos(latitude * Double.pi/180)) * gridSize / nTiles
  return metersPerTile / pixelsPerTile
}

public func webMercatorScale(_ point: Point, zoom: Int, scale: Int = 2)->Float {
  return Float(webMercatorScale(zoom: Double(zoom), latitude: Double(point.y), tileSize: Double(256*scale)))
}

public func webMercatorToEpsg4236(_ pt: Point)->Point {
  let d = -pt.y / earthRadius;
  let phi = Double.pi / 2 - 2 * atan(exp(d));
  let lambda = pt.x / earthRadius;
  let lat = phi / Double.pi * 180;
  let lon = lambda / Double.pi * 180;
  return Point(x: lon, y: lat)
}

public extension CLLocationCoordinate2D {
  init(webMercatorPoint pt: Point) {
    let scalar = Double.pi / 180 * earthRadius
    self.init(latitude: pt.y/scalar, longitude: pt.x/scalar)
  }
}

func tileEnvelope(x: Int, y: Int, z: Int) throws -> Envelope {
  return try tileEnvelope(x: Double(x), y: Double(y), z: Double(z))
}

func tileEnvelope(x: Double, y: Double, z: Double) throws -> Envelope {
  let nTiles = pow(2, z)
  if x < 0 || x >= nTiles || y < 0 || y >= nTiles {
    throw GeographyError.invalidTileIndex(Int(x),Int(y),Int(z))
  }
  return _tileEnvelope(x: x, y: y, z: z)
}

private func _tileEnvelope(x: Double, y: Double, z: Double) -> Envelope {
  let nTiles = pow(2, z)
  
  let cx = gridSize/2
  let cy = gridSize/2

  let tileSize = gridSize/nTiles
  
  let env = Envelope(
    minX: tileSize*x-cx,
    maxX: tileSize*(x+1)-cx,
    minY: cy-tileSize*(y+1),
    maxY: cy-tileSize*y
  )
  
  return env
}

public struct TileCoord {
  public let x: Int
  public let y: Int
  public let z: Int
  
  public init(_ x: Int, _ y: Int, _ z: Int) {
    self.x = x
    self.y = y
    self.z = z
  }
  
  public var center: CLLocationCoordinate2D {
    let cc = gridSize/2
    let tileSizeMeters = gridSize/pow(2,Double(z))
    let cx = cc-tileSizeMeters*(Double(x)+0.5)
    let cy = cc-tileSizeMeters*(Double(y)+0.5)
    let scalar = Double.pi / 180 * earthRadius
    return CLLocationCoordinate2D(latitude: cy/scalar, longitude: cx/scalar)
  }
  
  public func estimatedPixelScale(tileSize: Double = 512)->Double {
    // meters per pixel at the center of the tile
    return webMercatorScale(zoom: Double(self.z), latitude: self.center.latitude, tileSize: tileSize)
  }
  
  public var envelope: Envelope {
    return _tileEnvelope(x: Double(x), y: Double(y), z: Double(z))
  }
}

extension TileCoord: CustomStringConvertible {
  public var description: String {
    "Tile x:\(self.x),y:\(self.y),z:\(self.z)"
  }
}
