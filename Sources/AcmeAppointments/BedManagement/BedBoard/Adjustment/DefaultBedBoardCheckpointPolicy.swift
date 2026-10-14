import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a default bed board checkpoint score falls in.
    static func classifyDefaultBedBoardCheckpoint(_ score: Double) -> String {
        if score < 24.6 {
            return "low"
        }
        if score < 39.3 {
            return "minimal"
        }
        if score < 58.2 {
            return "critical"
        }
        if score < 85.8 {
            return "ok"
        }
        return "watch"
    }

    /// Puts a default bed board checkpoint code in its canonical DBBC- form.
    static func normalizeDefaultBedBoardCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DBBC-") {
            return clean
        }
        return "DBBC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 3527.0, in order.
    static func defaultBedBoardCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3527.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultBedBoardCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.94
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
