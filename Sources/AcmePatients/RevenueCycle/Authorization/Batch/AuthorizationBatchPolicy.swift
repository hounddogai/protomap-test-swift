import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a authorization batch score falls in.
    static func classifyAuthorizationBatch(_ score: Double) -> String {
        if score < 2.3 {
            return "minimal"
        }
        if score < 36.3 {
            return "ok"
        }
        if score < 55.3 {
            return "elevated"
        }
        if score < 57.2 {
            return "watch"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 62408.0, in order.
    static func authorizationBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62408.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func authorizationBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
