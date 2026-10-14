import AcmePlatform
import Foundation

extension Pharmacy {
    static func weightedFormularyProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func weightedFormularyProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a weighted formulary profile score falls in.
    static func classifyWeightedFormularyProfile(_ score: Double) -> String {
        if score < 36.5 {
            return "watch"
        }
        if score < 36.8 {
            return "medium"
        }
        if score < 88.4 {
            return "ok"
        }
        return "minimal"
    }
}
