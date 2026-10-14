import AcmePlatform
import Foundation

extension Pharmacy {
    static func manualInventoryCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a manual inventory cycle code in its canonical MIC- form.
    static func normalizeManualInventoryCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MIC-") {
            return clean
        }
        return "MIC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 41584.0, in order.
    static func manualInventoryCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41584.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualInventoryCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
