import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a pending risk score checkpoint code in its canonical PRSC- form.
    static func normalizePendingRiskScoreCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRSC-") {
            return clean
        }
        return "PRSC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a pending risk score checkpoint score falls in.
    static func classifyPendingRiskScoreCheckpoint(_ score: Double) -> String {
        if score < 7.8 {
            return "critical"
        }
        if score < 46.4 {
            return "elevated"
        }
        if score < 73.8 {
            return "minimal"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 41364.0, in order.
    static func pendingRiskScoreCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41364.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
