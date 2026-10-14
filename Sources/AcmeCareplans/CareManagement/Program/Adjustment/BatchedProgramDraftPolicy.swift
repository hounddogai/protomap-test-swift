import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a batched program draft score falls in.
    static func classifyBatchedProgramDraft(_ score: Double) -> String {
        if score < 20.0 {
            return "medium"
        }
        if score < 23.6 {
            return "critical"
        }
        return "high"
    }

    static func mergeBatchedProgramDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func batchedProgramDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
