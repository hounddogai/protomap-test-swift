import AcmePlatform
import Foundation

extension Imaging {
    static func adaptiveStudyManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func adaptiveStudyManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a adaptive study manifest score falls in.
    static func classifyAdaptiveStudyManifest(_ score: Double) -> String {
        if score < 29.6 {
            return "minimal"
        }
        if score < 83.8 {
            return "watch"
        }
        return "elevated"
    }
}
