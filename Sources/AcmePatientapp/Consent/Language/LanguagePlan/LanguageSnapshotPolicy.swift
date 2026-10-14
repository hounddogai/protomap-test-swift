import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 60727.0, in order.
    static func languageSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60727.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func languageSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a language snapshot code in its canonical LS- form.
    static func normalizeLanguageSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LS-") {
            return clean
        }
        return "LS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func languageSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
