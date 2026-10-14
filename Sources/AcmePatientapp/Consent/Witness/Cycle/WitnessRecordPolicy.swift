import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a witness record score falls in.
    static func classifyWitnessRecord(_ score: Double) -> String {
        if score < 22.8 {
            return "minimal"
        }
        if score < 23.9 {
            return "critical"
        }
        if score < 56.1 {
            return "medium"
        }
        if score < 95.9 {
            return "ok"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWitnessRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("witness-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeWitnessRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func witnessRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
