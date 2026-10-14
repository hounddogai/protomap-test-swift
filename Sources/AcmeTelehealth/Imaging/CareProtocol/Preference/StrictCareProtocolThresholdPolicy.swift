import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 23673.0, in order.
    static func strictCareProtocolThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23673.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a strict care protocol threshold score falls in.
    static func classifyStrictCareProtocolThreshold(_ score: Double) -> String {
        if score < 31.4 {
            return "critical"
        }
        if score < 38.2 {
            return "minimal"
        }
        if score < 52.7 {
            return "ok"
        }
        if score < 79.9 {
            return "high"
        }
        return "watch"
    }

    static func strictCareProtocolThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func strictCareProtocolThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }
}
