import AcmePlatform
import Foundation

extension Labs {
    static func adaptiveCourierMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Puts a adaptive courier milestone code in its canonical ACM- form.
    static func normalizeAdaptiveCourierMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACM-") {
            return clean
        }
        return "ACM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveCourierMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveCourierMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-courier-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
