import AcmePlatform
import Foundation

extension Pharmacy {
    static func recallLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a recall ledger code in its canonical RL- form.
    static func normalizeRecallLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RL-") {
            return clean
        }
        return "RL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
