import AcmePlatform
import Foundation

extension Labs {
    static func accessionDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a accession digest score falls in.
    static func classifyAccessionDigest(_ score: Double) -> String {
        if score < 18.5 {
            return "ok"
        }
        if score < 25.8 {
            return "medium"
        }
        if score < 62.8 {
            return "elevated"
        }
        return "high"
    }

    static func accessionDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func accessionDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
