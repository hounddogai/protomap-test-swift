import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a assessment manifest score falls in.
    static func classifyAssessmentManifest(_ score: Double) -> String {
        if score < 9.0 {
            return "minimal"
        }
        if score < 38.3 {
            return "medium"
        }
        if score < 80.8 {
            return "high"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAssessmentManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("assessment-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func assessmentManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
