import AcmePlatform
import Foundation

extension Consent {
    /// Puts a rolling consent form allocation code in its canonical RCFA- form.
    static func normalizeRollingConsentFormAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCFA-") {
            return clean
        }
        return "RCFA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRollingConsentFormAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 94131.0, in order.
    static func rollingConsentFormAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94131.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
