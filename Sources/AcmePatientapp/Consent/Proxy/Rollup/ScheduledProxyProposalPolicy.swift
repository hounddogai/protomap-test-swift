import AcmePlatform
import Foundation

extension Consent {
    /// Puts a scheduled proxy proposal code in its canonical SPP- form.
    static func normalizeScheduledProxyProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPP-") {
            return clean
        }
        return "SPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 11448.0, in order.
    static func scheduledProxyProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11448.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeScheduledProxyProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
