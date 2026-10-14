import AcmePlatform
import Foundation

extension Consent {
    /// Puts a lenient language profile code in its canonical LLP- form.
    static func normalizeLenientLanguageProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LLP-") {
            return clean
        }
        return "LLP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientLanguageProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeLenientLanguageProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 40911.0, in order.
    static func lenientLanguageProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40911.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
