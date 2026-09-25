import Combine
import Foundation

@MainActor
final class ReaderSettings: ObservableObject {
    private enum Key {
        static let textScale = "reader.textScale"
        static let legacyFontSize = "reader.fontSize"
        static let contrast = "reader.contrast"
        static let contentWidth = "reader.contentWidth"
        static let grayscale = "reader.grayscale"
        static let reduceMotion = "reader.reduceMotion"
    }

    private let defaults: UserDefaults

    @Published var textScale: Double { didSet { defaults.set(textScale, forKey: Key.textScale) } }
    @Published var contrast: Double { didSet { defaults.set(contrast, forKey: Key.contrast) } }
    @Published var contentWidth: Double { didSet { defaults.set(contentWidth, forKey: Key.contentWidth) } }
    @Published var grayscale: Bool { didSet { defaults.set(grayscale, forKey: Key.grayscale) } }
    @Published var reduceMotion: Bool { didSet { defaults.set(reduceMotion, forKey: Key.reduceMotion) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedScale = defaults.object(forKey: Key.textScale) as? Double
        let legacyFontSize = defaults.object(forKey: Key.legacyFontSize) as? Double
        let profile = EInkProfile(
            textScale: savedScale ?? legacyFontSize.map { $0 / 32 } ?? EInkProfile.defaultTextScale,
            contrast: defaults.object(forKey: Key.contrast) as? Double ?? EInkProfile.defaultContrast,
            contentWidth: defaults.object(forKey: Key.contentWidth) as? Double ?? EInkProfile.defaultContentWidth,
            grayscale: defaults.object(forKey: Key.grayscale) as? Bool ?? true,
            reduceMotion: defaults.object(forKey: Key.reduceMotion) as? Bool ?? true
        )
        textScale = profile.textScale
        contrast = profile.contrast
        contentWidth = profile.contentWidth
        grayscale = profile.grayscale
        reduceMotion = profile.reduceMotion
    }

    var profile: EInkProfile {
        EInkProfile(
            textScale: textScale,
            contrast: contrast,
            contentWidth: contentWidth,
            grayscale: grayscale,
            reduceMotion: reduceMotion
        )
    }

    func increaseTextScale() {
        textScale = min((textScale + 0.1).rounded(toPlaces: 1), 2)
    }

    func decreaseTextScale() {
        textScale = max((textScale - 0.1).rounded(toPlaces: 1), 1)
    }

    func increaseContrast() {
        contrast = min((contrast + 0.1).rounded(toPlaces: 1), 2)
    }

    func decreaseContrast() {
        contrast = max((contrast - 0.1).rounded(toPlaces: 1), 1)
    }

    func increaseContentWidth() {
        contentWidth = min((contentWidth + 0.05).rounded(toPlaces: 2), 0.95)
    }

    func decreaseContentWidth() {
        contentWidth = max((contentWidth - 0.05).rounded(toPlaces: 2), 0.6)
    }

    func reset() {
        let profile = EInkProfile()
        textScale = profile.textScale
        contrast = profile.contrast
        contentWidth = profile.contentWidth
        grayscale = profile.grayscale
        reduceMotion = profile.reduceMotion
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
