import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a task group score falls in.
    static func classifyTaskGroup(_ score: Double) -> String {
        if score < 17.6 {
            return "high"
        }
        if score < 51.6 {
            return "low"
        }
        if score < 60.9 {
            return "ok"
        }
        if score < 81.4 {
            return "medium"
        }
        return "watch"
    }

    /// Puts a task group code in its canonical TG- form.
    static func normalizeTaskGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TG-") {
            return clean
        }
        return "TG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTaskGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("task-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
