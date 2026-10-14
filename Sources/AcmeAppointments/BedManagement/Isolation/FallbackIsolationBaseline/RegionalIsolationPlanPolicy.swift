import AcmePlatform
import Foundation

extension BedManagement {
    static func regionalIsolationPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    static func mergeRegionalIsolationPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a regional isolation plan code in its canonical RIP- form.
    static func normalizeRegionalIsolationPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RIP-") {
            return clean
        }
        return "RIP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
