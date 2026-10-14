import AcmePlatform
import Foundation

extension Consent {
    static func mergeManualWitnessBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a manual witness batch score falls in.
    static func classifyManualWitnessBatch(_ score: Double) -> String {
        if score < 16.9 {
            return "elevated"
        }
        if score < 24.6 {
            return "watch"
        }
        if score < 94.2 {
            return "critical"
        }
        return "low"
    }

    static func manualWitnessBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func manualWitnessBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
