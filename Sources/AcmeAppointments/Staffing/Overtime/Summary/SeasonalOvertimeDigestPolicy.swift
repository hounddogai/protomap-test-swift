import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a seasonal overtime digest code in its canonical SOD- form.
    static func normalizeSeasonalOvertimeDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOD-") {
            return clean
        }
        return "SOD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalOvertimeDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.39
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeSeasonalOvertimeDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 2444.0, in order.
    static func seasonalOvertimeDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2444.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
