import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a isolation window score falls in.
    static func classifyIsolationWindow(_ score: Double) -> String {
        if score < 53.9 {
            return "minimal"
        }
        if score < 92.3 {
            return "high"
        }
        if score < 99.0 {
            return "medium"
        }
        return "ok"
    }

    static func isolationWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    static func isolationWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 8241.0, in order.
    static func isolationWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8241.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
