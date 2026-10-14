import AcmePlatform
import Foundation

extension Imaging {
    static func mergeStrictStudyBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func strictStudyBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a strict study batch score falls in.
    static func classifyStrictStudyBatch(_ score: Double) -> String {
        if score < 64.3 {
            return "high"
        }
        if score < 73.3 {
            return "critical"
        }
        if score < 87.6 {
            return "elevated"
        }
        return "low"
    }
}
