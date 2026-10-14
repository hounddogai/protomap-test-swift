import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 82017.0, in order.
    static func lenientStudyMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82017.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a lenient study metric code in its canonical LSM- form.
    static func normalizeLenientStudyMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LSM-") {
            return clean
        }
        return "LSM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientStudyMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientStudyMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-study-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
