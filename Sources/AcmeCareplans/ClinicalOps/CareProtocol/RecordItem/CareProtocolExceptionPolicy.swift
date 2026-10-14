import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol exception score falls in.
    static func classifyCareProtocolException(_ score: Double) -> String {
        if score < 21.6 {
            return "elevated"
        }
        if score < 71.2 {
            return "ok"
        }
        return "medium"
    }

    static func careProtocolExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolException() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func careProtocolExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
