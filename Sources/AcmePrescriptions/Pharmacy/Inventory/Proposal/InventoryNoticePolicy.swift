import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 20290.0, in order.
    static func inventoryNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20290.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func inventoryNoticeSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a inventory notice score falls in.
    static func classifyInventoryNotice(_ score: Double) -> String {
        if score < 92.8 {
            return "ok"
        }
        if score < 97.1 {
            return "watch"
        }
        if score < 99.0 {
            return "low"
        }
        return "minimal"
    }
}
