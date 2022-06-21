import Foundation
import CoreLocation
import GEOSwift

private let latMax = 2*atan(exp(Double.pi))-Double.pi/2

let earthRadius: Double = 6378137
let gridSize = 2*Double.pi*earthRadius

enum GeographyError: Error {
  case invalidTileIndex(_ x: Int, _ y: Int, _ z: Int)
}

func webMercatorScale(zoom: Double, latitude: Double, tileSize: Double = 512)->Double {
  //meters per pixel
  let prefix = gridSize / tileSize
  let zoomTerm = pow(2,zoom)
  let trigTerm = abs(cos(latitude * Double.pi/180))
  return prefix * trigTerm / zoomTerm
}

func webMercatorScale(_ point: Point, zoom: Int, scale: Int = 2)->Float {
  return Float(webMercatorScale(zoom: Double(zoom), latitude: Double(point.y), tileSize: Double(256*scale)))
}

extension CLLocationCoordinate2D {
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

struct TileCoord {
  let x: Int
  let y: Int
  let z: Int
  
  var center: CLLocationCoordinate2D {
    let cc = gridSize/2
    let tileSizeMeters = gridSize/pow(2,Double(z))
    let cx = cc-tileSizeMeters*(Double(x)+0.5)
    let cy = cc-tileSizeMeters*(Double(y)+0.5)
    let scalar = Double.pi / 180 * earthRadius
    return CLLocationCoordinate2D(latitude: cy/scalar, longitude: cx/scalar)
  }
  
  func estimatedPixelScale(tileSize: Double = 512)->Double {
    // meters per pixel at the center of the tile
    return webMercatorScale(zoom: Double(self.z), latitude: self.center.latitude, tileSize: tileSize)
  }
}
