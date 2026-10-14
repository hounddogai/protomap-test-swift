import AcmePlatform
import Foundation

extension Consent {
    /// Puts a global revocation record code in its canonical GRR- form.
    static func normalizeGlobalRevocationRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GRR-") {
            return clean
        }
        return "GRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeGlobalRevocationRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a global revocation record score falls in.
    static func classifyGlobalRevocationRecord(_ score: Double) -> String {
        if score < 21.3 {
            return "minimal"
        }
        if score < 26.9 {
            return "low"
        }
        if score < 56.8 {
            return "watch"
        }
        if score < 61.0 {
            return "high"
        }
        return "ok"
    }

    static func globalRevocationRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
