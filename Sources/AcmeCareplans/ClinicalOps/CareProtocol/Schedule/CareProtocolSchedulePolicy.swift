import AcmePlatform
import Foundation

extension ClinicalOps {
    static func careProtocolScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 1500.0, in order.
    static func careProtocolScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1500.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a care protocol schedule score falls in.
    static func classifyCareProtocolSchedule(_ score: Double) -> String {
        if score < 58.8 {
            return "ok"
        }
        if score < 78.7 {
            return "medium"
        }
        if score < 86.2 {
            return "low"
        }
        return "critical"
    }
}
