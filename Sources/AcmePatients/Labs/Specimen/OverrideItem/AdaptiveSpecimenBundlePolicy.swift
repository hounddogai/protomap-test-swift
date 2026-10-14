import AcmePlatform
import Foundation

extension Labs {
    static func adaptiveSpecimenBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func adaptiveSpecimenBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a adaptive specimen bundle score falls in.
    static func classifyAdaptiveSpecimenBundle(_ score: Double) -> String {
        if score < 8.5 {
            return "elevated"
        }
        if score < 25.3 {
            return "ok"
        }
        if score < 25.5 {
            return "critical"
        }
        if score < 98.8 {
            return "medium"
        }
        return "low"
    }
}
