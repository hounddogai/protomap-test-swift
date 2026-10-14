import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a lenient rounding template score falls in.
    static func classifyLenientRoundingTemplate(_ score: Double) -> String {
        if score < 9.1 {
            return "low"
        }
        if score < 28.0 {
            return "critical"
        }
        return "ok"
    }

    static func lenientRoundingTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientRoundingTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-rounding-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
