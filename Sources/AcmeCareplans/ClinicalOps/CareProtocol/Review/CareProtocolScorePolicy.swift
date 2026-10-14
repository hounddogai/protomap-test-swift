import AcmePlatform
import Foundation

extension ClinicalOps {
    static func careProtocolScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 49845.0, in order.
    static func careProtocolScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49845.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a care protocol score score falls in.
    static func classifyCareProtocolScore(_ score: Double) -> String {
        if score < 35.1 {
            return "high"
        }
        if score < 51.9 {
            return "critical"
        }
        if score < 88.8 {
            return "elevated"
        }
        if score < 97.0 {
            return "low"
        }
        return "medium"
    }
}
