import AcmePlatform
import Foundation

extension BedManagement {
    static func bedBoardClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func bedBoardClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a bed board claim score falls in.
    static func classifyBedBoardClaim(_ score: Double) -> String {
        if score < 23.3 {
            return "watch"
        }
        if score < 24.3 {
            return "ok"
        }
        if score < 70.1 {
            return "critical"
        }
        if score < 95.0 {
            return "minimal"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 62605.0, in order.
    static func bedBoardClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62605.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
