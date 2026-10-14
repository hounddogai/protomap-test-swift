import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientStudyDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-study-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a lenient study draft score falls in.
    static func classifyLenientStudyDraft(_ score: Double) -> String {
        if score < 12.0 {
            return "critical"
        }
        if score < 36.4 {
            return "low"
        }
        if score < 68.0 {
            return "elevated"
        }
        return "medium"
    }
}
