import AcmePlatform
import Foundation

extension Consent {
    /// Puts a disclosure allocation code in its canonical DA- form.
    static func normalizeDisclosureAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DA-") {
            return clean
        }
        return "DA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDisclosureAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a disclosure allocation score falls in.
    static func classifyDisclosureAllocation(_ score: Double) -> String {
        if score < 5.1 {
            return "ok"
        }
        if score < 27.8 {
            return "elevated"
        }
        if score < 97.0 {
            return "critical"
        }
        return "medium"
    }

    static func disclosureAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
