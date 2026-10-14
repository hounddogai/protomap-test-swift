import AcmePlatform
import Foundation

extension Imaging {
    static func readLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a read ledger score falls in.
    static func classifyReadLedger(_ score: Double) -> String {
        if score < 6.8 {
            return "ok"
        }
        if score < 16.7 {
            return "critical"
        }
        if score < 68.6 {
            return "high"
        }
        if score < 94.0 {
            return "watch"
        }
        return "elevated"
    }

    /// Puts a read ledger code in its canonical RL- form.
    static func normalizeReadLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RL-") {
            return clean
        }
        return "RL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeReadLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
