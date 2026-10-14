import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 88669.0, in order.
    static func cappedReadBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 88669.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func cappedReadBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeCappedReadBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedReadBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-read-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
