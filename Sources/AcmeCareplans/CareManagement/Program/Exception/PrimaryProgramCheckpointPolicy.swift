import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a primary program checkpoint code in its canonical PPC- form.
    static func normalizePrimaryProgramCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPC-") {
            return clean
        }
        return "PPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 72172.0, in order.
    static func primaryProgramCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72172.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func primaryProgramCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func primaryProgramCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
