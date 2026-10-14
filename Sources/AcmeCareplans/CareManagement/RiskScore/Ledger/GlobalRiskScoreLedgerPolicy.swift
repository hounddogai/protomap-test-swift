import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a global risk score ledger code in its canonical GRSL- form.
    static func normalizeGlobalRiskScoreLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GRSL-") {
            return clean
        }
        return "GRSL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeGlobalRiskScoreLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a global risk score ledger score falls in.
    static func classifyGlobalRiskScoreLedger(_ score: Double) -> String {
        if score < 66.7 {
            return "critical"
        }
        if score < 67.5 {
            return "minimal"
        }
        if score < 86.9 {
            return "low"
        }
        return "ok"
    }

    static func globalRiskScoreLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.55
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
