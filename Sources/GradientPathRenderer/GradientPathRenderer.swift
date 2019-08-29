

import MapKit

/// Draws a given polyline with a gradient fill
class GradientPathRenderer: MKOverlayPathRenderer {
    
    var polyline: MKPolyline
    
    /// The colors used to draw the gradient
    var colors: [UIColor]
    
    /// If a border should be rendered to make the line more visible
    var showsBorder = false
    
    /// The color of tne border, if showsBorder is true
    var borderColor: UIColor?


    init(_ polyline: MKPolyline,
         _ colors: [UIColor]) {
        
        self.polyline = polyline
        self.colors = colors
        super.init(overlay: polyline)
    }
    
    init(_ polyline: MKPolyline,
         _ colors: [UIColor],
         showsBorder: Bool,
         borderColor: UIColor) {
        
        self.polyline = polyline
        self.colors = colors
        self.showsBorder = showsBorder
        self.borderColor = borderColor
        super.init(overlay: polyline)
    }
    
    //MARK: Override methods
    
    override func draw(_ mapRect: MKMapRect,
                       zoomScale: MKZoomScale,
                       in context: CGContext) {
        
        // Set path width relative to map zoom scale
        let baseWidth: CGFloat = lineWidth / zoomScale
        
        if self.showsBorder {
            context.setLineWidth(baseWidth * 2)
            context.setLineJoin(CGLineJoin.round)
            context.setLineCap(CGLineCap.round)
            context.addPath(path)
            context.setStrokeColor(borderColor?.cgColor ?? UIColor.white.cgColor)
            context.strokePath()
        }
        
        //  Create a gradient from the colors provided with evenly spaced stops
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let stopValues = calculateNumStops()
        let locations = stopValues
        let gradient = CGGradient(colorsSpace: colorspace, colors: cgColors as CFArray, locations: locations)
        
        // Define path properties and add it to context
        context.setLineWidth(baseWidth)
        context.setLineJoin(CGLineJoin.round)
        context.setLineCap(CGLineCap.round)
        
        context.addPath(self.path)
        
        //Replace path with stroked version so we can clip
        context.saveGState()
        
        context.replacePathWithStrokedPath()
        context.clip()
        
        //Create bounding box around path and get top and bottom points
        let boundingBox = path.boundingBoxOfPath
        let gradientStart = boundingBox.origin
        let gradientEnd = CGPoint(x:boundingBox.maxX, y:boundingBox.maxY)
        
        //Draw the gradient in the clipped context of the path
        if let gradient = gradient {
            context.drawLinearGradient(gradient, start: gradientStart, end: gradientEnd, options: .drawsBeforeStartLocation)
        }
        
        context.restoreGState()
        
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }
    
    override func createPath() {
        let path = CGMutablePath()
        var pathIsEmpty = true
        
        for i in 0...polyline.pointCount-1 {
            
            let p = point(for: polyline.points()[i])
            if pathIsEmpty {
                path.move(to: p)
                pathIsEmpty = false
            } else {
                path.addLine(to: p)
            }
        }
        self.path = path
    }
    
    //MARK: Helpers
    
    private func calculateNumStops() -> [CGFloat] {
        
        let stopDifference = 1 / Double(cgColors.count)
        
        return stride(from: 0, to: 1+stopDifference, by: stopDifference).map {CGFloat($0)}
    }
    
    private var cgColors: [CGColor] {
        return colors.map{$0.cgColor}
    }
}
