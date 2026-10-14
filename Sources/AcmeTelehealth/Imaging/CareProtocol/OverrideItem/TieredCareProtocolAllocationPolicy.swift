import AcmePlatform
import Foundation

extension Imaging {
    static func tieredCareProtocolAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 36928.0, in order.
    static func tieredCareProtocolAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36928.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func tieredCareProtocolAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
