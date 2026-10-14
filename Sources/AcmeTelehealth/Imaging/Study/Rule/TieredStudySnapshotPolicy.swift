import AcmePlatform
import Foundation

extension Imaging {
    static func tieredStudySnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredStudySnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-study-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeTieredStudySnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a tiered study snapshot code in its canonical TSS- form.
    static func normalizeTieredStudySnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TSS-") {
            return clean
        }
        return "TSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
