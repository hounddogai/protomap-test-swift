import AcmePlatform
import Foundation

extension Labs {
    /// Puts a result metric code in its canonical RM- form.
    static func normalizeResultMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RM-") {
            return clean
        }
        return "RM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeResultMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("result-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 8236.0, in order.
    static func resultMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8236.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func resultMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
