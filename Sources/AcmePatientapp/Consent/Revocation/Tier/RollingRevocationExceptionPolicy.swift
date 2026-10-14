import AcmePlatform
import Foundation

extension Consent {
    /// Puts a rolling revocation exception code in its canonical RRE- form.
    static func normalizeRollingRevocationExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRE-") {
            return clean
        }
        return "RRE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 58187.0, in order.
    static func rollingRevocationExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58187.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeRollingRevocationExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
