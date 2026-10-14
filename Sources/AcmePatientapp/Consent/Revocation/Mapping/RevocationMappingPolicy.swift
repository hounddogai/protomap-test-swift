import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a revocation mapping score falls in.
    static func classifyRevocationMapping(_ score: Double) -> String {
        if score < 52.1 {
            return "ok"
        }
        if score < 93.4 {
            return "watch"
        }
        return "medium"
    }

    static func revocationMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func revocationMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func revocationMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.04
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
