import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a priority window score falls in.
    static func classifyPriorityWindow(_ score: Double) -> String {
        if score < 67.4 {
            return "ok"
        }
        if score < 82.5 {
            return "critical"
        }
        if score < 92.8 {
            return "low"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePriorityWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("priority-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func priorityWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Puts a priority window code in its canonical PW- form.
    static func normalizePriorityWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PW-") {
            return clean
        }
        return "PW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
