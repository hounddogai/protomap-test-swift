import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a shift target code in its canonical ST- form.
    static func normalizeShiftTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ST-") {
            return clean
        }
        return "ST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a shift target score falls in.
    static func classifyShiftTarget(_ score: Double) -> String {
        if score < 50.3 {
            return "high"
        }
        if score < 74.4 {
            return "medium"
        }
        if score < 81.2 {
            return "elevated"
        }
        if score < 92.2 {
            return "watch"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 18908.0, in order.
    static func shiftTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 18908.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeShiftTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
