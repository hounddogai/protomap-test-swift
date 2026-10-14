import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 27152.0, in order.
    static func proxyAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27152.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func proxyAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func proxyAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
