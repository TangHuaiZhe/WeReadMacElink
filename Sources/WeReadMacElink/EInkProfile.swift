import Foundation

struct EInkProfile: Equatable {
    static let defaultTextScale = 1.4
    static let defaultContrast = 1.3
    static let defaultContentWidth = 0.82

    var textScale: Double
    var contrast: Double
    var contentWidth: Double
    var grayscale: Bool
    var reduceMotion: Bool

    init(
        textScale: Double = defaultTextScale,
        contrast: Double = defaultContrast,
        contentWidth: Double = defaultContentWidth,
        grayscale: Bool = true,
        reduceMotion: Bool = true
    ) {
        self.textScale = Self.clamp(textScale, to: 1...2)
        self.contrast = Self.clamp(contrast, to: 1...2)
        self.contentWidth = Self.clamp(contentWidth, to: 0.6...0.95)
        self.grayscale = grayscale
        self.reduceMotion = reduceMotion
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
