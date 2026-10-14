import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProgramManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("program-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func programManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a program manifest score falls in.
    static func classifyProgramManifest(_ score: Double) -> String {
        if score < 14.6 {
            return "critical"
        }
        if score < 30.4 {
            return "watch"
        }
        return "elevated"
    }
}
