import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a capped recall snapshot code in its canonical CRS- form.
    static func normalizeCappedRecallSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRS-") {
            return clean
        }
        return "CRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCappedRecallSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func cappedRecallSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func cappedRecallSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
