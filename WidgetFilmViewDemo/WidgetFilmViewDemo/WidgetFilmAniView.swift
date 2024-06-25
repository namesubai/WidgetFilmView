//
//  WidgetFilmAniView.swift
//  WidgetFilmViewDemo
//
//  Created by yangsq on 2024/6/25.
//

import SwiftUI
import ClockHandRotationKit

struct ProgressShape: Shape {
    let progress: Double
    var startDegress = -75.0
    var endDegress = -15.0
    var clockwise = false
    private var totalProgressDegress: CGFloat {
        endDegress - startDegress
    }
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(startDegress),
            endAngle: .degrees(startDegress + totalProgressDegress * progress),
            clockwise: clockwise
        )
        return path
    }
}

struct WidgetFilmAniImageView: View {
    var images: [UIImage]
    var duration: TimeInterval
    var body: some View {
        FilmAnimationView(count: images.count, duration: duration) { index in
            Image(uiImage: images[index])
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}



struct FilmAnimationView<Content: View>: View {
    var count: Int
    var duration: TimeInterval
    @ViewBuilder
    var content: (Int) -> Content
    
    var body: some View {
        if count > 0 {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let angle = 360.0 / Double(count)
                let maxWidth = max(proxy.size.width, proxy.size.height)
                let scale = maxWidth / 40 * 2
                let fScale = scale * 5
                ZStack {
                    
                    ForEach(1...count, id: \.self) {
                        index in
                        
                        content(count - index)
                            .frame(width: width, height: height)
                            .mask(
                                ProgressShape(progress: 1, startDegress: angle * Double(index - 1), endDegress: angle * Double(index), clockwise: false)
                                    .stroke(.yellow, style: .init(lineWidth: 40, lineCap: .square, lineJoin: .miter))
                                    .frame(width: maxWidth * fScale, height: maxWidth * fScale)
                                    .scaleEffect(scale)
                                    .clockHandRotationEffect(period: .custom(duration))
                                    .offset(y: maxWidth * scale * fScale / 2)
                                
                            )
                    }
                }
                .frame(width: width, height: height)
                .clipped()
                
            }
        }
        
    }
}

struct WidgetFilmAniView: View {
    private var gifPath: URL?
    init(gifPath: URL? = nil) {
        self.gifPath = gifPath
    }
    
    var body: some View {
        
        if let gifPath = gifPath {
            if let gifData = try? Data(contentsOf: gifPath), let image = UIImage.animatedImage(withGIFData: gifData, cacheKey: gifPath.absoluteString), let images = image.images, images.count > 0 {
                WidgetFilmAniImageView(images: images, duration: image.duration)
                
            }
        }
    }
}


private var gifCache: NSCache<NSString, UIImage> = {
    let c = NSCache<NSString, UIImage>()
    c.totalCostLimit = 15 * 1024 * 1024
    return c
}()

extension UIImage {
    
    var image: Image {
        Image(uiImage: self)
    }
    
    static func animatedImage(withGIFData data: Data, cacheKey: String? = nil) -> UIImage? {
        if let cacheKey = cacheKey {
            if let cacheImage = gifCache.object(forKey: cacheKey as NSString) {
                return cacheImage
            }
            
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        
        let frameCount = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var gifDuration = 0.0
        
        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil),
               let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
               let frameDuration = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber) {
                gifDuration += frameDuration.doubleValue
            }
            
            let frameImage = UIImage(cgImage: cgImage)
            frames.append(frameImage)
        }
        
        let animatedImage = UIImage.animatedImage(with: frames, duration: gifDuration)
        if let animatedImage = animatedImage, let cacheKey = cacheKey {
            gifCache.setObject(animatedImage, forKey: cacheKey as NSString)
        }
        return animatedImage
    }
}


#Preview(body: {
    Color.red.frame(width: 40, height: 40)
        .mask {
            ProgressShape(progress: 1, startDegress: 0, endDegress: 15, clockwise: false)
                .stroke(.yellow, style: .init(lineWidth: 40, lineCap: .square, lineJoin: .miter))
                .frame(width: 200, height: 200)
                .clockHandRotationEffect(period: .custom(1))
                .offset(x: 0, y: 100)
        }
    
})
