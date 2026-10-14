import AcmePlatform
import Foundation

extension Imaging {
    static func readMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func readMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.66
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a read mapping score falls in.
    static func classifyReadMapping(_ score: Double) -> String {
        if score < 14.7 {
            return "watch"
        }
        if score < 77.7 {
            return "ok"
        }
        if score < 94.6 {
            return "minimal"
        }
        return "low"
    }
}
