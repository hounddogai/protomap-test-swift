import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a fallback risk score checkpoint code in its canonical FRSC- form.
    static func normalizeFallbackRiskScoreCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRSC-") {
            return clean
        }
        return "FRSC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackRiskScoreCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func fallbackRiskScoreCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.05
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 57333.0, in order.
    static func fallbackRiskScoreCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57333.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
