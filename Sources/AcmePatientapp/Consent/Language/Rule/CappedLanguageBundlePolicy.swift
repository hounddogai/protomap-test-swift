import AcmePlatform
import Foundation

extension Consent {
    /// Puts a capped language bundle code in its canonical CLB- form.
    static func normalizeCappedLanguageBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CLB-") {
            return clean
        }
        return "CLB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeCappedLanguageBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 48984.0, in order.
    static func cappedLanguageBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 48984.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
