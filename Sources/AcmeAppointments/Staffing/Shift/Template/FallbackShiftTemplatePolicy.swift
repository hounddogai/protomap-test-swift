import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackShiftTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-shift-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackShiftTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 82557.0, in order.
    static func fallbackShiftTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82557.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
