import AcmePlatform
import Foundation

extension Imaging {
    static func modalityAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeModalityAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a modality assignment score falls in.
    static func classifyModalityAssignment(_ score: Double) -> String {
        if score < 20.4 {
            return "watch"
        }
        if score < 27.5 {
            return "ok"
        }
        if score < 32.1 {
            return "medium"
        }
        if score < 77.3 {
            return "high"
        }
        return "low"
    }
}
