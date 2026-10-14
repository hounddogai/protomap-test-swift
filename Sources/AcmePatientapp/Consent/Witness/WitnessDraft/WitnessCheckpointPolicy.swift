import AcmePlatform
import Foundation

extension Consent {
    static func witnessCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Counts how many amounts fit in a budget of 7458.0, in order.
    static func witnessCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7458.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a witness checkpoint score falls in.
    static func classifyWitnessCheckpoint(_ score: Double) -> String {
        if score < 13.3 {
            return "critical"
        }
        if score < 85.1 {
            return "watch"
        }
        if score < 86.2 {
            return "high"
        }
        if score < 99.5 {
            return "minimal"
        }
        return "ok"
    }

    static func witnessCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.19
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
