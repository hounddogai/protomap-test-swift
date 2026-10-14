import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 77507.0, in order.
    static func pendingNetworkPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77507.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergePendingNetworkPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a pending network policy code in its canonical PNP- form.
    static func normalizePendingNetworkPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PNP-") {
            return clean
        }
        return "PNP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
