import AcmePlatform
import Foundation

extension CareManagement {
    static func lenientGoalVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a lenient goal variance score falls in.
    static func classifyLenientGoalVariance(_ score: Double) -> String {
        if score < 14.7 {
            return "medium"
        }
        if score < 40.8 {
            return "watch"
        }
        if score < 99.2 {
            return "ok"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientGoalVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-goal-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a lenient goal variance code in its canonical LGV- form.
    static func normalizeLenientGoalVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LGV-") {
            return clean
        }
        return "LGV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
