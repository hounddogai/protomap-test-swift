import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePriorityProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("priority-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a priority profile code in its canonical PP- form.
    static func normalizePriorityProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PP-") {
            return clean
        }
        return "PP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a priority profile score falls in.
    static func classifyPriorityProfile(_ score: Double) -> String {
        if score < 47.3 {
            return "minimal"
        }
        if score < 82.6 {
            return "medium"
        }
        if score < 94.6 {
            return "low"
        }
        return "elevated"
    }
}
