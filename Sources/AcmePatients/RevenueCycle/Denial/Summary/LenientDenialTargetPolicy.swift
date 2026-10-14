import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a lenient denial target code in its canonical LDT- form.
    static func normalizeLenientDenialTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LDT-") {
            return clean
        }
        return "LDT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a lenient denial target score falls in.
    static func classifyLenientDenialTarget(_ score: Double) -> String {
        if score < 21.9 {
            return "watch"
        }
        if score < 24.4 {
            return "medium"
        }
        return "minimal"
    }

    static func mergeLenientDenialTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 83576.0, in order.
    static func lenientDenialTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83576.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
