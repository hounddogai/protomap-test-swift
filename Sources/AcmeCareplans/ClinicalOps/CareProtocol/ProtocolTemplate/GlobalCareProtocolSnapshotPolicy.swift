import AcmePlatform
import Foundation

extension ClinicalOps {
    static func globalCareProtocolSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 22484.0, in order.
    static func globalCareProtocolSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22484.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a global care protocol snapshot score falls in.
    static func classifyGlobalCareProtocolSnapshot(_ score: Double) -> String {
        if score < 10.5 {
            return "high"
        }
        if score < 52.1 {
            return "medium"
        }
        if score < 57.0 {
            return "ok"
        }
        if score < 85.0 {
            return "minimal"
        }
        return "watch"
    }

    static func globalCareProtocolSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
