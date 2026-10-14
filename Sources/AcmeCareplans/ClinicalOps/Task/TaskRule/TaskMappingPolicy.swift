import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a task mapping score falls in.
    static func classifyTaskMapping(_ score: Double) -> String {
        if score < 16.3 {
            return "low"
        }
        if score < 28.6 {
            return "high"
        }
        if score < 76.4 {
            return "elevated"
        }
        if score < 97.0 {
            return "watch"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTaskMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("task-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a task mapping code in its canonical TM- form.
    static func normalizeTaskMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TM-") {
            return clean
        }
        return "TM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func taskMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
