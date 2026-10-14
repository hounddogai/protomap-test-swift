import AcmePlatform
import Foundation

extension Imaging {
    static func mergeLenientCareProtocolSegmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a lenient care protocol segment score falls in.
    static func classifyLenientCareProtocolSegment(_ score: Double) -> String {
        if score < 15.5 {
            return "elevated"
        }
        if score < 60.6 {
            return "low"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientCareProtocolSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-care-protocol-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 26269.0, in order.
    static func lenientCareProtocolSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26269.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
