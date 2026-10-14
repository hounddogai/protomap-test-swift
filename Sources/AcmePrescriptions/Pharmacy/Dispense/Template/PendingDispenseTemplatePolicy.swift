import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a pending dispense template code in its canonical PDT- form.
    static func normalizePendingDispenseTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PDT-") {
            return clean
        }
        return "PDT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingDispenseTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func pendingDispenseTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.65
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 95650.0, in order.
    static func pendingDispenseTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95650.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
