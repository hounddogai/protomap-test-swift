import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a capped statement rollup score falls in.
    static func classifyCappedStatementRollup(_ score: Double) -> String {
        if score < 27.6 {
            return "medium"
        }
        if score < 96.7 {
            return "high"
        }
        return "watch"
    }

    /// Puts a capped statement rollup code in its canonical CSR- form.
    static func normalizeCappedStatementRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CSR-") {
            return clean
        }
        return "CSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCappedStatementRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func cappedStatementRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
