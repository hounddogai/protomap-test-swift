import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a manual outreach assignment code in its canonical MOA- form.
    static func normalizeManualOutreachAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MOA-") {
            return clean
        }
        return "MOA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualOutreachAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.84
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 49871.0, in order.
    static func manualOutreachAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49871.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualOutreachAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
